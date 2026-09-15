extends CharacterBody2D

signal died
signal jumped
signal bounced
signal landed
signal damaged(current_hp: int, max_hp: int)
signal exp_gained(current: int, target: int, level: int)
signal leveled_up(new_level: int)
signal shoot_bullet(pos: Vector2, dir: Vector2)
signal shockwave_triggered(pos: Vector2)

# 物理定数
const GRAVITY: float = 1450.0
const JUMP_VELOCITY: float = -560.0
const MIN_JUMP_VELOCITY: float = -220.0
const BOUNCE_VELOCITY: float = -640.0
const MAX_FALL_SPEED: float = 850.0

# 快適性パラメータ
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_alive: bool = true
var was_on_floor: bool = false

# HP（3桁スケール: 初期100） & 無敵時間
var max_hp: int = 100
var current_hp: int = 100
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

# レベル & EXP
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 35

# スキル & パッシブ
var skills: Dictionary = {}
var max_air_jumps: int = 1 # 最初から2段ジャンプ
var air_jumps_left: int = 1
var shoot_interval: float = 0.75
var shoot_timer: float = 0.0
var bullet_count: int = 1
var magnet_multiplier: float = 1.0
var has_spike_boots: bool = false
var has_stomp_shock: bool = false

# ビジュアル用
var squash_stretch: Vector2 = Vector2(1.0, 1.0)
var rotation_angle: float = 0.0
var trail_positions: Array[Vector2] = []
const MAX_TRAIL: int = 8

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	is_alive = true
	trail_positions.clear()

func reset(start_pos: Vector2) -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	is_alive = true
	max_hp = 100
	current_hp = max_hp
	invincible_timer = 0.0
	level = 1
	current_exp = 0
	exp_to_next_level = 35
	skills.clear()
	max_air_jumps = 1
	air_jumps_left = 1
	shoot_interval = 0.75
	shoot_timer = 0.0
	bullet_count = 1
	magnet_multiplier = 1.0
	has_spike_boots = false
	has_stomp_shock = false
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	squash_stretch = Vector2(1.0, 1.0)
	rotation_angle = 0.0
	trail_positions.clear()
	visible = true
	damaged.emit(current_hp, max_hp)
	exp_gained.emit(current_exp, exp_to_next_level, level)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	if invincible_timer > 0.0:
		invincible_timer -= delta
		
	trail_positions.push_front(global_position)
	if trail_positions.size() > MAX_TRAIL:
		trail_positions.pop_back()
		
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		execute_auto_shoot()
		
	if not is_on_floor():
		velocity.y += GRAVITY * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)
		coyote_timer -= delta
		rotation_angle += delta * 6.0
	else:
		coyote_timer = COYOTE_TIME
		air_jumps_left = max_air_jumps
		rotation_angle = lerp_angle(rotation_angle, 0.0, 15.0 * delta)
		if not was_on_floor:
			squash_stretch = Vector2(1.35, 0.65)
			landed.emit()
			
	was_on_floor = is_on_floor()
	squash_stretch = squash_stretch.lerp(Vector2(1.0, 1.0), 12.0 * delta)
	
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
		if not is_on_floor() and coyote_timer <= 0.0 and air_jumps_left > 0:
			execute_air_jump()
	else:
		jump_buffer_timer -= delta
		
	if jump_buffer_timer > 0.0 and (is_on_floor() or coyote_timer > 0.0):
		execute_jump()
		
	if Input.is_action_just_released("jump") and velocity.y < MIN_JUMP_VELOCITY:
		velocity.y = MIN_JUMP_VELOCITY
		
	move_and_slide()
	queue_redraw()

func execute_jump() -> void:
	velocity.y = JUMP_VELOCITY
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	squash_stretch = Vector2(0.7, 1.4)
	jumped.emit()

func execute_air_jump() -> void:
	air_jumps_left -= 1
	velocity.y = JUMP_VELOCITY * 0.95
	jump_buffer_timer = 0.0
	squash_stretch = Vector2(0.65, 1.45)
	rotation_angle += PI
	jumped.emit()

