extends Node2D

signal stomped(enemy: Node2D)
signal defeated(pos: Vector2)

@export var enemy_type: String = "patrol" # "patrol", "hopper", "static"
@export var move_speed: float = 60.0
@export var patrol_distance: float = 60.0
@export var hp: int = 3
@export var max_hp: int = 3
@export var contact_damage: int = 18

var start_x: float = 0.0
var move_dir: float = -1.0
var hop_timer: float = 0.0
var is_dead: bool = false
var squash_y: float = 1.0
var hit_flash_timer: float = 0.0

func _ready() -> void:
	start_x = position.x
	if enemy_type == "hopper":
		hp = 2
		max_hp = 2
		contact_damage = 15
	else:
		hp = 3
		max_hp = 3
		contact_damage = 18
	
func _process(delta: float) -> void:
	if hit_flash_timer > 0.0:
		hit_flash_timer -= delta
		
	if is_dead:
		squash_y = lerp(squash_y, 0.1, 20.0 * delta)
		queue_redraw()
		return
		
	match enemy_type:
		"patrol":
			position.x += move_dir * move_speed * delta
			if abs(position.x - start_x) > patrol_distance:
				move_dir *= -1.0
		"hopper":
			hop_timer += delta * 4.0
			position.y += sin(hop_timer) * 1.2
			
	queue_redraw()

func take_damage(amount: int) -> void:
	if is_dead:
		return
	hp -= amount
	hit_flash_timer = 0.1
	if hp <= 0:
		is_dead = true
		defeated.emit(global_position)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(0.1, 0.1), 0.1)
		tween.tween_callback(queue_free)
	else:
		position.x += 10.0

func on_stomp_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("bounce") and body.velocity.y >= -50.0:
		body.bounce(1.0)
		stomped.emit(self)
		take_damage(99)
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 0.1), 0.12)

func on_hit_area_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.has_method("take_damage"):
		if body.velocity.y < -50.0 or body.global_position.y > global_position.y - 10.0:
			body.take_damage(contact_damage)

func _draw() -> void:
	var sz := Vector2(30.0, 30.0 * squash_y)
	var rect := Rect2(-sz / 2.0, sz)
	
	if hit_flash_timer > 0.0:
		draw_rect(rect.grow(4.0), Color(1.0, 1.0, 1.0, 0.9), true)
		return
		
	draw_rect(rect.grow(3.0), Color(1.0, 0.1, 0.3, 0.25), true)
	draw_rect(rect, Color(0.35, 0.05, 0.15, 0.9), true)
	draw_rect(rect, Color(1.0, 0.2, 0.4, 1.0), false, 2.0)
	
	if hp < max_hp and not is_dead:
		var bar_w := 24.0
		var bar_h := 3.0
		var bar_bg := Rect2(-bar_w/2, -sz.y/2 - 10, bar_w, bar_h)
		var bar_fg := Rect2(-bar_w/2, -sz.y/2 - 10, bar_w * (float(hp) / float(max_hp)), bar_h)
		draw_rect(bar_bg, Color(0.2, 0.2, 0.2, 0.8), true)
		draw_rect(bar_fg, Color(0.2, 1.0, 0.3, 0.9), true)
		
	var eye_rect := Rect2(-10.0, -6.0 * squash_y, 20.0, 5.0 * squash_y)
	draw_rect(eye_rect, Color(1.0, 0.8, 0.2, 1.0), true)
	
	if not is_dead:
		draw_line(Vector2(-8, -sz.y/2 - 4), Vector2(8, -sz.y/2 - 4), Color(0.2, 1.0, 0.4, 0.8), 2.0)
