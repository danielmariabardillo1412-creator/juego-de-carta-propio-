extends SceneTree
## La postura se ofrece al lado de la carta y solo UCE decide cuándo se puede cambiar.

const CardTile = preload("res://demo/card_tile.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	var summon := _first_action(table.debug_snapshot()["legal_actions"], "summon_creature")
	if summon.is_empty() or not table.call("_perform_action", summon):
		_fail("no se pudo invocar la criatura de prueba")
		return
	var creature_id: String = summon["payload"]["instance_id"]
	await _click(_find_tile(table, creature_id).get_global_rect().get_center())
	var posture: Button = table.find_child("CreaturePostureAction", true, false)
	if posture == null or not posture.disabled or not posture.text.contains("Guardia"):
		_fail("el primer turno de la criatura no debe permitir cambio voluntario")
		return
	table.call("_confirm_end_turn")
	table.set_viewer(1, false)
	table.call("_confirm_end_turn")
	table.set_viewer(0, false)
	await process_frame
	var field_tile: CardTile = _find_tile(table, creature_id)
	if field_tile == null:
		var missing: Dictionary = table.debug_snapshot()
		_fail("la criatura no se dibuja: vista=%s fase=%s oculto=%s turno=%s render=%s" % [missing["viewer_id"], missing["phase"], missing["privacy_hidden"], missing["active_player"], missing["rendered_card_count"]])
		return
	await _click(field_tile.get_global_rect().get_center())
	posture = table.find_child("CreaturePostureAction", true, false)
	if posture == null or posture.disabled or posture.text != "Pasar a Guardia":
		_fail("el menú local no ofrece pasar a Guardia en el turno posterior")
		return
	var before: int = table.debug_snapshot()["state_version"]
	await _click(posture.get_global_rect().get_center())
	var after: Dictionary = table.debug_snapshot()
	var field_cards: Array = after["view"]["game"]["card_table"]["zones"]["creatures:0"]["cards"]
	if after["state_version"] != before + 1 or field_cards.size() != 1 or field_cards[0]["instance"]["metadata"]["position"] != "guard" or not field_cards[0]["instance"]["metadata"]["face_up"]:
		_fail("Cambiar postura no ejecutó una única acción UCE a Guardia visible")
		return
	await _click(_find_tile(table, creature_id).get_global_rect().get_center())
	posture = table.find_child("CreaturePostureAction", true, false)
	if posture == null or not posture.disabled:
		_fail("el mismo turno no permite un segundo cambio voluntario")
		return
	print("POSTURE_GUI PASS: menú local, bloqueo al entrar y cambio legal a Guardia mediante UCE")
	table.queue_free()
	quit(0)


func _first_action(actions: Array, kind: String) -> Dictionary:
	for action in actions:
		if action["type"] == kind:
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


func _fail(message: String) -> void:
	printerr("POSTURE_GUI FAIL: ", message)
	quit(1)
