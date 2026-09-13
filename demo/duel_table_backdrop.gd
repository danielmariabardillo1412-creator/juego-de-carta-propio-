extends Control
## Tapete vectorial original y ligero; sirve de base mientras no existe arte definitivo.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("070d12"))
	# Tapete oblicuo 2D: borde cercano ancho, borde lejano estrecho, sin deformar las cartas.
	var top_left := Vector2(size.x * 0.19, size.y * 0.035)
	var top_right := Vector2(size.x * 0.81, size.y * 0.035)
	var bottom_right := Vector2(size.x * 0.985, size.y * 0.985)
	var bottom_left := Vector2(size.x * 0.015, size.y * 0.985)
	var table_shape := PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	draw_colored_polygon(table_shape, Color("101112"))
	var far_band := PackedVector2Array([
		top_left, top_right,
		top_right.lerp(bottom_right, 0.49), top_left.lerp(bottom_left, 0.49),
	])
	draw_colored_polygon(far_band, Color("0e1012b8"))
	var near_band := PackedVector2Array([
		top_left.lerp(bottom_left, 0.52), top_right.lerp(bottom_right, 0.52),
		bottom_right, bottom_left,
	])
	draw_colored_polygon(near_band, Color("12141685"))
	# Las cartas y casillas ya dan estructura: solo tres costuras suaves en el tapete.
	for fraction in [0.28, 0.50, 0.76]:
		var left := top_left.lerp(bottom_left, fraction)
		var right := top_right.lerp(bottom_right, fraction)
		draw_line(left, right, Color("b4a36b20") if fraction != 0.50 else Color("d6bd6d60"), 1.0 if fraction != 0.50 else 2.0)
	var far_edge := Color("af995a8c")
	var near_edge := Color("e0bd6c")
	draw_line(top_left, top_right, far_edge, 1.5)
	draw_line(top_left, bottom_left, Color("b49a5ec7"), 2.0)
	draw_line(top_right, bottom_right, Color("b49a5ec7"), 2.0)
	draw_line(bottom_left, bottom_right, near_edge, 4.0)
	# Un canto visible en primer plano refuerza que el jugador está sentado ante la mesa.
	draw_line(bottom_left + Vector2(0, -9), bottom_right + Vector2(0, -9), Color("f2d18b38"), 2.0)
