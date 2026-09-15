extends Area2D

@export var speed: float = 620.0
@export var damage: int = 1
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	# コリジョン設定
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 8.0
	col.shape = shape
	add_child(col)
	
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * speed * delta
	if position.x > 800.0 or position.x < -100.0 or position.y > 800.0 or position.y < -100.0:
		queue_free()
	queue_redraw()

func _on_area_entered(area: Area2D) -> void:
	var enemy := area.get_parent()
	if enemy and enemy.has_method("take_damage"):
		enemy.take_damage(damage)
		spawn_hit_fx()
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not (body.has_method("take_damage") and body.name == "Player"):
		body.take_damage(damage)
		spawn_hit_fx()
		queue_free()

func spawn_hit_fx() -> void:
	# 命中時の微小スパーク
	pass

func _draw() -> void:
	# ネオンエナジー弾
	draw_circle(Vector2.ZERO, 9.0, Color(0.1, 0.9, 1.0, 0.3))
	draw_circle(Vector2.ZERO, 5.0, Color(0.4, 1.0, 0.9, 0.9))
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0, 1.0))
