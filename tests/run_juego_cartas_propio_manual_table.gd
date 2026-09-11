extends SceneTree
## Integración mínima de la mesa local con UCE, vistas privadas, acciones legales y cortina de relevo.

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
	root.add_child(table)
	await process_frame
	var snapshot: Dictionary = table.debug_snapshot()
	_expect(snapshot["ready"], "la mesa construye el motor")
	_expect_equal(snapshot["lifecycle"], "RUNNING", "la mesa inicia una partida")
	_expect_equal(snapshot["module_version"], "0.24.0-stress-hardening", "la mesa usa el módulo vigente")
	_expect_equal(snapshot["viewer_id"], 0, "la vista inicial pertenece al jugador uno")
	_expect_equal(snapshot["phase"], "MAIN_1", "Inicio y Robo se resuelven automáticamente antes de entregar control")
	_expect_equal(snapshot["board_player_count"], 2, "se presentan ambos lados del tablero")
	_expect_equal(snapshot["visual_board_layout"], "perspective-opponent-divider-player", "la mesa usa perspectiva, separación central y lados enfrentados")
	_expect_equal(snapshot["creature_slot_count"], 10, "las diez casillas de criatura permanecen dibujadas")
	_expect_equal(snapshot["support_slot_count"], 10, "las diez casillas de apoyo permanecen dibujadas")
	_expect_equal(snapshot["terrain_lane_count"], 2, "cada jugador dispone de una franja territorial visible")
	_expect_equal(snapshot["side_pile_count"], 6, "Baraja, Cementerio y materiales de Fusión ocupan zonas laterales separadas")
	_expect(snapshot["rendered_card_count"] >= 5, "la mano visible se representa con componentes de carta")
	var hand_fans: Array = []
	_find_named_nodes(table, "HandFan", hand_fans)
	_expect_equal(hand_fans.size(), 2, "ambas manos tienen una fila visual")
	if hand_fans.size() == 2 and hand_fans[0].get_child_count() > 0 and hand_fans[1].get_child_count() > 0:
		_expect_equal(hand_fans[0].get_child(0).custom_minimum_size, hand_fans[1].get_child(0).custom_minimum_size, "las cartas rivales y propias usan exactamente el mismo tamaño")
	var empty_card_slot: Button = _find_first_role_button(table, "creature_slot")
	_expect(empty_card_slot != null and empty_card_slot.size.y > empty_card_slot.size.x, "las casillas vacías conservan proporción de carta")
	_expect(snapshot["rendered_action_count"] < snapshot["legal_action_count"], "la mesa absorbe acciones directas y el lateral no las duplica")
	_expect_equal(snapshot["phase_track_count"], 6, "el tablero muestra las seis fases del turno")
	_expect(not snapshot["event_expanded"], "el historial comienza plegado")
	var table_view: Dictionary = snapshot["view"]["game"]["card_table"]
	_expect_equal(table_view["zones"]["hand:0"]["cards"].size(), 5, "el propietario ve sus cinco cartas")
	_expect_equal(table_view["zones"]["hand:1"]["cards"].size(), 0, "la mano rival no revela identidades")
	_expect_equal(table_view["zones"]["hand:1"]["count"], 5, "la mano rival conserva su recuento público")
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
	_expect(table.call("_selection_instruction", [{"type": "equip_item", "actor_id": 0, "payload": {"instance_id": "TEST", "target_instance_id": "X"}}], visible_test).contains("no ocupa una casilla de Apoyo"), "el equipo dirigido no se presenta como apoyo libre")
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
		_expect(snapshot["choice_action_count"] >= 2, "pulsar una casilla pide elegir ataque o guardia")
		_expect(snapshot["choice_overlay_visible"], "ataque o guardia aparece sobre el tablero y no en el lateral")
		var summon_choice: Dictionary = {}
		for choice_action in table.get("_choice_actions"):
			if choice_action["type"] == "summon_creature":
				summon_choice = choice_action
				break
		_expect(not summon_choice.is_empty(), "la elección directa conserva la invocación visible")
		if not summon_choice.is_empty():
			var choice_button: Button = _find_button_with_text(table.get("_choice_overlay_list"), "Invocar")
			_expect(choice_button != null, "la ventana central contiene un botón de invocación real")
			if choice_button != null:
				choice_button.emit_signal("pressed")
		snapshot = table.debug_snapshot()
		_expect_equal(snapshot["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"], 1, "la criatura aparece en el tablero")
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
