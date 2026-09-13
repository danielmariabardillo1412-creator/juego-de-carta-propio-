extends Control
## Superficie greybox apoyada en el plano: el Control no recibe clics.

var caption := ""
var detail := ""
var face_color := Color("24372f")
var edge_color := Color("87988b")
var occupied := false
var face_down := false
var guard := false
var highlighted := false
var auxiliary := false
var template_corners := PackedVector2Array()


func configure(
	new_caption: String, new_detail: String, new_color: Color, new_edge: Color,
	new_occupied: bool, new_face_down: bool = false, new_guard: bool = false,
	new_highlighted: bool = false, new_auxiliary: bool = false
) -> void:
	caption = new_caption
	detail = new_detail
	face_color = new_color
	edge_color = new_edge
	occupied = new_occupied
	face_down = new_face_down
	guard = new_guard
	highlighted = new_highlighted
	auxiliary = new_auxiliary
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func projected_corners() -> PackedVector2Array:
	if template_corners.size() == 4:
		return template_corners
	var width := size.x
	var height := size.y
	var far_factor := 0.79 if guard else 0.72
	var top := height * (0.28 if guard else 0.17)
	var bottom := height * (0.76 if guard else 0.86)
	if auxiliary:
		far_factor = 0.74
		top = height * 0.20
		bottom = height * 0.82
	var inset := width * (1.0 - far_factor) * 0.5
	return PackedVector2Array([
		Vector2(inset, top), Vector2(width - inset, top),
		Vector2(width, bottom), Vector2(0.0, bottom),
	])


func _draw() -> void:
	var quad := projected_corners()
	if quad.size() != 4:
		return
	var shadow := PackedVector2Array([quad[0] + Vector2(0, 4), quad[1] + Vector2(0, 4), quad[2] + Vector2(0, 4), quad[3] + Vector2(0, 4)])
	draw_colored_polygon(shadow, Color("00000066"))
	var fill := face_color if occupied else Color(face_color.r, face_color.g, face_color.b, 0.12)
	if face_down:
		fill = Color("221b30")
	draw_colored_polygon(quad, fill)
	var border := Color("f2d98b") if highlighted else edge_color
	for index in range(4):
		draw_line(quad[index], quad[(index + 1) % 4], border, 2.0 if highlighted or occupied else 1.2, true)
	if occupied:
		var art := PackedVector2Array([
			quad[0].lerp(quad[3], 0.20).lerp(quad[1].lerp(quad[2], 0.20), 0.09),
			quad[1].lerp(quad[2], 0.20).lerp(quad[0].lerp(quad[3], 0.20), 0.09),
			quad[2].lerp(quad[1], 0.22).lerp(quad[3].lerp(quad[0], 0.22), 0.09),
			quad[3].lerp(quad[0], 0.22).lerp(quad[2].lerp(quad[1], 0.22), 0.09),
		])
		draw_colored_polygon(art, fill.darkened(0.16))
		if face_down:
			draw_line(art[0], art[2], Color("d8b96c88"), 1.0, true)
			draw_line(art[1], art[3], Color("d8b96c88"), 1.0, true)
	var font := ThemeDB.fallback_font
	var text_color := Color("ffe6a2") if highlighted else Color("e4e5d6")
	var label := "OCULTA" if face_down else caption
	var font_size := 9 if auxiliary or occupied else 10
	var usable := maxf(20.0, size.x * 0.88)
	var text_left := (size.x - usable) * 0.5
	var baseline := quad[3].y - (9.0 if detail.is_empty() else 15.0)
	if not label.is_empty():
		draw_string(font, Vector2(text_left, baseline), label, HORIZONTAL_ALIGNMENT_CENTER, usable, font_size, text_color)
	if not detail.is_empty() and not face_down:
		draw_string(font, Vector2(text_left, quad[3].y - 4.0), detail, HORIZONTAL_ALIGNMENT_CENTER, usable, 8, text_color)
