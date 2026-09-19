extends Control
## Mesa local de prueba para recorrer una partida usando exclusivamente vistas y acciones legales de UCE.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const SaveCodec = preload("res://src/persistence/save_codec.gd")
const SaveFileStore = preload("res://src/persistence/save_file_store.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardTile = preload("res://demo/card_tile.gd")
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")
const FieldTemplateLayer = preload("res://demo/field_template_layer.gd")
const DuelTableBackdrop = preload("res://demo/duel_table_backdrop.gd")
const PrehumanOnboarding = preload("res://demo/prehuman_onboarding.gd")
const TableInteractionState = preload("res://demo/table_interaction_state.gd")
const CreatureDropSlot = preload("res://demo/creature_drop_slot.gd")
const ProjectedHitButton = preload("res://demo/projected_hit_button.gd")

# Contrato visual greybox 63:88, medido sobre una referencia de 1600×900.
const DESIGN_U := 72.0
const FIELD_ATTACK_SIZE := Vector2(72, 101)
const FIELD_GUARD_SIZE := Vector2(101, 72)
const FIELD_ENVELOPE_SIZE := Vector2(101, 101)
const FIELD_GAP := 11.0
const FIELD_ROW_HEIGHT := 105.0
const HAND_CARD_SIZE := Vector2(86, 120)
const HAND_ROW_HEIGHT := 124.0
const PLAYER_HUD_HEIGHT := 33.0
const SIDE_ZONE_SIZE := Vector2(60, 90)
const CONTEXT_RAIL_WIDTH := 274.0
const PHASE_HUD_HEIGHT := 26.0
const HAND_STEPS := [94.0, 76.0, 60.0, 48.0]
const OPPONENT_HAND_DEPTH_SCALE := 0.90
const ACTIVATION_REVEAL_SECONDS := 4.0

const DEFAULT_SEED := 210921
const MAX_SEED := 2147483646
const DEFAULT_SAVE_PATH := "user://juego_cartas_propio/partida_manual.json"
const PLAYER_NAMES := ["Jugador 1", "Jugador 2"]
const DIRECT_BOARD_ACTIONS := [
	"summon_creature", "set_creature", "set_support", "play_persistent", "play_terrain",
	"play_main_spell", "equip_item", "attack", "activate_creature_ability", "activate_fusion_ability",
]
const ZONE_LABELS := {
	"deck": "Baraja",
	"terrain": "Terreno",
	"creatures": "Criaturas",
	"support": "Apoyos",
	"attachments": "Equipos vinculados",
	"fusion_materials": "Materiales contenidos",
	"graveyard": "Cementerio",
	"hand": "Mano",
}
const TERRAIN_PREVIEWS := {
	"R01|R02": "Bosque Inundado", "R02|R01": "Humedal Fértil",
	"R01|R03": "Bosque Ardiente", "R03|R01": "Bosque Volcánico",
	"R02|R03": "Caldera de Vapor", "R03|R02": "Llanura de Obsidiana",
}

var _engine: Object
@export var startup_seed := -1
var _match_rng := RandomNumberGenerator.new()
var _active_seed := -1
var _viewer_id := 0
var _request_number := 0
var _privacy_hidden := false
var _status_message := ""
var _selected_card_id := ""
var _attack_targeting := false
var _choice_actions: Array = []
var _choice_stage := ""
var _forced_pass_pending := false
var _visible_card_locations: Dictionary = {}
var _visual_slot_assignments: Dictionary = {}
var _pending_visual_placement: Dictionary = {}
var _ai_running := false
var _creature_interaction = TableInteractionState.new()
var _last_committed_action: Dictionary = {}
var _cached_legal_version := -1
var _cached_legal_viewer := -1
var _cached_legal_actions: Array = []
var _activation_queue: Array = []
var _announced_main_spells: Dictionary = {}
var _activation_catalog: Dictionary = {}
var _activation_overlay: Control
var _activation_title: Label
var _activation_card_box: CenterContainer
var _activation_effect: Label
var _activation_progress: Label
var _activation_timer: Timer

var _summary_label: Label
var _viewer_label: Label
var _board_box: VBoxContainer
var _action_list: VBoxContainer
var _action_heading: Label
var _selection_label: Label
var _card_preview_box: CenterContainer
var _card_detail: RichTextLabel
var _event_log: RichTextLabel
var _result_panel: PanelContainer
var _result_label: Label
var _privacy_panel: PanelContainer
var _privacy_label: Label
var _seed_input: SpinBox
var _auto_follow: CheckButton
var _main_content: HSplitContainer
var _event_panel: PanelContainer
var _event_expanded := false
var _board_surface: PanelContainer
var _ai_enabled: CheckButton
var _advance_button: Button
var _end_turn_button: Button
var _phase_indicator: Label
var _field_layer: Control
var _choice_overlay: PanelContainer
var _choice_overlay_title: Label
var _choice_overlay_list: VBoxContainer
var _creature_mode_popup: PanelContainer
var _creature_mode_buttons: HBoxContainer
var _creature_action_popup: PanelContainer
var _creature_action_buttons: VBoxContainer
var _end_turn_dialog: ConfirmationDialog
var _onboarding


func _ready() -> void:
	_match_rng.randomize()
	_build_interface()
	start_match(startup_seed if startup_seed >= 0 else _fresh_seed())


func _fresh_seed() -> int:
	var seed := _match_rng.randi_range(0, MAX_SEED)
	while seed == _active_seed:
		seed = _match_rng.randi_range(0, MAX_SEED)
	return seed


func start_match(seed: int = DEFAULT_SEED, config_overrides: Dictionary = {}) -> bool:
	var config := {"player_names": PLAYER_NAMES.duplicate(), "starting_player": 0}
	config.merge(config_overrides, true)
	_engine = UniversalCardEngine.new(GameModule.new(), config)
	_request_number = 0
	_viewer_id = 0
	_privacy_hidden = false
	_selected_card_id = ""
	_attack_targeting = false
	_choice_actions = []
	_choice_stage = ""
	_forced_pass_pending = false
	_visual_slot_assignments = {}
	_pending_visual_placement = {}
	_ai_running = false
	_creature_interaction.reset()
	_last_committed_action = {}
	_cached_legal_version = -1
	_cached_legal_viewer = -1
	_cached_legal_actions = []
	_clear_activation_reveal()
	if not _engine.is_ready():
		_status_message = "No se pudo construir el motor: %s" % str(_engine.construction_error())
		_refresh()
		return false
	var result = _engine.start(seed)
	if not result.success:
		_status_message = "No se pudo iniciar: %s — %s" % [result.code, result.message]
		_refresh()
		return false
	_active_seed = seed
	if _seed_input != null:
		_seed_input.value = seed
	_status_message = "Partida iniciada con semilla %d." % seed
	_auto_resolve_opening(0)
	_refresh()
	return true


func set_viewer(player_id: int, require_reveal: bool = true) -> void:
	if _ai_enabled != null and _ai_enabled.button_pressed and player_id == 1:
		_status_message = "El Jugador 2 está controlado por el rival automático."
		_refresh()
		return
	if player_id not in [0, 1] or player_id == _viewer_id:
		return
	_viewer_id = player_id
	_privacy_hidden = require_reveal
	_selected_card_id = ""
	_attack_targeting = false
	_choice_actions = []
	_choice_stage = ""
	_creature_interaction.reset()
	_status_message = "Vista preparada para %s." % PLAYER_NAMES[player_id]
	_refresh()


func perform_legal_action(index: int) -> bool:
	if _engine == null or _privacy_hidden:
		return false
	var actions: Array = _legal_actions()
	if index < 0 or index >= actions.size():
		return false
	return _perform_action(actions[index])


func save_match(path: String = DEFAULT_SAVE_PATH) -> bool:
	if _engine == null or _engine.lifecycle_name() not in ["RUNNING", "FINISHED"]:
		_status_message = "No hay una partida iniciada que guardar."
		_refresh()
		return false
	var package: Dictionary = SaveCodec.build(_engine, _engine.module_version())
	if not package["ok"]:
		_status_message = "No se pudo preparar el guardado: %s." % package["code"]
		_refresh()
		return false
	var encoded: Dictionary = SaveCodec.encode(package["value"], true)
	if not encoded["ok"]:
		_status_message = "No se pudo codificar el guardado: %s." % encoded["code"]
		_refresh()
		return false
	var stored: Dictionary = SaveFileStore.write_atomic(path, encoded["value"])
	if not stored["ok"]:
		_status_message = "No se pudo guardar: %s." % stored["code"]
		_refresh()
		return false
	_status_message = "Partida guardada en la ranura local."
	_refresh()
	return true


func load_match(path: String = DEFAULT_SAVE_PATH) -> bool:
	var loaded: Dictionary = SaveFileStore.read_recoverable(path)
	if not loaded["ok"]:
		_status_message = "No se pudo leer la partida: %s." % loaded["code"]
		_refresh()
		return false
	var decoded: Dictionary = SaveCodec.decode(loaded["value"])
	if not decoded["ok"]:
		_status_message = "El guardado no es válido: %s." % decoded["code"]
		_refresh()
		return false
	var replay: Dictionary = ReplayService.replay_from_snapshot(GameModule.new(), decoded["value"]["payload"])
	if not replay["ok"]:
		_status_message = "No se pudo reconstruir la partida: %s." % replay["code"]
		_refresh()
		return false
	_engine = replay["engine"]
	_request_number = _engine.state_version()
	_selected_card_id = ""
	_choice_actions = []
	_choice_stage = ""
	_forced_pass_pending = false
	_creature_interaction.reset()
	_privacy_hidden = true
	_cached_legal_version = -1
	_cached_legal_viewer = -1
	_cached_legal_actions = []
	_clear_activation_reveal()
	_status_message = "Partida cargada y verificada; revela la mesa para continuar."
	_refresh()
	return true


func debug_snapshot() -> Dictionary:
	if _engine == null:
		return {"ready": false}
	var envelope: Dictionary = _engine.get_player_state(_viewer_id)
	var game: Dictionary = envelope.get("game", {})
	var legal_actions: Array = _legal_actions()
	var related_count := 0
	for action in legal_actions:
		if _action_mentions_card(action, _selected_card_id):
			related_count += 1
	return {
		"ready": _engine.is_ready(),
		"lifecycle": _engine.lifecycle_name(),
		"module_version": _engine.module_version(),
		"seed": _active_seed,
		"viewer_id": _viewer_id,
		"privacy_hidden": _privacy_hidden,
		"state_version": _engine.state_version(),
		"phase": game.get("phase", ""),
		"active_player": game.get("active_player", -1),
		"legal_action_count": legal_actions.size(),
		"legal_actions": legal_actions,
		"selected_card_id": _selected_card_id,
		"attack_targeting": _attack_targeting,
		"creature_action_popup_visible": _creature_action_popup.visible if _creature_action_popup != null else false,
		"status_message": _status_message,
		"related_action_count": related_count,
		"choice_action_count": _choice_actions.size(),
		"choice_overlay_visible": _choice_overlay.visible if _choice_overlay != null else false,
		"precommit_active": _precommit_interaction_active(),
		"creature_interaction": _creature_interaction.snapshot(),
		"creature_mode_popup_visible": _creature_mode_popup.visible if _creature_mode_popup != null else false,
		"request_number": _request_number,
		"last_committed_action": _last_committed_action.duplicate(true),
		"card_detail_text": _card_detail.text if _card_detail != null else "",
		"result_visible": _result_panel.visible if _result_panel != null else false,
		"result_text": _result_label.text if _result_label != null else "",
		"board_player_count": _board_box.get_child_count() if _board_box != null else 0,
		"visual_board_layout": "measured-template-1280x720",
		"creature_slot_count": _count_nodes_with_role(_board_surface, "creature_slot"),
		"support_slot_count": _count_nodes_with_role(_board_surface, "support_slot"),
		"terrain_lane_count": _count_nodes_with_role(_board_surface, "terrain_lane"),
		"side_pile_count": _count_nodes_with_role(_board_surface, "pile_zone"),
		"ai_enabled": _ai_enabled.button_pressed if _ai_enabled != null else false,
		"ai_running": _ai_running,
		"rendered_card_count": _count_card_tiles(_board_surface) if _board_surface != null else 0,
		"rendered_action_count": _action_list.get_child_count() if _action_list != null else 0,
		"direct_board_action_types": DIRECT_BOARD_ACTIONS.duplicate(),
		"event_expanded": _event_expanded,
		"phase_track_count": 1 if _phase_indicator != null else 0,
		"onboarding_visible": _onboarding.visible if _onboarding != null else false,
		"onboarding_page_count": _onboarding.page_count() if _onboarding != null else 0,
		"event_text": _event_log.text if _event_log != null else "",
		"view": envelope,
	}


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = Color("081319")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	add_child(margin)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 5)
	margin.add_child(root_box)

	var controls := HBoxContainer.new()
	controls.add_theme_constant_override("separation", 8)
	root_box.add_child(controls)
	var title := Label.new()
	title.text = "MESA DE DUELO"
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color("d9c896"))
	controls.add_child(title)
	var debug_controls := HBoxContainer.new()
	debug_controls.name = "TestTools"
	debug_controls.visible = false
	debug_controls.add_theme_constant_override("separation", 8)
	root_box.add_child(debug_controls)
	_viewer_label = Label.new()
	_viewer_label.custom_minimum_size.x = 105
	debug_controls.add_child(_viewer_label)
	for player_id in [0, 1]:
		var viewer_button := Button.new()
		viewer_button.text = "Ver J%d" % (player_id + 1)
		viewer_button.pressed.connect(set_viewer.bind(player_id, true))
		debug_controls.add_child(viewer_button)
	var curtain_button := Button.new()
	curtain_button.text = "Cortina"
	curtain_button.pressed.connect(_toggle_privacy)
	debug_controls.add_child(curtain_button)
	_auto_follow = CheckButton.new()
	_auto_follow.text = "Cortina 2P"
	_auto_follow.button_pressed = true
	debug_controls.add_child(_auto_follow)
	_ai_enabled = CheckButton.new()
	_ai_enabled.name = "AIEnabled"
	_ai_enabled.text = "Rival IA"
	_ai_enabled.button_pressed = DisplayServer.get_name() != "headless"
	_ai_enabled.toggled.connect(_on_ai_toggled)
	controls.add_child(_ai_enabled)
	var primary_spacer := Control.new()
	primary_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	controls.add_child(primary_spacer)
	_phase_indicator = Label.new()
	_phase_indicator.name = "PhaseIndicator"
	_phase_indicator.add_theme_color_override("font_color", Color("ffe291"))
	_phase_indicator.add_theme_font_size_override("font_size", 12)
	controls.add_child(_phase_indicator)
	_advance_button = Button.new()
	_advance_button.name = "AdvancePhaseButton"
	_advance_button.pressed.connect(_on_phase_button_pressed)
	controls.add_child(_advance_button)
	_end_turn_button = Button.new()
	_end_turn_button.name = "EndTurnButton"
	_end_turn_button.text = "TERMINAR TURNO"
	_end_turn_button.pressed.connect(_end_turn_pressed)
	controls.add_child(_end_turn_button)
	var tools_button := Button.new()
	tools_button.name = "TestToolsButton"
	tools_button.text = "Herramientas ▸"
	tools_button.flat = true
	tools_button.pressed.connect(func() -> void:
		debug_controls.visible = not debug_controls.visible
		tools_button.text = "Herramientas ▾" if debug_controls.visible else "Herramientas ▸"
	)
	controls.add_child(tools_button)
	_seed_input = SpinBox.new()
	_seed_input.min_value = 0
	_seed_input.max_value = MAX_SEED
	_seed_input.step = 1
	_seed_input.value = DEFAULT_SEED
	_seed_input.custom_minimum_size.x = 105
	debug_controls.add_child(_seed_input)
	var replay_button := Button.new()
	replay_button.name = "ReplaySeedButton"
	replay_button.text = "Jugar semilla"
	replay_button.tooltip_text = "Repite esta partida o escribe otra semilla para una prueba reproducible."
	replay_button.pressed.connect(func() -> void: start_match(int(_seed_input.value)))
	debug_controls.add_child(replay_button)
	var restart_button := Button.new()
	restart_button.name = "RestartButton"
	restart_button.text = "Nueva partida"
	restart_button.pressed.connect(_restart_pressed)
	controls.add_child(restart_button)
	var guide_button := Button.new()
	guide_button.name = "GuideButton"
	guide_button.text = "GUÍA"
	guide_button.tooltip_text = "Repasa objetivo, tipos de carta, zonas, posturas y respuestas."
	guide_button.pressed.connect(func() -> void:
		if _onboarding != null:
			_onboarding.open()
	)
	controls.add_child(guide_button)

	_summary_label = Label.new()
	_summary_label.name = "Summary"
	_summary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_summary_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_summary_label.add_theme_color_override("font_color", Color("aabbb9"))
	_summary_label.add_theme_font_size_override("font_size", 13)
	root_box.add_child(_summary_label)
	_result_panel = PanelContainer.new()
	_result_panel.name = "ResultPanel"
	_result_panel.visible = false
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
	_main_content.split_offset = 1600 - CONTEXT_RAIL_WIDTH - 32
	root_box.add_child(_main_content)

	_board_surface = PanelContainer.new()
	_board_surface.name = "BoardSurface"
	_board_surface.custom_minimum_size = Vector2(960, 2 * (PLAYER_HUD_HEIGHT + HAND_ROW_HEIGHT + 2 * FIELD_ROW_HEIGHT) + PHASE_HUD_HEIGHT)
	_board_surface.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_surface.add_theme_stylebox_override("panel", _style_box(Color("071014"), Color("8b7951"), 2, 10))
	_main_content.add_child(_board_surface)
	var board_art = DuelTableBackdrop.new()
	board_art.name = "DuelTableBackdrop"
	board_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_board_surface.add_child(board_art)
	var board_margin := MarginContainer.new()
	board_margin.add_theme_constant_override("margin_left", 22)
	board_margin.add_theme_constant_override("margin_right", 22)
	board_margin.add_theme_constant_override("margin_top", 8)
	board_margin.add_theme_constant_override("margin_bottom", 8)
	_board_surface.add_child(board_margin)
	_board_box = VBoxContainer.new()
	_board_box.name = "Board"
	_board_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_box.add_theme_constant_override("separation", 0)
	board_margin.add_child(_board_box)
	_field_layer = FieldTemplateLayer.new()
	_field_layer.name = "FieldTemplateLayer"
	_field_layer.z_index = 3
	_board_surface.add_child(_field_layer)
	_field_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_field_layer.resized.connect(_layout_template_field)

	var action_panel := PanelContainer.new()
	action_panel.custom_minimum_size.x = CONTEXT_RAIL_WIDTH
	action_panel.add_theme_stylebox_override("panel", _style_box(Color("111b22"), Color("3b4b55"), 1, 7))
	_main_content.add_child(action_panel)
	var action_outer := VBoxContainer.new()
	action_panel.add_child(action_outer)
	_action_heading = Label.new()
	_action_heading.text = "ACCIONES LEGALES"
	_action_heading.add_theme_font_size_override("font_size", 14)
	_action_heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_action_heading.clip_text = true
	var action_header := HBoxContainer.new()
	action_outer.add_child(action_header)
	action_header.add_child(_action_heading)
	var save_button := Button.new()
	save_button.name = "SaveButton"
	save_button.text = "Guardar"
	save_button.pressed.connect(save_match)
	var load_button := Button.new()
	load_button.name = "LoadButton"
	load_button.text = "Cargar"
	load_button.pressed.connect(load_match)
	_selection_label = Label.new()
	_selection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_selection_label.add_theme_color_override("font_color", Color("f3d58a"))
	action_outer.add_child(_selection_label)
	_card_preview_box = CenterContainer.new()
	_card_preview_box.name = "CardPreview"
	_card_preview_box.visible = false
	action_outer.add_child(_card_preview_box)
	_card_detail = RichTextLabel.new()
	_card_detail.name = "CardDetail"
	_card_detail.bbcode_enabled = true
	_card_detail.fit_content = true
	_card_detail.custom_minimum_size.y = 92
	_card_detail.visible = false
	action_outer.add_child(_card_detail)
	var action_scroll := ScrollContainer.new()
	action_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	action_outer.add_child(action_scroll)
	_action_list = VBoxContainer.new()
	_action_list.name = "ActionList"
	_action_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_scroll.add_child(_action_list)

	_event_panel = PanelContainer.new()
	_event_panel.custom_minimum_size.y = 30
	action_outer.add_child(_event_panel)
	var event_box := VBoxContainer.new()
	_event_panel.add_child(event_box)
	var event_toggle := Button.new()
	event_toggle.name = "EventToggle"
	event_toggle.text = "HISTORIAL DE LA PARTIDA  ▸"
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
	var utility_row := HBoxContainer.new()
	utility_row.alignment = BoxContainer.ALIGNMENT_END
	action_outer.add_child(utility_row)
	utility_row.add_child(save_button)
	utility_row.add_child(load_button)

	_end_turn_dialog = ConfirmationDialog.new()
	_end_turn_dialog.title = "Terminar el turno"
	_end_turn_dialog.dialog_text = "¿Terminar ahora? Se descartará la jugada sin confirmar y se omitirán las fases restantes."
	_end_turn_dialog.ok_button_text = "Terminar turno"
	_end_turn_dialog.cancel_button_text = "Seguir jugando"
	_end_turn_dialog.confirmed.connect(_confirm_end_turn)
	add_child(_end_turn_dialog)

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
	reveal_button.text = "Soy este jugador: revelar mesa"
	reveal_button.custom_minimum_size = Vector2(320, 54)
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
	_choice_overlay.offset_left = -250
	_choice_overlay.offset_top = -115
	_choice_overlay.offset_right = 250
	_choice_overlay.offset_bottom = 115
	_choice_overlay.add_theme_stylebox_override("panel", _style_box(Color("111b22f5"), Color("e2c977"), 3, 10))
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
	_choice_overlay_title.add_theme_font_size_override("font_size", 19)
	_choice_overlay_title.add_theme_color_override("font_color", Color("f3d58a"))
	choice_box.add_child(_choice_overlay_title)
	_choice_overlay_list = VBoxContainer.new()
	_choice_overlay_list.add_theme_constant_override("separation", 6)
	choice_box.add_child(_choice_overlay_list)
	_creature_mode_popup = PanelContainer.new()
	_creature_mode_popup.name = "CreatureModePopup"
	_creature_mode_popup.visible = false
	_creature_mode_popup.z_index = 21
	_creature_mode_popup.custom_minimum_size = Vector2(186, 38)
	_creature_mode_popup.add_theme_stylebox_override("panel", _style_box(Color("111b22ed"), Color("b9a566"), 1, 5))
	add_child(_creature_mode_popup)
	_creature_mode_buttons = HBoxContainer.new()
	_creature_mode_buttons.add_theme_constant_override("separation", 4)
	_creature_mode_popup.add_child(_creature_mode_buttons)
	_creature_action_popup = PanelContainer.new()
	_creature_action_popup.name = "CreatureActionPopup"
	_creature_action_popup.visible = false
	_creature_action_popup.z_index = 22
	_creature_action_popup.custom_minimum_size = Vector2(162, 0)
	_creature_action_popup.add_theme_stylebox_override("panel", _style_box(Color("111b22f5"), Color("d3bc75"), 1, 5))
	add_child(_creature_action_popup)
	var action_margin := MarginContainer.new()
	action_margin.add_theme_constant_override("margin_left", 5)
	action_margin.add_theme_constant_override("margin_right", 5)
	action_margin.add_theme_constant_override("margin_top", 5)
	action_margin.add_theme_constant_override("margin_bottom", 5)
	_creature_action_popup.add_child(action_margin)
	_creature_action_buttons = VBoxContainer.new()
	_creature_action_buttons.add_theme_constant_override("separation", 3)
	action_margin.add_child(_creature_action_buttons)
	_build_activation_reveal()

	_onboarding = PrehumanOnboarding.new()
	# Solo autoabrir cuando esta mesa es la escena principal real.
	# Tests/herramientas instancian la mesa como hija y no deben quedar bloqueados.
	_onboarding.visible = DisplayServer.get_name() != "headless" and get_tree().current_scene == self
	add_child(_onboarding)


