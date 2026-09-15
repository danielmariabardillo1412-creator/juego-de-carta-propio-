extends SceneTree
## Regresión de intención visual de criatura; solo UCE puede confirmar la jugada.

const CardTile = preload("res://demo/card_tile.gd")
const CreatureDropSlot = preload("res://demo/creature_drop_slot.gd")
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	_expect(scene != null, "la escena de mesa carga")
	if scene == null:
		_finish(null)
		return
	var table = scene.instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	var initial: Dictionary = table.debug_snapshot()
	var source_id := _first_creature_id(initial["legal_actions"])
	_expect(not source_id.is_empty(), "hay una criatura jugable en la mano")
	if source_id.is_empty():
		_finish(table)
		return
	var original_version: int = initial["state_version"]
	var original_requests: int = initial["request_number"]
	var original_hand: int = initial["view"]["game"]["card_table"]["zones"]["hand:0"]["count"]
	var original_energy: int = initial["view"]["game"]["players"][0]["energy"] if initial["view"]["game"].has("players") else -1
	var hand_tile := _find_tile(table, source_id)
	_expect(hand_tile != null, "la criatura jugable tiene carta frontal de mano")
	if hand_tile != null:
		hand_tile.emit_signal("pressed")
	var selected: Dictionary = table.debug_snapshot()
	_expect_equal(selected["creature_interaction"]["phase"], "TARGET_SELECTION", "primer clic entra en selección de destino")
	_expect_equal(selected["creature_interaction"]["source_id"], source_id, "el estado recuerda la fuente")
	_expect_equal(selected["creature_interaction"]["legal_destinations"], [0, 1, 2, 3, 4], "solo las cinco casillas vacías son destinos")
	_expect_equal(_count_highlighted_empty(table), 5, "solo cinco casillas legales se resaltan")
	_expect_equal(selected["state_version"], original_version, "seleccionar no muta UCE")
	_expect_equal(selected["request_number"], original_requests, "seleccionar no envía comando UCE")
	_expect_equal(selected["view"]["game"]["card_table"]["zones"]["hand:0"]["count"], original_hand, "la criatura permanece en mano")
	if original_energy >= 0:
		_expect_equal(selected["view"]["game"]["players"][0]["energy"], original_energy, "seleccionar no gasta Energía")
	_expect(not table.get("_end_turn_button").disabled, "Terminar turno sigue disponible con acción incompleta")
	table.call("_end_turn_pressed")
	_expect(table.get("_end_turn_dialog").visible, "Terminar turno abre confirmación aun con selección pendiente")
	table.get("_end_turn_dialog").hide()
	_expect_equal(table.debug_snapshot()["state_version"], original_version, "abrir confirmación no muta UCE")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	table.call("_input", escape)
	_check_idle(table, original_version, "Escape")
	_expect_equal(_count_highlighted_empty(table), 0, "Escape retira los resaltados")
	table.call("_select_card", source_id)
	var blank := InputEventMouseButton.new()
	blank.button_index = MOUSE_BUTTON_LEFT
	blank.pressed = true
	blank.global_position = table.get("_board_surface").get_global_rect().position + Vector2(20, 230)
	table.call("_input", blank)
	_check_idle(table, original_version, "clic en espacio vacío")
	_expect_equal(_count_highlighted_empty(table), 0, "clic fuera retira los resaltados")
	var alternate := _find_seed_with_two_creatures(table)
	_expect(alternate["seed"] >= 0, "existe una apertura reproducible con dos criaturas jugables")
	if alternate["seed"] >= 0:
		var first: String = alternate["ids"][0]
		var second: String = alternate["ids"][1]
		var before_swap: int = table.debug_snapshot()["state_version"]
		table.call("_select_card", first)
		table.call("_select_card", second)
		var swapped: Dictionary = table.debug_snapshot()
		_expect_equal(swapped["creature_interaction"]["source_id"], second, "otra criatura jugable sustituye la fuente")
		_expect_equal(swapped["selected_card_id"], second, "no queda selección anterior")
		_expect_equal(swapped["state_version"], before_swap, "sustituir selección no muta UCE")
	table.start_match(210921)
	await process_frame
	source_id = _first_creature_id(table.debug_snapshot()["legal_actions"])
	original_version = table.debug_snapshot()["state_version"]
	original_requests = table.debug_snapshot()["request_number"]
	table.call("_select_card", source_id)
	table.call("_choose_creature_slot", 8)
	_expect_equal(table.debug_snapshot()["state_version"], original_version, "casilla ilegal no hace COMMIT")
	_expect_equal(table.debug_snapshot()["request_number"], original_requests, "casilla ilegal no envía acción")
	table.call("_on_empty_slot_pressed", 0, "creatures", 2)
	await process_frame
	var pending: Dictionary = table.debug_snapshot()
	_expect_equal(pending["creature_interaction"]["phase"], "MODE_SELECTION", "C3 abre selección contextual de modo")
	_expect(pending["creature_mode_popup_visible"], "el menú de criatura aparece")
	_expect(not pending["choice_overlay_visible"], "la ventana central permanece oculta")
	_expect_equal(pending["state_version"], original_version, "elegir destino todavía no muta")
	_expect_equal(pending["request_number"], original_requests, "elegir destino todavía no envía acción")
	_expect(not table.get("_end_turn_button").disabled, "Terminar turno sigue disponible al elegir modo")
	var attack := _candidate(pending, table, "summon_creature")
	var guard := _candidate(pending, table, "set_creature")
	_expect(not attack.is_empty() and not guard.is_empty(), "UCE ofrece dos modos legales exactos")
	if not attack.is_empty():
		table.call("_commit_creature_mode", attack)
	var attack_done: Dictionary = table.debug_snapshot()
	_expect_equal(attack_done["request_number"], original_requests + 1, "Ataque envía exactamente un comando")
	_expect_equal(attack_done["state_version"], original_version + 1, "Ataque muta exactamente al COMMIT")
	_expect_equal(attack_done["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"], 1, "Ataque coloca una criatura")
	_expect_equal(attack_done["creature_interaction"]["phase"], "IDLE", "Ataque vuelve a IDLE")
	_expect_equal(table.call("_visual_slot_for", "creatures", 0, source_id), 2, "Ataque conserva C3")
	var click_command: Dictionary = attack_done["last_committed_action"]
	table.start_match(210921)
	await process_frame
	source_id = _first_creature_id(table.debug_snapshot()["legal_actions"])
	original_requests = table.debug_snapshot()["request_number"]
	table.call("_select_card", source_id)
	table.call("_on_empty_slot_pressed", 0, "creatures", 2)
	guard = _candidate(table.debug_snapshot(), table, "set_creature")
	if not guard.is_empty():
		table.call("_commit_creature_mode", guard)
	var guard_done: Dictionary = table.debug_snapshot()
	_expect_equal(guard_done["request_number"], original_requests + 1, "Guardia envía exactamente un comando")
	_expect_equal(guard_done["creature_interaction"]["phase"], "IDLE", "Guardia vuelve a IDLE")
	_expect_equal(guard_done["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"], 1, "Guardia coloca una criatura")
	_expect(_has_guard(table), "Guardia utiliza una pieza proyectada boca abajo")
	table.start_match(210921)
	await process_frame
	source_id = _first_creature_id(table.debug_snapshot()["legal_actions"])
	original_version = table.debug_snapshot()["state_version"]
	original_requests = table.debug_snapshot()["request_number"]
	var legal_slot: Control = table.call("_field_slot", "creatures", 2)
	_expect(legal_slot is CreatureDropSlot, "C3 acepta el contrato de arrastre")
	if legal_slot is CreatureDropSlot:
		_expect(legal_slot._can_drop_data(Vector2.ZERO, {"kind": "creature_from_hand", "instance_id": source_id}), "C3 acepta la criatura legal")
		_expect(not legal_slot._can_drop_data(Vector2.ZERO, {"kind": "creature_from_hand", "instance_id": "ILEGAL"}), "C3 rechaza una carta ajena")
	table.call("_on_creature_drag_started", source_id)
	_expect_equal(table.debug_snapshot()["creature_interaction"]["phase"], "TARGET_SELECTION", "drag alimenta el mismo estado de destino")
	table.call("_on_creature_drag_failed", source_id)
	_check_idle(table, original_version, "drag fuera de casilla legal")
	_expect_equal(table.debug_snapshot()["request_number"], original_requests, "drag fallido no envía acción")
	table.call("_on_creature_drag_started", source_id)
	table.call("_on_creature_dropped", source_id, 0, 2)
	var drag_pending: Dictionary = table.debug_snapshot()
	_expect_equal(drag_pending["creature_interaction"]["phase"], "MODE_SELECTION", "drag legal llega al mismo modo pendiente")
	_expect_equal(drag_pending["state_version"], original_version, "soltar con dos modos no muta")
	attack = _candidate(drag_pending, table, "summon_creature")
	if not attack.is_empty():
		table.call("_commit_creature_mode", attack)
	var drag_done: Dictionary = table.debug_snapshot()
	_expect_equal(drag_done["last_committed_action"], click_command, "clic y drag generan el mismo comando final")
	_expect_equal(drag_done["request_number"], original_requests + 1, "drag legal confirma una sola vez")
	_expect_equal(drag_done["creature_interaction"]["phase"], "IDLE", "drag legal vuelve a IDLE")
	table.start_match(210921)
	await process_frame
	source_id = _first_creature_id(table.debug_snapshot()["legal_actions"])
	table.call("_select_card", source_id)
	_expect_equal(table.debug_snapshot()["creature_interaction"]["phase"], "TARGET_SELECTION", "hay una invocación a medias antes de terminar")
	table.call("_confirm_end_turn")
	var ended: Dictionary = table.debug_snapshot()
	_expect_equal(ended["creature_interaction"]["phase"], "IDLE", "terminar cancela la invocación a medias")
	_expect_equal(ended["view"]["game"]["active_player"], 1, "terminar entrega el turno al rival")
	_finish(table)


