extends Control
## Fondo greybox de la mesa final: jerarquía de duelo sin arte definitivo.
## Mantiene dos territorios enfrentados, un eje central limpio y guías discretas.


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, Color("060d12"))

	# Superficie de juego casi cenital. La perspectiva es leve para conservar
	# proporciones idénticas en ambos lados y no convertir el tablero en una pista.
	var top_left := Vector2(size.x * 0.055, size.y * 0.025)
	var top_right := Vector2(size.x * 0.945, size.y * 0.025)
	var bottom_right := Vector2(size.x * 0.985, size.y * 0.985)
	var bottom_left := Vector2(size.x * 0.015, size.y * 0.985)
	var table_shape := PackedVector2Array([top_left, top_right, bottom_right, bottom_left])
	draw_colored_polygon(table_shape, Color("10221f"))
	draw_polyline(
		PackedVector2Array([top_left, top_right, bottom_right, bottom_left, top_left]),
		Color("b99b50"), 2.0, true
	)

	# Dos mitades con identidad suficiente para orientarse sin depender de texto.
	var upper := PackedVector2Array([
		Vector2(size.x * 0.075, size.y * 0.055), Vector2(size.x * 0.925, size.y * 0.055),
		Vector2(size.x * 0.955, size.y * 0.475), Vector2(size.x * 0.045, size.y * 0.475),
	])
	var lower := PackedVector2Array([
		Vector2(size.x * 0.045, size.y * 0.525), Vector2(size.x * 0.955, size.y * 0.525),
		Vector2(size.x * 0.985, size.y * 0.955), Vector2(size.x * 0.015, size.y * 0.955),
	])
	draw_colored_polygon(upper, Color("2b1e274f"))
	draw_colored_polygon(lower, Color("17372f63"))

	# Guías de filas: existen para ayudar a colocar cartas, no para parecer una
	# hoja de cálculo. No se dibuja una cuadrícula completa.
	for fraction in [0.19, 0.35, 0.65, 0.81]:
		var y := size.y * fraction
		var inset := 0.105 if fraction in [0.19, 0.81] else 0.085
		draw_line(
			Vector2(size.x * inset, y), Vector2(size.x * (1.0 - inset), y),
			Color("8094862b"), 1.0
		)

	# Eje de duelo limpio. Las fases se muestran en HUD, no como botones sobre él.
	var center_y := size.y * 0.5
	draw_line(Vector2(size.x * 0.065, center_y), Vector2(size.x * 0.935, center_y), Color("dfc367"), 2.0)
	draw_line(Vector2(size.x * 0.09, center_y + 4), Vector2(size.x * 0.91, center_y + 4), Color("020507aa"), 1.0)
