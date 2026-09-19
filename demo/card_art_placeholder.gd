extends Control
## Arte provisional determinista para la vertical slice prehumana.
## No pretende sustituir ilustraciones finales: da identidad visual inmediata
## a cada tipo de carta sin introducir assets externos ni tocar reglas.

var _title := ""
var _card_type := ""
var _element := ""


func setup(title: String, card_type: String, element: String) -> void:
	_title = title
	_card_type = card_type
	_element = element
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_monogram()
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	if bounds.size.x <= 1.0 or bounds.size.y <= 1.0:
		return
	var base := _element_color()
	draw_rect(bounds, base.darkened(0.42))
	draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), base.darkened(0.20), false, 1.0)

	var center: Vector2 = size * 0.5
	var unit: float = minf(size.x, size.y)
	var accent: Color = base.lightened(0.42)
	var soft: Color = Color(accent, 0.35)
	var seed: int = _stable_hash(_title)
	var shift: float = float((seed % 9) - 4) * unit * 0.012

	match _card_type:
		"creature":
			_draw_creature(center, unit, accent, soft, shift, seed)
		"fusion":
			_draw_fusion(center, unit, accent, soft, shift, seed)
		"spell":
			_draw_spell(center, unit, accent, soft, shift)
		"trap":
			_draw_trap(center, unit, accent, soft, shift)
		"item":
			_draw_item(center, unit, accent, soft, shift)
		"terrain":
			_draw_terrain(center, unit, accent, soft, shift)
		_:
			draw_circle(center, unit * 0.22, soft)
			draw_circle(center, unit * 0.12, accent, false, max(1.0, unit * 0.025))


func _draw_creature(center: Vector2, unit: float, accent: Color, soft: Color, shift: float, seed: int) -> void:
	var head := center + Vector2(shift, -unit * 0.02)
	draw_circle(head, unit * 0.19, soft)
	var horn := unit * (0.13 + float(seed % 3) * 0.018)
	draw_line(head + Vector2(-unit * 0.12, -unit * 0.10), head + Vector2(-horn, -unit * 0.25), accent, max(1.0, unit * 0.035))
	draw_line(head + Vector2(unit * 0.12, -unit * 0.10), head + Vector2(horn, -unit * 0.25), accent, max(1.0, unit * 0.035))
	draw_circle(head + Vector2(-unit * 0.07, -unit * 0.01), max(1.5, unit * 0.024), accent)
	draw_circle(head + Vector2(unit * 0.07, -unit * 0.01), max(1.5, unit * 0.024), accent)
	draw_line(head + Vector2(-unit * 0.09, unit * 0.09), head + Vector2(unit * 0.09, unit * 0.09), accent, max(1.0, unit * 0.025))


func _draw_fusion(center: Vector2, unit: float, accent: Color, soft: Color, shift: float, seed: int) -> void:
	var left := center + Vector2(-unit * 0.09 + shift, 0)
	var right := center + Vector2(unit * 0.09 - shift, 0)
	draw_circle(left, unit * 0.15, soft)
	draw_circle(right, unit * 0.15, soft)
	draw_circle(center, unit * 0.08, accent, false, max(1.0, unit * 0.03))
	draw_line(left + Vector2(0, -unit * 0.09), center + Vector2(0, -unit * 0.22), accent, max(1.0, unit * 0.03))
	draw_line(right + Vector2(0, -unit * 0.09), center + Vector2(0, -unit * 0.22), accent, max(1.0, unit * 0.03))
	if seed % 2 == 0:
		draw_line(center + Vector2(-unit * 0.18, unit * 0.18), center + Vector2(unit * 0.18, unit * 0.18), accent, max(1.0, unit * 0.025))


func _draw_spell(center: Vector2, unit: float, accent: Color, soft: Color, shift: float) -> void:
	var c := center + Vector2(shift, 0)
	draw_circle(c, unit * 0.22, soft)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(angle), sin(angle))
		draw_line(c + dir * unit * 0.10, c + dir * unit * 0.27, accent, max(1.0, unit * 0.025))
	draw_circle(c, unit * 0.10, accent, false, max(1.0, unit * 0.03))


