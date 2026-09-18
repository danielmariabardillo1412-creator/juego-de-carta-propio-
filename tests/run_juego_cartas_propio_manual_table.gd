extends SceneTree
## Integración mínima de la mesa local con UCE, vistas privadas, acciones legales y cortina de relevo.

const CardTile = preload("res://demo/card_tile.gd")
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")
const GameAction = preload("res://src/core/game_action.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://demo/juego_cartas_table.tscn")
	_expect(packed != null, "la escena de mesa carga")
	if packed == null:
		_finish()
		return
	var table = packed.instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	var snapshot: Dictionary = table.debug_snapshot()
	_expect(snapshot["ready"], "la mesa construye el motor")
	_expect_equal(snapshot["lifecycle"], "RUNNING", "la mesa inicia una partida")
	_expect_equal(snapshot["module_version"], "0.24.0-stress-hardening", "la mesa usa el módulo vigente")
	_expect_equal(snapshot["viewer_id"], 0, "la vista inicial pertenece al jugador uno")
	_expect_equal(snapshot["phase"], "MAIN_1", "Inicio y Robo se resuelven automáticamente antes de entregar control")
	var test_tools: Array = []
	var tools_buttons: Array = []
	_find_named_nodes(table, "TestTools", test_tools)
	_find_named_nodes(table, "TestToolsButton", tools_buttons)
	_expect_equal(test_tools.size(), 1, "los controles de prueba siguen presentes")
	if test_tools.size() == 1 and tools_buttons.size() == 1:
		_expect(not test_tools[0].visible, "los controles de prueba comienzan plegados")
		tools_buttons[0].pressed.emit()
		_expect(test_tools[0].visible, "Herramientas permite abrir los controles de prueba")
		tools_buttons[0].pressed.emit()
		_expect(not test_tools[0].visible, "Herramientas permite plegar de nuevo los controles")
	_expect_equal(snapshot["board_player_count"], 2, "se presentan ambos lados del tablero")
	_expect_equal(snapshot["visual_board_layout"], "measured-template-1280x720", "la mesa usa una plantilla medida común")
	_expect_equal(snapshot["creature_slot_count"], 10, "las diez casillas de criatura permanecen dibujadas")
	_expect_equal(snapshot["support_slot_count"], 10, "las diez casillas de apoyo permanecen dibujadas")
	_expect_equal(snapshot["terrain_lane_count"], 2, "cada jugador dispone de una franja territorial visible")
	_expect_equal(snapshot["side_pile_count"], 6, "Baraja, Cementerio y materiales de Fusión ocupan zonas laterales separadas")
	_expect(snapshot["rendered_card_count"] >= 5, "la mano visible se representa con componentes de carta")
	var hand_fans: Array = []
	_find_named_nodes(table, "HandFan", hand_fans)
	_expect_equal(hand_fans.size(), 2, "ambas manos tienen una fila visual")
	if hand_fans.size() == 2 and hand_fans[0].get_child_count() > 0 and hand_fans[1].get_child_count() > 0:
		_expect_equal(hand_fans[0].get_child(0).custom_minimum_size, hand_fans[1].get_child(0).custom_minimum_size, "las cartas rivales y propias conservan la misma métrica nominal")
		_expect_equal(hand_fans[0].get_child(0).custom_minimum_size, Vector2(86, 120), "ambas manos usan carta 86×120")
		_expect_equal(hand_fans[0].scale, Vector2(0.90, 0.90), "la mano rival se reduce moderadamente por profundidad")
		_expect_equal(hand_fans[1].scale, Vector2.ONE, "la mano propia conserva escala de primer plano")
	var layers: Array = []
	_find_named_nodes(table, "FieldTemplateLayer", layers)
	_expect_equal(layers.size(), 1, "una malla única cubre las cuatro bandas")
	if layers.size() == 1:
		var layer: Control = layers[0]
		var geometry: Dictionary = layer.get_script().get_script_constant_map()
		_expect_equal(geometry["REFERENCE_SIZE"], Vector2(1280, 720), "la referencia geométrica es 1280×720")
		_expect_equal(geometry["BANDS"], [
			[Vector2(612, 197), Vector2(992, 197), Vector2(1007, 245), Vector2(598, 245)],
			[Vector2(595, 250), Vector2(1008, 250), Vector2(1025, 308), Vector2(580, 308)],
			[Vector2(565, 355), Vector2(1038, 355), Vector2(1062, 433), Vector2(542, 433)],
			[Vector2(540, 440), Vector2(1063, 440), Vector2(1092, 537), Vector2(512, 537)],
		], "las cuatro bandas coinciden exactamente con la referencia")
		_expect_equal(geometry["CENTERS"], [
			[Vector2(643, 221), Vector2(722, 221), Vector2(802, 220), Vector2(881, 221), Vector2(962, 221)],
			[Vector2(628, 278), Vector2(715, 279), Vector2(803, 278), Vector2(888, 279), Vector2(975, 279)],
			[Vector2(601, 394), Vector2(701, 394), Vector2(802, 394), Vector2(903, 394), Vector2(1003, 394)],
			[Vector2(579, 489), Vector2(690, 489), Vector2(802, 489), Vector2(914, 489), Vector2(1025, 489)],
		], "los veinte centros coinciden exactamente con la referencia")
		_expect(is_equal_approx(layer.call("template_scale"), minf(layer.size.x / 1280.0, layer.size.y / 720.0)), "la plantilla se escala uniformemente")
		_check_field_row_geometry(table, layer, "OpponentSupportRow", "support_slot", 0)
		_check_field_row_geometry(table, layer, "OpponentCreatureRow", "creature_slot", 1)
		_check_field_row_geometry(table, layer, "PlayerCreatureRow", "creature_slot", 2)
		_check_field_row_geometry(table, layer, "PlayerSupportRow", "support_slot", 3)
		var spans: Array = []
		for band_index in range(4):
			var left: Vector2 = layer.call("slot_center", band_index, 0)
			var middle: Vector2 = layer.call("slot_center", band_index, 2)
			var right: Vector2 = layer.call("slot_center", band_index, 4)
			spans.append(right.x - left.x)
			_expect(absf(middle.x - layer.size.x * 0.5) <= layer.call("template_scale") * 1.0, "C3 permanece centrada en la banda %d" % band_index)
		_expect(spans[0] < spans[1] and spans[1] < spans[2] and spans[2] < spans[3], "los extremos se abren progresivamente hacia el jugador")
		var own_band: PackedVector2Array = layer.call("band_corners", 2)
		_expect(own_band[0].y > layer.size.y * 0.51, "la costura del fondo queda entre bandos y no cruza las casillas propias")
	_expect_equal(table.get_script().get_script_constant_map()["FIELD_ENVELOPE_SIZE"], Vector2(101, 101), "la envolvente de campo admite Ataque y Guardia")
	_expect_equal(table.get_script().get_script_constant_map()["FIELD_GAP"], 11.0, "cinco envolventes mantienen separación de 11 px")
	for sample in [["field", "attack", Vector2(72, 101)], ["field", "guard", Vector2(101, 72)], ["opponent_field", "guard", Vector2(101, 72)], ["preview", "attack", Vector2(180, 251)]]:
		var sample_tile = CardTile.new()
		sample_tile.setup("SAMPLE", "Muestra", "", false, "creature", "neutral", sample[1], true, sample[0])
		_expect_equal(sample_tile.custom_minimum_size, sample[2], "carta %s/%s respeta la métrica TCG" % [sample[0], sample[1]])
		sample_tile.free()
	var hidden_face = CardTile.new()
	hidden_face.setup("SECRET", "Nombre oculto", "", false, "creature", "fire", "guard", false, "opponent_hand", {"cost": 7, "attack": 8, "defense": 6})
	_expect(hidden_face.find_child("CardCost", true, false) == null and hidden_face.find_child("CardATQ", true, false) == null, "una carta boca abajo no dibuja coste ni estadísticas")
	_expect_equal(hidden_face.tooltip_text, "Carta oculta", "la ayuda de una carta oculta tampoco revela identidad ni cifras")
	hidden_face.free()
	for hand_case in [[5, 94.0], [7, 76.0], [9, 60.0], [10, 48.0]]:
		_expect_equal(table.call("_hand_step", hand_case[0]), hand_case[1], "paso de mano para %d cartas" % hand_case[0])
	var empty_card_slot: Button = _find_first_role_button(table, "creature_slot")
	_expect(empty_card_slot != null and empty_card_slot.size.y > empty_card_slot.size.x, "las casillas vacías conservan proporción de carta")
	_expect(snapshot["rendered_action_count"] < snapshot["legal_action_count"], "la mesa absorbe acciones directas y el lateral no las duplica")
	_expect_equal(snapshot["phase_track_count"], 1, "la cabecera muestra una sola fase actual")
	var phase_indicators: Array = []
	var phase_overlays: Array = []
	_find_named_nodes(table, "PhaseIndicator", phase_indicators)
	_find_named_nodes(table, "PhaseOverlay", phase_overlays)
	_expect_equal(phase_indicators.size(), 1, "el HUD superior contiene el indicador de fase")
	_expect_equal(phase_overlays.size(), 0, "la mesa no conserva una banda de fases central")
	if phase_indicators.size() == 1:
		_expect(phase_indicators[0].text.contains("PRINCIPAL 1"), "la fase actual aparece en la cabecera")
	var projected_pieces: Array = []
	_find_projected_pieces(table, projected_pieces)
	_expect_equal(projected_pieces.size(), 28, "veinte casillas y ocho zonas laterales tienen superficie proyectada")
	for piece in projected_pieces:
		var quad: PackedVector2Array = piece.projected_corners()
		_expect(piece.template_corners.size() == 4 and quad[1].x - quad[0].x < quad[2].x - quad[3].x and quad[0].y < quad[3].y, "cada pieza de campo usa el trapecio de su banda")
	_expect(not snapshot["event_expanded"], "el historial comienza plegado")
	var table_view: Dictionary = snapshot["view"]["game"]["card_table"]
	_expect_equal(table_view["zones"]["hand:0"]["cards"].size(), 5, "el propietario ve sus cinco cartas")
	_expect_equal(table_view["zones"]["hand:1"]["cards"].size(), 0, "la mano rival no revela identidades")
	_expect_equal(table_view["zones"]["hand:1"]["count"], 5, "la mano rival conserva su recuento público")
	var checked_face := false
	for card in table_view["zones"]["hand:0"]["cards"]:
		var attributes: Dictionary = card["definition"]["attributes"]
		if attributes.get("card_type", "") != "creature":
			continue
		var hand_face: Button = table.call("_tile_from_card", card, 0, "hand")
		var preview_face: Button = table.call("_preview_tile_from_card", card)
		for face in [hand_face, preview_face]:
			_expect_equal(face.find_child("CardCost", true, false).text, "E %d" % int(attributes["cost"]), "el frontal muestra el coste impreso")
			_expect_equal(face.find_child("CardATQ", true, false).text, "ATQ %d" % int(attributes["attack"]), "el frontal muestra el ataque impreso")
			_expect_equal(face.find_child("CardDEF", true, false).text, "DEF %d" % int(attributes["defense"]), "el frontal muestra la defensa impresa")
			_expect(face.find_child("ArtPlaceholder", true, false) != null, "el frontal reserva espacio para la ilustración futura")
		if not String(attributes.get("effect_text", "")).is_empty():
			_expect_equal(preview_face.find_child("CardEffect", true, false).text, attributes["effect_text"], "la ficha grande imprime el texto de efecto")
		_expect(table.call("_card_detail_text", card).contains("ATQ %d · DEF %d" % [attributes["attack"], attributes["defense"]]), "la ficha lateral también muestra ATQ y DEF antes de invocar")
		hand_face.free()
		preview_face.free()
		checked_face = true
		break
	_expect(checked_face, "la mano inicial permite comprobar una criatura real")
	_expect(snapshot["event_text"].contains("Motor iniciado"), "el registro presenta eventos visibles")
	var fake_attacks := [
		{"index": 0, "action": {"type": "attack", "actor_id": 0, "payload": {"attacker_id": "A", "target_slot": 0}, "label": "Atacar criatura", "metadata": {}}},
		{"index": 1, "action": {"type": "attack", "actor_id": 0, "payload": {"attacker_id": "A", "target_slot": 1}, "label": "Atacar criatura", "metadata": {}}},
	]
	var grouped: Array = table.call("_group_action_entries", fake_attacks)
	_expect_equal(grouped.size(), 1, "dos objetivos del mismo atacante forman una sola intención")
	_expect_equal(grouped[0]["actions"].size(), 2, "la intención conserva ambas acciones legales exactas")
	fake_attacks.append({"index": 2, "action": {"type": "attack", "actor_id": 0, "payload": {"attacker_id": "B", "target_slot": 0}, "label": "Atacar criatura", "metadata": {}}})
	grouped = table.call("_group_action_entries", fake_attacks)
	_expect_equal(grouped.size(), 2, "otro atacante conserva una intención independiente")
	table.set("_visible_card_locations", {"TRAP": {"kind": "support", "player_id": 0, "slot": 2}, "ENEMY": {"kind": "creatures", "player_id": 1, "slot": 1}})
	_expect(table.call("_action_mentions_card", {"type": "activate_reaction", "actor_id": 0, "payload": {"support_slot": 2}}, "TRAP"), "una respuesta se relaciona con su carta preparada")
	_expect(table.call("_action_mentions_card", fake_attacks[1]["action"], "ENEMY"), "un ataque se relaciona con la criatura de su casilla objetivo")
	_expect(not table.call("_action_mentions_card", fake_attacks[0]["action"], "ENEMY"), "otra casilla no crea una relación falsa")
	table.set("_selected_card_id", "TEST")
	var visible_test := {"TEST": "Carta de prueba"}
	_expect(table.call("_selection_instruction", [{"type": "equip_item", "actor_id": 0, "payload": {"instance_id": "TEST", "target_instance_id": "X"}}], visible_test).contains("NO lo coloques en Apoyo"), "el equipo dirigido no se presenta como apoyo libre")
	_expect(table.call("_selection_instruction", [{"type": "play_main_spell", "actor_id": 0, "payload": {"instance_id": "TEST", "target_slot": 0}}], visible_test).contains("Cementerio"), "la Magia instantánea anuncia su destino final")
	_expect(table.call("_selection_instruction", [{"type": "play_persistent", "actor_id": 0, "payload": {"instance_id": "TEST"}}], visible_test).contains("boca arriba"), "la Magia persistente explica su permanencia")
	_expect(table.call("_selection_instruction", [{"type": "set_support", "actor_id": 0, "payload": {"instance_id": "TEST"}}], visible_test).contains("boca abajo"), "la respuesta preparada explica su ocultación")
	table.set("_selected_card_id", "")
	table.set("_visible_card_locations", {})
	var terrain_ids: Array = []
	for hand_card in table_view["zones"]["hand:0"]["cards"]:
		if hand_card["definition"]["attributes"].get("card_type", "") == "terrain":
			terrain_ids.append(hand_card["instance"]["id"])
	_expect_equal(terrain_ids.size(), 2, "la semilla de interfaz ofrece dos Terrenos para probar una receta")
	if terrain_ids.size() == 2:
		table.call("_select_card", terrain_ids[0])
		table.call("_on_terrain_pressed", 0)
		snapshot = table.debug_snapshot()
		var second_terrain_legal_same_turn := false
		for legal in snapshot["legal_actions"]:
			if legal["type"] == "play_terrain" and legal["payload"].get("instance_id", "") == terrain_ids[1]:
				second_terrain_legal_same_turn = true
		_expect(not second_terrain_legal_same_turn, "la mesa no ofrece un segundo Terreno normal el mismo turno")
		_expect(_advance_table_to_next_own_main(table, 0), "la mesa alcanza el siguiente turno propio antes de transformar")
		table.call("_select_card", terrain_ids[1])
		table.call("_on_terrain_pressed", 0)
		snapshot = table.debug_snapshot()
		var terrain_zone: Dictionary = snapshot["view"]["game"]["card_table"]["zones"]["terrain:0"]
		_expect_equal(terrain_zone["count"], 1, "la receta conserva un único Territorio activo")
		_expect(terrain_zone["cards"][0]["terrain_identity"].get("transformed", false), "dos Terrenos compatibles se transforman desde la mesa")
		_expect(snapshot["view"]["game"]["card_table"]["zones"]["graveyard:0"]["count"] >= 1, "el soporte territorial anterior llega al Cementerio")
	var summon_index := -1
	snapshot = table.debug_snapshot()
	for index in range(snapshot["legal_actions"].size()):
		if snapshot["legal_actions"][index]["type"] == "summon_creature":
			summon_index = index
			break
	_expect(summon_index >= 0, "la apertura ofrece una invocación costeable")
	if summon_index >= 0:
		var selected_id: String = snapshot["legal_actions"][summon_index]["payload"]["instance_id"]
		var hand_tile: Button = _find_card_tile(table, selected_id)
		_expect(hand_tile != null, "la carta de la mano dispone de un botón real")
		if hand_tile != null:
			hand_tile.emit_signal("pressed")
		snapshot = table.debug_snapshot()
		_expect_equal(snapshot["selected_card_id"], selected_id, "una carta visible puede seleccionarse")
		_expect(not snapshot["card_detail_text"].is_empty(), "la selección abre una ficha de carta")
		_expect(snapshot["card_detail_text"].contains("coste"), "la ficha muestra datos mecánicos legibles")
		_expect(snapshot["related_action_count"] >= 2, "seleccionar prioriza sus acciones legales")
		var destination: Button = _find_slot_button(table, "creature_slot", "C5")
		_expect(destination != null and destination.text.contains("JUGAR AQUÍ"), "la quinta casilla real queda resaltada")
		if destination != null:
			destination.emit_signal("pressed")
		snapshot = table.debug_snapshot()
		_expect_equal(snapshot["creature_interaction"]["phase"], "MODE_SELECTION", "pulsar una casilla pide elegir ataque o guardia antes de COMMIT")
		_expect(snapshot["creature_mode_popup_visible"], "ataque o guardia aparece junto a la casilla")
		_expect(not snapshot["choice_overlay_visible"], "la elección de criatura ya no usa la ventana central")
		var summon_choice: Dictionary = {}
		for choice_action in table.get("_creature_interaction").candidate_actions:
			if choice_action["type"] == "summon_creature":
				summon_choice = choice_action
				break
		_expect(not summon_choice.is_empty(), "la elección directa conserva la invocación visible")
		if not summon_choice.is_empty():
			var choice_button: Button = _find_button_with_text(table.get("_creature_mode_buttons"), "ATAQUE")
			_expect(choice_button != null, "el menú contextual contiene un botón real de Ataque")
			if choice_button != null:
				choice_button.emit_signal("pressed")
		snapshot = table.debug_snapshot()
		_expect_equal(snapshot["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"], 1, "la criatura aparece en el tablero")
		var projected_card: Array = []
		_find_projected_pieces(table, projected_card)
		_expect(projected_card.any(func(piece: Control) -> bool: return piece.occupied and not piece.auxiliary and not piece.face_down), "la criatura en Ataque usa una superficie proyectada")
		_expect_equal(table.call("_visual_slot_for", "creatures", 0, selected_id), 4, "la criatura ocupa la casilla visual elegida")
		_expect_equal(snapshot["selected_card_id"], "", "una acción aplicada limpia la selección")
		var has_second_summon := false
		for action in snapshot["legal_actions"]:
			if action["type"] in ["summon_creature", "set_creature"]:
				has_second_summon = true
		_expect(not has_second_summon, "la mesa refleja el límite de invocación del turno")
	var test_save_path := "user://jcp_tests/manual_table.json"
	var saved_version: int = snapshot["state_version"]
	var saved_phase: String = snapshot["phase"]
	_expect(table.save_match(test_save_path), "la mesa guarda una partida iniciada")
	table.set_viewer(1, true)
	snapshot = table.debug_snapshot()
	_expect(snapshot["privacy_hidden"], "cambiar de jugador activa la cortina")
	_expect(not table.perform_legal_action(0), "la cortina bloquea acciones accidentales")
	table.call("_toggle_privacy")
	snapshot = table.debug_snapshot()
	_expect(not snapshot["privacy_hidden"], "el siguiente jugador puede revelar su vista")
	table.set_viewer(0, false)
	_expect(table.start_match(77), "una partida puede reiniciarse con otra semilla")
	snapshot = table.debug_snapshot()
	_expect_equal(snapshot["state_version"], 2, "reiniciar completa automáticamente Inicio y Robo")
	_expect_equal(snapshot["viewer_id"], 0, "reiniciar vuelve a la primera vista")
	table.get("_auto_follow").button_pressed = false
	table.call("_confirm_end_turn")
	snapshot = table.debug_snapshot()
	_expect_equal(snapshot["active_player"], 1, "terminar turno entrega el control al rival")
	_expect_equal(snapshot["phase"], "MAIN_1", "el turno rival también recibe Inicio y Robo automáticos")
	_expect_equal(snapshot["state_version"], 8, "terminar desde Principal 1 recorre las fases y la apertura siguiente")
	_expect(table.start_match(77), "la prueba puede restaurar una mesa limpia tras comprobar el final rápido")
	_expect(table.load_match(test_save_path), "la mesa carga y verifica la ranura guardada")
	snapshot = table.debug_snapshot()
	_expect(snapshot["privacy_hidden"], "cargar protege la vista con la cortina")
	_expect_equal(snapshot["state_version"], saved_version, "cargar recupera la versión exacta")
	_expect_equal(snapshot["phase"], saved_phase, "cargar recupera la fase exacta")
	table.call("_toggle_privacy")
	snapshot = table.debug_snapshot()
	var concede_index := -1
	for index in range(snapshot["legal_actions"].size()):
		if snapshot["legal_actions"][index]["type"] == "concede":
			concede_index = index
			break
	_expect(concede_index >= 0, "la mesa presenta la rendición legal")
	if concede_index >= 0:
		_expect(table.perform_legal_action(concede_index), "la rendición puede cerrar la partida")
		snapshot = table.debug_snapshot()
		_expect_equal(snapshot["lifecycle"], "FINISHED", "el motor queda terminado")
		_expect(snapshot["result_visible"], "la mesa presenta el resultado final")
		_expect(snapshot["result_text"].contains("GANA LA PARTIDA"), "el resultado identifica al ganador")
		_expect(snapshot["result_text"].contains("rendición"), "el resultado explica la rendición")
	_expect(table.start_match(991, {"starting_life": 3}), "la mesa prepara una partida completa de recorrido")
	table.get("_auto_follow").button_pressed = true
	var safety := 320
	while table.debug_snapshot()["lifecycle"] == "RUNNING" and safety > 0:
		safety -= 1
		snapshot = table.debug_snapshot()
		if snapshot["privacy_hidden"]:
			table.call("_toggle_privacy")
			snapshot = table.debug_snapshot()
		var preferred_index := _preferred_action_index(snapshot["legal_actions"], snapshot["phase"], snapshot["active_player"])
		if preferred_index < 0 or not table.perform_legal_action(preferred_index):
			break
	snapshot = table.debug_snapshot()
	_expect(safety > 0, "el recorrido completo no entra en un bucle")
	_expect_equal(snapshot["lifecycle"], "FINISHED", "una partida sin rendición llega al final desde la mesa")
	_expect(snapshot["result_visible"] and not snapshot["result_text"].is_empty(), "el final natural también muestra su resultado")
	_expect(snapshot["result_text"].contains("vida agotada"), "el final natural explica la derrota por vida")
	if FileAccess.file_exists(test_save_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save_path))
	table.queue_free()
	_finish()


