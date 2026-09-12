extends "res://demo/juego_cartas_table.gd"
## Greybox representativo de la interfaz final.
##
## Conserva intactos UCE, reglas, acciones y privacidad. Esta capa cambia solo
## jerarquía visual y disposición para que las pruebas humanas se hagan sobre
## una mesa parecida a la que finalmente se jugará, todavía sin arte definitivo.

const GreyboxBackdrop = preload("res://demo/duel_table_backdrop_greybox.gd")
const GreyboxCardTile = preload("res://demo/card_tile.gd")

# Estándar métrico V0.2. La referencia de validación es 1600x900 y 1 U = 72 px.
# La silueta 63:88 produce una carta de campo de 72x101 y una Guardia de 101x72.
# La casilla usa una envolvente cuadrada para que rotar nunca invada la vecina.
const DESIGN_U := 72.0
const FIELD_ATTACK_SIZE := Vector2(72, 101)
const FIELD_GUARD_SIZE := Vector2(101, 72)
const FIELD_ENVELOPE_SIZE := Vector2(101, 101)
const FIELD_GAP := 11.0
const FIELD_ROW_HEIGHT := 105.0
const HAND_ROW_HEIGHT := 124.0
const PLAYER_HUD_HEIGHT := 33.0
const SIDE_ZONE_SIZE := Vector2(60, 90)
const SIDE_ZONE_GAP := 16.0
const CONTEXT_RAIL_WIDTH := 274.0
const PHASE_HUD_HEIGHT := 26.0


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("050b10")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 4)
	margin.add_child(root_box)

	# HUD superior: solo controles de partida. Las herramientas de laboratorio
	# se desplazan al lateral para que no compitan con la mesa.
	var top_bar := HBoxContainer.new()
	top_bar.name = "GameHUD"
	top_bar.add_theme_constant_override("separation", 7)
	root_box.add_child(top_bar)

	var title := Label.new()
	title.text = "ZAPITY · DUELO"
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color("efd37b"))
	top_bar.add_child(title)

	var greybox_tag := Label.new()
	greybox_tag.text = "GREYBOX"
	greybox_tag.add_theme_font_size_override("font_size", 10)
	greybox_tag.add_theme_color_override("font_color", Color("82948e"))
	top_bar.add_child(greybox_tag)

	var hud_spacer := Control.new()
	hud_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(hud_spacer)

	_ai_enabled = CheckButton.new()
	_ai_enabled.name = "AIEnabled"
	_ai_enabled.text = "Rival IA"
	_ai_enabled.button_pressed = DisplayServer.get_name() != "headless"
	_ai_enabled.toggled.connect(_on_ai_toggled)
	top_bar.add_child(_ai_enabled)

	_advance_button = Button.new()
	_advance_button.name = "AdvancePhaseButton"
	_advance_button.custom_minimum_size.x = 122
	_advance_button.pressed.connect(_advance_phase_pressed)
	top_bar.add_child(_advance_button)

	_end_turn_button = Button.new()
	_end_turn_button.name = "EndTurnButton"
	_end_turn_button.text = "TERMINAR TURNO"
	_end_turn_button.custom_minimum_size.x = 132
	_end_turn_button.pressed.connect(_end_turn_pressed)
	top_bar.add_child(_end_turn_button)

	_seed_input = SpinBox.new()
	_seed_input.min_value = 0
	_seed_input.max_value = 2147483646
	_seed_input.step = 1
	_seed_input.value = DEFAULT_SEED
	_seed_input.custom_minimum_size.x = 92
	top_bar.add_child(_seed_input)

	var restart_button := Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "NUEVA"
	restart_button.tooltip_text = "Comenzar una nueva partida con la semilla indicada."
	restart_button.pressed.connect(_restart_pressed)
	top_bar.add_child(restart_button)

	# Se conserva para el contrato de la mesa y para modo local 2P, pero no ocupa
	# el HUD principal.
	_viewer_label = Label.new()
	_viewer_label.visible = false
	root_box.add_child(_viewer_label)

	_summary_label = Label.new()
	_summary_label.name = "Summary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_summary_label.add_theme_font_size_override("font_size", 12)
	_summary_label.add_theme_color_override("font_color", Color("cbd7d3"))
	root_box.add_child(_summary_label)

	# Banda de fases: HUD compacto pegado al borde superior del tablero, nunca una
	# fila de botones en mitad de la mesa.
	var phase_track := HBoxContainer.new()
	phase_track.alignment = BoxContainer.ALIGNMENT_CENTER
	phase_track.add_theme_constant_override("separation", 4)
	for phase_id in ["START", "DRAW", "MAIN_1", "COMBAT", "MAIN_2", "END"]:
		var phase_label := Label.new()
		phase_label.text = _phase_name(phase_id).to_upper()
		phase_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		phase_label.custom_minimum_size = Vector2(76, 20)
		phase_label.add_theme_font_size_override("font_size", 10)
		phase_track.add_child(phase_label)
		_phase_labels[phase_id] = phase_label

	_result_panel = PanelContainer.new()
	_result_panel.name = "ResultPanel"
	_result_panel.visible = false
	_result_panel.add_theme_stylebox_override("panel", _style_box(Color("171d20ed"), Color("d8bd64"), 2, 7))
	root_box.add_child(_result_panel)
	_result_label = Label.new()
	_result_label.name = "ResultLabel"
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_result_label.add_theme_font_size_override("font_size", 20)
	_result_label.add_theme_color_override("font_color", Color("f3d58a"))
	_result_panel.add_child(_result_label)

	_main_content = HSplitContainer.new()
	_main_content.name = "MainContent"
	_main_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# A 1600 px deja al tablero ~80 % del ancho y un rail contextual compacto.
	_main_content.split_offset = 1280
	root_box.add_child(_main_content)

	_board_surface = PanelContainer.new()
	_board_surface.name = "BoardSurface"
	_board_surface.custom_minimum_size = Vector2(890, 610)
	_board_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_surface.add_theme_stylebox_override("panel", _style_box(Color("071014"), Color("887448"), 1, 8))
	_main_content.add_child(_board_surface)

	var board_art = GreyboxBackdrop.new()
	board_art.name = "GreyboxBackdrop"
	board_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board_surface.add_child(board_art)

	var phase_panel := PanelContainer.new()
	phase_panel.name = "PhaseHUD"
	phase_panel.z_index = 8
	phase_panel.anchor_left = 0.5
	phase_panel.anchor_top = 0.0
	phase_panel.anchor_right = 0.5
	phase_panel.anchor_bottom = 0.0
	phase_panel.offset_left = -255
	phase_panel.offset_top = 4
	phase_panel.offset_right = 255
	phase_panel.offset_bottom = 4 + PHASE_HUD_HEIGHT
	phase_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	phase_panel.add_theme_stylebox_override("panel", _style_box(Color("0b1419df"), Color("6f694d"), 1, 12))
	_board_surface.add_child(phase_panel)
	var phase_center := CenterContainer.new()
	phase_panel.add_child(phase_center)
	phase_center.add_child(phase_track)

	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 12)
	board_margin.add_theme_constant_override("margin_right", 12)
	board_margin.add_theme_constant_override("margin_top", 32)
	board_margin.add_theme_constant_override("margin_bottom", 5)
	_board_surface.add_child(board_margin)
	_board_box = VBoxContainer.new()
	_board_box.name = "Board"
	_board_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_box.add_theme_constant_override("separation", 0)
	board_margin.add_child(_board_box)

	# Lateral contextual: carta grande primero, decisiones después. Deja de ser un
	# listado de depuración que compita visualmente con el tablero.
	var action_panel := PanelContainer.new()
	action_panel.custom_minimum_size.x = CONTEXT_RAIL_WIDTH
	action_panel.add_theme_stylebox_override("panel", _style_box(Color("0d161c"), Color("34464f"), 1, 7))
	_main_content.add_child(action_panel)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 8)
	action_margin.add_theme_constant_override("margin_right", 8)
	action_margin.add_theme_constant_override("margin_top", 7)
	action_margin.add_theme_constant_override("margin_bottom", 7)
	action_panel.add_child(action_margin)
	var action_outer := VBoxContainer.new()
	action_outer.add_theme_constant_override("separation", 5)
	action_margin.add_child(action_outer)

	var action_header := HBoxContainer.new()
	action_outer.add_child(action_header)
	_action_heading = Label.new()
	_action_heading.text = "DECISIONES"
	_action_heading.add_theme_font_size_override("font_size", 15)
	_action_heading.add_theme_color_override("font_color", Color("e9d28a"))
	action_header.add_child(_action_heading)
	var action_header_spacer := Control.new()
	action_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_header.add_child(action_header_spacer)
	var save_button := Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Guardar"
	save_button.pressed.connect(save_match)
	action_header.add_child(save_button)
	var load_button := Button.new()
	load_button.name = "LoadButton"
	load_button.text = "Cargar"
	load_button.pressed.connect(load_match)
	action_header.add_child(load_button)

	_selection_label = Label.new()
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_label.add_theme_font_size_override("font_size", 12)
	_selection_label.add_theme_color_override("font_color", Color("e8d17f"))
	action_outer.add_child(_selection_label)

	_card_preview_box = CenterContainer.new()
	_card_preview_box.name = "CardPreview"
	_card_preview_box.visible = false
	action_outer.add_child(_card_preview_box)

	_card_detail = RichTextLabel.new()
	_card_detail.name = "CardDetail"
	_card_detail.bbcode_enabled = true
	_card_detail.fit_content = true
	_card_detail.custom_minimum_size.y = 76
	_card_detail.visible = false
	action_outer.add_child(_card_detail)

	var action_separator := HSeparator.new()
	action_outer.add_child(action_separator)
	var action_scroll := ScrollContainer.new()
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_outer.add_child(action_scroll)
	_action_list = VBoxContainer.new()
	_action_list.name = "ActionList"
	_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_list.add_theme_constant_override("separation", 4)
	action_scroll.add_child(_action_list)

	_event_panel = PanelContainer.new()
	_event_panel.custom_minimum_size.y = 28
	action_outer.add_child(_event_panel)
	var event_box := VBoxContainer.new()
	_event_panel.add_child(event_box)
	var event_toggle := Button.new()
	event_toggle.name = "EventToggle"
	event_toggle.text = "HISTORIAL  ▸"
	event_toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
	event_toggle.flat = true
	event_toggle.pressed.connect(_toggle_event_log.bind(event_toggle))
	event_box.add_child(event_toggle)
	_event_log = RichTextLabel.new()
	_event_log.name = "EventLog"
	_event_log.bbcode_enabled = true
	_event_log.fit_content = false
	_event_log.scroll_active = true
	_event_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_event_log.visible = false
	event_box.add_child(_event_log)

	# Herramientas que siguen siendo necesarias para laboratorio / dos personas,
	# pero quedan fuera de la lectura normal de la partida.
	var local_tools := HBoxContainer.new()
	local_tools.name = "LocalTwoPlayerTools"
	local_tools.add_theme_constant_override("separation", 3)
	action_outer.add_child(local_tools)
	var local_caption := Label.new()
	local_caption.text = "2P"
	local_caption.add_theme_font_size_override("font_size", 9)
	local_caption.add_theme_color_override("font_color", Color("6f817e"))
	local_tools.add_child(local_caption)
	for player_id in [0, 1]:
		var viewer_button := Button.new()
		viewer_button.text = "J%d" % (player_id + 1)
		viewer_button.tooltip_text = "Cambiar a la vista del jugador %d." % (player_id + 1)
		viewer_button.pressed.connect(set_viewer.bind(player_id, true))
		local_tools.add_child(viewer_button)
	var curtain_button := Button.new()
	curtain_button.text = "Cortina"
	curtain_button.pressed.connect(_toggle_privacy)
	local_tools.add_child(curtain_button)
	_auto_follow = CheckButton.new()
	_auto_follow.text = "auto"
	_auto_follow.tooltip_text = "Cortina automática al cambiar de jugador en modo local."
	_auto_follow.button_pressed = true
	local_tools.add_child(_auto_follow)

	_end_turn_dialog = ConfirmationDialog.new()
	_end_turn_dialog.title = "Terminar el turno"
	_end_turn_dialog.dialog_text = "¿Terminar ahora? Se omitirán las fases que todavía no hayas jugado."
	_end_turn_dialog.ok_button_text = "Terminar turno"
	_end_turn_dialog.cancel_button_text = "Seguir jugando"
	_end_turn_dialog.confirmed.connect(_confirm_end_turn)
	add_child(_end_turn_dialog)

	_terrain_dialog = ConfirmationDialog.new()
	_terrain_dialog.title = "Cambiar el Territorio"
	_terrain_dialog.ok_button_text = "Jugar Terreno"
	_terrain_dialog.cancel_button_text = "Cancelar"
	_terrain_dialog.confirmed.connect(_confirm_terrain)
	add_child(_terrain_dialog)

	_privacy_panel = PanelContainer.new()
	_privacy_panel.name = "PrivacyOverlay"
	_privacy_panel.visible = false
	_privacy_panel.custom_minimum_size.y = 540
	root_box.add_child(_privacy_panel)
	var privacy_box := VBoxContainer.new()
	privacy_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_privacy_panel.add_child(privacy_box)
	_privacy_label = Label.new()
	_privacy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_privacy_label.add_theme_font_size_override("font_size", 24)
	privacy_box.add_child(_privacy_label)
	var reveal_button := Button.new()
	reveal_button.text = "Revelar mesa"
	reveal_button.custom_minimum_size = Vector2(260, 48)
	reveal_button.pressed.connect(_toggle_privacy)
	privacy_box.add_child(reveal_button)

	_choice_overlay = PanelContainer.new()
	_choice_overlay.name = "BoardChoiceOverlay"
	_choice_overlay.visible = false
	_choice_overlay.z_index = 20
	_choice_overlay.anchor_left = 0.5
	_choice_overlay.anchor_top = 0.5
	_choice_overlay.anchor_right = 0.5
	_choice_overlay.anchor_bottom = 0.5
	_choice_overlay.offset_left = -245
	_choice_overlay.offset_top = -110
	_choice_overlay.offset_right = 245
	_choice_overlay.offset_bottom = 110
	_choice_overlay.add_theme_stylebox_override("panel", _style_box(Color("0d171df7"), Color("e2c977"), 2, 10))
	add_child(_choice_overlay)
	var choice_margin := MarginContainer.new()
	choice_margin.add_theme_constant_override("margin_left", 16)
	choice_margin.add_theme_constant_override("margin_right", 16)
	choice_margin.add_theme_constant_override("margin_top", 12)
	choice_margin.add_theme_constant_override("margin_bottom", 12)
	_choice_overlay.add_child(choice_margin)
	var choice_box := VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 8)
	choice_margin.add_child(choice_box)
	_choice_overlay_title = Label.new()
	_choice_overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_choice_overlay_title.add_theme_font_size_override("font_size", 18)
	_choice_overlay_title.add_theme_color_override("font_color", Color("f3d58a"))
	choice_box.add_child(_choice_overlay_title)
	_choice_overlay_list = VBoxContainer.new()
	_choice_overlay_list.add_theme_constant_override("separation", 6)
	choice_box.add_child(_choice_overlay_list)


