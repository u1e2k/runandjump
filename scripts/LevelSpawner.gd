extends Node2D

signal enemy_stomped(enemy: Node2D)
signal enemy_defeated(pos: Vector2)
signal checkpoint_reached(section_index: int)
signal zone_changed(zone_index: int)

const PlatformScript = preload("res://scripts/Platform.gd")
const SpikeScript = preload("res://scripts/Spike.gd")
const EnemyScript = preload("res://scripts/Enemy.gd")

@export var base_scroll_speed: float = 340.0
var current_scroll_speed: float = 340.0
var is_scrolling: bool = false
var spawn_x: float = 0.0

const CHUNK_WIDTH: float = 720.0
var active_chunks: Array[Node2D] = []

# セクション管理 (500m ごとにチェックポイント)
const CHECKPOINT_INTERVAL: float = 500.0
var total_distance_traveled: float = 0.0
var next_checkpoint_dist: float = 500.0
var current_section: int = 1
var checkpoint_spawned: bool = false
var current_zone: int = 1

func _ready() -> void:
	current_scroll_speed = base_scroll_speed

func start_run() -> void:
	clear_all_chunks()
	current_scroll_speed = base_scroll_speed
	spawn_x = 0.0
	is_scrolling = true
	total_distance_traveled = 0.0
	next_checkpoint_dist = CHECKPOINT_INTERVAL
	current_section = 1
	checkpoint_spawned = false
	current_zone = 1
	zone_changed.emit(current_zone)
	
	spawn_start_chunk()
	for i in range(2):
		spawn_random_chunk()

func stop_run() -> void:
	is_scrolling = false

func _process(delta: float) -> void:
	if not is_scrolling:
		return
		
	current_scroll_speed = min(current_scroll_speed + delta * 1.5, 500.0)
	var move_dist := current_scroll_speed * delta
	total_distance_traveled += move_dist * 0.05
	
	# ゾーン判定 (1000m区切り)
	var new_zone := 1
	if total_distance_traveled >= 2000.0:
		new_zone = 3
	elif total_distance_traveled >= 1000.0:
		new_zone = 2
		
	if new_zone != current_zone:
		current_zone = new_zone
		zone_changed.emit(current_zone)
		
	for chunk in active_chunks:
		chunk.position.x -= move_dist
		
	spawn_x -= move_dist
	
	# チェックポイント到達判定 (500mごと)
	if not checkpoint_spawned and total_distance_traveled >= next_checkpoint_dist:
		checkpoint_spawned = true
		spawn_checkpoint_chunk()
		
	if spawn_x < 1440.0:
		spawn_random_chunk()
		
	for i in range(active_chunks.size() - 1, -1, -1):
		var chunk := active_chunks[i]
		if chunk.position.x < -CHUNK_WIDTH - 200.0:
			active_chunks.remove_at(i)
			chunk.queue_free()

func clear_all_chunks() -> void:
	for chunk in active_chunks:
		if is_instance_valid(chunk):
			chunk.queue_free()
	active_chunks.clear()

func create_chunk_root() -> Node2D:
	var chunk := Node2D.new()
	chunk.position.x = spawn_x
	add_child(chunk)
	active_chunks.append(chunk)
	spawn_x += CHUNK_WIDTH
	return chunk

func get_platform_colors_for_zone() -> Dictionary:
	match current_zone:
		1: # Neo City
			return { "fill": Color(0.06, 0.10, 0.20), "border": Color(0.15, 0.85, 1.0) }
		2: # Acid Slum
			return { "fill": Color(0.08, 0.12, 0.08), "border": Color(0.35, 0.95, 0.25) }
		_: # Digital Void
			return { "fill": Color(0.12, 0.06, 0.20), "border": Color(0.85, 0.25, 0.95) }

func spawn_start_chunk() -> void:
	var chunk := create_chunk_root()
	var cols := get_platform_colors_for_zone()
	var plat := create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH + 100, cols.fill, cols.border)