func _advance_table_to_next_own_main(table: Control, player_id: int) -> bool:
	var engine = table.get("_engine")
	var initial_state: Dictionary = engine.export_module_state()
	var initial_turn: int = initial_state["turn"]["turn_number"]
	for step in range(24):
		var state: Dictionary = engine.export_module_state()
		var active: int = state["turn"]["order"][state["turn"]["active_index"]]
		if state["turn"]["turn_number"] > initial_turn and active == player_id and state["phase"]["current"] == "MAIN_1" and not state["turn_usage"]["terrain_used"]:
			table.call("_refresh")
			return true
		var result = engine.perform_action(GameAction.new("advance_phase", active, {}, "manual-terrain-advance-%02d" % step))
		if not result.success:
			return false
	table.call("_refresh")
	return false


func _finish() -> void:
	if _failures.is_empty():
		print("JCP-MANUAL-TABLE PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-MANUAL-TABLE FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])


func _preferred_action_index(actions: Array, phase: String, active_player: int) -> int:
	for forced_type in ["choose_fusion_combat_bonus", "decline_redirect", "redirect_attack", "pass_reaction"]:
		for index in range(actions.size()):
			if actions[index]["type"] == forced_type:
				return index
	if active_player == 1:
		for index in range(actions.size()):
			if actions[index]["type"] == "advance_phase":
				return index
	var priorities := [
		"fuse_creatures", "summon_creature", "set_creature", "set_support", "play_terrain",
		"equip_item", "play_persistent_spell", "play_main_spell", "activate_creature_ability",
		"activate_fusion_ability", "attack", "change_position", "advance_phase",
	]
	if phase == "COMBAT":
		priorities.erase("attack")
		priorities.push_front("attack")
	for action_type in priorities:
		for index in range(actions.size()):
			if actions[index]["type"] == action_type:
				return index
	return 0 if not actions.is_empty() else -1


func _check_field_row_geometry(table: Control, layer: Control, row_name: String, slot_role: String, band_index: int) -> void:
	var rows: Array = []
	_find_named_nodes(table, row_name, rows)
	_expect_equal(rows.size(), 1, "%s existe" % row_name)
	if rows.size() != 1:
		return
	var slots: Array = []
	var sides: Array = []
	for child in rows[0].get_children():
		if child.get_meta("board_role", "") == slot_role:
			slots.append(child)
		elif child.get_meta("board_role", "") in ["pile_zone", "terrain_lane"]:
			sides.append(child)
	_expect_equal(slots.size(), 5, "%s conserva cinco posiciones" % row_name)
	_expect_equal(sides.size(), 2, "%s conserva dos zonas laterales" % row_name)
	if slots.size() == 5:
		for slot_index in range(5):
			var expected: PackedVector2Array = layer.call("slot_corners", band_index, slot_index, false)
			var visual = _first_projected_piece(slots[slot_index])
			_expect(visual != null and visual.template_corners.size() == 4, "%s C%d tiene visual derivado de la plantilla" % [row_name, slot_index + 1])
			if visual != null and visual.template_corners.size() == 4:
				_expect(visual.projected_corners()[0].distance_to(expected[0] - slots[slot_index].position - visual.position) < 0.5, "%s C%d coincide con la banda medida" % [row_name, slot_index + 1])
	if sides.size() == 2:
		for side_index in range(2):
			var visual = _first_projected_piece(sides[side_index])
			var expected: PackedVector2Array = layer.call("side_corners", band_index, side_index == 1)
			_expect(visual != null and visual.template_corners.size() == 4, "%s lateral %d deriva de la banda" % [row_name, side_index])
			if visual != null and visual.template_corners.size() == 4:
				_expect(visual.projected_corners()[0].distance_to(expected[0] - sides[side_index].position - visual.position) < 0.5, "%s lateral %d coincide con la banda" % [row_name, side_index])


func _first_projected_piece(node: Node):
	for child in node.get_children():
		if child is ProjectedFieldPiece:
			return child
	return null


func _find_projected_pieces(node: Node, result: Array) -> void:
	if node is ProjectedFieldPiece:
		result.append(node)
	for child in node.get_children():
		_find_projected_pieces(child, result)


func _find_card_tile(node: Node, instance_id: String) -> Button:
	if node is Button and node.is_in_group("jcp_card_tiles") and node.get("instance_id") == instance_id:
		return node
	for child in node.get_children():
		var found := _find_card_tile(child, instance_id)
		if found != null:
			return found
	return null


func _find_slot_button(node: Node, role: String, text_fragment: String) -> Button:
	if node is Button and node.get_meta("board_role", "") == role and node.text.contains(text_fragment) and node.text.contains("JUGAR AQUÍ"):
		return node
	for child in node.get_children():
		var found := _find_slot_button(child, role, text_fragment)
		if found != null:
			return found
	return null


func _find_button_with_text(node: Node, text_fragment: String) -> Button:
	if node is Button and node.text.contains(text_fragment):
		return node
	for child in node.get_children():
		var found := _find_button_with_text(child, text_fragment)
		if found != null:
			return found
	return null


func _find_first_role_button(node: Node, role: String) -> Button:
	if node is Button and node.get_meta("board_role", "") == role:
		return node
	for child in node.get_children():
		var found := _find_first_role_button(child, role)
		if found != null:
			return found
	return null


func _find_named_nodes(node: Node, node_name: String, result: Array) -> void:
	if node.name == node_name:
		result.append(node)
	for child in node.get_children():
		_find_named_nodes(child, node_name, result)