func _build_activation_reveal() -> void:
	_activation_overlay = Control.new()
	_activation_overlay.name = "ActivationOverlay"
	_activation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_activation_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_activation_overlay.visible = false
	_activation_overlay.z_index = 30
	add_child(_activation_overlay)
	var shade := ColorRect.new()
	shade.color = Color("000000b8")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activation_overlay.add_child(shade)
	var centered := CenterContainer.new()
	centered.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	centered.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activation_overlay.add_child(centered)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620, 320)
	panel.add_theme_stylebox_override("panel", _style_box(Color("111b22f5"), Color("e2c977"), 3, 10))
	centered.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	_activation_title = Label.new()
	_activation_title.name = "ActivationTitle"
	_activation_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_activation_title.add_theme_font_size_override("font_size", 20)
	_activation_title.add_theme_color_override("font_color", Color("f3d58a"))
	column.add_child(_activation_title)
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 18)
	column.add_child(content)
	_activation_card_box = CenterContainer.new()
	_activation_card_box.name = "ActivationCard"
	_activation_card_box.custom_minimum_size.x = 180
	content.add_child(_activation_card_box)
	var details := VBoxContainer.new()
	details.custom_minimum_size.x = 360
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(details)
	_activation_effect = Label.new()
	_activation_effect.name = "ActivationEffect"
	_activation_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_activation_effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_activation_effect.add_theme_font_size_override("font_size", 16)
	details.add_child(_activation_effect)
	_activation_progress = Label.new()
	_activation_progress.name = "ActivationProgress"
	_activation_progress.add_theme_color_override("font_color", Color("c7d1d6"))
	details.add_child(_activation_progress)
	var next_button := Button.new()
	next_button.name = "ActivationNext"
	next_button.text = "Siguiente ahora"
	next_button.pressed.connect(_advance_activation_reveal)
	details.add_child(next_button)
	_activation_timer = Timer.new()
	_activation_timer.one_shot = true
	_activation_timer.timeout.connect(_advance_activation_reveal)
	add_child(_activation_timer)
	for spec in GameModule.new().call("_card_specs"):
		_activation_catalog[String(spec["id"])] = spec["attributes"]


func _clear_activation_reveal() -> void:
	_activation_queue.clear()
	_announced_main_spells.clear()
	if _activation_timer != null:
		_activation_timer.stop()
	if _activation_overlay != null:
		_activation_overlay.visible = false


func _activation_entries_from_events(events: Array) -> Array:
	var entries: Array = []
	for event in events:
		var kind: String = event.get("type", "")
		var payload: Dictionary = event.get("payload", {})
		var definition_id: String = String(payload.get("source_definition_id", "")) if kind == "persistent_effect_triggered" else String(payload.get("definition_id", ""))
		if not _activation_catalog.has(definition_id):
			continue
		var attributes: Dictionary = _activation_catalog[definition_id]
		if not String(attributes.get("card_type", "")) in ["spell", "trap"]:
			continue
		var key := "%s:%s" % [str(payload.get("player_id", -1)), definition_id]
		if kind == "main_spell_activated":
			_announced_main_spells[key] = int(_announced_main_spells.get(key, 0)) + 1
		elif kind == "main_spell_resolved":
			if int(_announced_main_spells.get(key, 0)) > 0:
				_announced_main_spells[key] = int(_announced_main_spells[key]) - 1
				continue
		elif kind not in ["reaction_activated", "persistent_played", "persistent_effect_triggered"]:
			continue
		entries.append({"definition_id": definition_id, "player_id": int(payload.get("player_id", -1)), "kind": kind, "sequence": int(event.get("sequence", 0))})
	return entries


func _queue_public_activations(start_index: int) -> void:
	var events: Array = _engine.get_events(0, _viewer_id)
	var entries := _activation_entries_from_events(events.slice(start_index))
	if DisplayServer.get_name() == "headless" or entries.is_empty():
		return
	_activation_queue.append_array(entries)
	if not _activation_overlay.visible and not _privacy_hidden:
		call_deferred("_show_next_activation")


func _show_next_activation() -> void:
	if _privacy_hidden or _activation_overlay.visible or _activation_queue.is_empty():
		return
	var entry: Dictionary = _activation_queue.pop_front()
	var attributes: Dictionary = _activation_catalog[entry["definition_id"]]
	var owner: int = entry["player_id"]
	var who := "Tu carta" if owner == _viewer_id else ("Carta rival" if owner in [0, 1] else "Carta activada")
	_activation_title.text = "%s · %s" % [who, "TRAMPA" if attributes["card_type"] == "trap" else "MAGIA"]
	_clear_children(_activation_card_box)
	var tile := CardTile.new()
	tile.setup("", String(attributes["display_name"]), "", false, String(attributes["card_type"]), String(attributes.get("element", "")), "", true, "preview", {"effect_text": String(attributes.get("effect_text", ""))})
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_activation_card_box.add_child(tile)
	_activation_effect.text = String(attributes.get("effect_text", ""))
	_activation_progress.text = "Activación pública #%d · %d más en espera · continúa en %.0f s" % [entry["sequence"], _activation_queue.size(), ACTIVATION_REVEAL_SECONDS]
	_activation_overlay.visible = true
	_activation_timer.start(ACTIVATION_REVEAL_SECONDS)


func _advance_activation_reveal() -> void:
	_activation_timer.stop()
	_activation_overlay.visible = false
	if not _activation_queue.is_empty():
		_show_next_activation()
	elif _forced_pass_pending:
		call_deferred("_pass_forced_response")


func _activation_pause_active() -> bool:
	return _activation_overlay.visible or not _activation_queue.is_empty()


