extends Area2D

signal collected(value: int)

@export var coin_value: int = 1
var target_player: CharacterBody2D = null
var velocity: Vector2 = Vector2.ZERO
var attract_speed: float = 0.0
var base_magnet_distance: float = 160.0
var spin_phase: float = 0.0
var is_collected: bool = false
var is_popped: bool = false

func _ready() -> void:
	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 16.0
	col.shape = circle
	add_child(col)
	
	body_entered.connect(_on_body_entered)
	spin_phase = randf() * TAU

func set_pop_velocity(dir_vel: Vector2) -> void:
	is_popped = true
	velocity = dir_vel

func _process(delta: float) -> void:
	if is_collected:
		return
		
	spin_phase += delta * 5.0
	
	if is_instance_valid(target_player):
		var magnet_range := base_magnet_distance
		if target_player.has_method("get_magnet_range"):
			magnet_range = target_player.get_magnet_range()
			
		var dist := global_position.distance_to(target_player.global_position)
		if dist < magnet_range:
			attract_speed = min(attract_speed + delta * 1200.0, 900.0)
			var dir := (target_player.global_position - global_position).normalized()
			global_position += dir * attract_speed * delta
			
			if dist < 24.0:
				collect()
				return
		elif is_popped:
			velocity.y += 450.0 * delta
			global_position += velocity * delta
			velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)
			global_position.x -= 200.0 * delta
	elif is_popped:
		velocity.y += 450.0 * delta
		global_position += velocity * delta
		velocity = velocity.lerp(Vector2.ZERO, 3.0 * delta)
		global_position.x -= 200.0 * delta
		
	if global_position.x < -100.0 or global_position.y > 800.0:
		queue_free()
		
	queue_redraw()

func _on_body_entered(body: Node2D) -> void:
	if is_collected:
		return
	if body.name == "Player":
		collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit(coin_value)
	
	# スケール拡大とフェードアウト
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.12)
	tween.tween_property(self, "modulate:a", 0.0, 0.08)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# 3D回転風の幅変化
	var width_scale: float = maxf(0.2, absf(cos(spin_phase)))
	
	var r: float = 10.0
	var outer_color := Color(1.0, 0.85, 0.2, 0.95)
	var inner_color := Color(1.0, 0.65, 0.1, 0.95)
	var shine_color := Color(1.0, 1.0, 0.8, 0.9)
	
	# 外枠
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := float(i) / 16.0 * TAU
		pts.append(Vector2(cos(angle) * r * width_scale, sin(angle) * r))
	draw_colored_polygon(pts, inner_color)
	draw_polyline(pts, outer_color, 2.0)
	
	# 内側コア（キラッと光る）
	if width_scale > 0.4:
		var inner_pts := PackedVector2Array()
		for i in range(12):
			var angle := float(i) / 12.0 * TAU
			inner_pts.append(Vector2(cos(angle) * (r * 0.5) * width_scale, sin(angle) * (r * 0.5)))
		draw_colored_polygon(inner_pts, shine_color)