func _draw_trap(center: Vector2, unit: float, accent: Color, soft: Color, shift: float) -> void:
	var c := center + Vector2(shift, 0)
	var diamond := PackedVector2Array([
		c + Vector2(0, -unit * 0.24),
		c + Vector2(unit * 0.22, 0),
		c + Vector2(0, unit * 0.24),
		c + Vector2(-unit * 0.22, 0),
	])
	draw_colored_polygon(diamond, soft)
	for p in diamond:
		draw_line(c, p, accent, max(1.0, unit * 0.022))
	for i in range(diamond.size()):
		draw_line(diamond[i], diamond[(i + 1) % diamond.size()], accent, max(1.0, unit * 0.025))


func _draw_item(center: Vector2, unit: float, accent: Color, soft: Color, shift: float) -> void:
	var c := center + Vector2(shift, 0)
	draw_circle(c, unit * 0.20, soft)
	draw_line(c + Vector2(-unit * 0.16, unit * 0.16), c + Vector2(unit * 0.14, -unit * 0.15), accent, max(2.0, unit * 0.05))
	draw_line(c + Vector2(-unit * 0.14, -unit * 0.15), c + Vector2(unit * 0.16, unit * 0.16), accent, max(2.0, unit * 0.05))
	draw_line(c + Vector2(unit * 0.08, -unit * 0.19), c + Vector2(unit * 0.19, -unit * 0.08), accent, max(2.0, unit * 0.045))


func _draw_terrain(center: Vector2, unit: float, accent: Color, soft: Color, shift: float) -> void:
	var horizon_y := center.y - unit * 0.02
	draw_rect(Rect2(Vector2(unit * 0.08, horizon_y), Vector2(max(1.0, size.x - unit * 0.16), unit * 0.24)), soft)
	var left := Vector2(unit * 0.08, horizon_y + unit * 0.22)
	var mid := Vector2(center.x + shift, horizon_y - unit * 0.14)
	var right := Vector2(size.x - unit * 0.08, horizon_y + unit * 0.22)
	draw_colored_polygon(PackedVector2Array([left, mid, right]), Color(accent, 0.30))
	draw_line(Vector2(unit * 0.08, horizon_y), Vector2(size.x - unit * 0.08, horizon_y), accent, max(1.0, unit * 0.025))


func _build_monogram() -> void:
	for child in get_children():
		child.queue_free()
	var mark := Label.new()
	mark.text = _initials(_title)
	mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mark.add_theme_font_size_override("font_size", 16)
	mark.add_theme_color_override("font_color", Color("ffffffcc"))
	mark.add_theme_color_override("font_shadow_color", Color("000000cc"))
	mark.add_theme_constant_override("shadow_offset_x", 1)
	mark.add_theme_constant_override("shadow_offset_y", 1)
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(mark)


func _initials(title: String) -> String:
	var words := title.split(" ", false)
	if words.is_empty():
		return "?"
	var result := ""
	for word in words:
		var clean := String(word).strip_edges()
		if clean.length() < 2 or clean.to_lower() in ["de", "del", "la", "las", "los", "el", "y"]:
			continue
		result += clean.left(1).to_upper()
		if result.length() >= 2:
			break
	if result.is_empty():
		return title.left(1).to_upper()
	return result


func _stable_hash(value: String) -> int:
	var h := 17
	for i in range(value.length()):
		h = int((h * 31 + value.unicode_at(i)) & 0x7fffffff)
	return h


func _element_color() -> Color:
	return {
		"fire": Color("9b4a31"),
		"water": Color("356f99"),
		"nature": Color("4f7a4a"),
		"earth": Color("7b6242"),
		"air": Color("6f8790"),
		"ice": Color("6fa3ad"),
		"electricity": Color("8f8031"),
		"light": Color("9a8750"),
		"darkness": Color("514467"),
		"neutral": Color("6a6251"),
	}.get(_element, Color("655b4b"))
