extends Node2D

const SoundSynthScript = preload("res://scripts/SoundSynth.gd")
const SkillDatabaseScript = preload("res://scripts/SkillDatabase.gd")
const ProjectileScript = preload("res://scripts/Projectile.gd")
const ExpGemScript = preload("res://scripts/ExpGem.gd")
const BuildManagerScript = preload("res://scripts/BuildManager.gd")

enum State { TITLE, BUILD_MENU, PLAYING, UPGRADE_STATION, PAUSED, GAME_OVER }
var current_state: State = State.TITLE

@onready var player: CharacterBody2D = $Player
@onready var spawner: Node2D = $LevelSpawner
@onready var hud: CanvasLayer = $HUD
@onready var camera: Camera2D = $Camera2D
@onready var build_menu: Control = $HUD/BuildMenu

# ビルド・セーブデータ管理
var build_manager = null

# オーディオプレイヤー
var sfx_jump: AudioStreamPlayer
var sfx_bounce: AudioStreamPlayer
var sfx_death: AudioStreamPlayer
var sfx_land: AudioStreamPlayer
var sfx_shoot: AudioStreamPlayer
var sfx_hit: AudioStreamPlayer
var sfx_exp: AudioStreamPlayer
var sfx_levelup: AudioStreamPlayer

# ゲーム内数値
var score: int = 0
var high_score: int = 0
var distance: float = 0.0
var retry_ready_timer: float = 0.0
var run_earned_coins: int = 0

# 画面シェイク
var shake_amount: float = 0.0

const PLAYER_START_POS := Vector2(160, 480)

func _ready() -> void:
	build_manager = BuildManagerScript.new()
	init_audio()
	
	# プレイヤーシグナル接続
	player.jumped.connect(_on_player_jumped)
	player.bounced.connect(_on_player_bounced)
	player.landed.connect(_on_player_landed)
	player.died.connect(_on_player_died)
	player.damaged.connect(_on_player_damaged)
	player.exp_gained.connect(_on_player_exp_gained)
	player.sp_gained.connect(_on_player_sp_gained)
	player.shoot_bullet.connect(_on_player_shoot_bullet)
	player.shockwave_triggered.connect(_on_player_shockwave)
	
	# スポナーシグナル接続
	spawner.enemy_stomped.connect(_on_enemy_stomped)
	spawner.enemy_defeated.connect(_on_enemy_defeated)
	spawner.checkpoint_reached.connect(_on_checkpoint_reached)
	
	# HUDシグナル接続
	hud.skill_selected.connect(_on_skill_selected)
	hud.start_game_requested.connect(start_game)
	hud.open_build_menu.connect(_on_open_build_menu)
	hud.pause_requested.connect(_on_pause_requested)
	hud.resume_requested.connect(_on_resume_requested)
	hud.restart_requested.connect(_on_restart_requested)
	hud.quit_to_title_requested.connect(_on_quit_to_title_requested)
	
	build_menu.back_to_title.connect(_on_back_from_build_menu)
	
	player.visible = false
	build_menu.visible = false
	hud.show_title()

func init_audio() -> void:
	sfx_jump = create_player(SoundSynthScript.create_jump_sound())
	sfx_bounce = create_player(SoundSynthScript.create_bounce_sound())
	sfx_death = create_player(SoundSynthScript.create_death_sound())
	sfx_land = create_player(SoundSynthScript.create_land_sound())
	sfx_shoot = create_player(SoundSynthScript.create_shoot_sound())
	sfx_hit = create_player(SoundSynthScript.create_hit_sound())
	sfx_exp = create_player(SoundSynthScript.create_exp_sound())
	sfx_levelup = create_player(SoundSynthScript.create_levelup_sound())

func create_player(stream: AudioStreamWAV) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(p)
	return p

func _process(delta: float) -> void:
	if not get_tree().paused:
		if shake_amount > 0.0:
			camera.offset = Vector2(randf_range(-shake_amount, shake_amount), randf_range(-shake_amount, shake_amount))
			shake_amount = lerp(shake_amount, 0.0, 15.0 * delta)
		else:
			camera.offset = Vector2.ZERO
		
	match current_state:
		State.PLAYING:
			distance += spawner.current_scroll_speed * delta * 0.05
			score += int(spawner.current_scroll_speed * delta * 0.1)
			hud.update_stats(score, distance, spawner.current_section, spawner.next_checkpoint_dist)
			
			if player.global_position.y > 730.0:
				player.rescue_from_fall()
				trigger_shake(8.0)
				
		State.GAME_OVER:
			retry_ready_timer -= delta
			if retry_ready_timer <= 0.0 and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("ui_accept")):
				restart_game()

func start_game() -> void:
	get_tree().paused = false
	current_state = State.PLAYING
	score = 0
	distance = 0.0
	run_earned_coins = 0
	hud.hide_title()
	hud.hide_pause()
	hud.hide_game_over()
	hud.hide_upgrade_station()
	build_menu.close()
	player.reset(PLAYER_START_POS, build_manager)
	spawner.start_run()
	player.execute_jump()
	sfx_jump.play()

func restart_game() -> void:
	start_game()

func _on_pause_requested() -> void:
	if current_state == State.PLAYING:
		current_state = State.PAUSED
		get_tree().paused = true
		hud.show_pause()

func _on_resume_requested() -> void:
	if current_state == State.PAUSED:
		get_tree().paused = false
		hud.hide_pause()
		current_state = State.PLAYING

