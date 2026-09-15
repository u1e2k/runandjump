extends Node2D

signal stomped(enemy: Node2D)
signal defeated(pos: Vector2)
signal enemy_shoot(pos: Vector2, dir: Vector2)

@export var enemy_type: String = "patrol" # "patrol", "hopper", "drone", "shield_heavy", "turret", "rusher"
@export var move_speed: float = 60.0
@export var patrol_distance: float = 60.0
@export var hp: int = 3
@export var max_hp: int = 3
@export var contact_damage: int = 18

var start_pos: Vector2 = Vector2.ZERO
var move_dir: float = -1.0
var anim_timer: float = 0.0
var is_dead: bool = false
var squash_y: float = 1.0
var hit_flash_timer: float = 0.0
var shoot_cooldown: float = 2.0
var is_rushing: bool = false

# ゾーンカラー
var zone_color: Color = Color(1.0, 0.2, 0.4)

func _ready() -> void:
	start_pos = position
	match enemy_type:
		"patrol":
			hp = 3
			max_hp = 3
			move_speed = 60.0
			contact_damage = 18
		"hopper":
			hp = 2
			max_hp = 2
			move_speed = 50.0
			contact_damage = 15
		"drone":
			hp = 2
			max_hp = 2
			move_speed = 45.0
			contact_damage = 14
		"shield_heavy":
			hp = 6
			max_hp = 6
			move_speed = 30.0
			contact_damage = 25
		"turret":
			hp = 4
			max_hp = 4
			move_speed = 0.0
			contact_damage = 20
			shoot_cooldown = randf_range(1.5, 2.5)
		"rusher":
			hp = 2
			max_hp = 2
			move_speed = 40.0
			contact_damage = 20

func _process(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		
	if is_dead:
		squash_y = lerp(squash_y, 0.1, 20.0 * delta)
		queue_redraw()
		return
		
	anim_timer += delta
	
	match enemy_type:
		"patrol":
			position.x += move_dir * move_speed * delta
			if abs(position.x - start_pos.x) > patrol_distance:
				move_dir *= -1.0
		"hopper":
			var hop_speed: float = anim_timer * 4.0
			position.y = start_pos.y + sin(hop_speed) * 18.0
			position.x += move_dir * move_speed * delta
			if abs(position.x - start_pos.x) > patrol_distance:
				move_dir *= -1.0
		"drone":
			# 空中浮遊
			position.y = start_pos.y + sin(anim_timer * 3.0) * 24.0
			position.x += move_dir * move_speed * delta
			if abs(position.x - start_pos.x) > patrol_distance:
				move_dir *= -1.0
		"shield_heavy":
			position.x += move_dir * move_speed * delta
			if abs(position.x - start_pos.x) > patrol_distance * 0.5:
				move_dir *= -1.0
		"turret":
			shoot_cooldown -= delta
			if shoot_cooldown <= 0.0:
				shoot_cooldown = 2.4
				enemy_shoot.emit(global_position + Vector2(-16.0, 0.0), Vector2(-1.0, 0.0))
		"rusher":
			# 画面内に近づいたら突進
			if not is_rushing and global_position.x < 650.0:
				is_rushing = true
				move_speed = 180.0
				move_dir = -1.0
			position.x += move_dir * move_speed * delta
			
	queue_redraw()

func take_damage(amount: int, is_piercing: bool = false) -> void:
	if is_dead:
		return
		
	# シールドエネミーは正面からの通常弾を半減/防御
	if enemy_type == "shield_heavy" and not is_piercing and amount < 90:
		amount = max(1, amount - 1)
		
	hp -= amount
	hit_flash_timer = 0.1
	if hp <= 0:
		is_dead = true
		defeated.emit(global_position)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.1)
		tween.tween_callback(queue_free)
	else:
		position.x += 8.0

func on_stomp_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("bounce") and body.velocity.y >= -50.0:
		body.bounce(1.0)
		stomped.emit(self)
		take_damage(99, true)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 0.1), 0.12)

func on_hit_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("take_damage"):
		if body.velocity.y < -50.0 or body.global_position.y > global_position.y - 10.0:
			body.take_damage(contact_damage)