func _refresh() -> void:
	super._refresh()
	if _summary_label == null or _engine == null or not _engine.is_ready() or _engine.lifecycle_name() == "CREATED":
		return
	var envelope: Dictionary = _engine.get_player_state(_viewer_id)
	var game: Dictionary = envelope.get("game", {})
	if game.is_empty():
		return
	var active: int = game.get("active_player", 0)
	var response: Dictionary = game.get("response_window", {})
	var priority: int = response.get("priority_player_id", active) if response.get("active", false) else active
	var energy: Dictionary = game.get("energy", {}).get(str(active), {"available": 0, "maximum": 0})
	var turn_owner := "TU TURNO" if active == _viewer_id else "TURNO RIVAL"
	var summary := "%s  ·  Turno %d  ·  %s  ·  Energía %d/%d" % [
		turn_owner, game.get("turn_number", 0), _phase_name(game.get("phase", "")),
		energy.get("available", 0), energy.get("maximum", 0),
	]
	if priority != active:
		summary += "  ·  Decide %s" % PLAYER_NAMES[priority]
	if not _status_message.is_empty():
		summary += "  ·  %s" % _status_message
	_summary_label.text = summary
	if not _choice_actions.is_empty():
		_action_heading.text = "ELIGE UNA OPCIÓN"
	elif not _selected_card_id.is_empty():
		_action_heading.text = "CARTA SELECCIONADA"
	else:
		_action_heading.text = "DECISIONES"


