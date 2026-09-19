extends Control
## Malla única medida en una referencia 1280×720. Todo el campo usa esta transformación.

const REFERENCE_SIZE := Vector2(1280, 720)
const REFERENCE_CENTER := Vector2(802, 367)
const BANDS := [
	[Vector2(612, 197), Vector2(992, 197), Vector2(1007, 245), Vector2(598, 245)],
	[Vector2(595, 250), Vector2(1008, 250), Vector2(1025, 308), Vector2(580, 308)],
	[Vector2(565, 355), Vector2(1038, 355), Vector2(1062, 433), Vector2(542, 433)],
	[Vector2(540, 440), Vector2(1063, 440), Vector2(1092, 537), Vector2(512, 537)],
]
const BAND_LABELS := ["APOYOS RIVAL", "CRIATURAS RIVAL", "TUS CRIATURAS", "TUS APOYOS"]
const CENTERS := [
	[Vector2(643, 221), Vector2(722, 221), Vector2(802, 220), Vector2(881, 221), Vector2(962, 221)],
	[Vector2(628, 278), Vector2(715, 279), Vector2(803, 278), Vector2(888, 279), Vector2(975, 279)],
	[Vector2(601, 394), Vector2(701, 394), Vector2(802, 394), Vector2(903, 394), Vector2(1003, 394)],
	[Vector2(579, 489), Vector2(690, 489), Vector2(802, 489), Vector2(914, 489), Vector2(1025, 489)],
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func template_scale() -> float:
	return minf(size.x / REFERENCE_SIZE.x, size.y / REFERENCE_SIZE.y)


func project(point: Vector2) -> Vector2:
	var factor := template_scale()
	var centered_y := size.y * 0.5 - REFERENCE_CENTER.y * factor
	# El fondo existente separa territorios al 51 % de su altura. La traslación
	# mínima impide que esa costura cruce la tercera banda sin alterar la malla.
	var seam_y := size.y * 0.51
	var clear_y := seam_y + 4.0 * factor - BANDS[2][0].y * factor
	var origin_y := maxf(centered_y, clear_y)
	return Vector2((point.x - REFERENCE_CENTER.x) * factor + size.x * 0.5, point.y * factor + origin_y)


func band_corners(index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point in BANDS[index]:
		points.append(project(point))
	return points


func slot_center(band_index: int, slot_index: int) -> Vector2:
	return project(CENTERS[band_index][slot_index])


func slot_corners(band_index: int, slot_index: int, guard: bool = false) -> PackedVector2Array:
	var band: Array = BANDS[band_index]
	var centers: Array = CENTERS[band_index]
	var center_x: float = centers[slot_index].x
	var left_pitch: float = center_x - centers[maxi(0, slot_index - 1)].x if slot_index > 0 else centers[1].x - center_x
	var right_pitch: float = centers[mini(4, slot_index + 1)].x - center_x if slot_index < 4 else center_x - centers[3].x
	var mid_left: float = (band[0].x + band[3].x) * 0.5
	var mid_right: float = (band[1].x + band[2].x) * 0.5
	var expansion := 0.56 if guard else 0.44
	var left_t := (center_x - left_pitch * expansion - mid_left) / (mid_right - mid_left)
	var right_t := (center_x + right_pitch * expansion - mid_left) / (mid_right - mid_left)
	var top_v := 0.20 if guard else 0.06
	var bottom_v := 0.80 if guard else 0.94
	return _band_strip(band_index, left_t, right_t, top_v, bottom_v)


func side_corners(band_index: int, right_side: bool) -> PackedVector2Array:
	return _band_strip(band_index, 1.025 if right_side else -0.16, 1.16 if right_side else -0.025, 0.13, 0.87)


func _band_strip(band_index: int, left_t: float, right_t: float, top_v: float, bottom_v: float) -> PackedVector2Array:
	var band: Array = BANDS[band_index]
	return PackedVector2Array([
		project(band[0].lerp(band[1], left_t).lerp(band[3].lerp(band[2], left_t), top_v)),
		project(band[0].lerp(band[1], right_t).lerp(band[3].lerp(band[2], right_t), top_v)),
		project(band[0].lerp(band[1], right_t).lerp(band[3].lerp(band[2], right_t), bottom_v)),
		project(band[0].lerp(band[1], left_t).lerp(band[3].lerp(band[2], left_t), bottom_v)),
	])


func _draw() -> void:
	var factor: float = template_scale()
	var font_size: int = maxi(10, roundi(12.0 * factor))
	var label_width: float = maxf(120.0, 150.0 * factor)
	for index in range(BANDS.size()):
		var quad := band_corners(index)
		draw_colored_polygon(quad, Color("c8d8b005"))
		for edge in range(4):
			draw_line(quad[edge], quad[(edge + 1) % 4], Color("91a89430"), 1.0, true)
		var left_mid: Vector2 = quad[0].lerp(quad[3], 0.56)
		var side_quad: PackedVector2Array = side_corners(index, false)
		var side_left_x: float = side_quad[0].x
		for corner in side_quad:
			side_left_x = minf(side_left_x, corner.x)
		var label_pos := Vector2(side_left_x - label_width - 10.0 * factor, left_mid.y + float(font_size) * 0.35)
		draw_string_outline(
			ThemeDB.fallback_font, label_pos, BAND_LABELS[index],
			HORIZONTAL_ALIGNMENT_RIGHT, label_width, font_size, 2, Color("05090bcc")
		)
		draw_string(
			ThemeDB.fallback_font, label_pos, BAND_LABELS[index],
			HORIZONTAL_ALIGNMENT_RIGHT, label_width, font_size, Color("d7ddd4d8")
		)