func _refresh() -> void:
	if _summary_label == null:
		return
	_viewer_label.text = "Vista: J%d" % (_viewer_id + 1)
	_main_content.visible = not _privacy_hidden
	_event_panel.visible = not _privacy_hidden
	_privacy_panel.visible = _privacy_hidden
	_privacy_label.text = "Mesa oculta\nEntrega el control a %s" % PLAYER_NAMES[_viewer_id]
	_clear_children(_board_box)
	_clear_children(_field_layer)
	_clear_children(_action_list)
	_clear_children(_choice_overlay_list)
	_choice_overlay.visible = false
	_clear_children(_creature_mode_buttons)
	_creature_mode_popup.visible = false
	_clear_children(_creature_action_buttons)
	_creature_action_popup.visible = false
	if _engine == null or not _engine.is_ready() or _engine.lifecycle_name() == "CREATED":
		_summary_label.text = _status_message
		return
	var envelope: Dictionary = _engine.get_player_state(_viewer_id)
	var game: Dictionary = envelope["game"]
	_sync_visual_slots(game["card_table"])
	_visible_card_locations = _visible_card_location_index(game["card_table"])
	_update_result_panel(game)
	var active: int = game["active_player"]
	var response: Dictionary = game["response_window"]
	var actor: int = response.get("priority_player_id", active) if response.get("active", false) else active
	var turn_context := "Tu turno" if active == _viewer_id else "Turno rival"
	if response.get("active", false):
		turn_context = "Puedes responder" if actor == _viewer_id else "El rival puede responder"
	_summary_label.text = "%s · %s" % [turn_context, _phase_name(game["phase"])]
	if not _status_message.is_empty():
		_summary_label.text += " · " + _status_message
	_summary_label.tooltip_text = _status_message
	_update_advance_button(game)
	_update_phase_track(game["phase"])
	if _privacy_hidden:
		return
	_board_box.add_child(_build_player_half(game, 1 - _viewer_id, true))
	_board_box.add_child(_build_player_half(game, _viewer_id, false))
	for field_spec in [[1 - _viewer_id, "support", true], [1 - _viewer_id, "creatures", true], [_viewer_id, "creatures", false], [_viewer_id, "support", false]]:
		var field_row := _build_field_row(game["card_table"], field_spec[0], field_spec[1], field_spec[2])
		_field_layer.add_child(field_row)
		field_row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_layout_template_field()
	call_deferred("_layout_template_field")
	var actions: Array = _legal_actions()
	_schedule_forced_pass(actions, game)
	var visible_index: Dictionary = _visible_card_index(game["card_table"])
	var visible_cards: Dictionary = _visible_cards_by_id(game["card_table"])
	if not _selected_card_id.is_empty() and not visible_index.has(_selected_card_id):
		_selected_card_id = ""
		_attack_targeting = false
		_creature_interaction.reset()
	_card_detail.visible = not _selected_card_id.is_empty()
	_card_detail.text = _card_detail_text(visible_cards.get(_selected_card_id, {})) if _card_detail.visible else ""
	_clear_children(_card_preview_box)
	_card_preview_box.visible = _card_detail.visible
	if _card_preview_box.visible:
		var preview_card: Dictionary = visible_cards.get(_selected_card_id, {})
		if not preview_card.is_empty():
			_card_preview_box.add_child(_preview_tile_from_card(preview_card))
	var valid_choices: Array = []
	for choice_action in _choice_actions:
		if choice_action in actions:
			valid_choices.append(choice_action)
	_choice_actions = valid_choices
	if _choice_actions.is_empty():
		_choice_stage = ""
	if _creature_interaction.phase == TableInteractionState.Phase.MODE_SELECTION:
		_render_creature_mode_popup(actions)
	if _choice_actions.is_empty():
		_render_creature_action_popup(actions, visible_cards)
	if not _choice_actions.is_empty():
		_action_heading.text = "ELECCIÓN"
		_selection_label.text = "Elige postura y, si el efecto lo requiere, su objetivo."
		_choice_overlay.visible = true
		_render_choice_buttons(visible_index)
		if _choice_actions[0]["type"] == "fuse_creatures":
			var change_material_button := Button.new()
			change_material_button.name = "FusionChangeSecondMaterial"
			change_material_button.text = "← CAMBIAR SEGUNDO MATERIAL"
			change_material_button.tooltip_text = "Mantiene el primer material y vuelve a elegir el segundo. No compromete cartas ni Energía."
			change_material_button.pressed.connect(_back_to_fusion_partner_selection)
			_choice_overlay_list.add_child(change_material_button)
		var cancel_button := Button.new()
		cancel_button.text = "NO · CANCELAR FUSIÓN" if _choice_actions[0]["type"] == "fuse_creatures" else "Cancelar y volver al tablero"
		cancel_button.pressed.connect(_cancel_choices)
		_choice_overlay_list.add_child(cancel_button)
		_render_events()
		return
	var related: Array = []
	var general: Array = []
	for index in range(actions.size()):
		var entry := {"index": index, "action": actions[index]}
		if _action_mentions_card(actions[index], _selected_card_id):
			if actions[index]["type"] not in DIRECT_BOARD_ACTIONS and not (actions[index]["type"] == "change_position" and _own_creature_selected()):
				related.append(entry)
		elif actions[index]["type"] == "concede":
			general.append(entry)
	var ordered_actions: Array = related + general
	_action_heading.text = "CARTA" if _selected_card_id.is_empty() else "SELECCIÓN · %d" % ordered_actions.size()
	_selection_label.text = _selection_instruction(actions, visible_index, visible_cards)
	if actions.is_empty():
		var none := Label.new()
		none.text = "El rival está decidiendo…" if _ai_is_actor(game) else "Este jugador no tiene la prioridad."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_action_list.add_child(none)
	else:
		for group in _group_action_entries(ordered_actions):
			var group_actions: Array = group["actions"]
			var action: Dictionary = group_actions[0]
			var button := Button.new()
			button.text = _describe_action(action, visible_index) if group_actions.size() == 1 else "%s\n  Elegir entre %d objetivos u opciones" % [action["label"], group_actions.size()]
			button.tooltip_text = JSON.stringify(action["payload"])
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			if group_actions.size() == 1:
				button.pressed.connect(_perform_action.bind(action))
			else:
				button.pressed.connect(_open_action_choices.bind(group_actions))
			_action_list.add_child(button)
	_render_events()


func _build_player_half(game: Dictionary, player_id: int, opponent: bool) -> Control:
	var panel := MarginContainer.new()
	panel.name = "OpponentHalf" if opponent else "PlayerHalf"
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = 1.0
	var table: Dictionary = game["card_table"]
	panel.add_theme_constant_override("margin_left", 55)
	panel.add_theme_constant_override("margin_right", 55)
	var outer := VBoxContainer.new()
	outer.add_theme_constant_override("separation", 0)
	outer.alignment = BoxContainer.ALIGNMENT_BEGIN if opponent else BoxContainer.ALIGNMENT_END
	panel.add_child(outer)
	var heading := Button.new()
	var life: int = game["life"][str(player_id)]
	var energy: Dictionary = game["energy"][str(player_id)]
	heading.text = "%s%s     ❤ VIDA %d     ◆ ENERGÍA %d/%d" % [
		PLAYER_NAMES[player_id], " · RIVAL" if opponent else " · TÚ", life,
		energy["available"], energy["maximum"],
	]
	heading.alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.custom_minimum_size.y = PLAYER_HUD_HEIGHT
	heading.add_theme_stylebox_override("normal", _style_box(Color("111a20d9"), Color("867346"), 1, 14))
	heading.add_theme_stylebox_override("hover", _style_box(Color("24302fd9"), Color("e6ca75"), 2, 14))
	heading.add_theme_font_size_override("font_size", 16)
	heading.add_theme_color_override("font_color", Color("9fd4a8") if player_id == _viewer_id else Color("d6a6a6"))
	if opponent and _selected_direct_attack_available():
		heading.text += "     ⚔ ATAQUE DIRECTO"
		heading.tooltip_text = "El rival no tiene criaturas. Pulsa aquí para atacar directamente."
		heading.add_theme_color_override("font_color", Color("ffe58a"))
		heading.add_theme_stylebox_override("normal", _style_box(Color("4b351d"), Color("f0c85a"), 2, 5))
		heading.pressed.connect(_on_direct_player_pressed)
	else:
		heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if opponent:
		outer.add_child(_hud_row(heading, 760.0))
		outer.add_child(_depth_row(_build_hand_row(table, player_id), OPPONENT_HAND_DEPTH_SCALE))
		outer.add_child(_field_spacer())
		outer.add_child(_field_spacer())
	else:
		outer.add_child(_field_spacer())
		outer.add_child(_field_spacer())
		outer.add_child(_build_hand_row(table, player_id))
		outer.add_child(_hud_row(heading, 930.0))
	return panel


func _field_spacer() -> Control:
	var spacer := Control.new()
	spacer.custom_minimum_size.y = FIELD_ROW_HEIGHT
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return spacer


func _hud_row(heading: Button, width: float) -> Control:
	var center := CenterContainer.new()
	center.custom_minimum_size.y = PLAYER_HUD_HEIGHT
	heading.custom_minimum_size = Vector2(width, PLAYER_HUD_HEIGHT)
	center.add_child(heading)
	return center


func _territory_colors(table: Dictionary, player_id: int, opponent: bool) -> Array:
	var zone: Dictionary = table["zones"]["terrain:%d" % player_id]
	if zone["count"] <= 0:
		return [Color("17211fd9") if opponent else Color("1b2925d9"), Color("8f7950")]
	var identity: Dictionary = zone["cards"][0].get("terrain_identity", {})
	var components: Array = identity.get("components", [])
	var base := Color("23372b")
	if "R03" in components:
		base = Color("43241f")
	elif "R02" in components:
		base = Color("1e3441")
	elif "R01" in components:
		base = Color("253d28")
	if components.size() > 1:
		base = base.lightened(0.08)
	base.a = 0.84
	var border := base.lightened(0.32)
	border.a = 1.0
	return [base, border]


func _build_pile_row(table: Dictionary, player_id: int) -> Control:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size.y = 22
	row.add_theme_constant_override("separation", 14)
	for zone_info in [["deck", "BARAJA"], ["graveyard", "CEMENTERIO"], ["attachments", "EQUIPOS"], ["fusion_materials", "MATERIALES"]]:
		var zone_id := "%s:%d" % [zone_info[0], player_id]
		var pile := PanelContainer.new()
		pile.set_meta("board_role", "pile_zone")
		pile.custom_minimum_size = Vector2(104, 20)
		pile.add_theme_stylebox_override("panel", _style_box(Color("0a1217c8"), Color("52656b"), 1, 8))
		var label := Label.new()
		label.text = "%s  %d" % [zone_info[1], table["zones"][zone_id]["count"]]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 10)
		pile.add_child(label)
		row.add_child(pile)
	return row


func _build_field_row(table: Dictionary, player_id: int, kind: String, opponent: bool) -> Control:
	var row := Control.new()
	row.name = ("Opponent" if opponent else "Player") + ("SupportRow" if kind == "support" else "CreatureRow")
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.custom_minimum_size.y = FIELD_ROW_HEIGHT
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zone: Dictionary = table["zones"]["%s:%d" % [kind, player_id]]
	var capacity: int = zone["definition"]["capacity"]
	var envelope_size := FIELD_ENVELOPE_SIZE
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
		var left := 0.0 # La posición final sale exclusivamente de FieldTemplateLayer.
		if card == null:
			var empty := CreatureDropSlot.new()
			empty.name = "CreatureSlot" if kind == "creatures" else "SupportSlot"
			empty.set_meta("board_role", "creature_slot" if kind == "creatures" else "support_slot")
			empty.set_anchors_preset(Control.PRESET_CENTER_TOP)
			var slot_size := FIELD_ATTACK_SIZE
			empty.offset_left = left + (envelope_size.x - slot_size.x) * 0.5
			empty.offset_right = empty.offset_left + slot_size.x
			empty.offset_top = (FIELD_ENVELOPE_SIZE.y - slot_size.y) * 0.5
			empty.offset_bottom = empty.offset_top + slot_size.y
			var direct_attack := player_id != _viewer_id and kind == "creatures" and _selected_direct_attack_available()
			var creature_destination: bool = player_id == _viewer_id and kind == "creatures" and _creature_interaction.source_id == _selected_card_id and slot_index in _creature_interaction.legal_destinations
			var direct_destination: bool = (creature_destination if kind == "creatures" and _creature_interaction.phase != TableInteractionState.Phase.IDLE else (player_id == _viewer_id and _selected_card_can_enter(kind))) or direct_attack
			var destination_text := "ATAQUE DIRECTO" if direct_attack else ("JUGAR AQUÍ" if direct_destination else "")
			empty.text = ("A" if kind == "support" else "C") + "%d%s" % [slot_index + 1, "\n" + destination_text if not destination_text.is_empty() else ""]
			empty.tooltip_text = "Selecciona una carta y después esta casilla."
			empty.add_theme_font_size_override("font_size", 10)
			empty.add_theme_color_override("font_color", Color("f2d98b") if direct_destination else Color("718781"))
			empty.add_theme_stylebox_override("normal", _style_box(Color("263b31b8") if direct_destination else Color("09131530"), Color("e2c977") if direct_destination else Color("77908780"), 2 if direct_destination else 1, 5, true))
			empty.add_theme_stylebox_override("hover", _style_box(Color("294139"), Color("e2c977"), 2, 5))
			empty.pressed.connect(_on_empty_slot_pressed.bind(player_id, kind, slot_index))
			empty.configure_drop(player_id, slot_index, _legal_creature_source_ids() if player_id == _viewer_id and kind == "creatures" else [])
			empty.creature_dropped.connect(_on_creature_dropped)
			row.add_child(empty)
			empty.self_modulate = Color.TRANSPARENT
			var guide = _projected_piece(empty.text.get_slice("\n", 0), destination_text, Color("263b31"), Color("e2c977") if direct_destination else Color("779087"), false, false, false, direct_destination)
			empty.add_child(guide)
			guide.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		else:
			var holder := Control.new()
			holder.name = "CreatureSlot" if kind == "creatures" else "SupportSlot"
			holder.set_meta("board_role", "creature_slot" if kind == "creatures" else "support_slot")
			holder.set_anchors_preset(Control.PRESET_CENTER_TOP)
			holder.offset_left = left
			holder.offset_right = left + envelope_size.x
			holder.offset_top = 0
			holder.offset_bottom = envelope_size.y
			var tile: Button
			if card is Dictionary and card.get("hidden", false):
				var hidden_targetable := _hidden_slot_attack_available(player_id, card["engine_slot"])
				tile = CardTile.new()
				tile.setup("hidden-slot-%d-%d" % [player_id, card["engine_slot"]], "CARTA OCULTA", "GUARDIA", hidden_targetable, "", "", "guard", false, "opponent_field" if opponent else "field")
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
			if tile is CardTile:
				var visual_title: String = tile.tooltip_text.get_slice("\n", 0)
				var visual_detail: String = tile.tooltip_text.get_slice("\n", 1)
				var card_color: Color = tile.call("_card_color")
				var visual = _projected_piece(visual_title, visual_detail, card_color, Color("ffe58a") if tile.get("_selected") or tile.get("_targeted") else Color("c3a85d"), true, not tile.face_up, tile.card_posture == "guard", tile.get("_selected") or tile.get("_targeted"))
				holder.add_child(visual)
				visual.set_anchors_preset(Control.PRESET_CENTER)
				visual.offset_left = -tile_size.x * 0.5
				visual.offset_right = tile_size.x * 0.5
				visual.offset_top = -tile_size.y * 0.5
				visual.offset_bottom = tile_size.y * 0.5
				tile.modulate = Color.TRANSPARENT
			if kind == "creatures" and card is Dictionary and not card.get("hidden", false):
				var equipment_cards := _equipment_cards_for(table, player_id, card["instance"]["id"])
				if not equipment_cards.is_empty():
					holder.add_child(_build_equipment_strip(equipment_cards, card["instance"]["id"]))
			row.add_child(holder)
	_add_field_side_zones(row, table, player_id, kind, opponent)
	return row


func _layout_template_field() -> void:
	if _field_layer == null or _field_layer.get_child_count() != 4:
		return
	for band_index in range(4):
		var row: Control = _field_layer.get_child(band_index)
		for index in range(7):
			var piece: Control = row.get_child(index)
			var visual: Control = null
			for child in piece.get_children():
				if child is ProjectedFieldPiece:
					visual = child
					break
			if visual == null:
				continue
			var quad: PackedVector2Array
			if index < 5:
				quad = _field_layer.slot_corners(band_index, index, visual.guard)
			else:
				quad = _field_layer.side_corners(band_index, index == 6)
			var center := (quad[0] + quad[1] + quad[2] + quad[3]) * 0.25
			piece.set_anchors_preset(Control.PRESET_TOP_LEFT)
			piece.position = center - piece.size * 0.5
			var local_quad := PackedVector2Array()
			for corner in quad:
				local_quad.append(corner - piece.position - visual.position)
			visual.template_corners = local_quad
			visual.queue_redraw()
			if piece.has_method("set_projected_hit_polygon"):
				piece.call("set_projected_hit_polygon", local_quad)
			for child in piece.get_children():
				if child is CardTile:
					child.set_projected_hit_polygon(local_quad)


func _depth_row(row: Control, depth_scale: float) -> Control:
	var wrapper := Control.new()
	wrapper.custom_minimum_size.y = row.custom_minimum_size.y
	wrapper.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrapper.add_child(row)
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_apply_depth_scale(row, depth_scale)
	return wrapper


