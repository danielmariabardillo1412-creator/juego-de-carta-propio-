extends Control
## Tapete vectorial original y ligero; sirve de base mientras no existe arte definitivo.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("071014"))
	# Inclinación suave de sobremesa: profundidad sin efecto de "pista hacia el horizonte".
	var top_left := Vector2(size.x * 0.085, size.y * 0.035)
	var top_right := Vector2(size.x * 0.915, size.y * 0.035)
	var bottom_right := Vector2(size.x * 0.98, size.y * 0.985)
	var bottom_left := Vector2(size.x * 0.02, size.y * 0.985)
	var table_shape := PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	draw_colored_polygon(table_shape, Color("13231f"))
	draw_polyline(PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left]), Color("c8a957"), 3.0, true)
	for fraction in [0.12, 0.26, 0.40, 0.55, 0.70, 0.84]:
		var y := lerpf(top_left.y, bottom_left.y, fraction)
		var half_width := lerpf((top_right.x - top_left.x) * 0.5, (bottom_right.x - bottom_left.x) * 0.5, fraction)
		draw_line(Vector2(size.x * 0.5 - half_width, y), Vector2(size.x * 0.5 + half_width, y), Color("a9935350"), 1.5)
	for bottom_fraction in [0.08, 0.22, 0.36, 0.50, 0.64, 0.78, 0.92]:
		var tx := lerpf(top_left.x, top_right.x, bottom_fraction)
		var bx := lerpf(bottom_left.x, bottom_right.x, bottom_fraction)
		draw_line(Vector2(tx, top_left.y), Vector2(bx, bottom_left.y), Color("78908628"), 1.0)
	var upper := PackedVector2Array([
		Vector2(size.x * 0.17, size.y * 0.08), Vector2(size.x * 0.83, size.y * 0.08),
		Vector2(size.x * 0.91, size.y * 0.47), Vector2(size.x * 0.09, size.y * 0.47),
	])
	var lower := PackedVector2Array([
		Vector2(size.x * 0.09, size.y * 0.53), Vector2(size.x * 0.91, size.y * 0.53),
		Vector2(size.x * 0.98, size.y * 0.96), Vector2(size.x * 0.02, size.y * 0.96),
	])
	draw_colored_polygon(upper, Color("391f2848"))
	draw_colored_polygon(lower, Color("173d364d"))
	var center := size * 0.5
	draw_line(Vector2(size.x * 0.075, center.y), Vector2(size.x * 0.925, center.y), Color("e1c66a"), 3.0)
	draw_line(Vector2(size.x * 0.10, center.y + 5), Vector2(size.x * 0.90, center.y + 5), Color("071014aa"), 1.0)