func spawn_checkpoint_chunk() -> void:
	var chunk := create_chunk_root()
	
	# 安全なゴールドネオンのロング足場
	var gold_fill := Color(0.15, 0.12, 0.04)
	var gold_border := Color(1.0, 0.85, 0.2)
	var plat := create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH + 200, gold_fill, gold_border)
	
	# ランドマーク：巨大ネオンゲート & 天空光柱（レーザービーム）
	var gate_visual := CheckpointGateVisual.new()
	gate_visual.position = Vector2(300.0, 580.0)
	chunk.add_child(gate_visual)
	
	# チェックポイントエリア（トリガー）
	var gate_area := Area2D.new()
	gate_area.position = Vector2(300.0, 500.0)
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(60.0, 220.0)
	col.shape = rect
	gate_area.add_child(col)
	
	gate_area.body_entered.connect(func(body):
		if body.name == "Player":
			next_checkpoint_dist += CHECKPOINT_INTERVAL
			current_section += 1
			checkpoint_spawned = false
			checkpoint_reached.emit(current_section - 1)
	)
	chunk.add_child(gate_area)

func spawn_random_chunk() -> void:
	var chunk := create_chunk_root()
	var cols := get_platform_colors_for_zone()
	var f_col: Color = cols.fill
	var b_col: Color = cols.border
	
	# 12種類の多彩なチャンクパターン
	var pattern := randi() % 12
	
	match pattern:
		0: # フラット＆パトロール敵
			create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH + 20, f_col, b_col)
			create_enemy(chunk, Vector2(420, 536), "patrol")
			
		1: # 穴開き＆トゲトラップ
			create_platform(chunk, Vector2(0, 580), 300, f_col, b_col)
			create_spike(chunk, Vector2(230, 540))
			create_platform(chunk, Vector2(380, 580), 340, f_col, b_col)
			create_enemy(chunk, Vector2(520, 536), "patrol")
			
		2: # 2段ステップ＆ホッパー敵
			create_platform(chunk, Vector2(0, 580), 220, f_col, b_col)
			create_platform(chunk, Vector2(280, 460), 200, f_col, b_col)
			create_enemy(chunk, Vector2(300, 416), "hopper")
			create_platform(chunk, Vector2(520, 580), 200, f_col, b_col)
			
		3: # トゲ地帯＆高所空中足場ルート
			create_platform(chunk, Vector2(0, 580), 160, f_col, b_col)
			for s in range(4):
				create_spike(chunk, Vector2(210 + s * 45, 620))
			create_platform(chunk, Vector2(220, 420), 280, f_col, b_col)
			create_enemy(chunk, Vector2(340, 376), "hopper")
			create_platform(chunk, Vector2(500, 580), 220, f_col, b_col)
			
		4: # 2階建てビル屋上
			create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH, f_col, b_col)
			create_platform(chunk, Vector2(240, 430), 240, f_col, b_col)
			create_enemy(chunk, Vector2(260, 386), "patrol")
			create_enemy(chunk, Vector2(540, 536), "patrol")
			
		5: # ジャンプパッドギミック（大ジャンプで高所へ飛べる！）
			create_platform(chunk, Vector2(0, 580), 240, f_col, b_col)
			create_jump_pad(chunk, Vector2(180, 550))
			create_platform(chunk, Vector2(260, 360), 240, f_col, b_col)
			create_enemy(chunk, Vector2(360, 316), "patrol")
			create_platform(chunk, Vector2(480, 580), 240, f_col, b_col)
			
		6: # 3段連続ステップアップ（リズムアクション）
			create_platform(chunk, Vector2(0, 580), 180, f_col, b_col)
			create_platform(chunk, Vector2(220, 500), 140, f_col, b_col)
			create_platform(chunk, Vector2(400, 420), 140, f_col, b_col)
			create_platform(chunk, Vector2(570, 580), 150, f_col, b_col)
			create_enemy(chunk, Vector2(400, 376), "hopper")
			
		7: # 連続ホッパーラッシュ地帯
			create_platform(chunk, Vector2(0, 580), 320, f_col, b_col)
			create_enemy(chunk, Vector2(200, 536), "hopper")
			create_enemy(chunk, Vector2(290, 536), "hopper")
			create_platform(chunk, Vector2(380, 580), 340, f_col, b_col)
			create_spike(chunk, Vector2(460, 540))
			
		8: # スモールアイランド連続ジャンプ
			create_platform(chunk, Vector2(0, 580), 140, f_col, b_col)
			create_platform(chunk, Vector2(190, 530), 110, f_col, b_col)
			create_platform(chunk, Vector2(350, 480), 110, f_col, b_col)
			create_platform(chunk, Vector2(510, 530), 110, f_col, b_col)
			create_platform(chunk, Vector2(650, 580), 100, f_col, b_col)
			
		9: # ジャンプパッド＋長距離谷越え
			create_platform(chunk, Vector2(0, 580), 200, f_col, b_col)
			create_jump_pad(chunk, Vector2(150, 550))
			for s in range(6):
				create_spike(chunk, Vector2(240 + s * 45, 630))
			create_platform(chunk, Vector2(500, 580), 220, f_col, b_col)
			create_enemy(chunk, Vector2(580, 536), "patrol")
			
		10: # 高低差の交差ルート（上：安全・下：トゲ）
			create_platform(chunk, Vector2(0, 580), 180, f_col, b_col)
			create_platform(chunk, Vector2(180, 400), 380, f_col, b_col)
			create_enemy(chunk, Vector2(320, 356), "patrol")
			create_enemy(chunk, Vector2(450, 356), "patrol")
			create_spike(chunk, Vector2(300, 600))
			create_spike(chunk, Vector2(420, 600))
			create_platform(chunk, Vector2(550, 580), 170, f_col, b_col)
			
		11: # 密集防衛ライン（敵3体）
			create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH, f_col, b_col)
			create_enemy(chunk, Vector2(220, 536), "patrol")
			create_enemy(chunk, Vector2(380, 536), "hopper")
			create_enemy(chunk, Vector2(560, 536), "patrol")