func _apply_depth_scale(control: Control, depth_scale: float) -> void:
	control.scale = Vector2(depth_scale, depth_scale)
	control.resized.connect(func() -> void:
		control.pivot_offset = control.size * 0.5
	)


func _add_field_side_zones(
	row: Control, table: Dictionary, player_id: int, kind: String, opponent: bool
) -> void:
	var side_size := SIDE_ZONE_SIZE
	var left_x := 0.0
	var right_x := 0.0
	if kind == "support":
		var materials: int = table["zones"]["fusion_materials:%d" % player_id]["count"]
		_add_side_pile(row, "FUSIÓN", materials, left_x, side_size, opponent)
		var deck: int = table["zones"]["deck:%d" % player_id]["count"]
		_add_side_pile(row, "BARAJA", deck, right_x, side_size, opponent)
	else:
		_add_terrain_side(row, table, player_id, opponent, left_x, side_size)
		var graveyard: int = table["zones"]["graveyard:%d" % player_id]["count"]
		_add_side_pile(row, "CEMENTERIO", graveyard, right_x, side_size, opponent)


func _add_side_pile(row: Control, title: String, count: int, x: float, side_size: Vector2, opponent: bool) -> void:
	var pile := ProjectedHitButton.new()
	pile.set_meta("board_role", "pile_zone")
	pile.set_anchors_preset(Control.PRESET_CENTER_TOP)
	pile.offset_left = x
	pile.offset_right = x + side_size.x
	pile.offset_top = 1
	pile.offset_bottom = 1 + side_size.y
	pile.text = "%s\n%d" % [title, count]
	pile.tooltip_text = "%s: %d cartas" % [title.capitalize(), count]
	pile.disabled = true
	pile.add_theme_font_size_override("font_size", 9)
	pile.add_theme_color_override("font_disabled_color", Color("cbd5d2"))
	pile.add_theme_stylebox_override("disabled", _style_box(Color("121a20c8"), Color("718087"), 2, 5, true))
	row.add_child(pile)
	pile.self_modulate = Color.TRANSPARENT
	var visual = _projected_piece(title, str(count), Color("19242b"), Color("718087"), true, false, false, false, true)
	pile.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _add_terrain_side(row: Control, table: Dictionary, player_id: int, opponent: bool, x: float, side_size: Vector2) -> void:
	var zone: Dictionary = table["zones"]["terrain:%d" % player_id]
	var destination := player_id == _viewer_id and _has_selected_action_type("play_terrain")
	var terrain := ProjectedHitButton.new()
	terrain.name = "TerrainLane"
	terrain.set_meta("board_role", "terrain_lane")
	terrain.set_anchors_preset(Control.PRESET_CENTER_TOP)
	terrain.offset_left = x
	terrain.offset_right = x + side_size.x
	terrain.offset_top = 1
	terrain.offset_bottom = 1 + side_size.y
	var terrain_name := "VACÍO"
	if zone["count"] > 0:
		terrain_name = zone["cards"][0].get("terrain_identity", {}).get("display_name", "ACTIVO")
	terrain.text = "TERRITORIO\n%s" % terrain_name
	terrain.tooltip_text = "Territorio de %s" % PLAYER_NAMES[player_id]
	terrain.add_theme_font_size_override("font_size", 9)
	terrain.add_theme_color_override("font_color", Color("f5df91") if destination else Color("b9c9bd"))
	terrain.add_theme_stylebox_override("normal", _style_box(Color("33412bc8") if destination else Color("17251fc8"), Color("e2c977") if destination else Color("66806c"), 3 if destination else 2, 5, true))
	terrain.add_theme_stylebox_override("hover", _style_box(Color("3c4b32"), Color("f2d98b"), 3, 5))
	terrain.pressed.connect(_on_terrain_pressed.bind(player_id))
	row.add_child(terrain)
	terrain.self_modulate = Color.TRANSPARENT
	var visual = _projected_piece("TERR.", terrain_name, Color("2d3c2a"), Color("e2c977") if destination else Color("66806c"), zone["count"] > 0, false, false, destination, true)
	terrain.add_child(visual)
	visual.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _projected_piece(
	caption: String, detail: String, face_color: Color, edge_color: Color,
	occupied: bool, face_down: bool = false, guard: bool = false,
	highlighted: bool = false, auxiliary: bool = false
) -> Control:
	var visual = ProjectedFieldPiece.new()
	visual.configure(caption, detail, face_color, edge_color, occupied, face_down, guard, highlighted, auxiliary)
	return visual


func _equipment_cards_for(table: Dictionary, player_id: int, carrier_id: String) -> Array:
	var cards: Array = []
	for card in table["zones"]["attachments:%d" % player_id]["cards"]:
		if card["instance"]["metadata"].get("linked_to", "") == carrier_id:
			cards.append(card)
	return cards


func _build_equipment_strip(equipment_cards: Array, carrier_id: String) -> Control:
	var strip := HBoxContainer.new()
	strip.name = "EquipmentStrip"
	strip.set_meta("board_role", "equipment_strip")
	strip.set_meta("carrier_id", carrier_id)
	strip.alignment = BoxContainer.ALIGNMENT_CENTER
	strip.add_theme_constant_override("separation", 2)
	strip.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	strip.offset_left = -50
	strip.offset_right = 50
	strip.offset_top = -20
	strip.offset_bottom = 0
	for index in range(equipment_cards.size()):
		var card: Dictionary = equipment_cards[index]
		var instance_id: String = card["instance"]["id"]
		var display_name: String = card["definition"]["attributes"].get("display_name", "Equipo")
		var chip := Button.new()
		chip.name = "EquipmentChip"
		chip.set_meta("board_role", "equipment_chip")
		chip.set_meta("carrier_id", carrier_id)
		chip.set_meta("equipment_instance_id", instance_id)
		chip.text = "⚒ %s" % _short_equipment_name(display_name) if equipment_cards.size() == 1 else "⚒%d" % (index + 1)
		chip.tooltip_text = "Equipo vinculado: %s\nPulsa para inspeccionarlo." % display_name
		chip.custom_minimum_size = Vector2(28, 18)
		chip.add_theme_font_size_override("font_size", 9)
		chip.add_theme_color_override("font_color", Color("fff0b0") if instance_id == _selected_card_id else Color("e2ca81"))
		chip.add_theme_stylebox_override("normal", _style_box(Color("182026e8"), Color("ad9558"), 1, 5))
		chip.add_theme_stylebox_override("hover", _style_box(Color("2a3032f2"), Color("f1cf70"), 2, 5))
		chip.pressed.connect(_select_card.bind(instance_id))
		strip.add_child(chip)
	return strip


func _short_equipment_name(display_name: String) -> String:
	if display_name.length() <= 9:
		return display_name
	return display_name.substr(0, 8) + "…"


func _build_terrain_lane(table: Dictionary, player_id: int, opponent: bool) -> Control:
	var lane := PanelContainer.new()
	lane.name = "TerrainLane"
	lane.set_meta("board_role", "terrain_lane")
	lane.custom_minimum_size.y = 46
	var direct_destination := player_id == _viewer_id and _has_selected_action_type("play_terrain")
	lane.add_theme_stylebox_override("panel", _style_box(Color("3c3c2488") if direct_destination else Color("0d18163d"), Color("e2c977") if direct_destination else Color("71896f70"), 2 if direct_destination else 1, 18, true))
	var zone: Dictionary = table["zones"]["terrain:%d" % player_id]
	if zone["count"] <= 0:
		var empty := Button.new()
		empty.text = ("TERRITORIO RIVAL" if opponent else "TU TERRITORIO") + ("  ·  JUGAR AQUÍ" if direct_destination else "  ·  VACÍO")
		empty.add_theme_color_override("font_color", Color("f2d98b") if direct_destination else Color("8fa095"))
		empty.flat = true
		empty.pressed.connect(_on_terrain_pressed.bind(player_id))
		lane.add_child(empty)
	else:
		var card: Dictionary = zone["cards"][0]
		var content := HBoxContainer.new()
		content.alignment = BoxContainer.ALIGNMENT_CENTER
		var tile := _tile_from_card(card, player_id, "terrain")
		content.add_child(tile)
		if player_id == _viewer_id and _has_selected_action_type("play_terrain"):
			var replace := Button.new()
			replace.text = "JUGAR AQUÍ"
			replace.pressed.connect(_on_terrain_pressed.bind(player_id))
			content.add_child(replace)
		lane.add_child(content)
	return lane


func _build_hand_row(table: Dictionary, player_id: int) -> Control:
	var zone: Dictionary = table["zones"]["hand:%d" % player_id]
	var scroll := Control.new()
	scroll.name = "HandFan"
	scroll.custom_minimum_size.y = HAND_ROW_HEIGHT
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var cards: Array = zone["cards"] if zone["identities_visible"] else range(zone["count"])
	var count := cards.size()
	var step := _hand_step(count)
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
		tile.offset_bottom = tile.offset_top + tile_size.y
		tile.rotation_degrees = 0
		tile.z_index = index
		scroll.add_child(tile)
	return scroll


func _hand_step(count: int) -> float:
	if count <= 5:
		return HAND_STEPS[0]
	if count <= 7:
		return HAND_STEPS[1]
	if count <= 9:
		return HAND_STEPS[2]
	return HAND_STEPS[3]


func _tile_from_card(card: Dictionary, player_id: int = -1, kind: String = "", visual_slot: int = -1) -> Button:
	var attributes: Dictionary = card["definition"]["attributes"]
	var title: String = attributes["display_name"]
	if card.has("fusion_identity"):
		title = card["fusion_identity"].get("display_name", title)
	var detail: Array = []
	if card.has("effective_stats"):
		detail.append("%d/%d" % [card["effective_stats"]["attack"], card["effective_stats"]["defense"]])
	var metadata: Dictionary = card["instance"]["metadata"]
	if metadata.has("position"):
		detail.append("ATQ" if metadata["position"] == "attack" else "GUARDIA")
	if not metadata.get("face_up", true):
		detail.append("oculta")
	var card_type: String = attributes.get("card_type", "")
	if card.has("fusion_identity"):
		card_type = "fusion"
	var display_mode := "hand" if kind == "hand" else ("terrain" if kind == "terrain" else ("opponent_field" if player_id >= 0 and player_id != _viewer_id else "field"))
	return _make_card_tile(
		card["instance"]["id"], title, " · ".join(detail), true, player_id, kind, visual_slot,
		card_type, attributes.get("element", ""), metadata.get("position", ""), metadata.get("face_up", true), display_mode,
		_card_face_data(card)
	)


func _preview_tile_from_card(card: Dictionary) -> Button:
	var attributes: Dictionary = card["definition"]["attributes"]
	var metadata: Dictionary = card["instance"]["metadata"]
	var title: String = card.get("fusion_identity", {}).get("display_name", attributes.get("display_name", "Carta"))
	var card_kind: String = "fusion" if card.has("fusion_identity") else attributes.get("card_type", "")
	var detail := ""
	if card.has("effective_stats"):
		detail = "ATQ %d  ·  DEF %d" % [card["effective_stats"]["attack"], card["effective_stats"]["defense"]]
	var tile = CardTile.new()
	tile.setup(card["instance"]["id"], title, detail, true, card_kind, attributes.get("element", ""), metadata.get("position", ""), metadata.get("face_up", true), "preview", _card_face_data(card))
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


func _card_face_data(card: Dictionary) -> Dictionary:
	var attributes: Dictionary = card["definition"]["attributes"]
	var identity: Dictionary = card.get("fusion_identity", attributes)
	var data := {
		"element_label": _element_name(String(identity.get("element", attributes.get("element", "")))),
		"effect_text": String(identity.get("effect_text", attributes.get("effect_text", ""))),
	}
	if attributes.get("card_type", "") == "creature" or card.has("fusion_identity"):
		data["cost"] = int(identity.get("cost", attributes.get("cost", 0)))
		var stats: Dictionary = card.get("effective_stats", identity)
		data["attack"] = int(stats.get("attack", 0))
		data["defense"] = int(stats.get("defense", 0))
	return data


func _make_card_tile(
	instance_id: String, title: String, detail: String, interactive: bool,
	player_id: int = -1, kind: String = "", visual_slot: int = -1,
	card_type: String = "", element: String = "", position: String = "",
	face_up: bool = true, display_mode: String = "field", face_data: Dictionary = {}
) -> Button:
	var tile = CardTile.new()
	tile.setup(instance_id, title, detail, interactive, card_type, element, position, face_up, display_mode, face_data)
	if kind == "hand" and player_id == _viewer_id and card_type == "creature":
		tile.set_creature_drag_enabled(not _legal_creature_actions(instance_id).is_empty())
		tile.creature_drag_started.connect(_on_creature_drag_started)
		tile.creature_drag_failed.connect(_on_creature_drag_failed)
	if kind == "hand" and player_id == _viewer_id and card_type == "item":
		var equip_targets := _equipment_targets_for_source(instance_id)
		tile.set_equipment_drag_enabled(not equip_targets.is_empty())
		tile.equipment_drag_started.connect(_on_equipment_drag_started)
		tile.equipment_drag_failed.connect(_on_equipment_drag_failed)
	if kind == "creatures" and player_id == _viewer_id:
		var partners := _fusion_partners(instance_id)
		tile.set_fusion_drag_enabled(not partners.is_empty())
		tile.set_fusion_drop_sources(partners)
		tile.fusion_drag_started.connect(_on_fusion_drag_started)
		tile.fusion_drag_failed.connect(_on_fusion_drag_failed)
		tile.fusion_dropped.connect(_on_fusion_dropped)
		var equipment_sources := _equipment_sources_for_target(instance_id)
		tile.set_equipment_drop_sources(equipment_sources)
		tile.equipment_dropped.connect(_on_equipment_dropped)
	tile.set_selected(not instance_id.is_empty() and instance_id == _selected_card_id)
	tile.set_targeted(not instance_id.is_empty() and _is_direct_target(instance_id, player_id, kind))
	if player_id >= 0 and not kind.is_empty():
		tile.card_selected.connect(_on_board_card_selected.bind(player_id, kind, visual_slot))
	else:
		tile.card_selected.connect(_select_card)
	tile.add_to_group("jcp_card_tiles")
	return tile


func _is_direct_target(instance_id: String, player_id: int, kind: String) -> bool:
	if _selected_card_id.is_empty() or instance_id == _selected_card_id or _engine == null:
		return false
	if _attack_targeting and kind == "creatures" and player_id != _viewer_id and _can_offer_attack_from_main():
		return true
	var location: Dictionary = _visible_card_locations.get(instance_id, {})
	for action in _legal_actions():
		var payload: Dictionary = action["payload"]
		if action["type"] == "fuse_creatures" and _selected_card_id in payload.get("material_instance_ids", []) and instance_id in payload.get("material_instance_ids", []):
			return true
		if payload.get("instance_id", "") != _selected_card_id and payload.get("attacker_id", "") != _selected_card_id:
			continue
		if action["type"] == "equip_item" and payload.get("target_instance_id", "") == instance_id:
			return true
		if action["type"] == "play_main_spell" and not location.is_empty() and payload.get("target_player_id", -1) == player_id and payload.get("target_slot", -2) == location.get("slot", -3):
			return true
		if _attack_targeting and action["type"] == "attack" and kind == "creatures" and player_id != _viewer_id and not location.is_empty() and payload.get("target_slot", -2) == location.get("slot", -3):
			return true
	return false


func _equipment_targets_for_source(instance_id: String) -> Array:
	var targets: Array = []
	for action in _legal_actions():
		if action["type"] != "equip_item" or action["payload"].get("instance_id", "") != instance_id:
			continue
		var target_id: String = action["payload"].get("target_instance_id", "")
		if not target_id.is_empty() and target_id not in targets:
			targets.append(target_id)
	return targets


