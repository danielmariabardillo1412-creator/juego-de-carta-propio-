extends SceneTree
## La selección incompleta no bloquea el fin de turno; una respuesta se puede pasar.

const GameAction = preload("res://src/core/game_action.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	if not table.start_match(555):
		_fail("no inicia semilla de respuesta")
		return
	var engine = table.get("_engine")
	var state: Dictionary = engine.export_module_state()
	var attacker: String = _find_hand(state, 0, "M01")
	var defender: String = _find_hand(state, 1, "M02")
	var trap: String = _find_hand(state, 1, "G06")
	if attacker.is_empty() or defender.is_empty() or trap.is_empty():
		_fail("la semilla no contiene la secuencia reproducible")
		return
	if not _act(engine, "summon_creature", 0, {"instance_id": attacker}):
		_fail("no invoca atacante")
		return
	for step in range(4):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no avanza fase atacante %d" % step)
			return
	for step in range(2):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no abre principal del defensor %d" % step)
			return
	if not _act(engine, "set_creature", 1, {"instance_id": defender}) or not _act(engine, "set_support", 1, {"instance_id": trap}):
		_fail("no prepara defensor y respuesta")
		return
	for step in range(4):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no cierra turno defensor %d" % step)
			return
	for step in range(3):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no abre combate atacante %d" % step)
			return
	if not _act(engine, "attack", 0, {"attacker_id": attacker, "target_slot": 0}):
		_fail("no declara ataque")
		return
	table.set_viewer(1, false)
	if not engine.get_public_state()["game"]["response_window"].get("active", false):
		_fail("no se abrió respuesta")
		return
	var end_button: Button = table.get("_end_turn_button")
	if end_button.disabled or end_button.text != "PASAR RESPUESTA":
		_fail("la respuesta no ofrece un pase visible")
		return
	var before: int = engine.state_version()
	table.call("_end_turn_pressed")
	if engine.state_version() != before + 1:
		_fail("el pase visible no envía pass_reaction")
		return
	if engine.get_public_state()["game"]["active_player"] != 0:
		_fail("pasar la respuesta no debe terminar el turno atacante")
		return
	print("END_TURN_RESPONSE PASS: una selección no bloquea turno y la respuesta se pasa explícitamente")
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
	printerr("END_TURN_RESPONSE FAIL: ", message)
	quit(1)
