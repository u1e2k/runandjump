extends Area2D

@export var speed: float = 650.0
@export var damage: int = 1
@export var weapon_type: String = "pulse_laser" # "pulse_laser", "scatter_shot", "plasma_cannon"

var direction: Vector2 = Vector2.RIGHT
var is_piercing: bool = false
var pierce_count: int = 0

func _ready() -> void:
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	
	match weapon_type:
		"pulse_laser":
			shape.radius = 8.0
			speed = 650.0
		"scatter_shot":
			shape.radius = 6.0
			speed = 580.0
		"plasma_cannon":
			shape.radius = 16.0
			speed = 460.0
			is_piercing = true
			pierce_count = 3
			
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
		if is_piercing:
			pierce_count -= 1
			if pierce_count <= 0:
				queue_free()
		else:
			queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage") and not (body.name == "Player"):
		body.take_damage(damage)
		if is_piercing:
			pierce_count -= 1
			if pierce_count <= 0:
				queue_free()
		else:
			queue_free()

func _draw() -> void:
	match weapon_type:
		"pulse_laser":
			draw_circle(Vector2.ZERO, 9.0, Color(0.1, 0.9, 1.0, 0.3))
			draw_circle(Vector2.ZERO, 5.0, Color(0.4, 1.0, 0.9, 0.9))
			draw_circle(Vector2.ZERO, 2.5, Color(1.0, 1.0, 1.0, 1.0))
		"scatter_shot":
			draw_circle(Vector2.ZERO, 7.0, Color(1.0, 0.8, 0.1, 0.35))
			draw_circle(Vector2.ZERO, 4.0, Color(1.0, 0.6, 0.1, 0.9))
			draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 1.0))
		"plasma_cannon":
			draw_circle(Vector2.ZERO, 18.0, Color(0.8, 0.2, 1.0, 0.35))
			draw_circle(Vector2.ZERO, 12.0, Color(0.9, 0.4, 1.0, 0.85))
			draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 1.0, 0.95))
