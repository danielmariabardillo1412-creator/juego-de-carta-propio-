extends SceneTree
## Tras un ataque, el jugador sin ninguna reacción posible no debe quedar esperando un clic de pase.

const GameAction = preload("res://src/core/game_action.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	table.start_match(555)
	var engine = table.get("_engine")
	var state: Dictionary = engine.export_module_state()
	var attacker := _find_hand(state, 0, "M01")
	var defender := _find_hand(state, 1, "M02")
	var trap := _find_hand(state, 1, "G06")
	if attacker.is_empty() or defender.is_empty() or trap.is_empty() or not _act(engine, "summon_creature", 0, {"instance_id": attacker}):
		_fail("no se prepara atacante")
		return
	for i in range(4):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no avanza turno inicial")
			return
	for i in range(2):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no abre turno rival")
			return
	if not _act(engine, "set_creature", 1, {"instance_id": defender}) or not _act(engine, "set_support", 1, {"instance_id": trap}):
		_fail("no prepara defensor")
		return
	for i in range(4):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no cierra turno rival")
			return
	for i in range(3):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no abre ataques")
			return
	if not _act(engine, "attack", 0, {"attacker_id": attacker, "target_slot": 0}):
		_fail("no declara ataque")
		return
	var reaction: Dictionary = {}
	for legal in engine.get_legal_actions(1):
		if legal.type == "activate_reaction":
			reaction = {"type": legal.type, "payload": legal.payload}
			break
	if reaction.is_empty() or not _act(engine, reaction["type"], 1, reaction["payload"]):
		_fail("el rival no activa una respuesta y entrega prioridad")
		return
	var actions: Array = engine.get_legal_actions(0)
	for action in actions:
		if action.type not in ["pass_reaction", "concede"]:
			_fail("el caso de prueba contiene una reacción opcional")
			return
	table.get("_ai_enabled").button_pressed = true
	table.call("_refresh")
	for i in range(8):
		await process_frame
	var game: Dictionary = engine.get_public_state()["game"]
	if game["response_window"].get("active", false) or table.get("_end_turn_button").text != "TERMINAR TURNO":
		_fail("sin reacción disponible, la mesa dejó al jugador atrapado en Pasar respuesta")
		return
	var found := false
	for event in engine.get_events(0, 0):
		if event["type"] == "reaction_resolved" or event["type"] == "creature_combat_resolved":
			found = true
	if not found:
		_fail("la cadena de respuestas no se resolvió")
		return
	if not table.get("_summary_label").text.contains("Combate:") and not table.get("_summary_label").text.contains("Ataque cancelado"):
		_fail("la mesa no explica el resultado después de las respuestas: " + table.get("_summary_label").text)
		return
	print("UNCONTESTED_RESPONSE PASS: pase automático sin reacción y cadena resuelta")
	table.queue_free()
	quit(0)


func _find_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _act(engine, action_type: String, player_id: int, payload: Dictionary) -> bool:
	return engine.perform_action(GameAction.new(action_type, player_id, payload)).success


func _fail(message: String) -> void:
	printerr("UNCONTESTED_RESPONSE FAIL: ", message)
	quit(1)