func _on_restart_requested() -> void:
	hud.hide_pause()
	get_tree().paused = false
	restart_game()

func _on_quit_to_title_requested() -> void:
	hud.hide_pause()
	get_tree().paused = false
	spawner.stop_run()
	player.visible = false
	current_state = State.TITLE
	hud.show_title()

func _on_open_build_menu() -> void:
	current_state = State.BUILD_MENU
	hud.hide_title()
	build_menu.open(build_manager)

func _on_back_from_build_menu() -> void:
	build_menu.close()
	current_state = State.TITLE
	hud.show_title()

func trigger_shake(amount: float) -> void:
	shake_amount = max(shake_amount, amount)

func _on_player_jumped() -> void:
	sfx_jump.play()

func _on_player_bounced() -> void:
	sfx_bounce.play()
	trigger_shake(6.0)
	score += 250
	hud.add_combo()

func _on_player_landed() -> void:
	sfx_land.play()

func _on_player_damaged(current_hp: int, max_hp: int) -> void:
	hud.update_hp(current_hp, max_hp)
	if current_hp > 0:
		sfx_hit.play()
		trigger_shake(10.0)

func _on_player_exp_gained(current: int, target: int, level: int) -> void:
	hud.update_exp(current, target, level)
	sfx_exp.play()

func _on_player_sp_gained(new_sp: int, current_level: int) -> void:
	# 走行を止めずにSPストック＆SE再生！
	sfx_levelup.play()
	hud.update_sp(new_sp)

func _on_checkpoint_reached(completed_section: int) -> void:
	# チェックポイント到達：HP小回復
	player.heal(20)
	trigger_shake(6.0)
	
	if player.sp_points > 0:
		current_state = State.UPGRADE_STATION
		get_tree().paused = true
		show_next_skill_offer()

func show_next_skill_offer() -> void:
	var offered := SkillDatabaseScript.get_random_skills(3, player.skills)
	hud.show_upgrade_station(offered, player.sp_points)

func _on_skill_selected(skill_id: String) -> void:
	player.apply_skill(skill_id)
	player.sp_points = max(0, player.sp_points - 1)
	hud.update_sp(player.sp_points)
	
	if player.sp_points > 0:
		# まだSPが残っていれば続けて選択！
		show_next_skill_offer()
	else:
		# SPを使い切ったら次セクションへ出発！
		hud.hide_upgrade_station()
		get_tree().paused = false
		current_state = State.PLAYING

func _on_player_shoot_bullet(pos: Vector2, dir: Vector2, wtype: String, dmg: int) -> void:
	var bullet: Area2D = ProjectileScript.new()
	bullet.position = pos
	bullet.direction = dir
	bullet.weapon_type = wtype
	bullet.damage = dmg
	add_child(bullet)
	sfx_shoot.play()

func _on_player_shockwave(pos: Vector2) -> void:
	trigger_shake(14.0)
	spawner.trigger_shockwave_damage(pos, 350.0)
	spawn_stomp_particles(pos)

func _on_enemy_stomped(enemy: Node2D) -> void:
	spawn_stomp_particles(enemy.global_position)

func _on_enemy_defeated(pos: Vector2) -> void:
	score += 100
	run_earned_coins += 2
	if build_manager:
		build_manager.coins += 2
		build_manager.save_data()
		
	if player.has_method("on_enemy_killed"):
		player.on_enemy_killed()
		
	var gem: Node2D = ExpGemScript.new()
	gem.position = pos
	gem.target_player = player
	add_child(gem)

func _on_player_died() -> void:
	get_tree().paused = false
	current_state = State.GAME_OVER
	retry_ready_timer = 0.25
	spawner.stop_run()
	sfx_death.play()
	trigger_shake(18.0)
	spawn_death_particles(player.global_position)
	
	if score > high_score:
		high_score = score
		
	hud.show_game_over(score, high_score, run_earned_coins)

func spawn_death_particles(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	add_child(root)
	
	for i in range(16):
		var shard := DeathShard.new()
		var angle := randf() * TAU
		var spd := randf_range(150.0, 380.0)
		shard.velocity = Vector2(cos(angle), sin(angle)) * spd
		root.add_child(shard)
		
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(root.queue_free)

func spawn_stomp_particles(pos: Vector2) -> void:
	var ring := StompRing.new()
	ring.position = pos
	add_child(ring)

class DeathShard extends Node2D:
	var velocity: Vector2 = Vector2.ZERO
	var col: Color = Color(0.1, 0.9, 1.0, 1.0)
	var life: float = 0.6
	var max_life: float = 0.6
	
	func _process(delta: float) -> void:
		position += velocity * delta
		velocity.y += 800.0 * delta
		life -= delta
		col.a = life / max_life
		if life <= 0:
			queue_free()
		queue_redraw()
		
	func _draw() -> void:
		draw_rect(Rect2(-3, -3, 6, 6), col, true)

class StompRing extends Node2D:
	var radius: float = 5.0
	var alpha: float = 1.0
	
	func _process(delta: float) -> void:
		radius += 240.0 * delta
		alpha -= 3.0 * delta
		if alpha <= 0:
			queue_free()
		queue_redraw()
		
	func _draw() -> void:
		draw_arc(Vector2.ZERO, radius, 0, TAU, 32, Color(1.0, 0.8, 0.2, alpha), 3.0)
