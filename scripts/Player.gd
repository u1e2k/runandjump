extends CharacterBody2D

signal died
signal jumped
signal bounced
signal landed
signal damaged(current_hp: int, max_hp: int)
signal exp_gained(current: int, target: int, level: int)
signal sp_gained(new_sp: int, current_level: int)
signal shoot_bullet(pos: Vector2, dir: Vector2, wtype: String, dmg: int)
signal shockwave_triggered(pos: Vector2)

# 物理定数
const BASE_GRAVITY: float = 1450.0
var current_gravity: float = 1450.0
const JUMP_VELOCITY: float = -560.0
const MIN_JUMP_VELOCITY: float = -220.0
const BOUNCE_VELOCITY: float = -640.0
const MAX_FALL_SPEED: float = 850.0
const TARGET_X: float = 160.0

# 快適性パラメータ
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER_TIME: float = 0.12

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var is_alive: bool = true
var was_on_floor: bool = false

# HP & 無敵時間
var max_hp: int = 100
var current_hp: int = 100
var invincible_timer: float = 0.0
const INVINCIBLE_DURATION: float = 1.0

# レベル & EXP & SPポイント
var level: int = 1
var current_exp: int = 0
var exp_to_next_level: int = 35
var sp_points: int = 0

# 装備・パーク
var current_weapon: String = "pulse_laser"
var current_accessory: String = "none"
var weapon_damage: int = 1
var weapon_bullet_count: int = 1
var base_shoot_interval: float = 0.7
var shoot_interval: float = 0.7
var shoot_timer: float = 0.0

var skills: Dictionary = {}
var max_air_jumps: int = 1
var air_jumps_left: int = 1
var magnet_multiplier: float = 1.0
var has_spike_boots: bool = false
var has_stomp_shock: bool = false
var kill_counter: int = 0

# ビジュアル用
var squash_stretch: Vector2 = Vector2(1.0, 1.0)
var rotation_angle: float = 0.0
var trail_positions: Array[Vector2] = []
const MAX_TRAIL: int = 8
var levelup_pop_timer: float = 0.0

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	is_alive = true
	trail_positions.clear()

func setup_loadout(build_mgr) -> void:
	current_weapon = build_mgr.equipped_weapon
	current_accessory = build_mgr.equipped_accessory
	
	var perk_hp: int = build_mgr.perk_levels.get("max_hp", 0) * 15
	max_hp = 100 + perk_hp
	current_hp = max_hp
	
	var perk_rate: float = 1.0 - float(build_mgr.perk_levels.get("fire_rate", 0)) * 0.08
	var perk_mag: float = 1.0 + float(build_mgr.perk_levels.get("magnet", 0)) * 0.25
	magnet_multiplier = perk_mag
	
	match current_weapon:
		"pulse_laser":
			weapon_damage = 1
			base_shoot_interval = 0.7 * perk_rate
			weapon_bullet_count = 1
		"scatter_shot":
			weapon_damage = 1
			base_shoot_interval = 0.85 * perk_rate
			weapon_bullet_count = 3
		"plasma_cannon":
			weapon_damage = 3
			base_shoot_interval = 1.2 * perk_rate
			weapon_bullet_count = 1
			
	shoot_interval = base_shoot_interval
	
	current_gravity = BASE_GRAVITY
	has_spike_boots = false
	match current_accessory:
		"feather_charm":
			current_gravity = BASE_GRAVITY * 0.85
		"spike_guard":
			has_spike_boots = true
		"vampire_ring":
			kill_counter = 0

func reset(start_pos: Vector2, build_mgr = null) -> void:
	global_position = start_pos
	velocity = Vector2.ZERO
	is_alive = true
	invincible_timer = 0.0
	level = 1
	current_exp = 0
	exp_to_next_level = 35
	sp_points = 0
	skills.clear()
	max_air_jumps = 1
	air_jumps_left = 1
	has_stomp_shock = false
	kill_counter = 0
	levelup_pop_timer = 0.0
	
	if build_mgr:
		setup_loadout(build_mgr)
	else:
		max_hp = 100
		current_hp = 100
		shoot_interval = 0.75
		
	coyote_timer = 0.0
	jump_buffer_timer = 0.0
	squash_stretch = Vector2(1.0, 1.0)
	rotation_angle = 0.0
	trail_positions.clear()
	visible = true
	damaged.emit(current_hp, max_hp)
	exp_gained.emit(current_exp, exp_to_next_level, level)
	sp_gained.emit(sp_points, level)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
		
	if invincible_timer > 0.0:
		invincible_timer -= delta
		
	if levelup_pop_timer > 0.0:
		levelup_pop_timer -= delta
		
	trail_positions.push_front(global_position)
	if trail_positions.size() > MAX_TRAIL:
		trail_positions.pop_back()
		
	shoot_timer += delta
	if shoot_timer >= shoot_interval:
		shoot_timer = 0.0
		execute_auto_shoot()
		
	if not is_on_floor():
		velocity.y += current_gravity * delta
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
		
	velocity.x = (TARGET_X - global_position.x) * 12.0
	
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
	var count := weapon_bullet_count
	for i in range(count):
		var angle_offset: float = 0.0
		if count > 1:
			angle_offset = (float(i) - float(count - 1) * 0.5) * 0.16
		var dir := Vector2(cos(angle_offset), sin(angle_offset))
		shoot_bullet.emit(muzzle_pos, dir, current_weapon, weapon_damage)

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

func heal(amount: int) -> void:
	if not is_alive:
		return
	current_hp = min(max_hp, current_hp + amount)
	damaged.emit(current_hp, max_hp)

func on_enemy_killed() -> void:
	if current_accessory == "vampire_ring":
		kill_counter += 1
		if kill_counter >= 5:
			kill_counter = 0
			heal(6)

func rescue_from_fall() -> void:
	if not is_alive:
		return
	take_damage(25)
	if is_alive:
		global_position = Vector2(TARGET_X, 120.0)
		velocity = Vector2(0.0, 100.0)
		air_jumps_left = max_air_jumps

func add_exp(amount: int) -> void:
	if not is_alive:
		return
	current_exp += amount
	if current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		sp_points += 1 # SPポイントを加算（ゲームは止めない！）
		exp_to_next_level = int(float(exp_to_next_level) * 1.3)
		levelup_pop_timer = 1.2
		sp_gained.emit(sp_points, level)
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
			shoot_interval = base_shoot_interval * pow(0.72, rank)
		"multishot":
			weapon_bullet_count += 1
		"stomp_shock":
			has_stomp_shock = true
		"magnet":
			magnet_multiplier = (magnet_multiplier) + 0.8
		"spike_boots":
			has_spike_boots = true
		"heal_max_hp":
			max_hp += 30
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
		
	# レベルアップ時のポップエフェクト
	if levelup_pop_timer > 0.0:
		var alpha_pop: float = levelup_pop_timer / 1.2
		draw_arc(Vector2.ZERO, 35.0 + (1.2 - levelup_pop_timer) * 30.0, 0, TAU, 24, Color(1.0, 0.85, 0.2, alpha_pop), 2.5)