func _equipment_sources_for_target(target_id: String) -> Array:
	var sources: Array = []
	for action in _legal_actions():
		if action["type"] != "equip_item" or action["payload"].get("target_instance_id", "") != target_id:
			continue
		var source_id: String = action["payload"].get("instance_id", "")
		if not source_id.is_empty() and source_id not in sources:
			sources.append(source_id)
	return sources


func _equipment_action(source_id: String, target_id: String) -> Dictionary:
	for action in _legal_actions():
		if action["type"] == "equip_item" and action["payload"].get("instance_id", "") == source_id and action["payload"].get("target_instance_id", "") == target_id:
			return action
	return {}


func _fusion_partners(instance_id: String) -> Array:
	var partners: Array = []
	if _engine == null or _privacy_hidden or instance_id.is_empty():
		return partners
	for action in _legal_actions():
		if action["type"] != "fuse_creatures":
			continue
		var materials: Array = action["payload"].get("material_instance_ids", [])
		if instance_id in materials:
			for other_id in materials:
				if other_id != instance_id and other_id not in partners:
					partners.append(other_id)
	return partners


func _zone_description(table: Dictionary, player_id: int, kind: String) -> String:
	var zone: Dictionary = table["zones"]["%s:%d" % [kind, player_id]]
	var count: int = zone["count"]
	if count <= 0:
		return "—"
	if kind == "deck":
		return "%d cartas" % count
	if kind == "hand" and not zone["identities_visible"]:
		return "%d cartas ocultas" % count
	var cards: Array = zone["cards"]
	if cards.is_empty():
		return "%d cartas ocultas" % count
	var descriptions: Array = []
	for card in cards:
		descriptions.append(_card_description(card))
	return " · ".join(descriptions)


func _card_description(card: Dictionary) -> String:
	var instance: Dictionary = card["instance"]
	var attributes: Dictionary = card["definition"]["attributes"]
	var name: String = attributes["display_name"]
	if card.has("fusion_identity"):
		name = card["fusion_identity"].get("display_name", name)
	var details: Array = []
	if card.has("effective_stats"):
		details.append("%d/%d" % [card["effective_stats"]["attack"], card["effective_stats"]["defense"]])
	if instance["metadata"].has("position"):
		details.append("ATQ" if instance["metadata"]["position"] == "attack" else "GUARDIA")
	if not instance["metadata"].get("face_up", true):
		details.append("boca abajo")
	return "%s%s" % [name, " [%s]" % ", ".join(details) if not details.is_empty() else ""]


func _visible_card_index(table: Dictionary) -> Dictionary:
	var result := {}
	for zone_id in table["zones"]:
		for card in table["zones"][zone_id]["cards"]:
			result[card["instance"]["id"]] = _card_description(card)
	return result


func _visible_cards_by_id(table: Dictionary) -> Dictionary:
	var result := {}
	for zone_id in table["zones"]:
		for card in table["zones"][zone_id]["cards"]:
			result[card["instance"]["id"]] = card
	return result


func _card_detail_text(card: Dictionary) -> String:
	if card.is_empty():
		return ""
	var attributes: Dictionary = card["definition"]["attributes"]
	var title: String = attributes.get("display_name", "Carta")
	var effect_text: String = attributes.get("effect_text", "")
	var identity_lines: Array = []
	if card.has("fusion_identity"):
		var fusion: Dictionary = card["fusion_identity"]
		title = fusion.get("display_name", title)
		effect_text = fusion.get("effect_text", effect_text)
		identity_lines.append("Fusión %s" % fusion.get("id", ""))
	else:
		identity_lines.append("%s · coste %d" % [_card_type_name(attributes.get("card_type", "")), int(attributes.get("cost", 0))])
	var stat_line := ""
	if attributes.get("card_type", "") == "creature" or card.has("fusion_identity"):
		var face_values := _card_face_data(card)
		stat_line = "ATQ %d · DEF %d" % [face_values["attack"], face_values["defense"]]
	var traits: Array = []
	var element: String = attributes.get("element", "")
	if not element.is_empty():
		traits.append(_element_name(element))
	for family in attributes.get("families", []):
		traits.append(String(family).capitalize())
	var lines: Array = ["[b]%s[/b]" % title, " · ".join(identity_lines)]
	if not stat_line.is_empty():
		lines.append(stat_line)
	if not traits.is_empty():
		lines.append(" · ".join(traits))
	if not effect_text.is_empty():
		lines.append(effect_text)
	return "\n".join(lines)


func _card_type_name(card_type: String) -> String:
	return {
		"creature": "Criatura", "spell": "Magia", "trap": "Trampa",
		"item": "Objeto", "terrain": "Terreno",
	}.get(card_type, card_type.capitalize())


func _element_name(element: String) -> String:
	return {
		"nature": "Naturaleza", "water": "Agua", "fire": "Fuego", "neutral": "Neutral",
		"light": "Luz", "darkness": "Oscuridad", "earth": "Tierra", "air": "Aire",
	}.get(element, element.capitalize())


func _update_result_panel(game: Dictionary) -> void:
	var finished: bool = _engine.lifecycle_name() == "FINISHED"
	_result_panel.visible = finished and not _privacy_hidden
	if not finished:
		_result_label.text = ""
		return
	var winners: Array = game.get("winner_ids", [])
	var result_text := "EMPATE" if winners.size() != 1 else "%s GANA LA PARTIDA" % PLAYER_NAMES[int(winners[0])]
	_result_label.text = "%s\nMotivo: %s" % [result_text, _finished_reason_name(game.get("finished_reason", ""))]


func _finished_reason_name(reason: String) -> String:
	return {
		"concession": "rendición", "life_zero": "vida agotada", "deck_empty": "baraja agotada al intentar robar",
	}.get(reason, reason.replace("_", " ").to_lower())


func _visible_card_location_index(table: Dictionary) -> Dictionary:
	var result := {}
	for zone_id in table["zones"]:
		var parts: PackedStringArray = zone_id.split(":")
		if parts.size() != 2:
			continue
		for slot in table["zones"][zone_id]["slots"]:
			if slot["card"] != null:
				result[slot["card"]["instance"]["id"]] = {"kind": parts[0], "player_id": int(parts[1]), "slot": slot["index"]}
	return result


func _action_mentions_card(action: Dictionary, instance_id: String) -> bool:
	if instance_id.is_empty():
		return false
	for value in action["payload"].values():
		if (value is String and value == instance_id) or (value is Array and instance_id in value):
			return true
	var location: Dictionary = _visible_card_locations.get(instance_id, {})
	if location.is_empty():
		return false
	var payload: Dictionary = action["payload"]
	if location["kind"] == "support" and location["player_id"] == action["actor_id"] and payload.get("support_slot", -1) == location["slot"]:
		return true
	if location["kind"] == "creatures" and location["player_id"] != action["actor_id"] and payload.get("target_slot", -1) == location["slot"]:
		return true
	return false


func _action_family_key(action: Dictionary) -> String:
	var payload: Dictionary = action["payload"].duplicate(true)
	for choice_key in ["target_instance_id", "target_player_id", "target_slot", "peek_support_slot", "position", "choice", "guardian_id", "target_creature_id"]:
		payload.erase(choice_key)
	return "%s|%s" % [action["type"], JSON.stringify(payload)]


func _group_action_entries(entries: Array) -> Array:
	var groups: Array = []
	var index_by_key: Dictionary = {}
	for entry in entries:
		var key := _action_family_key(entry["action"])
		if not index_by_key.has(key):
			index_by_key[key] = groups.size()
			groups.append({"key": key, "actions": []})
		groups[index_by_key[key]]["actions"].append(entry["action"])
	return groups


func _legal_actions() -> Array:
	if _engine == null or not _engine.is_ready():
		return []
	var version: int = _engine.state_version()
	if _cached_legal_version != version or _cached_legal_viewer != _viewer_id:
		_cached_legal_actions = _engine.get_legal_actions(_viewer_id)
		_cached_legal_version = version
		_cached_legal_viewer = _viewer_id
	return _cached_legal_actions


func _legal_creature_actions(instance_id: String) -> Array:
	var result: Array = []
	if _engine == null or _privacy_hidden:
		return result
	var modes := {}
	for action in _legal_actions():
		if action["type"] in ["summon_creature", "set_creature"] and action["payload"].get("instance_id", "") == instance_id:
			# Una habilidad de entrada puede ofrecer varios comandos de Ataque con
			# objetivos distintos. Su elección pertenece a otra pasada de UX.
			if modes.has(action["type"]):
				return []
			modes[action["type"]] = true
			result.append(action)
	return result


func _legal_creature_source_ids() -> Array:
	var result: Array = []
	if _engine == null or _privacy_hidden:
		return result
	for action in _legal_actions():
		if action["type"] in ["summon_creature", "set_creature"]:
			var instance_id: String = action["payload"].get("instance_id", "")
			if not instance_id.is_empty() and instance_id not in result and not _legal_creature_actions(instance_id).is_empty():
				result.append(instance_id)
	return result


func _field_slot(kind: String, visual_slot: int) -> Control:
	if _field_layer == null or visual_slot < 0 or visual_slot >= 5 or _field_layer.get_child_count() != 4:
		return null
	var row_index := 2 if kind == "creatures" else 3
	return _field_layer.get_child(row_index).get_child(visual_slot)


func _legal_empty_creature_slots() -> Array:
	var result: Array = []
	for slot_index in range(5):
		if _field_slot("creatures", slot_index) is CreatureDropSlot:
			result.append(slot_index)
	return result


func _select_card(instance_id: String, refresh_view: bool = true) -> void:
	_selected_card_id = instance_id
	_attack_targeting = false
	_choice_actions = []
	_choice_stage = ""
	_pending_visual_placement = {}
	var location: Dictionary = _visible_card_locations.get(instance_id, {})
	var game: Dictionary = _engine.get_player_state(_viewer_id)["game"] if _engine != null else {}
	var creature_actions := _legal_creature_actions(instance_id)
	if location.get("kind", "") == "hand" and location.get("player_id", -1) == _viewer_id and not creature_actions.is_empty():
		_creature_interaction.begin_source(instance_id, creature_actions)
		_creature_interaction.set_destinations(_legal_empty_creature_slots())
	else:
		_creature_interaction.reset()
	if location.get("kind", "") == "creatures" and location.get("player_id", -1) == _viewer_id:
		if game.get("turn_number", 0) == 1 and game.get("active_player", -1) == _viewer_id:
			_status_message = "Primer turno: todavía no puedes atacar. Las acciones de la criatura aparecen junto a ella; también puedes Fusionar con otra compatible."
		elif game.get("phase", "") == "COMBAT":
			_status_message = "Elige Atacar junto a la criatura y luego un objetivo iluminado."
		else:
			_status_message = "Elige Atacar o Cambiar postura junto a la criatura. Para Fusionar, pulsa o arrastra hacia otra propia compatible."
	else:
		_status_message = "Carta seleccionada: pulsa una casilla amarilla o una carta objetivo válida."
	if refresh_view:
		_refresh()
	else:
		_update_live_drag_highlights()


func _own_creature_selected() -> bool:
	var location: Dictionary = _visible_card_locations.get(_selected_card_id, {})
	return location.get("kind", "") == "creatures" and location.get("player_id", -1) == _viewer_id


func _render_creature_action_popup(actions: Array, visible_cards: Dictionary) -> void:
	if not _own_creature_selected() or _attack_targeting or _privacy_hidden:
		return
	var card: Dictionary = visible_cards.get(_selected_card_id, {})
	if card.is_empty():
		return
	var attack_available := _can_offer_attack_from_main()
	var posture_action: Dictionary = {}
	var ability_actions: Array = []
	for action in actions:
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == _selected_card_id:
			attack_available = true
		if action["type"] == "change_position" and action["payload"].get("instance_id", "") == _selected_card_id:
			posture_action = action
		if action["type"] in ["activate_creature_ability", "activate_fusion_ability"] and action["payload"].get("source_instance_id", "") == _selected_card_id:
			ability_actions.append(action)
	var attack_button := Button.new()
	attack_button.name = "CreatureAttackAction"
	attack_button.text = "Atacar"
	attack_button.disabled = not attack_available
	attack_button.tooltip_text = "Elige después una criatura rival o la Vida rival." if attack_available else "No puede atacar ahora: comprueba fase, Guardia, primer turno o ataque ya usado."
	attack_button.pressed.connect(_begin_creature_attack)
	_creature_action_buttons.add_child(attack_button)
	var current_position: String = card["instance"]["metadata"].get("position", "attack")
	var posture_button := Button.new()
	posture_button.name = "CreaturePostureAction"
	posture_button.text = "Pasar a Ataque" if current_position == "guard" else "Pasar a Guardia"
	posture_button.disabled = posture_action.is_empty()
	posture_button.tooltip_text = "Cambio de postura permitido por UCE." if not posture_action.is_empty() else "No disponible ahora: solo en fase principal propia, desde un turno posterior, una vez por turno y no después de atacar."
	if not posture_action.is_empty():
		posture_button.pressed.connect(_perform_action.bind(posture_action))
	_creature_action_buttons.add_child(posture_button)
	if not ability_actions.is_empty():
		var ability_button := Button.new()
		ability_button.name = "CreatureAbilityAction"
		ability_button.text = "Habilidad"
		ability_button.tooltip_text = ability_actions[0].get("label", "Activar habilidad") if ability_actions.size() == 1 else "Elige el objetivo de la habilidad."
		ability_button.set_meta("jcp_ability_actions", ability_actions.duplicate(true))
		if ability_actions.size() == 1:
			ability_button.pressed.connect(_perform_action.bind(ability_actions[0]))
		else:
			ability_button.pressed.connect(_open_action_choices.bind(ability_actions))
		_creature_action_buttons.add_child(ability_button)
	_creature_action_popup.visible = true
	call_deferred("_place_creature_action_popup")


func _place_creature_action_popup() -> void:
	if not _creature_action_popup.visible or not _own_creature_selected() or _field_layer == null:
		return
	var tile: CardTile = null
	for row in _field_layer.get_children():
		for holder in row.get_children():
			for child in holder.get_children():
				if child is CardTile and child.instance_id == _selected_card_id:
					tile = child
					break
	if tile == null:
		_creature_action_popup.visible = false
		return
	var card_rect := tile.get_global_rect()
	var popup_size := _creature_action_popup.get_combined_minimum_size()
	_creature_action_popup.size = popup_size
	var root_origin := get_global_rect().position
	var desired := Vector2(card_rect.get_center().x - popup_size.x * 0.5, card_rect.end.y + 8.0) - root_origin
	var board_rect := _board_surface.get_global_rect()
	var board_left: float = board_rect.position.x - root_origin.x
	var board_right: float = board_rect.end.x - root_origin.x
	desired.x = clampf(desired.x, board_left + 8.0, board_right - popup_size.x - 8.0)
	if desired.y + popup_size.y > size.y - 8.0:
		desired.y = card_rect.position.y - root_origin.y - popup_size.y - 8.0
	_creature_action_popup.position = desired


func _begin_creature_attack() -> void:
	if not _own_creature_selected():
		return
	var available := _can_offer_attack_from_main()
	for action in _legal_actions():
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == _selected_card_id:
			available = true
	if not available:
		return
	_attack_targeting = true
	_status_message = "Elige una criatura rival iluminada o la Vida rival si el ataque directo es legal."
	_refresh()


func _update_live_drag_highlights() -> void:
	for slot_index in range(5):
		var slot := _field_slot("creatures", slot_index)
		if slot is CreatureDropSlot:
			for child in slot.get_children():
				if child is ProjectedFieldPiece:
					child.highlighted = slot_index in _creature_interaction.legal_destinations
					child.detail = "JUGAR AQUÍ" if child.highlighted else ""
					child.queue_redraw()
	if _field_layer == null or _selected_card_id.is_empty():
		return
	var partners := _fusion_partners(_selected_card_id)
	for row in _field_layer.get_children():
		for holder in row.get_children():
			var target_id := ""
			var visual: ProjectedFieldPiece = null
			for child in holder.get_children():
				if child is CardTile:
					target_id = child.instance_id
				elif child is ProjectedFieldPiece:
					visual = child
			if visual != null and target_id in partners:
				visual.highlighted = true
				visual.queue_redraw()


