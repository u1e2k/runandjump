extends StaticBody2D
class_name Platform

@export var size: Vector2 = Vector2(200, 40)
@export var fill_color: Color = Color(0.08, 0.12, 0.22, 1.0)
@export var border_color: Color = Color(0.1, 0.7, 0.9, 1.0)

var collision_shape: CollisionShape2D

func _ready() -> void:
	# コリジョン形状の動的設定
	collision_shape = CollisionShape2D.new()
	var rect_shape := RectangleShape2D.new()
	rect_shape.size = size
	collision_shape.shape = rect_shape
	add_child(collision_shape)
	queue_redraw()

func set_platform_size(new_size: Vector2) -> void:
	size = new_size
	if collision_shape and collision_shape.shape is RectangleShape2D:
		(collision_shape.shape as RectangleShape2D).size = size
	queue_redraw()

func _draw() -> void:
	var rect := Rect2(-size / 2.0, size)
	# 背景
	draw_rect(rect, fill_color, true)
	# 上面ハイライト（着地ガイドライン）
	draw_line(Vector2(-size.x/2, -size.y/2), Vector2(size.x/2, -size.y/2), border_color, 3.0)
	# 枠線
	draw_rect(rect, Color(border_color.r, border_color.g, border_color.b, 0.4), false, 1.5)
	# グリッド装飾ライン
	var step := 30.0
	var x := -size.x/2 + step
	while x < size.x/2:
		draw_line(Vector2(x, -size.y/2), Vector2(x, size.y/2), Color(0.2, 0.4, 0.6, 0.15), 1.0)
		x += step
