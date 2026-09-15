extends Node2D

signal enemy_stomped(enemy: Node2D)
signal enemy_defeated(pos: Vector2)

const PlatformScript = preload("res://scripts/Platform.gd")
const SpikeScript = preload("res://scripts/Spike.gd")
const EnemyScript = preload("res://scripts/Enemy.gd")

@export var base_scroll_speed: float = 340.0
var current_scroll_speed: float = 340.0
var is_scrolling: bool = false
var spawn_x: float = 0.0

const CHUNK_WIDTH: float = 720.0
var active_chunks: Array[Node2D] = []

func _ready() -> void:
	current_scroll_speed = base_scroll_speed

func start_run() -> void:
	clear_all_chunks()
	current_scroll_speed = base_scroll_speed
	spawn_x = 0.0
	is_scrolling = true
	
	spawn_start_chunk()
	for i in range(2):
		spawn_random_chunk()

func stop_run() -> void:
	is_scrolling = false

func _process(delta: float) -> void:
	if not is_scrolling:
		return
		
	current_scroll_speed = min(current_scroll_speed + delta * 2.0, 520.0)
	var move_dist := current_scroll_speed * delta
	
	for chunk in active_chunks:
		chunk.position.x -= move_dist
		
	spawn_x -= move_dist
	
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

func spawn_start_chunk() -> void:
	var chunk := create_chunk_root()
	var plat: StaticBody2D = PlatformScript.new()
	plat.size = Vector2(CHUNK_WIDTH + 100, 60)
	plat.position = Vector2(CHUNK_WIDTH / 2.0, 580)
	chunk.add_child(plat)

func spawn_random_chunk() -> void:
	var chunk := create_chunk_root()
	var pattern := randi() % 5
	
	match pattern:
		0:
			create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH + 20)
			create_enemy(chunk, Vector2(400, 536), "patrol")
		1:
			create_platform(chunk, Vector2(0, 580), 320)
			create_spike(chunk, Vector2(240, 540))
			create_platform(chunk, Vector2(360, 580), 360)
			create_enemy(chunk, Vector2(500, 536), "patrol")
		2:
			create_platform(chunk, Vector2(0, 580), 220)
			create_platform(chunk, Vector2(300, 470), 180)
			create_enemy(chunk, Vector2(300, 426), "hopper")
			create_platform(chunk, Vector2(520, 580), 200)
		3:
			create_platform(chunk, Vector2(0, 580), 160)
			for s in range(4):
				create_spike(chunk, Vector2(220 + s * 45, 620))
			create_enemy(chunk, Vector2(260, 480), "hopper")
			create_enemy(chunk, Vector2(380, 430), "hopper")
			create_platform(chunk, Vector2(480, 580), 240)
		4:
			create_platform(chunk, Vector2(0, 580), CHUNK_WIDTH)
			create_platform(chunk, Vector2(250, 440), 220)
			create_enemy(chunk, Vector2(250, 396), "patrol")
			create_spike(chunk, Vector2(540, 540))

func create_platform(parent: Node2D, local_pos: Vector2, width: float) -> StaticBody2D:
	var plat: StaticBody2D = PlatformScript.new()
	plat.size = Vector2(width, 50)
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