func _selection_instruction(actions: Array, visible_index: Dictionary, visible_cards: Dictionary = {}) -> String:
	if _selected_card_id.is_empty():
		return _status_message if not _status_message.is_empty() else "Elige una carta para ver sus destinos."
	var name: String = visible_index.get(_selected_card_id, "Carta")
	var selected_card: Dictionary = visible_cards.get(_selected_card_id, {})
	var definition_id: String = selected_card.get("definition", {}).get("id", "")
	var action_types: Array = []
	for action in actions:
		if _action_mentions_card(action, _selected_card_id) and action["type"] not in action_types:
			action_types.append(action["type"])
	if "equip_item" in action_types:
		return "%s\nEQUIPO: pulsa una criatura propia iluminada. Se vincula y se activa al instante; NO lo coloques en Apoyo." % name
	if "play_main_spell" in action_types:
		return "%s\nMAGIA INSTANTÁNEA: elige el objetivo iluminado. Se resuelve y después va al Cementerio." % name
	if "play_persistent" in action_types:
		match definition_id:
			"G04":
				return "%s\nElige Apoyo. Después da +1 DEF automáticamente a TODAS tus criaturas en Guardia; no se entrega ni se activa sobre una sola." % name
			"G05":
				return "%s\nElige Apoyo. Queda activa: +1 ATQ cuando una criatura propia pase de Guardia a Ataque (primera vez de cada turno)." % name
			"E04":
				return "%s\nARTEFACTO: va a Apoyo. No da DEF: permite trasladar un equipo YA vinculado entre dos criaturas compatibles." % name
		return "%s\nMAGIA PERSISTENTE: elige Apoyo. Queda boca arriba y se activa según el texto de la carta." % name
	if "set_support" in action_types:
		return "%s\nTRAMPA O RESPUESTA: elige una casilla de Apoyo. Queda boca abajo; colocarla no activa su efecto. Se usa después, cuando sea legal responder." % name
	if "play_terrain" in action_types:
		var table: Dictionary = _engine.get_player_state(_viewer_id)["game"]["card_table"] if _engine != null else {}
		var terrain_zone: Dictionary = table.get("zones", {}).get("terrain:%d" % _viewer_id, {})
		if terrain_zone.get("count", 0) > 0:
			var current: Dictionary = terrain_zone["cards"][0]
			var current_identity: Dictionary = current.get("terrain_identity", {})
			var incoming_id: String = selected_card.get("definition", {}).get("id", "")
			var incoming_name: String = selected_card.get("definition", {}).get("attributes", {}).get("display_name", "Terreno nuevo")
			var preview_key := "%s|%s" % [current_identity.get("id", ""), incoming_id]
			if TERRAIN_PREVIEWS.has(preview_key):
				return "%s\nTERRENO: pulsa TERRITORIO. Resultado público: %s + %s → %s." % [name, current_identity.get("display_name", "Terreno actual"), incoming_name, TERRAIN_PREVIEWS[preview_key]]
			return "%s\nTERRENO: pulsa TERRITORIO. %s sustituirá a %s y el anterior irá al Cementerio." % [name, incoming_name, current_identity.get("display_name", "Terreno actual")]
		return "%s\nTERRENO: pulsa tu zona central de Territorio." % name
	if "summon_creature" in action_types or "set_creature" in action_types:
		return "%s\nCRIATURA: elige una casilla. Después decidirás ataque visible o guardia oculta." % name
	if "activate_creature_ability" in action_types or "activate_fusion_ability" in action_types:
		return "%s\nHABILIDAD: usa el botón contextual junto a la criatura. Si necesita objetivo, la elección aparecerá después." % name
	if "attack" in action_types:
		return "%s\nATACANTE: pulsa una criatura rival iluminada o la Vida rival si el ataque directo está permitido." % name
	var location: Dictionary = _visible_card_locations.get(_selected_card_id, {})
	if location.get("kind", "") == "support" and location.get("player_id", -1) == _viewer_id:
		match definition_id:
			"G04":
				return "%s\nACTIVA AUTOMÁTICAMENTE: +1 DEF a todas tus criaturas en Guardia. No se asigna ni necesita otro clic; sin criaturas en Guardia no verás aumento." % name
			"G05":
				return "%s\nACTIVA AUTOMÁTICAMENTE al pasar una criatura propia de Guardia a Ataque, una vez por turno. No requiere otro clic." % name
			"E04":
				return "%s\nSolo traslada un equipo ya vinculado a otra criatura compatible. Si no hay equipo vinculado, todavía no tiene uso." % name
	if location.get("kind", "") == "creatures" and location.get("player_id", -1) == _viewer_id:
		var game: Dictionary = _engine.get_public_state()["game"]
		if game.get("turn_number", 0) == 1 and game.get("active_player", -1) == _viewer_id:
			return "%s\nPRIMER TURNO: no puedes atacar. Las acciones aparecen junto a esta carta; FUSIÓN: pulsa otra criatura propia iluminada o arrastra esta sobre ella." % name
		if "fuse_creatures" in action_types:
			return "%s\nElige Atacar o Cambiar postura junto a la carta. FUSIÓN: pulsa otra criatura propia iluminada o arrastra esta sobre ella; confirma el resultado." % name
		var phase: String = game["phase"]
		if phase == "COMBAT":
			return "%s\nElige Atacar junto a la carta si está habilitado. Si no, comprueba Guardia, ataque ya usado o restricciones." % name
		return "%s\nAcciones junto a la carta: Atacar o Cambiar postura cuando sean legales. FUSIÓN: pulsa o arrastra hacia una criatura propia compatible." % name
	return "%s\nEsta carta no tiene ahora un destino directo legal. Consulta su ficha o cambia de fase." % name


func _open_action_choices(actions: Array) -> void:
	_choice_actions = actions.duplicate(true)
	_choice_stage = ""
	_refresh()


func _back_to_fusion_partner_selection() -> void:
	if _choice_actions.is_empty() or _choice_actions[0].get("type", "") != "fuse_creatures":
		return
	if _selected_card_id.is_empty() or _fusion_partners(_selected_card_id).is_empty():
		_cancel_pending_interaction("Fusión cancelada; los materiales ya no son válidos.")
		return
	_choice_actions = []
	_choice_stage = ""
	_status_message = "FUSIÓN 1/2 · primer material conservado. Elige otra criatura compatible o cancela."
	_refresh()


func _cancel_choices() -> void:
	_cancel_pending_interaction("Selección cancelada; no se ha comprometido ninguna acción.")


func _cancel_pending_interaction(message: String = "Selección cancelada.") -> void:
	_creature_interaction.reset()
	_selected_card_id = ""
	_attack_targeting = false
	_choice_actions = []
	_choice_stage = ""
	_pending_visual_placement = {}
	_status_message = message
	_refresh()


func _precommit_interaction_active() -> bool:
	if not _choice_actions.is_empty() or _attack_targeting or _creature_interaction.phase != TableInteractionState.Phase.IDLE or not _pending_visual_placement.is_empty():
		return true
	if _selected_card_id.is_empty():
		return false
	for action in _legal_actions():
		if action["type"] != "concede" and _action_mentions_card(action, _selected_card_id):
			return true
	return false


func _perform_choice(action: Dictionary) -> void:
	_choice_actions = []
	_choice_stage = ""
	_perform_action(action)


func _choice_position(action: Dictionary) -> String:
	if action["type"] == "summon_creature":
		return "attack"
	if action["type"] == "set_creature":
		return "guard"
	return str(action["payload"].get("position", "attack"))


func _choice_target_text(action: Dictionary, visible_index: Dictionary) -> String:
	var payload: Dictionary = action["payload"]
	var target_id: String = payload.get("target_instance_id", "")
	if not target_id.is_empty():
		var target_name: String = visible_index.get(target_id, "Criatura visible")
		var target_location: Dictionary = _visible_card_locations.get(target_id, {})
		if target_location.get("kind", "") == "creatures":
			return "%s · C%d" % [target_name, _visual_slot_for("creatures", int(target_location["player_id"]), target_id) + 1]
		return target_name
	if payload.has("target_slot"):
		return "Criatura rival · C%d" % (int(payload["target_slot"]) + 1)
	return "Sin objetivo adicional"


func _render_choice_buttons(visible_index: Dictionary) -> void:
	var first: Dictionary = _choice_actions[0]
	var is_fusion: bool = first["type"] == "fuse_creatures"
	var is_creature: bool = first["type"] in ["summon_creature", "set_creature"]
	if not is_fusion and not is_creature:
		_choice_overlay_title.text = "ELIGE UNA OPCIÓN"
		for action in _choice_actions:
			var legacy_button := Button.new()
			legacy_button.text = _describe_action(action, visible_index)
			legacy_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			legacy_button.custom_minimum_size.y = 48
			legacy_button.pressed.connect(_perform_choice.bind(action))
			_choice_overlay_list.add_child(legacy_button)
		return
	var result_name: String = str(first["label"]).get_slice(": ", 1)
	_choice_overlay_title.text = "¿FUSIONAR %s? · 0 ENERGÍA" % result_name if is_fusion else "¿CÓMO QUIERES JUGARLA?"
	if _choice_stage == "targets":
		_choice_overlay_title.text = "ELIGE OBJETIVO · %s" % result_name if is_fusion else "ELIGE OBJETIVO DEL EFECTO"
		for action in _choice_actions:
			var target_button := Button.new()
			target_button.text = _choice_target_text(action, visible_index)
			target_button.custom_minimum_size.y = 40
			target_button.pressed.connect(_perform_choice.bind(action))
			_choice_overlay_list.add_child(target_button)
		return
	var positions: Array = []
	for action in _choice_actions:
		var position := _choice_position(action)
		if position not in positions:
			positions.append(position)
	for position in positions:
		var mode_button := Button.new()
		mode_button.text = "ATAQUE · Visible" if position == "attack" else "GUARDIA · Oculta" if is_creature else "GUARDIA · Visible"
		mode_button.custom_minimum_size.y = 42
		mode_button.pressed.connect(_select_choice_position.bind(position))
		_choice_overlay_list.add_child(mode_button)


func _select_choice_position(position: String) -> void:
	var matching: Array = []
	for action in _choice_actions:
		if _choice_position(action) == position:
			matching.append(action)
	if matching.size() == 1:
		_perform_choice(matching[0])
	elif matching.size() > 1:
		_choice_actions = matching
		_choice_stage = "targets"
		_refresh()


func _render_creature_mode_popup(legal_actions: Array) -> void:
	var valid: Array = []
	for action in _creature_interaction.candidate_actions:
		if action in legal_actions:
			valid.append(action)
	if valid.size() < 2:
		_creature_interaction.reset()
		_pending_visual_placement = {}
		return
	for action in valid:
		var button := Button.new()
		button.text = "ATAQUE" if action["type"] == "summon_creature" else "GUARDIA"
		button.tooltip_text = "Boca arriba" if action["type"] == "summon_creature" else "Boca abajo"
		button.custom_minimum_size = Vector2(88, 30)
		button.pressed.connect(_commit_creature_mode.bind(action))
		_creature_mode_buttons.add_child(button)
	_creature_mode_popup.visible = true
	call_deferred("_position_creature_mode_popup")


func _position_creature_mode_popup() -> void:
	if not _creature_mode_popup.visible:
		return
	var slot := _field_slot("creatures", _creature_interaction.target_slot)
	if slot == null:
		return
	_creature_mode_popup.reset_size()
	var slot_rect := slot.get_global_rect()
	var width := maxf(_creature_mode_popup.size.x, 186.0)
	var height := maxf(_creature_mode_popup.size.y, 38.0)
	var bounds := _board_surface.get_global_rect()
	var left := clampf(slot_rect.get_center().x - width * 0.5, bounds.position.x + 4.0, bounds.end.x - width - 4.0)
	var top := slot_rect.position.y - height - 5.0
	for child in slot.get_children():
		if child is ProjectedFieldPiece:
			var visual_top := INF
			for corner in child.projected_corners():
				visual_top = minf(visual_top, (child.get_global_transform() * corner).y)
			top = visual_top - height - 3.0
			break
	_creature_mode_popup.global_position = Vector2(left, top)


func _describe_action(action: Dictionary, cards: Dictionary) -> String:
	var text: String = action["label"]
	if action["type"] == "fuse_creatures":
		var result_name: String = text.get_slice(": ", 1)
		var posture: String = "ATAQUE" if action["payload"].get("position", "") == "attack" else "GUARDIA"
		text = "FUSIONAR · %s · %s · 0 Energía" % [result_name, posture]
	elif action["type"] == "summon_creature":
		text = "ATAQUE · Visible\n" + text
	elif action["type"] == "set_creature":
		text = "GUARDIA · Oculta\n" + text
	var payload: Dictionary = action["payload"]
	var references: Array = []
	for key in ["instance_id", "source_instance_id", "target_instance_id", "attacker_id", "guardian_id"]:
		if payload.has(key):
			references.append("%s: %s" % [_payload_label(key), cards.get(payload[key], "carta visible")])
	if payload.has("material_instance_ids"):
		var materials: Array = []
		for instance_id in payload["material_instance_ids"]:
			materials.append(cards.get(instance_id, "carta visible"))
		references.append("materiales: %s" % " + ".join(materials))
	if payload.has("target_slot"):
		references.append("casilla objetivo %d" % (int(payload["target_slot"]) + 1) if int(payload["target_slot"]) >= 0 else "ataque directo")
	if payload.has("peek_support_slot"):
		references.append("apoyo rival %d" % (int(payload["peek_support_slot"]) + 1))
	if payload.has("support_slot"):
		references.append("apoyo %d" % (int(payload["support_slot"]) + 1))
	if payload.has("target_position"):
		references.append("postura %s" % payload["target_position"])
	if payload.has("choice"):
		references.append("elección %s" % payload["choice"])
	if not references.is_empty():
		text += "\n  " + " · ".join(references)
	return text


func _payload_label(key: String) -> String:
	return {
		"instance_id": "carta", "source_instance_id": "origen", "target_instance_id": "objetivo",
		"attacker_id": "atacante", "guardian_id": "guardián",
	}.get(key, key)


func _render_events() -> void:
	var events: Array = _engine.get_events(0, _viewer_id)
	var first: int = maxi(0, events.size() - 14)
	var lines: Array = []
	for index in range(first, events.size()):
		var event: Dictionary = events[index]
		lines.append("[color=#8fb9d4]#%d[/color] %s  [color=#aeb9c1]%s[/color]" % [event["sequence"], _event_name(event["type"]), JSON.stringify(event["payload"])])
	_event_log.text = "\n".join(lines)
	_event_log.scroll_to_line(maxi(0, lines.size() - 1))


func _toggle_event_log(button: Button) -> void:
	_event_expanded = not _event_expanded
	_event_log.visible = _event_expanded
	_event_panel.custom_minimum_size.y = 150 if _event_expanded else 30
	button.text = "HISTORIAL DE LA PARTIDA  %s" % ("▾" if _event_expanded else "▸")


func _event_name(type: String) -> String:
	return {
		"engine_started": "Motor iniciado", "phase_started": "Comienza fase", "turn_started": "Comienza turno",
		"card_drawn": "Carta robada", "private_card_drawn": "Robo privado", "creature_summoned": "Criatura invocada",
		"creature_set": "Criatura colocada", "attack_declared": "Ataque declarado", "combat_resolved": "Combate resuelto",
		"reaction_activated": "Respuesta activada", "reaction_resolved": "Respuesta resuelta",
		"creature_private_inspection": "Inspección realizada", "private_support_inspected": "Apoyo inspeccionado",
		"creature_attack_redirected": "Ataque redirigido",
	}.get(type, type.replace("_", " ").capitalize())


