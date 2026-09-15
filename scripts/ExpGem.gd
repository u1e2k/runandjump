extends Node2D

@export var exp_value: int = 15
var target_player: CharacterBody2D = null
var velocity: Vector2 = Vector2.ZERO
var attract_speed: float = 0.0
var base_magnet_distance: float = 180.0
var bob_phase: float = 0.0

func _ready() -> void:
	# 出現時のランダムポップ
	var angle := randf_range(-PI, 0.0)
	var spd := randf_range(80.0, 180.0)
	velocity = Vector2(cos(angle), sin(angle)) * spd
	bob_phase = randf() * TAU

func _process(delta: float) -> void:
	bob_phase += delta * 6.0
	
	if is_instance_valid(target_player):
		var magnet_range := base_magnet_distance
		if target_player.has_method("get_magnet_range"):
			magnet_range = target_player.get_magnet_range()
			
		var dist := global_position.distance_to(target_player.global_position)
		if dist < magnet_range:
			attract_speed = min(attract_speed + delta * 900.0, 750.0)
			var dir := (target_player.global_position - global_position).normalized()
			global_position += dir * attract_speed * delta
			
			# 回収判定
			if dist < 24.0:
				if target_player.has_method("add_exp"):
					target_player.add_exp(exp_value)
				queue_free()
				return
		else:
			# 通常物理移動（左スクロールに合わせて流れる）
			velocity.y += 400.0 * delta
			global_position += velocity * delta
			velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)
			global_position.x -= 200.0 * delta
	else:
		global_position.x -= 200.0 * delta
		
	if global_position.x < -100.0 or global_position.y > 800.0:
		queue_free()
		
	queue_redraw()

func _draw() -> void:
	# ダイヤ型のネオンEXPジェム
	var s := 6.0 + sin(bob_phase) * 1.0
	var pts := PackedVector2Array([
		Vector2(0, -s * 1.3),
		Vector2(s, 0),
		Vector2(0, s * 1.3),
		Vector2(-s, 0)
	])
	draw_colored_polygon(pts, Color(0.2, 0.9, 0.4, 0.85))
	draw_polyline(pts, Color(0.8, 1.0, 0.4, 1.0), 1.5)
	draw_circle(Vector2.ZERO, s * 0.4, Color(1.0, 1.0, 1.0, 0.9))
