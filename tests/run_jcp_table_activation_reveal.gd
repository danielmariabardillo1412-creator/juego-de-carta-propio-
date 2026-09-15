extends SceneTree
## Una respuesta pública se presenta con ficha legible antes de continuar; ocultas no se anuncian.

const GameAction = preload("res://src/core/game_action.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	table.start_match(555)
	var hidden: Array = table.call("_activation_entries_from_events", [{"sequence": 1, "type": "support_set", "payload": {"player_id": 1, "definition_id": "G06"}}])
	if not hidden.is_empty():
		_fail("una carta solo preparada no puede anunciarse")
		return
	var chain: Array = table.call("_activation_entries_from_events", [
		{"sequence": 2, "type": "reaction_activated", "payload": {"player_id": 1, "definition_id": "T01"}},
		{"sequence": 3, "type": "reaction_activated", "payload": {"player_id": 0, "definition_id": "G06"}},
	])
	if chain.size() != 2 or chain[0]["definition_id"] != "T01" or chain[1]["definition_id"] != "G06":
		_fail("dos activaciones deben conservar su orden y ambos jugadores")
		return
	table.get("_activation_queue").append_array(chain)
	table.call("_show_next_activation")
	if not table.get("_activation_overlay").visible or not table.get("_activation_title").text.contains("TRAMPA"):
		_fail("la primera ficha de una cadena no aparece")
		return
	table.call("_advance_activation_reveal")
	if not table.get("_activation_overlay").visible or not table.get("_activation_title").text.contains("MAGIA"):
		_fail("la segunda ficha no espera su turno")
		return
	table.call("_clear_activation_reveal")
	var main_chain: Array = table.call("_activation_entries_from_events", [
		{"sequence": 4, "type": "main_spell_activated", "payload": {"player_id": 0, "definition_id": "G01"}},
		{"sequence": 5, "type": "main_spell_resolved", "payload": {"player_id": 0, "definition_id": "G01"}},
		{"sequence": 6, "type": "main_spell_resolved", "payload": {"player_id": 1, "definition_id": "G02"}},
	])
	if main_chain.size() != 2 or main_chain[0]["definition_id"] != "G01" or main_chain[1]["definition_id"] != "G02":
		_fail("una magia pendiente no debe mostrarse dos veces al resolverse")
		return
	table.call("_clear_activation_reveal")
	table.start_match(419)
	var main_engine = table.get("_engine")
	var main_state: Dictionary = main_engine.export_module_state()
	var main_creature := _find_hand(main_state, 0, "M01")
	var main_spell := _find_hand(main_state, 0, "G01")
	var summon_action: Dictionary = {}
	for legal in table.call("_legal_actions"):
		if legal["type"] == "summon_creature" and legal["payload"].get("instance_id", "") == main_creature:
			summon_action = legal
			break
	if main_creature.is_empty() or main_spell.is_empty() or summon_action.is_empty() or not table.call("_perform_action", summon_action):
		_fail("no se prepara la magia principal")
		return
	var spell_action: Dictionary = {}
	for legal in table.call("_legal_actions"):
		if legal["type"] == "play_main_spell" and legal["payload"].get("instance_id", "") == main_spell:
			spell_action = legal
			break
	if spell_action.is_empty() or not table.call("_perform_action", spell_action):
		_fail("G01 no se juega desde la mesa")
		return
	await process_frame
	await process_frame
	if not table.get("_activation_overlay").visible or not table.get("_activation_effect").text.contains("ATQ"):
		_fail("la magia principal G01 no muestra su ficha pública")
		return
	table.call("_clear_activation_reveal")
	table.start_match(555)
	var engine = table.get("_engine")
	var state: Dictionary = engine.export_module_state()
	var attacker := _find_hand(state, 0, "M01")
	var defender := _find_hand(state, 1, "M02")
	var trap := _find_hand(state, 1, "G06")
	if attacker.is_empty() or defender.is_empty() or trap.is_empty() or not _act(engine, "summon_creature", 0, {"instance_id": attacker}):
		_fail("no se prepara el atacante")
		return
	for i in range(4):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no avanza el turno inicial")
			return
	for i in range(2):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no abre turno rival")
			return
	if not _act(engine, "set_creature", 1, {"instance_id": defender}) or not _act(engine, "set_support", 1, {"instance_id": trap}):
		_fail("no prepara la respuesta rival")
		return
	for i in range(4):
		if not _act(engine, "advance_phase", 1, {}):
			_fail("no cierra turno rival")
			return
	for i in range(3):
		if not _act(engine, "advance_phase", 0, {}):
			_fail("no abre combate")
			return
	if not _act(engine, "attack", 0, {"attacker_id": attacker, "target_slot": 0}):
		_fail("no declara ataque")
		return
	table.set_viewer(1, false)
	var reaction: Dictionary = {}
	for legal in table.call("_legal_actions"):
		if legal["type"] == "activate_reaction":
			reaction = legal
			break
	if reaction.is_empty() or not table.call("_perform_action", reaction):
		_fail("la respuesta pública no se activa mediante la mesa")
		return
	await process_frame
	await process_frame
	var overlay: Control = table.get("_activation_overlay")
	var title: Label = table.get("_activation_title")
	var effect: Label = table.get("_activation_effect")
	if not overlay.visible or not title.text.contains("Carta rival") and not title.text.contains("Tu carta") or not title.text.contains("MAGIA") or not effect.text.contains("DEF"):
		_fail("la magia G06 no aparece ampliada con su efecto")
		return
	if table.get("_activation_timer").time_left <= 0.0:
		_fail("falta tiempo de lectura")
		return
	var capture := "res://artifacts/manual_table_activation_reveal.png"
	var saved: Error = root.get_texture().get_image().save_png(ProjectSettings.globalize_path(capture))
	if saved != OK:
		_fail("no se pudo guardar la captura")
		return
	await create_timer(4.2).timeout
	if overlay.visible or table.call("_activation_pause_active"):
		_fail("la presentación no avanza automáticamente tras la pausa de lectura")
		return
	table.set_viewer(0, true)
	var before_pass: int = engine.get_events(0, 0).size()
	table.call("_queue_public_activations", before_pass - 1)
	if overlay.visible or not table.get("_privacy_hidden"):
		_fail("la cortina de dos personas debe ocultar el anuncio")
		return
	table.call("_toggle_privacy")
	table.get("_ai_enabled").button_pressed = true
	table.call("_refresh")
	for i in range(4):
		await process_frame
	if not overlay.visible or not table.get("_activation_title").text.contains("Carta rival") or not table.get("_forced_pass_pending") or not engine.get_public_state()["game"]["response_window"]["active"]:
		_fail("el pase automático debe esperar mientras se lee la respuesta rival")
		return
	table.call("_advance_activation_reveal")
	for i in range(12):
		await process_frame
	var passed := false
	for event in engine.get_events(before_pass, 0):
		if event["type"] == "reaction_priority_passed" and event["payload"].get("player_id", -1) == 0:
			passed = true
	if not passed:
		_fail("el pase automático no continúa tras cerrar la ficha")
		return
	print("ACTIVATION_REVEAL PASS: ocultación, orden, ficha G06, temporizador, pausa IA y captura 1600x900")
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
	printerr("ACTIVATION_REVEAL FAIL: ", message)
	quit(1)