func execute_auto_shoot() -> void:
	var muzzle_pos := global_position + Vector2(20.0, 0.0)
	for i in range(bullet_count):
		var angle_offset: float = 0.0
		if bullet_count > 1:
			angle_offset = (float(i) - float(bullet_count - 1) * 0.5) * 0.15
		var dir := Vector2(cos(angle_offset), sin(angle_offset))
		shoot_bullet.emit(muzzle_pos, dir)

func bounce(multiplier: float = 1.0) -> void:
	if not is_alive:
		return
	velocity.y = BOUNCE_VELOCITY * multiplier
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	air_jumps_left = max_air_jumps
	squash_stretch = Vector2(0.6, 1.5)
	rotation_angle += PI * 0.5
	bounced.emit()
	
	if has_stomp_shock:
		shockwave_triggered.emit(global_position)

func take_damage(amount: int = 20) -> void:
	if not is_alive or invincible_timer > 0.0:
		return
		
	current_hp = max(0, current_hp - amount)
	invincible_timer = INVINCIBLE_DURATION
	damaged.emit(current_hp, max_hp)
	
	velocity.y = -300.0
	squash_stretch = Vector2(1.4, 0.6)
	
	if current_hp <= 0:
		die()

func rescue_from_fall() -> void:
	if not is_alive:
		return
	take_damage(25) # 落下は25ダメージ
	if is_alive:
		global_position = Vector2(160.0, 120.0)
		velocity = Vector2(0.0, 100.0)
		air_jumps_left = max_air_jumps

func add_exp(amount: int) -> void:
	if not is_alive:
		return
	current_exp += amount
	if current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		exp_to_next_level = int(float(exp_to_next_level) * 1.35)
		leveled_up.emit(level)
	exp_gained.emit(current_exp, exp_to_next_level, level)

func get_magnet_range() -> float:
	return 180.0 * magnet_multiplier

func apply_skill(skill_id: String) -> void:
	skills[skill_id] = skills.get(skill_id, 0) + 1
	var rank: int = skills[skill_id]
	
	match skill_id:
		"triple_jump":
			max_air_jumps = 1 + rank
		"rapid_fire":
			shoot_interval = 0.75 * pow(0.72, rank)
		"multishot":
			bullet_count = 1 + rank
		"stomp_shock":
			has_stomp_shock = true
		"magnet":
			magnet_multiplier = 1.0 + float(rank) * 0.8
		"spike_boots":
			has_spike_boots = true
		"heal_max_hp":
			max_hp += 30 # 最大HP+30 & 全回復
			current_hp = max_hp
			damaged.emit(current_hp, max_hp)

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	visible = false
	died.emit()

func _draw() -> void:
	if not is_alive:
		return
		
	if invincible_timer > 0.0 and int(invincible_timer * 20.0) % 2 == 0:
		return
		
	for i in range(trail_positions.size()):
		var p := trail_positions[i] - global_position
		var alpha := (1.0 - float(i) / float(trail_positions.size())) * 0.35
		var sz := 28.0 * (1.0 - float(i) * 0.08)
		draw_rect(Rect2(p - Vector2(sz/2, sz/2), Vector2(sz, sz)), Color(0.0, 0.9, 1.0, alpha))
		
	var size := Vector2(30.0 * squash_stretch.x, 30.0 * squash_stretch.y)
	var rect := Rect2(-size / 2.0, size)
	
	draw_set_transform(Vector2.ZERO, rotation_angle, Vector2.ONE)
	
	draw_rect(rect.grow(4.0), Color(0.1, 0.8, 1.0, 0.3), true)
	draw_rect(rect, Color(0.05, 0.12, 0.25, 0.9), true)
	draw_rect(rect, Color(0.2, 0.95, 1.0, 1.0), false, 2.5)
	var inner := Rect2(-size * 0.25, size * 0.5)
	draw_rect(inner, Color(1.0, 1.0, 1.0, 0.95), true)
	
	if has_spike_boots:
		draw_line(Vector2(-size.x/2, size.y/2), Vector2(size.x/2, size.y/2), Color(1.0, 0.9, 0.2, 1.0), 3.0)