func _build_player_half(game: Dictionary, player_id: int, opponent: bool) -> Control:
	var panel := MarginContainer.new()
	panel.name = "OpponentHalf" if opponent else "PlayerHalf"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 0.94 if opponent else 1.06
	panel.add_theme_constant_override("margin_left", 38)
	panel.add_theme_constant_override("margin_right", 38)

	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 1)
	outer.alignment = BoxContainer.ALIGNMENT_BEGIN if opponent else BoxContainer.ALIGNMENT_END
	panel.add_child(outer)

	var heading := Button.new()
	var life: int = game["life"][str(player_id)]
	var energy: Dictionary = game["energy"][str(player_id)]
	heading.text = "%s     ❤ %d     ◆ %d/%d" % [PLAYER_NAMES[player_id], life, energy["available"], energy["maximum"]]
	heading.alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.custom_minimum_size.y = PLAYER_HUD_HEIGHT
	heading.add_theme_stylebox_override("normal", _style_box(Color("111a20df"), Color("766846"), 1, 12))
	heading.add_theme_stylebox_override("hover", _style_box(Color("27312fe8"), Color("dfc66d"), 2, 12))
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", Color("9fd4a8") if player_id == _viewer_id else Color("d7aaaa"))
	if opponent and _selected_direct_attack_available():
		heading.text += "     ⚔ ATAQUE DIRECTO"
		heading.tooltip_text = "Pulsa aquí para declarar el ataque directo."
		heading.add_theme_color_override("font_color", Color("ffe58a"))
		heading.add_theme_stylebox_override("normal", _style_box(Color("49331c"), Color("e9c45c"), 2, 12))
		heading.pressed.connect(_on_direct_player_pressed)
	else:
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var table: Dictionary = game["card_table"]
	if opponent:
		outer.add_child(heading)
		outer.add_child(_build_hand_row(table, player_id))
		outer.add_child(_build_field_row(table, player_id, "support", true))
		outer.add_child(_build_field_row(table, player_id, "creatures", true))
	else:
		outer.add_child(_build_field_row(table, player_id, "creatures", false))
		outer.add_child(_build_field_row(table, player_id, "support", false))
		outer.add_child(_build_hand_row(table, player_id))
		outer.add_child(heading)
	return panel


