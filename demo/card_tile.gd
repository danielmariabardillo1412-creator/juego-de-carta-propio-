extends Button
## Carta visual provisional con silueta, postura y reverso. Las reglas siguen perteneciendo al motor.

signal card_selected(instance_id: String)
signal creature_drag_started(instance_id: String)
signal creature_drag_failed(instance_id: String)

const FIELD_ATTACK_SIZE := Vector2(72, 101)
const FIELD_GUARD_SIZE := Vector2(101, 72)
const HAND_SIZE := Vector2(86, 120)
const PREVIEW_SIZE := Vector2(180, 251)
const TERRAIN_SIZE := Vector2(112, 54)

var instance_id := ""
var card_type := ""
var element := ""
var card_posture := ""
var face_up := true
var display_mode := "field"
var _selected := false
var _targeted := false
var _playable := false
var _creature_drag_enabled := false


func setup(
	p_instance_id: String,
	title: String,
	detail: String,
	interactive: bool = true,
	p_card_type: String = "",
	p_element: String = "",
	p_position: String = "",
	p_face_up: bool = true,
	p_display_mode: String = "field"
) -> void:
	instance_id = p_instance_id
	card_type = p_card_type
	element = p_element
	card_posture = p_position
	face_up = p_face_up
	display_mode = p_display_mode
	text = ""
	tooltip_text = "%s%s" % [title, "\n" + detail if not detail.is_empty() else ""]
	clip_contents = true
	custom_minimum_size = _card_size()
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	disabled = not interactive or instance_id.is_empty()
	focus_mode = Control.FOCUS_ALL if not disabled else Control.FOCUS_NONE
	if not pressed.is_connected(_emit_selection):
		pressed.connect(_emit_selection)
	_build_face(title, detail)
	_apply_card_style(interactive)


func set_selected(value: bool) -> void:
	_selected = value
	button_pressed = value
	toggle_mode = value
	_apply_card_style(not disabled, value)


func set_targeted(value: bool) -> void:
	_targeted = value
	_apply_card_style(not disabled, _selected)


func set_creature_drag_enabled(value: bool) -> void:
	_creature_drag_enabled = value
	_playable = value
	_apply_card_style(not disabled, _selected)


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _creature_drag_enabled or disabled or instance_id.is_empty():
		return null
	creature_drag_started.emit(instance_id)
	var preview := PanelContainer.new()
	preview.custom_minimum_size = HAND_SIZE
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var label := Label.new()
	label.text = tooltip_text.get_slice("\n", 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.add_child(label)
	set_drag_preview(preview)
	return {"kind": "creature_from_hand", "instance_id": instance_id}


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _creature_drag_enabled and not get_viewport().gui_is_drag_successful():
		creature_drag_failed.emit(instance_id)


func _build_face(title: String, detail: String) -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 2)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	if not face_up:
		var back_mark := Label.new()
		back_mark.text = "✦\nZ\n✦" if display_mode != "opponent_hand" else "✦\nZ"
		back_mark.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		back_mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		back_mark.size_flags_vertical = Control.SIZE_EXPAND_FILL
		back_mark.add_theme_font_size_override("font_size", 18 if display_mode != "opponent_hand" else 13)
		back_mark.add_theme_color_override("font_color", Color("d8b96c"))
		back_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(back_mark)
		return
	var header := Label.new()
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_theme_font_size_override("font_size", 15 if display_mode == "preview" else (10 if display_mode == "hand" else 9))
	header.add_theme_color_override("font_color", Color("fff4d5"))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(header)
	var art := PanelContainer.new()
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel", _art_style())
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(art)
	var sigil := Label.new()
	sigil.text = _sigil(title)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.add_theme_font_size_override("font_size", 42 if display_mode == "preview" else (20 if display_mode == "hand" else 15))
	sigil.add_theme_color_override("font_color", Color("ffffff99"))
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(sigil)
	var footer := Label.new()
	footer.text = detail if not detail.is_empty() else _type_label(card_type)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	footer.add_theme_font_size_override("font_size", 13 if display_mode == "preview" else 9)
	footer.add_theme_color_override("font_color", Color("f6e8bd"))
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(footer)


func _card_size() -> Vector2:
	if display_mode == "preview":
		return PREVIEW_SIZE
	if display_mode in ["hand", "opponent_hand"]:
		return HAND_SIZE
	if display_mode == "terrain":
		return TERRAIN_SIZE
	if card_posture == "guard":
		return FIELD_GUARD_SIZE
	return FIELD_ATTACK_SIZE


func _apply_card_style(interactive: bool, selected: bool = false) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = _card_color() if face_up else Color("221b30")
	normal.border_color = Color("fff09b") if selected or _targeted else (Color("ddc56d") if _playable else (Color("c3a85d") if face_up else Color("786894")))
	normal.set_border_width_all(4 if selected else (3 if _targeted else 2))
	normal.set_corner_radius_all(4)
	normal.shadow_color = Color("00000088")
	normal.shadow_size = 7 if display_mode in ["hand", "preview"] else 5
	normal.shadow_offset = Vector2(0, 4)
	add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.13)
	hover.border_color = Color("fff2a8")
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", hover)
	var disabled_style := normal.duplicate()
	disabled_style.bg_color = normal.bg_color.darkened(0.1)
	add_theme_stylebox_override("disabled", disabled_style)


func _art_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _card_color().darkened(0.2)
	style.border_color = Color("f5e6b84d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	return style


func _type_label(value: String) -> String:
	return {
		"creature": "CRIATURA", "spell": "MAGIA", "trap": "TRAMPA",
		"item": "OBJETO", "terrain": "TERRENO", "fusion": "FUSIÓN",
	}.get(value, "CARTA")


func _sigil(title: String) -> String:
	if card_type == "terrain":
		return "⌁"
	if card_type == "spell":
		return "✦"
	if card_type == "trap":
		return "◇"
	if card_type == "item":
		return "⚒"
	if card_type == "fusion":
		return "✧"
	return title.left(1).to_upper() if not title.is_empty() else "?"


func _card_color() -> Color:
	if card_type == "terrain":
		return Color("41643f")
	if card_type == "spell":
		return Color("2d6574")
	if card_type == "trap":
		return Color("74476f")
	if card_type == "item":
		return Color("70603d")
	if card_type == "fusion":
		return Color("4d4079")
	return {
		"fire": Color("7c4332"), "water": Color("315c7b"), "nature": Color("426944"),
		"neutral": Color("625b4c"), "light": Color("776b3d"), "darkness": Color("403852"),
	}.get(element, Color("554c3d"))


func _emit_selection() -> void:
	if not instance_id.is_empty():
		card_selected.emit(instance_id)
