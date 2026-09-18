extends SceneTree
## Distingue equipo E02 dirigido y persistente G04 global desde la mesa.

const CardTile = preload("res://demo/card_tile.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	if not await _test_equipment():
		quit(1)
		return
	if not await _test_persistent():
		quit(1)
		return
	print("BOOST_GUI PASS: E02 click/drag equivalentes, inspeccionable, adjuntos múltiples y G04 automático")
	quit(0)


func _test_equipment() -> bool:
	var table = await _new_table(487)
	var hand: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	var creature_id := _id_by_definition(hand, "M01")
	var item_id := _id_by_definition(hand, "E02")
	if creature_id.is_empty() or item_id.is_empty():
		return _fail("seed 487 no contiene M01/E02")
	var summon := _action_for(table, "summon_creature", creature_id)
	if summon.is_empty() or not table.call("_perform_action", summon):
		return _fail("no se pudo invocar M01")
	await process_frame
	var before_def: int = _creature(table, creature_id)["effective_stats"]["defense"]
	var item_tile: CardTile = _find_tile(table, item_id)
	if item_tile == null:
		return _fail("E02 no aparece en mano")
	await _click(item_tile.get_global_rect().get_center())
	if not table.get("_selection_label").text.contains("NO lo coloques en Apoyo"):
		return _fail("E02 no explica su destino")
	var target: CardTile = _find_tile(table, creature_id)
	var before_version: int = table.debug_snapshot()["state_version"]
	await _click(target.get_global_rect().get_center())
	var after: Dictionary = table.debug_snapshot()
	if after["state_version"] != before_version + 1 or after["view"]["game"]["card_table"]["zones"]["attachments:0"]["count"] != 1:
		return _fail("E02 no se vinculó al objetivo elegido")
	var click_command: Dictionary = after["last_committed_action"].duplicate(true)
	if _creature(table, creature_id)["effective_stats"]["defense"] != before_def + 1:
		return _fail("E02 no aplicó +1 DEF")
	var equipment_chip: Button = _find_equipment_chip(table, item_id)
	if equipment_chip == null or not equipment_chip.tooltip_text.contains("Objeto E02"):
		return _fail("el Equipo vinculado no queda representado como adjunto inspeccionable")
	await _click(equipment_chip.get_global_rect().get_center())
	var inspected: Dictionary = table.debug_snapshot()
	if inspected["selected_card_id"] != item_id or not inspected["card_detail_text"].contains("Objeto E02"):
		return _fail("pulsar el adjunto no abre la ficha del Equipo")
	var synthetic_strip: Control = table.call("_build_equipment_strip", [
		{"instance": {"id": "EQ-A"}, "definition": {"attributes": {"display_name": "Espada Simple"}}},
		{"instance": {"id": "EQ-B"}, "definition": {"attributes": {"display_name": "Coraza Pesada"}}},
	], creature_id)
	if synthetic_strip.get_child_count() != 2:
		return _fail("dos Equipos vinculados no producen dos adjuntos independientes")
	if synthetic_strip.get_child(0).get_meta("equipment_instance_id", "") != "EQ-A" or synthetic_strip.get_child(1).get_meta("equipment_instance_id", "") != "EQ-B":
		return _fail("los adjuntos múltiples pierden identidad individual")
	if synthetic_strip.get_child(0).text != "⚒1" or synthetic_strip.get_child(1).text != "⚒2":
		return _fail("los adjuntos múltiples no se compactan de forma legible")
	synthetic_strip.free()
	table.queue_free()
	await process_frame

	var drag_table = await _new_table(487)
	var drag_hand: Array = drag_table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	var drag_creature_id := _id_by_definition(drag_hand, "M01")
	var drag_item_id := _id_by_definition(drag_hand, "E02")
	var drag_summon := _action_for(drag_table, "summon_creature", drag_creature_id)
	if drag_summon.is_empty() or not drag_table.call("_perform_action", drag_summon):
		return _fail("no se pudo preparar M01 para la prueba de drag de E02")
	await process_frame
	var drag_item: CardTile = _find_tile(drag_table, drag_item_id)
	var drag_target: CardTile = _find_tile(drag_table, drag_creature_id)
	if drag_item == null or drag_target == null:
		return _fail("faltan origen o destino visual para arrastrar E02")
	if not drag_item.get("_equipment_drag_enabled") or drag_item_id not in drag_target.get("_equipment_drop_sources"):
		return _fail("E02 no expone drag solo hacia su portador legal")
	var drag_before: int = drag_table.debug_snapshot()["state_version"]
	await _drag(drag_item.get_global_rect().get_center(), drag_target.get_global_rect().get_center())
	var drag_after: Dictionary = drag_table.debug_snapshot()
	if drag_after["state_version"] != drag_before + 1 or drag_after["view"]["game"]["card_table"]["zones"]["attachments:0"]["count"] != 1:
		return _fail("arrastrar E02 no ejecuta un único equip_item")
	if drag_after["last_committed_action"] != click_command:
		return _fail("drag y click-click no producen exactamente el mismo comando UCE de Equipo")
	drag_table.queue_free()
	await process_frame
	return true


func _test_persistent() -> bool:
	var table = await _new_table(2512)
	var hand: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	var creature_id := _id_by_definition(hand, "M02")
	var spell_id := _id_by_definition(hand, "G04")
	if creature_id.is_empty() or spell_id.is_empty():
		return _fail("seed 2512 no contiene M02/G04")
	var spell_tile: CardTile = _find_tile(table, spell_id)
	await _click(spell_tile.get_global_rect().get_center())
	if not table.get("_selection_label").text.contains("TODAS tus criaturas en Guardia"):
		return _fail("G04 no explica su efecto global")
	var support_slot: Control = _find_own_support_slot(table)
	if support_slot == null:
		return _fail("no aparece casilla propia de Apoyo")
	await _click(support_slot.get_global_rect().get_center())
	if table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["support:0"]["count"] != 1:
		return _fail("G04 no llegó a Apoyo")
	if not table.get("_summary_label").text.contains("Bastión activo"):
		return _fail("no se anuncia el efecto automático de G04")
	var set_action := _action_for(table, "set_creature", creature_id)
	if set_action.is_empty() or not table.call("_perform_action", set_action):
		return _fail("M02 no pudo colocarse en Guardia")
	var card: Dictionary = _creature(table, creature_id)
	if card["effective_stats"]["defense"] != card["effective_stats"]["base_defense"] + 1:
		return _fail("G04 no añade +1 DEF a Guardia automáticamente")
	table.queue_free()
	await process_frame
	return true


func _new_table(seed: int):
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	table.start_match(seed)
	await process_frame
	return table


func _id_by_definition(cards: Array, definition_id: String) -> String:
	for card in cards:
		if card["definition"]["id"] == definition_id:
			return card["instance"]["id"]
	return ""


func _action_for(table, action_type: String, instance_id: String) -> Dictionary:
	for action in table.debug_snapshot()["legal_actions"]:
		if action["type"] == action_type and action["payload"].get("instance_id", "") == instance_id:
			return action
	return {}


func _creature(table, instance_id: String) -> Dictionary:
	for card in table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["creatures:0"]["cards"]:
		if card["instance"]["id"] == instance_id:
			return card
	return {}


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
		if found != null:
			return found
	return null


func _find_equipment_chip(node: Node, instance_id: String) -> Button:
	if node is Button and node.get_meta("board_role", "") == "equipment_chip" and node.get_meta("equipment_instance_id", "") == instance_id:
		return node
	for child in node.get_children():
		var found := _find_equipment_chip(child, instance_id)
		if found != null:
			return found
	return null


func _find_own_support_slot(node: Node) -> Control:
	if node is Control and node.get_meta("board_role", "") == "support_slot":
		var ancestor := node.get_parent()
		while ancestor != null:
			if ancestor.name == "PlayerSupportRow":
				return node
			ancestor = ancestor.get_parent()
	for child in node.get_children():
		var found := _find_own_support_slot(child)
		if found != null:
			return found
	return null


func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.position = point
	up.global_position = point
	up.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(up)
	await process_frame


func _drag(origin: Vector2, target: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = origin
	down.global_position = origin
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	for fraction in [0.12, 0.45, 0.72, 1.0]:
		var motion := InputEventMouseMotion.new()
		motion.position = origin.lerp(target, fraction)
		motion.global_position = motion.position
		motion.relative = (target - origin) * 0.25
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
	var up := InputEventMouseButton.new()
	up.position = target
	up.global_position = target
	up.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _fail(message: String) -> bool:
	printerr("BOOST_GUI FAIL: ", message)
	return false