func create_platform(parent: Node2D, local_pos: Vector2, width: float, fill_c: Color = Color(0.08, 0.12, 0.22), border_c: Color = Color(0.1, 0.7, 0.9)) -> StaticBody2D:
	var plat: StaticBody2D = PlatformScript.new()
	plat.size = Vector2(width, 50)
	plat.fill_color = fill_c
	plat.border_color = border_c
	plat.position = local_pos + Vector2(width / 2.0, 0)
	parent.add_child(plat)
	return plat

func create_spike(parent: Node2D, local_pos: Vector2) -> Area2D:
	var spike: Area2D = SpikeScript.new()
	var col := CollisionPolygon2D.new()
	col.polygon = PackedVector2Array([
		Vector2(-12, 12),
		Vector2(0, -12),
		Vector2(12, 12)
	])
	spike.add_child(col)
	spike.position = local_pos
	parent.add_child(spike)
	return spike

func create_enemy(parent: Node2D, local_pos: Vector2, type: String = "patrol") -> Node2D:
	var enemy: Node2D = EnemyScript.new()
	enemy.enemy_type = type
	enemy.position = local_pos
	
	var stomp_area := Area2D.new()
	stomp_area.name = "StompArea"
	var stomp_col := CollisionShape2D.new()
	var stomp_rect := RectangleShape2D.new()
	stomp_rect.size = Vector2(24, 10)
	stomp_col.shape = stomp_rect
	stomp_col.position = Vector2(0, -14)
	stomp_area.add_child(stomp_col)
	stomp_area.body_entered.connect(enemy.on_stomp_area_body_entered)
	enemy.add_child(stomp_area)
	
	var hit_area := Area2D.new()
	hit_area.name = "HitArea"
	var hit_col := CollisionShape2D.new()
	var hit_rect := RectangleShape2D.new()
	hit_rect.size = Vector2(22, 18)
	hit_col.shape = hit_rect
	hit_col.position = Vector2(0, 4)
	hit_area.add_child(hit_col)
	hit_area.body_entered.connect(enemy.on_hit_area_body_entered)
	enemy.add_child(hit_area)
	
	enemy.stomped.connect(_on_enemy_stomped)
	enemy.defeated.connect(_on_enemy_defeated)
	parent.add_child(enemy)
	return enemy

func create_jump_pad(parent: Node2D, local_pos: Vector2) -> Area2D:
	var pad := JumpPad.new()
	pad.position = local_pos
	parent.add_child(pad)
	return pad

