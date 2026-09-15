extends SceneTree
## Sonda de entrada GUI para G01; la magia solo se confirma sobre criatura legal.

const CardTile = preload("res://demo/card_tile.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	table.start_match(419)
	await process_frame
	var hand: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	var creature_id := ""
	var spell_id := ""
	for card in hand:
		if card["definition"]["id"] == "M01":
			creature_id = card["instance"]["id"]
		if card["definition"]["id"] == "G01":
			spell_id = card["instance"]["id"]
	if creature_id.is_empty() or spell_id.is_empty():
		printerr("SPELL_GUI FAIL: seed 419 no contiene M01/G01")
		quit(1)
		return
	var summon := {}
	for action in table.debug_snapshot()["legal_actions"]:
		if action["type"] == "summon_creature" and action["payload"]["instance_id"] == creature_id:
			summon = action
			break
	if summon.is_empty() or not table.call("_perform_action", summon):
		printerr("SPELL_GUI FAIL: no se pudo invocar M01")
		quit(1)
		return
	await process_frame
	var hand_tile := _find_tile(table, spell_id)
	var field_tile := _find_tile(table, creature_id)
	if hand_tile == null or field_tile == null:
		_fail("faltan controles de carta")
		return
	var before_selection: int = table.debug_snapshot()["state_version"]
	await _click(hand_tile.get_global_rect().get_center())
	if table.debug_snapshot()["selected_card_id"] != spell_id or table.debug_snapshot()["state_version"] != before_selection:
		_fail("seleccionar G01 no debe jugarla sin objetivo")
		return
	if not table.get("_selection_label").text.contains("elige el objetivo"):
		_fail("falta instrucción del objetivo")
		return
	field_tile = _find_tile(table, creature_id)
	var before: int = table.debug_snapshot()["state_version"]
	await _click(field_tile.get_global_rect().get_center())
	var after: Dictionary = table.debug_snapshot()
	var zones: Dictionary = after["view"]["game"]["card_table"]["zones"]
	if after["state_version"] != before + 1 or zones["creatures:0"]["cards"][0]["effective_stats"]["attack"] != 4 or zones["graveyard:0"]["count"] != 1:
		_fail("G01 no modificó ATQ y/o no llegó al Cementerio")
		return
	if not table.get("_summary_label").text.contains("Magia dirigida"):
		_fail("el resultado de la magia no es visible")
		return
	print("SPELL_GUI PASS: objetivo obligatorio, ATQ 4, Cementerio 1 y mensaje visible")
	table.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("SPELL_GUI FAIL: ", message)
	quit(1)


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
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