func _phase_name(phase: String) -> String:
	return {
		"START": "Inicio", "DRAW": "Robo", "MAIN_1": "Principal 1", "COMBAT": "Combate",
		"MAIN_2": "Principal 2", "END": "Final", "FINISHED": "Partida terminada",
	}.get(phase, phase)


func _perform_action(action: Dictionary, from_ai: bool = false) -> bool:
	_request_number += 1
	var request_id := "table-%06d" % _request_number
	var defender_id: int = 1 - int(action["actor_id"])
	var life_before: int = int(_engine.get_public_state()["game"]["life"][str(defender_id)]) if action["type"] == "attack" else 0
	var events_before: int = _engine.get_events(0, _viewer_id).size()
	var result = _engine.perform_action(GameAction.new(action["type"], action["actor_id"], action["payload"], request_id))
	if not result.success:
		_status_message = "Acción rechazada: %s — %s" % [result.code, result.message]
		_refresh()
		return false
	_queue_public_activations(events_before)
	_status_message = "Aplicada: %s" % action["label"]
	var played_definition_id := ""
	if not from_ai and action["payload"].has("instance_id"):
		var player_table: Dictionary = _engine.get_player_state(_viewer_id)["game"]["card_table"]
		played_definition_id = _visible_cards_by_id(player_table).get(action["payload"]["instance_id"], {}).get("definition", {}).get("id", "")
	match action["type"]:
		"set_support":
			_status_message = "Carta preparada boca abajo. Su efecto no se activa al colocarla: espera a una respuesta legal."
		"play_persistent":
			match played_definition_id:
				"G04":
					_status_message = "Bastión activo: +1 DEF automático a TODAS tus criaturas en Guardia; no hay que asignarlo."
				"G05":
					_status_message = "Magia activa: bonifica el primer cambio propio de Guardia a Ataque de cada turno."
				"E04":
					_status_message = "Artefacto activo: necesita un equipo ya vinculado para poder trasladarlo; no da +1 DEF."
				_:
					_status_message = "Carta persistente boca arriba; consulta su condición de activación."
		"equip_item":
			_status_message = "Equipo vinculado a la criatura elegida: su bonificación ya está activa."
		"attack":
			var attack_game: Dictionary = _engine.get_public_state()["game"]
			if attack_game["response_window"].get("active", false):
				_status_message = "Ataque declarado; espera a que se resuelvan las respuestas."
			elif action["payload"].get("target_slot", -2) == -1:
				var damage: int = maxi(0, life_before - int(attack_game["life"][str(defender_id)]))
				_status_message = "Ataque directo: %d de daño a la Vida rival." % damage
			else:
				_status_message = "Combate resuelto; revisa Vida, criaturas y Cementerio."
		"play_main_spell":
			_status_message = "Magia dirigida jugada sobre el objetivo elegido; comprueba el resultado en la carta y el registro."
		"fuse_creatures":
			_status_message = "Fusión realizada; consulta la criatura resultante en el campo."
	var combat_status := _combat_status_from_events(events_before)
	if not combat_status.is_empty():
		_status_message = combat_status
	elif _events_contain_type(events_before, "attack_canceled"):
		_status_message = "Ataque cancelado por una respuesta. Esa criatura gastó su ataque; puedes atacar con otra o terminar turno."
	_last_committed_action = {"type": action["type"], "actor_id": action["actor_id"], "payload": action["payload"].duplicate(true)}
	if not from_ai and not _pending_visual_placement.is_empty():
		var placement_key := "%s:%d" % [_pending_visual_placement["kind"], _pending_visual_placement["player_id"]]
		if not _visual_slot_assignments.has(placement_key):
			_visual_slot_assignments[placement_key] = {}
		_visual_slot_assignments[placement_key][_pending_visual_placement["instance_id"]] = _pending_visual_placement["slot"]
	_selected_card_id = ""
	_choice_actions = []
	_choice_stage = ""
	_pending_visual_placement = {}
	_attack_targeting = false
	_creature_interaction.reset()
	if _engine.lifecycle_name() == "RUNNING":
		var public_game: Dictionary = _engine.get_public_state()["game"]
		_auto_resolve_opening(public_game["active_player"])
	if _ai_enabled.button_pressed and _engine.lifecycle_name() == "RUNNING":
		_viewer_id = 0
		_privacy_hidden = false
		_schedule_ai_if_needed()
	elif _auto_follow.button_pressed and _engine.lifecycle_name() == "RUNNING":
		var game: Dictionary = _engine.get_public_state()["game"]
		var response: Dictionary = game["response_window"]
		var next_viewer: int = response.get("priority_player_id", game["active_player"]) if response.get("active", false) else game["active_player"]
		if next_viewer != _viewer_id:
			_viewer_id = next_viewer
			_privacy_hidden = true
	_refresh()
	return true


func _combat_status_from_events(start_index: int) -> String:
	var events: Array = _engine.get_events(0, _viewer_id)
	for index in range(events.size() - 1, start_index - 1, -1):
		var event: Dictionary = events[index]
		if event["type"] != "creature_combat_resolved":
			continue
		var info: Dictionary = event["payload"]
		var attacker_falls: bool = info["attacker_destroyed"]
		var defender_falls: bool = info["target_destroyed"]
		if not attacker_falls and not defender_falls:
			return "Ninguna criatura cae: ATQ %d no supera DEF %d; la represalia ATQ %d no supera DEF %d. Vida sin cambios." % [info["attacker_attack"], info["target_defense"], info["target_attack"], info["attacker_defense"]]
		var fallen := "ambas criaturas" if attacker_falls and defender_falls else "la atacante" if attacker_falls else "la defensora"
		return "Combate: cae %s. Daño a Vida del atacante: %d; del defensor: %d." % [fallen, info["damage_to_attacker"], info["damage_to_defender"]]
	return ""


func _events_contain_type(start_index: int, event_type: String) -> bool:
	var events: Array = _engine.get_events(0, _viewer_id)
	for index in range(start_index, events.size()):
		if events[index]["type"] == event_type:
			return true
	return false


func _on_action_pressed(index: int) -> void:
	perform_legal_action(index)


func _toggle_privacy() -> void:
	_privacy_hidden = not _privacy_hidden
	if _privacy_hidden:
		_activation_timer.stop()
		_activation_overlay.visible = false
	else:
		_show_next_activation()
	_refresh()


func _restart_pressed() -> void:
	start_match(_fresh_seed())


func _on_empty_slot_pressed(player_id: int, kind: String, visual_slot: int) -> void:
	if kind == "creatures" and player_id == _viewer_id and _creature_interaction.phase != TableInteractionState.Phase.IDLE:
		_choose_creature_slot(visual_slot)
		return
	if player_id != _viewer_id and kind == "creatures" and not _selected_card_id.is_empty():
		_attempt_selected_attack(-1)
		return
	if player_id != _viewer_id or _selected_card_id.is_empty() or _privacy_hidden:
		_status_message = "Selecciona primero una carta de tu mano." if _selected_card_id.is_empty() else "Esa casilla no pertenece a tu lado."
		_refresh()
		return
	var allowed_types: Array = ["summon_creature", "set_creature"] if kind == "creatures" else ["set_support", "play_persistent"]
	var candidates: Array = []
	for action in _legal_actions():
		if action["type"] in allowed_types and action["payload"].get("instance_id", "") == _selected_card_id:
			candidates.append(action)
	if candidates.is_empty():
		var selected_card: Dictionary = _visible_cards_by_id(_engine.get_player_state(_viewer_id)["game"]["card_table"]).get(_selected_card_id, {})
		var card_type: String = selected_card.get("definition", {}).get("attributes", {}).get("card_type", "")
		_status_message = "Este equipo no va en Apoyo: pulsa una criatura propia compatible para vincularlo." if kind == "support" and card_type == "item" and selected_card.get("definition", {}).get("id", "") != "E04" else "Esa carta no puede jugarse en esta casilla durante la fase actual."
		_refresh()
		return
	_pending_visual_placement = {"kind": kind, "player_id": player_id, "slot": visual_slot, "instance_id": _selected_card_id}
	if candidates.size() == 1:
		_perform_action(candidates[0])
	else:
		_status_message = "Elige cómo entra la criatura: visible en ataque u oculta en guardia."
		_open_action_choices(candidates)


func _choose_creature_slot(visual_slot: int) -> void:
	if _privacy_hidden or _creature_interaction.phase not in [TableInteractionState.Phase.SOURCE_SELECTED, TableInteractionState.Phase.TARGET_SELECTION] or visual_slot not in _creature_interaction.legal_destinations or not (_field_slot("creatures", visual_slot) is CreatureDropSlot):
		_status_message = "Esa casilla no es un destino legal para la criatura seleccionada."
		_refresh()
		return
	var candidates := _legal_creature_actions(_creature_interaction.source_id)
	if candidates.is_empty():
		_cancel_creature_interaction()
		return
	_pending_visual_placement = {"kind": "creatures", "player_id": _viewer_id, "slot": visual_slot, "instance_id": _creature_interaction.source_id}
	if candidates.size() == 1:
		_perform_action(candidates[0])
		return
	_creature_interaction.choose_target(visual_slot, candidates)
	_status_message = "Elige Ataque o Guardia junto a la casilla."
	_refresh()


func _commit_creature_mode(action: Dictionary) -> void:
	if _creature_interaction.phase != TableInteractionState.Phase.MODE_SELECTION or action not in _creature_interaction.candidate_actions or action not in _legal_creature_actions(_creature_interaction.source_id):
		return
	_creature_interaction.pending_mode = "attack" if action["type"] == "summon_creature" else "guard"
	_perform_action(action)


func _on_creature_drag_started(instance_id: String) -> void:
	if not _legal_creature_actions(instance_id).is_empty():
		_select_card(instance_id, false)


func _on_creature_dropped(instance_id: String, player_id: int, visual_slot: int) -> void:
	if player_id != _viewer_id or _legal_creature_actions(instance_id).is_empty():
		_cancel_creature_interaction()
		return
	if _creature_interaction.source_id != instance_id:
		_select_card(instance_id)
	_choose_creature_slot(visual_slot)


func _on_creature_drag_failed(instance_id: String) -> void:
	if _creature_interaction.source_id == instance_id:
		_cancel_creature_interaction()


func _on_equipment_drag_started(instance_id: String) -> void:
	if not _equipment_targets_for_source(instance_id).is_empty():
		_select_card(instance_id, false)
		_status_message = "Suelta el Equipo sobre una criatura propia iluminada para vincularlo."


func _on_equipment_drag_failed(instance_id: String) -> void:
	if _selected_card_id == instance_id:
		_cancel_pending_interaction("Equipo no vinculado; no se ha comprometido ninguna acción.")


func _on_equipment_dropped(source_id: String, target_id: String) -> void:
	var action := _equipment_action(source_id, target_id)
	if action.is_empty():
		if _selected_card_id == source_id:
			_cancel_pending_interaction("Ese portador no es compatible con el Equipo.")
		return
	_perform_action(action)


func _on_fusion_drag_started(instance_id: String) -> void:
	if _fusion_partners(instance_id).is_empty():
		return
	_select_card(instance_id, false)
	_status_message = "Suelta sobre una criatura propia iluminada para ver el resultado de la Fusión."


func _on_fusion_drag_failed(instance_id: String) -> void:
	if _selected_card_id == instance_id:
		_selected_card_id = ""
		_attack_targeting = false
		_status_message = "Fusión cancelada; no se han gastado cartas ni Energía."
		_refresh()


func _on_fusion_dropped(source_id: String, target_id: String) -> void:
	if target_id not in _fusion_partners(source_id):
		return
	_selected_card_id = source_id
	_on_board_card_selected(target_id, _viewer_id, "creatures", _visual_slot_for("creatures", _viewer_id, target_id))


func _cancel_creature_interaction() -> void:
	if _creature_interaction.phase == TableInteractionState.Phase.IDLE:
		return
	_cancel_pending_interaction("")


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if not _selected_card_id.is_empty() or not _choice_actions.is_empty() or _attack_targeting or _creature_interaction.phase != TableInteractionState.Phase.IDLE:
			_cancel_pending_interaction()
			get_viewport().set_input_as_handled()
		return
	if _creature_interaction.phase == TableInteractionState.Phase.IDLE:
		if _creature_action_popup.visible or _attack_targeting:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _board_surface.get_global_rect().has_point(event.global_position):
				var hovered_context := get_viewport().gui_get_hovered_control()
				var over_control := false
				while hovered_context != null:
					if hovered_context is Button:
						over_control = true
						break
					hovered_context = hovered_context.get_parent() as Control
				if not over_control:
					_cancel_creature_context()
					get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and _board_surface != null and _board_surface.get_global_rect().has_point(event.global_position):
		var hovered := get_viewport().gui_get_hovered_control()
		var over_button := false
		while hovered != null:
			if hovered is Button:
				over_button = true
				break
			hovered = hovered.get_parent() as Control
		if not over_button:
			_cancel_creature_interaction()
			get_viewport().set_input_as_handled()


func _cancel_creature_context() -> void:
	_cancel_pending_interaction()


func _on_board_card_selected(instance_id: String, player_id: int, kind: String, _visual_slot: int) -> void:
	if _selected_card_id.is_empty() or _selected_card_id == instance_id:
		_select_card(instance_id)
		return
	var location: Dictionary = _visible_card_locations.get(instance_id, {})
	var selected_location: Dictionary = _visible_card_locations.get(_selected_card_id, {})
	if kind == "creatures" and player_id != _viewer_id and selected_location.get("kind", "") == "creatures" and selected_location.get("player_id", -1) == _viewer_id:
		_attempt_selected_attack(location.get("slot", -2))
		return
	if kind == "creatures" and player_id == _viewer_id and selected_location.get("player_id", -1) == _viewer_id and selected_location.get("kind", "") in ["hand", "support"]:
		var selected_card: Dictionary = _visible_cards_by_id(_engine.get_player_state(_viewer_id)["game"]["card_table"]).get(_selected_card_id, {})
		var definition_id: String = selected_card.get("definition", {}).get("id", "")
		if definition_id in ["G04", "G05", "E04"]:
			_status_message = "Esta carta no se entrega a una criatura: va en Apoyo y funciona automáticamente según su condición. E04 solo traslada equipos ya vinculados."
			_refresh()
			return
	var candidates: Array = []
	for action in _legal_actions():
		var payload: Dictionary = action["payload"]
		if action["type"] == "fuse_creatures" and _selected_card_id in payload.get("material_instance_ids", []) and instance_id in payload.get("material_instance_ids", []):
			candidates.append(action)
			continue
		var uses_selected: bool = payload.get("instance_id", "") == _selected_card_id or payload.get("attacker_id", "") == _selected_card_id
		if not uses_selected:
			continue
		if action["type"] in ["equip_item"] and payload.get("target_instance_id", "") == instance_id:
			candidates.append(action)
		elif action["type"] == "play_main_spell" and not location.is_empty() and payload.get("target_player_id", -1) == player_id and payload.get("target_slot", -2) == location.get("slot", -3):
			candidates.append(action)
		elif action["type"] == "attack" and kind == "creatures" and player_id != _viewer_id and not location.is_empty() and payload.get("target_slot", -2) == location.get("slot", -3):
			candidates.append(action)
	if candidates.size() == 1 and candidates[0]["type"] != "fuse_creatures":
		_perform_action(candidates[0])
	elif not candidates.is_empty():
		_status_message = "Comprueba resultado, postura y objetivo antes de confirmar. Fusión normal: 0 Energía." if candidates[0]["type"] == "fuse_creatures" else "Elige la acción exacta para esa carta objetivo."
		_open_action_choices(candidates)
	else:
		_select_card(instance_id)