func _build_hand_row(table: Dictionary, player_id: int) -> Control:
	var zone: Dictionary = table["zones"]["hand:%d" % player_id]
	var hand := Control.new()
	hand.name = "HandFan"
	hand.custom_minimum_size.y = HAND_ROW_HEIGHT
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cards: Array = zone["cards"] if zone["identities_visible"] else range(zone["count"])
	var count := cards.size()
	# Convención de densidad: primero se reduce separación y después se solapan
	# cartas. No se empequeñece la carta de mano mientras quepa el ancho normal.
	var step := 94.0
	if count >= 10:
		step = 48.0
	elif count >= 8:
		step = 60.0
	elif count >= 6:
		step = 76.0
	var total := step * maxi(0, count - 1)
	for index in range(count):
		var tile: Button
		if zone["identities_visible"]:
			tile = _tile_from_card(cards[index], player_id, "hand")
		else:
			tile = _make_card_tile("", "CARTA", "oculta", false, -1, "", -1, "", "", "", false, "opponent_hand")
			tile.tooltip_text = "Carta %d de la mano rival" % (index + 1)
		var tile_size: Vector2 = tile.custom_minimum_size
		tile.set_anchors_preset(Control.PRESET_CENTER_TOP)
		var x := -total * 0.5 + index * step - tile_size.x * 0.5
		tile.offset_left = x
		tile.offset_right = x + tile_size.x
		tile.offset_top = 2
		tile.offset_bottom = 2 + tile_size.y
		tile.rotation_degrees = 0
		tile.z_index = index
		hand.add_child(tile)
	return hand


