extends SceneTree
## Prueba cerrada de la primera capa: fases, turnos, energia y rendicion.
## Ejecutar con:
## godot --headless --path . --script res://tests/run_juego_cartas_propio_phases.gd

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("JCP-PHASES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-PHASES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), {
		"player_names": ["Lucia", "Alex"],
		"starting_life": 30,
		"energy_cap": 10,
		"starting_player": 0,
	})
	_expect(engine.is_ready(), "el modulo cumple el contrato universal")
	var start_result = engine.start(1412)
	_expect(start_result.success, "la partida arranca")
	if not start_result.success:
		_failures.append("arranque rechazado: %s — %s" % [start_result.code, start_result.message])
		return
	var view: Dictionary = engine.get_public_state()["game"]
	_expect_equal(view["active_player"], 0, "empieza el jugador configurado")
	_expect_equal(view["phase"], "START", "el turno comienza en Inicio")
	_expect_equal(view["life"], {"0": 30, "1": 30}, "ambos jugadores comienzan con 30 de vida")
	_expect_equal(view["energy"]["0"], {"maximum": 1, "available": 1}, "el jugador inicial recibe una energia")
	_expect_equal(view["energy"]["1"], {"maximum": 0, "available": 0}, "el rival aun no ha comenzado su turno")

	var wrong_actor = engine.perform_action(GameAction.new("advance_phase", 1, {}, "wrong-actor"))
	_expect(not wrong_actor.success, "el jugador inactivo no puede mover las fases")
	_expect_equal(wrong_actor.code, "JCP_WRONG_ACTOR", "el rechazo explica el actor incorrecto")

	var expected_phases := ["DRAW", "MAIN_1", "COMBAT", "MAIN_2", "END"]
	for index in range(expected_phases.size()):
		var result = engine.perform_action(GameAction.new("advance_phase", 0, {}, "p0-%d" % index))
		_expect(result.success, "el jugador 0 avanza la fase %d" % index)
		_expect_equal(engine.get_public_state()["game"]["phase"], expected_phases[index], "orden correcto de fases")
	var end_result = engine.perform_action(GameAction.new("advance_phase", 0, {}, "p0-end"))
	_expect(end_result.success, "Final entrega el turno")
	view = engine.get_public_state()["game"]
	_expect_equal(view["active_player"], 1, "el turno pasa al jugador 1")
	_expect_equal(view["phase"], "START", "el nuevo turno vuelve a Inicio")
	_expect_equal(view["energy"]["1"], {"maximum": 1, "available": 1}, "el jugador 1 recibe su primera energia")

	for index in range(6):
		var result = engine.perform_action(GameAction.new("advance_phase", 1, {}, "p1-%d" % index))
		_expect(result.success, "el jugador 1 completa su fase %d" % index)
	view = engine.get_public_state()["game"]
	_expect_equal(view["active_player"], 0, "la ronda vuelve al jugador 0")
	_expect_equal(view["round_number"], 2, "comienza la segunda ronda")
	_expect_equal(view["energy"]["0"], {"maximum": 2, "available": 2}, "la energia del jugador 0 aumenta y se rellena")

	var legal_p0: Array = engine.get_legal_actions(0)
	var legal_p1: Array = engine.get_legal_actions(1)
	_expect_equal(legal_p0.size(), 2, "el jugador activo ve avanzar y rendirse")
	_expect_equal(legal_p1.size(), 0, "el jugador inactivo no recibe acciones")
	var concede = engine.perform_action(GameAction.new("concede", 0, {}, "concede"))
	_expect(concede.success, "la rendicion se aplica")
	view = engine.get_public_state()["game"]
	_expect_equal(engine.lifecycle_name(), "FINISHED", "la rendicion termina la sesion")
	_expect_equal(view["winner_ids"], [1], "el rival es declarado ganador")
	_expect_equal(view["phase"], "FINISHED", "el modulo entra en la fase final")
	_expect(engine.validate_internal_consistency()["ok"], "el estado final conserva la integridad del motor")

	var deck_engine = UniversalCardEngine.new(GameModule.new(), {
		"player_names": ["Lucia", "Alex"],
		"starting_player": 0,
	})
	_expect(deck_engine.start(1412).success, "la partida de agotamiento arranca")
	var safety := 500
	while deck_engine.lifecycle_name() == "RUNNING" and safety > 0:
		safety -= 1
		var public_game: Dictionary = deck_engine.get_public_state()["game"]
		var actor: int = public_game["active_player"]
		var advance_action: Dictionary = {}
		for legal_action in deck_engine.get_legal_actions(actor):
			if legal_action["type"] == "advance_phase":
				advance_action = legal_action
				break
		if advance_action.is_empty():
			break
		var advanced = deck_engine.perform_action(GameAction.new(
			advance_action["type"], actor, advance_action["payload"], "deck-%d" % safety
		))
		if not advanced.success:
			break
	_expect(safety > 0, "el agotamiento de baraja no bloquea el flujo")
	view = deck_engine.get_public_state()["game"]
	_expect_equal(deck_engine.lifecycle_name(), "FINISHED", "intentar robar sin baraja termina la partida")
	_expect_equal(view["finished_reason"], "deck_empty", "el final identifica el agotamiento de baraja")
	_expect_equal(view["winner_ids"], [0], "el rival del jugador agotado gana")
	_expect_equal(view["phase"], "FINISHED", "el agotamiento entra en fase final")
	_expect_equal(deck_engine.get_legal_actions(0).size(), 0, "no quedan acciones tras agotarse la baraja")
	var deck_events: Array = deck_engine.get_events(0, -1)
	_expect(deck_events.any(func(event): return event["type"] == "player_deck_exhausted" and event["payload"]["player_id"] == 1), "el agotamiento emite un evento publico")
	var deck_replay: Dictionary = ReplayService.replay(GameModule.new(), deck_engine.export_runtime_snapshot()["config"], deck_engine.export_runtime_snapshot())
	_expect(deck_replay["ok"], "el final por agotamiento conserva replay exacto")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
