extends "res://demo/projected_hit_button.gd"
## Carta visual provisional con silueta, postura y reverso. Las reglas siguen perteneciendo al motor.

signal card_selected(instance_id: String)
signal creature_drag_started(instance_id: String)
signal creature_drag_failed(instance_id: String)
signal fusion_drag_started(instance_id: String)
signal fusion_drag_failed(instance_id: String)
signal fusion_dropped(source_id: String, target_id: String)
signal equipment_drag_started(instance_id: String)
signal equipment_drag_failed(instance_id: String)
signal equipment_dropped(source_id: String, target_id: String)

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
var face_data: Dictionary = {}
var _selected := false
var _targeted := false
var _playable := false
var _creature_drag_enabled := false
var _fusion_drag_enabled := false
var _fusion_drop_sources: Array = []
var _equipment_drag_enabled := false
var _equipment_drop_sources: Array = []


func setup(
	p_instance_id: String,
	title: String,
	detail: String,
	interactive: bool = true,
	p_card_type: String = "",
	p_element: String = "",
	p_position: String = "",
	p_face_up: bool = true,
	p_display_mode: String = "field",
	p_face_data: Dictionary = {}
) -> void:
	instance_id = p_instance_id
	card_type = p_card_type
	element = p_element
	card_posture = p_position
	face_up = p_face_up
	display_mode = p_display_mode
	face_data = p_face_data.duplicate(true)
	text = ""
	var info := detail
	if card_type in ["creature", "fusion"] and face_data.has("attack"):
		info = "%s · %s · ATQ %d · DEF %d" % [
			"Coste %d" % int(face_data.get("cost", 0)) if card_type == "creature" else "Coste ref. %d" % int(face_data.get("cost", 0)),
			String(face_data.get("element_label", "")), int(face_data["attack"]), int(face_data["defense"])
		]
	if not String(face_data.get("effect_text", "")).is_empty():
		info += "\n" + String(face_data["effect_text"])
	tooltip_text = "%s%s" % [title, "\n" + info if not info.is_empty() else ""] if face_up else "Carta oculta"
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


func set_fusion_drag_enabled(value: bool) -> void:
	_fusion_drag_enabled = value


func set_fusion_drop_sources(source_ids: Array) -> void:
	_fusion_drop_sources = source_ids.duplicate()


func set_equipment_drag_enabled(value: bool) -> void:
	_equipment_drag_enabled = value
	if value:
		_playable = true
	_apply_card_style(not disabled, _selected)


func set_equipment_drop_sources(source_ids: Array) -> void:
	_equipment_drop_sources = source_ids.duplicate()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if (not _creature_drag_enabled and not _fusion_drag_enabled and not _equipment_drag_enabled) or disabled or instance_id.is_empty():
		return null
	if _fusion_drag_enabled:
		fusion_drag_started.emit(instance_id)
	elif _equipment_drag_enabled:
		equipment_drag_started.emit(instance_id)
	else:
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
	var drag_kind := "fusion_material" if _fusion_drag_enabled else ("equipment_from_hand" if _equipment_drag_enabled else "creature_from_hand")
	return {"kind": drag_kind, "instance_id": instance_id}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if disabled or not data is Dictionary:
		return false
	var source_id: String = data.get("instance_id", "")
	match data.get("kind", ""):
		"fusion_material":
			return source_id in _fusion_drop_sources
		"equipment_from_hand":
			return source_id in _equipment_drop_sources
	return false


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	if data.get("kind", "") == "equipment_from_hand":
		equipment_dropped.emit(data["instance_id"], instance_id)
	else:
		fusion_dropped.emit(data["instance_id"], instance_id)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and _creature_drag_enabled and not get_viewport().gui_is_drag_successful():
		creature_drag_failed.emit(instance_id)
	if what == NOTIFICATION_DRAG_END and _fusion_drag_enabled and not get_viewport().gui_is_drag_successful():
		fusion_drag_failed.emit(instance_id)
	if what == NOTIFICATION_DRAG_END and _equipment_drag_enabled and not get_viewport().gui_is_drag_successful():
		equipment_drag_failed.emit(instance_id)


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
	if display_mode in ["hand", "preview"]:
		_build_info_face(content, title)
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


func _build_info_face(content: VBoxContainer, title: String) -> void:
	var large := display_mode == "preview"
	var header := Label.new()
	header.name = "CardName"
	header.text = title
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	header.add_theme_font_size_override("font_size", 15 if large else 10)
	header.add_theme_color_override("font_color", Color("fff4d5"))
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(header)
	var identity := HBoxContainer.new()
	identity.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(identity)
	var element_label := Label.new()
	element_label.name = "CardElement"
	element_label.text = String(face_data.get("element_label", _type_label(card_type)))
	element_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	element_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	element_label.add_theme_font_size_override("font_size", 11 if large else 8)
	element_label.add_theme_color_override("font_color", Color("f6e8bd"))
	element_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	identity.add_child(element_label)
	if card_type in ["creature", "fusion"] and face_data.has("cost"):
		var cost := Label.new()
		cost.name = "CardCost"
		cost.text = "E %d" % int(face_data["cost"]) if card_type == "creature" else "REF %d" % int(face_data["cost"])
		cost.add_theme_font_size_override("font_size", 11 if large else 8)
		cost.add_theme_color_override("font_color", Color("fff4d5"))
		cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
		identity.add_child(cost)
	var art := PanelContainer.new()
	art.name = "ArtPlaceholder"
	art.size_flags_vertical = Control.SIZE_EXPAND_FILL
	art.add_theme_stylebox_override("panel", _art_style())
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(art)
	var sigil := Label.new()
	sigil.text = _sigil(title)
	sigil.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sigil.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sigil.add_theme_font_size_override("font_size", 42 if large else 20)
	sigil.add_theme_color_override("font_color", Color("ffffff99"))
	sigil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.add_child(sigil)
	if large and not String(face_data.get("effect_text", "")).is_empty():
		var effect := Label.new()
		effect.name = "CardEffect"
		effect.text = String(face_data["effect_text"])
		effect.custom_minimum_size = Vector2(0, 44)
		effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		effect.max_lines_visible = 3
		effect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		effect.add_theme_font_size_override("font_size", 10)
		effect.add_theme_color_override("font_color", Color("f6e8bd"))
		effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(effect)
	var type_label := Label.new()
	type_label.name = "CardType"
	type_label.text = _type_label(card_type)
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 11 if large else 8)
	type_label.add_theme_color_override("font_color", Color("f6e8bd"))
	type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(type_label)
	if card_type in ["creature", "fusion"] and face_data.has("attack"):
		var stats := HBoxContainer.new()
		stats.name = "CardStats"
		stats.add_theme_constant_override("separation", 1)
		stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(stats)
		for stat in ["ATQ", "DEF"]:
			var badge := Label.new()
			badge.name = "Card%s" % stat
			badge.text = "%s %d" % [stat, int(face_data["attack" if stat == "ATQ" else "defense"])]
			badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge.add_theme_font_size_override("font_size", 13 if large else 8)
			badge.add_theme_color_override("font_color", Color("fff4d5"))
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stats.add_child(badge)


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