func _build_field_row(table: Dictionary, player_id: int, kind: String, opponent: bool) -> Control:
	var row := Control.new()
	row.name = ("Opponent" if opponent else "Player") + ("SupportRow" if kind == "support" else "CreatureRow")
	row.custom_minimum_size.y = FIELD_ROW_HEIGHT
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zone: Dictionary = table["zones"]["%s:%d" % [kind, player_id]]
	var capacity: int = zone["definition"]["capacity"]
	var envelope_size := FIELD_ENVELOPE_SIZE
	var gap := FIELD_GAP
	var total_width := capacity * envelope_size.x + (capacity - 1) * gap
	var cards_by_slot := {}
	for slot in zone["slots"]:
		if slot["card"] != null:
			var card_id: String = slot["card"]["instance"]["id"]
			cards_by_slot[_visual_slot_for(kind, player_id, card_id)] = slot["card"]
	for slot in zone["slots"]:
		if slot["card"] == null:
			var hidden_slot := 0
			while cards_by_slot.has(hidden_slot) and hidden_slot < capacity:
				hidden_slot += 1
			if hidden_slot < capacity:
				cards_by_slot[hidden_slot] = {"hidden": true, "engine_slot": slot["index"]}

	for slot_index in range(capacity):
		var card = cards_by_slot.get(slot_index, null)
		var left := -total_width * 0.5 + slot_index * (envelope_size.x + gap)
		if card == null:
			var empty := Button.new()
			empty.name = "CreatureSlot" if kind == "creatures" else "SupportSlot"
			empty.set_meta("board_role", "creature_slot" if kind == "creatures" else "support_slot")
			empty.set_anchors_preset(Control.PRESET_CENTER_TOP)
			var slot_size := FIELD_ATTACK_SIZE
			empty.offset_left = left + (envelope_size.x - slot_size.x) * 0.5
			empty.offset_right = empty.offset_left + slot_size.x
			empty.offset_top = (FIELD_ROW_HEIGHT - slot_size.y) * 0.5
			empty.offset_bottom = empty.offset_top + slot_size.y
			var direct_attack := player_id != _viewer_id and kind == "creatures" and _selected_direct_attack_available()
			var direct_destination := (player_id == _viewer_id and _selected_card_can_enter(kind)) or direct_attack
			var slot_code := ("A" if kind == "support" else "C") + str(slot_index + 1)
			if direct_attack:
				empty.text = "%s\nATAQUE DIRECTO" % slot_code
			elif direct_destination:
				empty.text = "%s\nJUGAR AQUÍ" % slot_code
			else:
				empty.text = slot_code
			empty.tooltip_text = "Casilla %s. Selecciona una carta y después su destino." % slot_code
			empty.add_theme_font_size_override("font_size", 9)
			empty.add_theme_color_override("font_color", Color("f1d887") if direct_destination else Color("506762"))
			empty.add_theme_stylebox_override("normal", _style_box(
				Color("24392fb5") if direct_destination else Color("07111524"),
				Color("e0c86f") if direct_destination else Color("69807858"),
				2 if direct_destination else 1, 5, true
			))
			empty.add_theme_stylebox_override("hover", _style_box(Color("263c34"), Color("d7be68"), 2, 5))
			empty.pressed.connect(_on_empty_slot_pressed.bind(player_id, kind, slot_index))
			row.add_child(empty)
		else:
			var holder := Control.new()
			holder.name = "CreatureSlot" if kind == "creatures" else "SupportSlot"
			holder.set_meta("board_role", "creature_slot" if kind == "creatures" else "support_slot")
			holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
			holder.offset_left = left
			holder.offset_right = left + envelope_size.x
			holder.offset_top = (FIELD_ROW_HEIGHT - envelope_size.y) * 0.5
			holder.offset_bottom = holder.offset_top + envelope_size.y
			var tile: Button
			if card is Dictionary and card.get("hidden", false):
				var hidden_targetable := _hidden_slot_attack_available(player_id, card["engine_slot"])
				tile = GreyboxCardTile.new()
				tile.setup(
					"hidden-slot-%d-%d" % [player_id, card["engine_slot"]], "CARTA OCULTA", "GUARDIA",
					hidden_targetable, "", "", "guard", false, "opponent_field" if opponent else "field"
				)
				tile.set_targeted(hidden_targetable)
				tile.card_selected.connect(_on_hidden_board_card_selected.bind(player_id, kind, card["engine_slot"]))
				tile.add_to_group("jcp_card_tiles")
			else:
				tile = _tile_from_card(card, player_id, kind, slot_index)
			tile.set_anchors_preset(Control.PRESET_CENTER)
			var tile_size: Vector2 = tile.custom_minimum_size
			tile.offset_left = -tile_size.x * 0.5
			tile.offset_right = tile_size.x * 0.5
			tile.offset_top = -tile_size.y * 0.5
			tile.offset_bottom = tile_size.y * 0.5
			holder.add_child(tile)
			if kind == "creatures" and card is Dictionary and not card.get("hidden", false):
				var equipment_names := _equipment_names_for(table, player_id, card["instance"]["id"])
				if not equipment_names.is_empty():
					var equipment := Label.new()
					equipment.text = "⚒ " + ", ".join(equipment_names)
					equipment.tooltip_text = "Equipo vinculado: " + ", ".join(equipment_names)
					equipment.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
					equipment.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
					equipment.add_theme_font_size_override("font_size", 9)
					equipment.add_theme_color_override("font_color", Color("e2ca81"))
					equipment.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
					equipment.offset_left = -50
					equipment.offset_right = 50
					equipment.offset_top = -13
					equipment.offset_bottom = 0
					holder.add_child(equipment)
			row.add_child(holder)

	_add_field_side_zones(row, table, player_id, kind, opponent, capacity, envelope_size, gap)
	return row


