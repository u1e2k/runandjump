extends Area2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		if body.get("has_spike_boots") == true and body.has_method("bounce"):
			body.bounce(1.0)
		else:
			body.take_damage(20)

func _draw() -> void:
	var pts := PackedVector2Array([
		Vector2(-12, 12),
		Vector2(0, -12),
		Vector2(12, 12)
	])
	draw_colored_polygon(pts, Color(0.9, 0.1, 0.2, 0.8))
	draw_polyline(pts, Color(1.0, 0.4, 0.5, 1.0), 2.0)
	draw_line(pts[2], pts[0], Color(1.0, 0.4, 0.5, 1.0), 2.0)
