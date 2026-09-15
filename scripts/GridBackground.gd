extends Node2D

@export var grid_color: Color = Color(0.12, 0.22, 0.38, 0.4)
@export var horizon_y: float = 400.0
@export var scroll_speed: float = 120.0

var offset_x: float = 0.0

func _process(delta: float) -> void:
	offset_x = fmod(offset_x + scroll_speed * delta, 60.0)
	queue_redraw()

func _draw() -> void:
	var screen_w: float = 720.0
	var screen_h: float = 720.0
	
	# 背景グラデーション風の帯
	draw_rect(Rect2(0, 0, screen_w, horizon_y), Color(0.04, 0.06, 0.1, 1.0), true)
	draw_rect(Rect2(0, horizon_y, screen_w, screen_h - horizon_y), Color(0.02, 0.04, 0.08, 1.0), true)
	
	# 遠景のサイバーサン/グロー
	draw_circle(Vector2(screen_w * 0.5, horizon_y - 20), 120.0, Color(0.9, 0.2, 0.6, 0.12))
	draw_circle(Vector2(screen_w * 0.5, horizon_y - 20), 70.0, Color(0.1, 0.8, 1.0, 0.18))
	
	# 水平グリッドライン
	for y in range(int(horizon_y), int(screen_h), 24):
		var alpha: float = (float(y - horizon_y) / (screen_h - horizon_y)) * 0.5
		var col := grid_color
		col.a = alpha
		draw_line(Vector2(0, y), Vector2(screen_w, y), col, 1.2)
		
	# 垂直パースペクティブグリッドライン
	var x := -offset_x
	while x < screen_w + 60.0:
		var col := grid_color
		col.a = 0.35
		draw_line(Vector2(x, horizon_y), Vector2((x - screen_w * 0.5) * 1.8 + screen_w * 0.5, screen_h), col, 1.2)
		x += 60.0