func _add_field_side_zones(
	row: Control, table: Dictionary, player_id: int, kind: String, opponent: bool,
	capacity: int, envelope_size: Vector2, gap: float
) -> void:
	var total_width := capacity * envelope_size.x + (capacity - 1) * gap
	var left_x := -total_width * 0.5 - SIDE_ZONE_GAP - SIDE_ZONE_SIZE.x
	var right_x := total_width * 0.5 + SIDE_ZONE_GAP
	if kind == "support":
		var materials: int = table["zones"]["fusion_materials:%d" % player_id]["count"]
		_add_side_pile(row, "FUSIÓN", materials, left_x, SIDE_ZONE_SIZE, opponent)
		var deck: int = table["zones"]["deck:%d" % player_id]["count"]
		_add_side_pile(row, "BARAJA", deck, right_x, SIDE_ZONE_SIZE, opponent)
	else:
		_add_terrain_side(row, table, player_id, opponent, left_x, SIDE_ZONE_SIZE)
		var graveyard: int = table["zones"]["graveyard:%d" % player_id]["count"]
		_add_side_pile(row, "CEMENTERIO", graveyard, right_x, SIDE_ZONE_SIZE, opponent)


func _add_side_pile(row: Control, title: String, count: int, x: float, side_size: Vector2, opponent: bool) -> void:
	var pile := Button.new()
	pile.set_meta("board_role", "pile_zone")
	pile.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pile.offset_left = x
	pile.offset_right = x + side_size.x
	pile.offset_top = (FIELD_ROW_HEIGHT - side_size.y) * 0.5
	pile.offset_bottom = pile.offset_top + side_size.y
	pile.text = "%s\n%d" % [title, count]
	pile.tooltip_text = "%s: %d cartas" % [title.capitalize(), count]
	pile.disabled = true
	pile.add_theme_font_size_override("font_size", 8)
	pile.add_theme_color_override("font_disabled_color", Color("aebbb7"))
	pile.add_theme_stylebox_override("disabled", _style_box(Color("0b1419b8"), Color("65747a"), 1, 5, true))
	row.add_child(pile)