func trigger_shockwave_damage(origin: Vector2, radius: float = 320.0) -> void:
	for chunk in active_chunks:
		for child in chunk.get_children():
			if child.has_method("take_damage") and not (child is StaticBody2D or child is Area2D):
				if child.global_position.distance_to(origin) <= radius:
					child.take_damage(2)

func _on_enemy_stomped(enemy: Node2D) -> void:
	enemy_stomped.emit(enemy)

func _on_enemy_defeated(pos: Vector2) -> void:
	enemy_defeated.emit(pos)

# --- 特殊ギミック & ビジュアルクラス ---

class JumpPad extends Area2D:
	var bounce_power: float = 1.35
	var anim_timer: float = 0.0
	
	func _ready() -> void:
		var col := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(36, 16)
		col.shape = rect
		add_child(col)
		body_entered.connect(_on_body_entered)
		
	func _process(delta: float) -> void:
		if anim_timer > 0.0:
			anim_timer -= delta
		queue_redraw()
		
	func _on_body_entered(body: Node2D) -> void:
		if body.has_method("bounce"):
			body.bounce(bounce_power)
			anim_timer = 0.35
			
	func _draw() -> void:
		var w := 34.0
		var h := 12.0
		var col := Color(0.2, 1.0, 0.4) if anim_timer <= 0.0 else Color(1.0, 1.0, 0.4)
		draw_rect(Rect2(-w/2, -h/2, w, h), Color(0.05, 0.15, 0.08), true)
		draw_rect(Rect2(-w/2, -h/2, w, h), col, false, 2.0)
		# 矢印アイコン
		var arrow_y := -h/2 - 4.0 - (sin(Time.get_ticks_msec() * 0.01) * 3.0)
		draw_line(Vector2(-8, arrow_y + 6), Vector2(0, arrow_y), col, 2.5)
		draw_line(Vector2(8, arrow_y + 6), Vector2(0, arrow_y), col, 2.5)

class CheckpointGateVisual extends Node2D:
	var time: float = 0.0
	
	func _process(delta: float) -> void:
		time += delta
		queue_redraw()
		
	func _draw() -> void:
		var gold := Color(1.0, 0.85, 0.2, 0.95)
		var cyan := Color(0.2, 0.95, 1.0, 0.95)
		
		# 1. 天空へ伸びる光の柱（レーザービーム）
		var beam_alpha := 0.25 + 0.15 * sin(time * 6.0)
		draw_rect(Rect2(-25.0, -700.0, 50.0, 700.0), Color(1.0, 0.85, 0.2, beam_alpha * 0.4), true)
		draw_rect(Rect2(-8.0, -700.0, 16.0, 700.0), Color(1.0, 1.0, 0.7, beam_alpha * 0.8), true)
		
		# 2. ネオンツインピラー（左右の柱）
		var pillar_w := 14.0
		var pillar_h := 160.0
		# 左柱
		draw_rect(Rect2(-45.0, -pillar_h, pillar_w, pillar_h), Color(0.08, 0.08, 0.12), true)
		draw_rect(Rect2(-45.0, -pillar_h, pillar_w, pillar_h), gold, false, 2.0)
		# 右柱
		draw_rect(Rect2(31.0, -pillar_h, pillar_w, pillar_h), Color(0.08, 0.08, 0.12), true)
		draw_rect(Rect2(31.0, -pillar_h, pillar_w, pillar_h), gold, false, 2.0)
		
		# 3. トップアーチ
		var arch_rect := Rect2(-52.0, -pillar_h - 18.0, 104.0, 18.0)
		draw_rect(arch_rect, Color(0.1, 0.08, 0.02), true)
		draw_rect(arch_rect, gold, false, 2.5)
		
		# 4. ホログラムネオンサイン「UPGRADE」
		var sign_pulse := (int(time * 5.0) % 6 != 0)
		var sign_col := cyan if sign_pulse else Color(0.3, 0.5, 0.6, 0.4)
		draw_circle(Vector2(0, -pillar_h - 9.0), 5.0, sign_col)
		draw_line(Vector2(-35, -pillar_h + 30), Vector2(35, -pillar_h + 30), cyan, 2.0)
		draw_line(Vector2(-35, -pillar_h + 60), Vector2(35, -pillar_h + 60), cyan, 2.0)