func _on_direct_player_pressed() -> void:
	if _selected_card_id.is_empty() or _engine == null:
		return
	_attempt_selected_attack(-1)


func _on_terrain_pressed(player_id: int) -> void:
	if player_id != _viewer_id or _selected_card_id.is_empty():
		_status_message = "Selecciona un Terreno de tu mano y después tu franja de Territorio."
		_refresh()
		return
	for action in _legal_actions():
		if action["type"] == "play_terrain" and action["payload"].get("instance_id", "") == _selected_card_id:
			var table: Dictionary = _engine.get_player_state(_viewer_id)["game"]["card_table"]
			var terrain_zone: Dictionary = table["zones"]["terrain:%d" % player_id]
			if terrain_zone["count"] <= 0:
				_perform_action(action)
				return
			var current: Dictionary = terrain_zone["cards"][0]
			var incoming: Dictionary = _visible_cards_by_id(table).get(_selected_card_id, {})
			var current_identity: Dictionary = current.get("terrain_identity", {})
			var incoming_id: String = incoming.get("definition", {}).get("id", "")
			var preview_key := "%s|%s" % [current_identity.get("id", ""), incoming_id]
			var incoming_name: String = incoming.get("definition", {}).get("attributes", {}).get("display_name", "el nuevo Terreno")
			if TERRAIN_PREVIEWS.has(preview_key):
				var transformation_name: String = TERRAIN_PREVIEWS[preview_key]
				if _perform_action(action):
					_status_message = "Transformación de Territorio: %s + %s → %s." % [current_identity.get("display_name", "Terreno actual"), incoming_name, transformation_name]
					_refresh()
				return
			if _perform_action(action):
				_status_message = "%s sustituye a %s; el Terreno anterior va al Cementerio." % [incoming_name, current_identity.get("display_name", "el Terreno actual")]
				_refresh()
			return
	_status_message = "La carta seleccionada no puede jugarse como Terreno ahora."
	_refresh()


func _has_selected_action_type(action_type: String) -> bool:
	if _selected_card_id.is_empty() or _engine == null:
		return false
	for action in _legal_actions():
		if action["type"] == action_type and action["payload"].get("instance_id", "") == _selected_card_id:
			return true
	return false


func _selected_card_can_enter(kind: String) -> bool:
	var accepted: Array = ["summon_creature", "set_creature"] if kind == "creatures" else ["set_support", "play_persistent"]
	for action_type in accepted:
		if _has_selected_action_type(action_type):
			return true
	return false


func _selected_direct_attack_available() -> bool:
	if _selected_card_id.is_empty() or _engine == null or not _attack_targeting:
		return false
	if _can_offer_attack_from_main():
		var game: Dictionary = _engine.get_public_state()["game"]
		if game["card_table"]["zones"]["creatures:%d" % (1 - _viewer_id)]["count"] == 0:
			return true
	for action in _legal_actions():
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == _selected_card_id and action["payload"].get("target_slot", -2) == -1:
			return true
	return false


func _can_offer_attack_from_main() -> bool:
	if _engine == null or _selected_card_id.is_empty() or _privacy_hidden:
		return false
	var location: Dictionary = _visible_card_locations.get(_selected_card_id, {})
	if location.get("kind", "") != "creatures" or location.get("player_id", -1) != _viewer_id:
		return false
	var game: Dictionary = _engine.get_player_state(_viewer_id)["game"]
	if game["phase"] != "MAIN_1" or game["active_player"] != _viewer_id or game["response_window"].get("active", false) or game["turn_number"] == 1:
		return false
	var card: Dictionary = _visible_cards_by_id(game["card_table"]).get(_selected_card_id, {})
	if card.is_empty():
		return false
	var metadata: Dictionary = card["instance"]["metadata"]
	if not metadata.get("face_up", false) or metadata.get("position", "") != "attack":
		return false
	if card.has("fusion_identity") and metadata.get("summoned_turn", -1) == game["turn_number"]:
		return false
	return true


func _attempt_selected_attack(target_slot: int) -> void:
	if _engine == null or _selected_card_id.is_empty():
		return
	var attacker_id := _selected_card_id
	var game: Dictionary = _engine.get_public_state()["game"]
	if game["phase"] == "MAIN_1":
		if not _can_offer_attack_from_main():
			_status_message = "Esta criatura no puede atacar ahora: comprueba el primer turno, Guardia o Fusión recién formada."
			_refresh()
			return
		var phase_action: Dictionary = {}
		for action in _legal_actions():
			if action["type"] == "advance_phase":
				phase_action = action
				break
		if phase_action.is_empty() or not _perform_action(phase_action):
			return
		_selected_card_id = attacker_id
		_refresh()
	for action in _legal_actions():
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == attacker_id and action["payload"].get("target_slot", -2) == target_slot:
			_perform_action(action)
			return
	_status_message = "No hay ataque legal contra ese objetivo. Elige una criatura rival iluminada; ataque directo solo con campo rival vacío."
	_refresh()


func _hidden_slot_attack_available(player_id: int, engine_slot: int) -> bool:
	if player_id == _viewer_id or _selected_card_id.is_empty() or _engine == null or not _attack_targeting:
		return false
	if _can_offer_attack_from_main():
		return true
	for action in _legal_actions():
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == _selected_card_id and action["payload"].get("target_slot", -2) == engine_slot:
			return true
	return false


func _on_hidden_board_card_selected(_ui_id: String, player_id: int, kind: String, engine_slot: int) -> void:
	if player_id == _viewer_id or kind != "creatures":
		return
	_attempt_selected_attack(engine_slot)


func _sync_visual_slots(table: Dictionary) -> void:
	for player_id in [0, 1]:
		for kind in ["creatures", "support"]:
			var key := "%s:%d" % [kind, player_id]
			var assignments: Dictionary = _visual_slot_assignments.get(key, {})
			var visible_ids: Array = []
			for card in table["zones"][key]["cards"]:
				visible_ids.append(card["instance"]["id"])
			for instance_id in assignments.keys():
				if instance_id not in visible_ids:
					assignments.erase(instance_id)
			var used: Array = assignments.values()
			for instance_id in visible_ids:
				if assignments.has(instance_id):
					continue
				for slot_index in range(5):
					if slot_index not in used:
						assignments[instance_id] = slot_index
						used.append(slot_index)
						break
			_visual_slot_assignments[key] = assignments


func _visual_slot_for(kind: String, player_id: int, instance_id: String) -> int:
	return int(_visual_slot_assignments.get("%s:%d" % [kind, player_id], {}).get(instance_id, 0))


func _update_advance_button(game: Dictionary) -> void:
	var actor: int = _current_actor(game)
	var owns_turn: bool = game["active_player"] == _viewer_id
	var response_active: bool = game["response_window"].get("active", false)
	var precommit_active := _precommit_interaction_active()
	var blocked: bool = actor != _viewer_id or not owns_turn or _privacy_hidden or _engine.lifecycle_name() != "RUNNING" or response_active or precommit_active
	_advance_button.visible = game["phase"] in ["MAIN_1", "COMBAT"]
	_advance_button.disabled = blocked
	_end_turn_button.text = "TERMINAR TURNO"
	_end_turn_button.disabled = not owns_turn or _privacy_hidden or _engine.lifecycle_name() != "RUNNING" or precommit_active
	_end_turn_button.tooltip_text = "Cancela la selección pendiente antes de terminar el turno." if precommit_active else ""
	if response_active:
		_end_turn_button.text = "PASAR RESPUESTA" if actor == _viewer_id else "ESPERANDO RESPUESTA"
		var can_pass := false
		if actor == _viewer_id:
			for action in _legal_actions():
				if action["type"] == "pass_reaction":
					can_pass = true
					break
		_end_turn_button.disabled = _privacy_hidden or _engine.lifecycle_name() != "RUNNING" or not can_pass or precommit_active
	if actor != _viewer_id:
		_advance_button.text = "Turno del rival…"
		return
	_advance_button.text = "Pasar sin atacar" if game["phase"] == "MAIN_1" else "Pasar ataques"


func _update_phase_track(current_phase: String) -> void:
	_phase_indicator.text = "FASE · %s" % _phase_name(current_phase).to_upper()


func _on_phase_button_pressed() -> void:
	if _precommit_interaction_active():
		_status_message = "Cancela la selección pendiente antes de cambiar de fase."
		_refresh()
		return
	var phase: String = _engine.get_public_state()["game"]["phase"]
	_advance_phase_pressed()
	if phase == "MAIN_1" and _engine.lifecycle_name() == "RUNNING":
		var game: Dictionary = _engine.get_public_state()["game"]
		if game["phase"] == "COMBAT" and game["active_player"] == _viewer_id and not game["response_window"].get("active", false):
			_advance_phase_pressed()


func _advance_phase_pressed() -> void:
	for action in _legal_actions():
		if action["type"] == "advance_phase":
			_perform_action(action)
			return


func _end_turn_pressed() -> void:
	if _engine == null or _engine.lifecycle_name() != "RUNNING" or _privacy_hidden:
		return
	if _precommit_interaction_active():
		_status_message = "Cancela la selección pendiente antes de terminar el turno."
		_refresh()
		return
	var game: Dictionary = _engine.get_public_state()["game"]
	if game["response_window"].get("active", false):
		if _current_actor(game) == _viewer_id:
			for action in _legal_actions():
				if action["type"] == "pass_reaction":
					_perform_action(action)
					return
		return
	if game["active_player"] != _viewer_id:
		return
	if _end_turn_dialog != null:
		_end_turn_dialog.popup_centered()


func _confirm_end_turn() -> void:
	if _engine == null or _engine.lifecycle_name() != "RUNNING":
		return
	if _precommit_interaction_active():
		_status_message = "La jugada pendiente sigue sin comprometerse. Cancélala antes de terminar el turno."
		_refresh()
		return
	var game_before: Dictionary = _engine.get_public_state()["game"]
	if game_before["response_window"].get("active", false):
		return
	var starting_player: int = game_before["active_player"]
	if starting_player != _viewer_id:
		return
	if _creature_interaction.phase != TableInteractionState.Phase.IDLE:
		_cancel_creature_interaction()
	_selected_card_id = ""
	_choice_actions = []
	_choice_stage = ""
	_attack_targeting = false
	var safety := 8
	while safety > 0 and _engine.lifecycle_name() == "RUNNING":
		safety -= 1
		var game: Dictionary = _engine.get_public_state()["game"]
		if game["active_player"] != starting_player or game["response_window"].get("active", false):
			break
		var advance: Dictionary = {}
		for action in _engine.get_legal_actions(starting_player):
			if action["type"] == "advance_phase":
				advance = action
				break
		if advance.is_empty() or not _perform_action(advance):
			break


func _auto_resolve_opening(player_id: int) -> void:
	var safety := 3
	while safety > 0 and _engine != null and _engine.lifecycle_name() == "RUNNING":
		safety -= 1
		var game: Dictionary = _engine.get_public_state()["game"]
		if game["active_player"] != player_id or game["phase"] not in ["START", "DRAW"] or game["response_window"].get("active", false):
			break
		var advance: Dictionary = {}
		for action in _engine.get_legal_actions(player_id):
			if action["type"] == "advance_phase":
				advance = action
				break
		if advance.is_empty():
			break
		_request_number += 1
		var result = _engine.perform_action(GameAction.new(advance["type"], player_id, advance["payload"], "table-auto-%06d" % _request_number))
		if not result.success:
			_status_message = "No se pudo resolver automáticamente %s." % _phase_name(game["phase"])
			break


func _current_actor(game: Dictionary) -> int:
	var response: Dictionary = game["response_window"]
	return int(response.get("priority_player_id", game["active_player"])) if response.get("active", false) else int(game["active_player"])


func _ai_is_actor(game: Dictionary) -> bool:
	return _ai_enabled != null and _ai_enabled.button_pressed and _current_actor(game) == 1


func _schedule_forced_pass(actions: Array, game: Dictionary) -> void:
	if _forced_pass_pending or _ai_enabled == null or not _ai_enabled.button_pressed or _viewer_id != 0 or _privacy_hidden:
		return
	if not game["response_window"].get("active", false) or _current_actor(game) != 0:
		return
	var can_pass := false
	for action in actions:
		if action["type"] == "pass_reaction":
			can_pass = true
		elif action["type"] != "concede":
			return
	if can_pass:
		_forced_pass_pending = true
		call_deferred("_pass_forced_response")


func _pass_forced_response() -> void:
	if _activation_pause_active():
		return
	_forced_pass_pending = false
	if _engine == null or _engine.lifecycle_name() != "RUNNING" or _ai_enabled == null or not _ai_enabled.button_pressed or _privacy_hidden:
		return
	var game: Dictionary = _engine.get_public_state()["game"]
	if not game["response_window"].get("active", false) or _current_actor(game) != 0:
		return
	var pass_action: Dictionary = {}
	for action in _legal_actions():
		if action["type"] == "pass_reaction":
			pass_action = action
		elif action["type"] != "concede":
			return
	if not pass_action.is_empty():
		_perform_action(pass_action)


func _on_ai_toggled(enabled: bool) -> void:
	if enabled:
		_viewer_id = 0
		_privacy_hidden = false
		_status_message = "Rival automático activado. Tú juegas como Jugador 1."
		_schedule_ai_if_needed()
	else:
		_status_message = "Modo local para dos personas activado."
	_refresh()


func _schedule_ai_if_needed() -> void:
	if _ai_running or not _ai_enabled.button_pressed or _engine == null or _engine.lifecycle_name() != "RUNNING":
		return
	var game: Dictionary = _engine.get_public_state()["game"]
	if _current_actor(game) == 1:
		call_deferred("_run_ai_until_human")


func _run_ai_until_human() -> void:
	if _ai_running:
		return
	_ai_running = true
	var safety := 80
	while safety > 0 and _engine.lifecycle_name() == "RUNNING":
		while _activation_pause_active():
			await get_tree().process_frame
		safety -= 1
		var game: Dictionary = _engine.get_public_state()["game"]
		if _current_actor(game) != 1:
			break
		var actions: Array = _engine.get_legal_actions(1)
		var choice := _choose_ai_action(actions, game["phase"], game["response_window"].get("active", false))
		if choice.is_empty() or not _perform_action(choice, true):
			break
		await get_tree().create_timer(0.001 if DisplayServer.get_name() == "headless" else 0.18).timeout
	_ai_running = false
	if _engine.lifecycle_name() == "RUNNING":
		_auto_resolve_opening(0)
	_refresh()


func _choose_ai_action(actions: Array, phase: String, response_active: bool) -> Dictionary:
	if actions.is_empty():
		return {}
	if response_active:
		for preferred in ["activate_reaction", "redirect_attack", "decline_redirect", "choose_fusion_combat_bonus", "pass_reaction"]:
			for action in actions:
				if action["type"] == preferred:
					return action
	var priorities: Array = [
		"fuse_creatures", "summon_creature", "set_support", "play_persistent", "equip_item",
		"play_main_spell", "play_terrain", "activate_creature_ability", "activate_fusion_ability",
		"attack", "change_position", "advance_phase",
	]
	if phase == "COMBAT":
		priorities.erase("attack")
		priorities.push_front("attack")
	for action_type in priorities:
		for action in actions:
			if action["type"] == action_type:
				return action
	return actions[0]


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()


func _count_card_tiles(node: Node) -> int:
	var count := 1 if node is CardTile else 0
	for child in node.get_children():
		count += _count_card_tiles(child)
	return count


func _count_nodes_with_role(node: Node, role: String) -> int:
	var count := 1 if node.get_meta("board_role", "") == role else 0
	for child in node.get_children():
		count += _count_nodes_with_role(child, role)
	return count


func _style_box(fill: Color, border: Color, width: int = 1, radius: int = 4, dashed: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 5
	style.content_margin_right = 5
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	if dashed:
		style.border_blend = true
	return style