func _draw() -> void:
	if hit_flash_timer > 0.0:
		draw_circle(Vector2.ZERO, 18.0, Color(1.0, 1.0, 1.0, 0.9))
		return
		
	match enemy_type:
		"drone":
			# 飛行ドローン（球体＋回転プロペラ/リング）
			var r: float = 14.0
			draw_circle(Vector2.ZERO, r, Color(0.1, 0.15, 0.3, 0.95))
			draw_circle(Vector2.ZERO, r, Color(0.2, 0.85, 1.0), false, 2.0)
			# 赤いセンサーアイ
			draw_circle(Vector2(-4, 0), 4.0, Color(1.0, 0.2, 0.3, 0.95))
			# 浮遊リング
			var ring_x := cos(anim_timer * 8.0) * 18.0
			draw_line(Vector2(-18, -10), Vector2(18, -10), Color(0.4, 0.9, 1.0, 0.8), 2.0)
			
		"shield_heavy":
			# 重装シールドエネミー（大型四角＋前部シールドライン）
			var sz := Vector2(36.0, 36.0 * squash_y)
			var rect := Rect2(-sz / 2.0, sz)
			draw_rect(rect, Color(0.25, 0.1, 0.15, 0.95), true)
			draw_rect(rect, Color(1.0, 0.3, 0.2, 1.0), false, 2.5)
			# 前面エネルギーシールド
			var shield_glow := 0.6 + 0.4 * sin(anim_timer * 6.0)
			draw_line(Vector2(-sz.x/2 - 6, -sz.y/2), Vector2(-sz.x/2 - 6, sz.y/2), Color(0.2, 0.9, 1.0, shield_glow), 4.0)
			# アイ
			draw_rect(Rect2(-12, -4, 8, 8), Color(1.0, 0.8, 0.2), true)
			
		"turret":
			# 砲台（固定台座＋回転バレル）
			draw_polygon(PackedVector2Array([
				Vector2(-16, 16), Vector2(16, 16), Vector2(10, -6), Vector2(-10, -6)
			]), [Color(0.12, 0.15, 0.22, 0.95)])
			draw_polyline(PackedVector2Array([
				Vector2(-16, 16), Vector2(16, 16), Vector2(10, -6), Vector2(-10, -6), Vector2(-16, 16)
			]), Color(0.9, 0.6, 0.1, 1.0), 2.0)
			# 砲身（左向き）
			draw_rect(Rect2(-24, -4, 16, 8), Color(0.9, 0.2, 0.3), true)
			draw_circle(Vector2(0, -6), 6.0, Color(1.0, 0.85, 0.2))
			
		"rusher":
			# サイバーハウンド（鋭利な三角形・高速感）
			var pts := PackedVector2Array([
				Vector2(-20, 0), Vector2(12, -12), Vector2(6, 0), Vector2(12, 12)
			])
			draw_colored_polygon(pts, Color(0.4, 0.05, 0.2, 0.95))
			draw_polyline(pts, Color(1.0, 0.1, 0.5, 1.0), 2.2)
			# 残像風ライン
			if is_rushing:
				draw_line(Vector2(16, -6), Vector2(30, -6), Color(1.0, 0.3, 0.6, 0.6), 2.0)
				draw_line(Vector2(16, 6), Vector2(30, 6), Color(1.0, 0.3, 0.6, 0.6), 2.0)
				
		_: # patrol, hopper
			var sz := Vector2(30.0, 30.0 * squash_y)
			var rect := Rect2(-sz / 2.0, sz)
			draw_rect(rect.grow(3.0), Color(1.0, 0.1, 0.3, 0.25), true)
			draw_rect(rect, Color(0.35, 0.05, 0.15, 0.9), true)
			draw_rect(rect, Color(1.0, 0.2, 0.4, 1.0), false, 2.0)
			var eye_rect := Rect2(-10.0, -6.0 * squash_y, 20.0, 5.0 * squash_y)
			draw_rect(eye_rect, Color(1.0, 0.8, 0.2, 1.0), true)
			
	# HPバー表示
	if hp < max_hp and not is_dead:
		var bar_w := 26.0
		var bar_h := 3.5
		var bar_bg := Rect2(-bar_w/2, -22, bar_w, bar_h)
		var bar_fg := Rect2(-bar_w/2, -22, bar_w * (float(hp) / float(max_hp)), bar_h)
		draw_rect(bar_bg, Color(0.2, 0.2, 0.2, 0.8), true)
		draw_rect(bar_fg, Color(0.2, 1.0, 0.3, 0.95), true)