func _add_terrain_side(row: Control, table: Dictionary, player_id: int, opponent: bool, x: float, side_size: Vector2) -> void:
	var zone: Dictionary = table["zones"]["terrain:%d" % player_id]
	var destination := player_id == _viewer_id and _has_selected_action_type("play_terrain")
	var terrain := Button.new()
	terrain.name = "TerrainLane"
	terrain.set_meta("board_role", "terrain_lane")
	terrain.set_anchors_preset(Control.PRESET_CENTER_TOP)
	terrain.offset_left = x
	terrain.offset_right = x + side_size.x
	terrain.offset_top = (FIELD_ROW_HEIGHT - side_size.y) * 0.5
	terrain.offset_bottom = terrain.offset_top + side_size.y
	var terrain_name := "—"
	if zone["count"] > 0:
		terrain_name = zone["cards"][0].get("terrain_identity", {}).get("display_name", "ACTIVO")
	terrain.text = "TERRITORIO\n%s" % terrain_name
	terrain.tooltip_text = "Territorio de %s" % PLAYER_NAMES[player_id]
	terrain.add_theme_font_size_override("font_size", 8)
	terrain.add_theme_color_override("font_color", Color("f5df91") if destination else Color("a8b8ad"))
	terrain.add_theme_stylebox_override("normal", _style_box(
		Color("34422cc8") if destination else Color("15221dc0"),
		Color("e2c977") if destination else Color("5d7463"), 2 if destination else 1, 5, true
	))
	terrain.add_theme_stylebox_override("hover", _style_box(Color("394832"), Color("ecd47b"), 2, 5))
	terrain.pressed.connect(_on_terrain_pressed.bind(player_id))
	row.add_child(terrain)