func _first_creature_id(actions: Array) -> String:
	for action in actions:
		if action["type"] == "summon_creature":
			return action["payload"]["instance_id"]
	return ""


func _find_seed_with_two_creatures(table: Node) -> Dictionary:
	for seed in range(1, 201):
		table.start_match(seed)
		var ids: Array = table.call("_legal_creature_source_ids")
		if ids.size() >= 2:
			return {"seed": seed, "ids": ids}
	return {"seed": -1, "ids": []}


func _candidate(_snapshot: Dictionary, table: Node, action_type: String) -> Dictionary:
	for action in table.get("_creature_interaction").candidate_actions:
		if action["type"] == action_type:
			return action
	return {}


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
		if found != null:
			return found
	return null


func _count_highlighted_empty(node: Node) -> int:
	var count := 1 if node is ProjectedFieldPiece and node.highlighted and not node.occupied else 0
	for child in node.get_children():
		count += _count_highlighted_empty(child)
	return count


func _has_guard(node: Node) -> bool:
	if node is ProjectedFieldPiece and node.occupied and node.guard and node.face_down:
		return true
	for child in node.get_children():
		if _has_guard(child):
			return true
	return false


func _check_idle(table: Node, version: int, label: String) -> void:
	var snapshot: Dictionary = table.debug_snapshot()
	_expect_equal(snapshot["creature_interaction"]["phase"], "IDLE", "%s vuelve a IDLE" % label)
	_expect_equal(snapshot["selected_card_id"], "", "%s limpia la fuente" % label)
	_expect_equal(snapshot["state_version"], version, "%s no muta UCE" % label)
	_expect(not table.get("_end_turn_button").disabled, "%s rehabilita Terminar turno" % label)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_expect(actual == expected, "%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])


func _finish(table: Node) -> void:
	if table != null:
		table.queue_free()
	if _failures.is_empty():
		print("JCP-CREATURE-UX PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-CREATURE-UX FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
