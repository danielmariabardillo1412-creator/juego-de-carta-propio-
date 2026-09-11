extends SceneTree
## Verifica colocacion oculta, privacidad y cambio de postura de criaturas.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("JCP-POSTURES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-POSTURES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var engine = _engine_with_affordable_opening()
	_expect(engine != null, "se encuentra una apertura con criatura de coste 1")
	if engine == null:
		return
	_expect(_advance(engine, 0), "el jugador entra en Robo")
	_expect(_advance(engine, 0), "el jugador entra en Principal 1")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_affordable_creature(state, 0)
	_expect(not creature_id.is_empty(), "la criatura asequible esta disponible")
	if creature_id.is_empty():
		return
	var definition_id: String = state["cards"]["instances"][creature_id]["definition_id"]
	var display_name: String = state["cards"]["definitions"][definition_id]["attributes"]["display_name"]
	var cost: int = state["cards"]["definitions"][definition_id]["attributes"]["cost"]
	var energy_before: int = state["energy"]["0"]["available"]

	var set_result = engine.perform_action(GameAction.new(
		"set_creature",
		0,
		{"instance_id": creature_id},
		_next_request("set")
	))
	_expect(set_result.success, "la criatura se coloca boca abajo")
	state = engine.export_module_state()
	var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
	_expect(not metadata["face_up"], "la carta queda marcada como oculta")
	_expect_equal(metadata["position"], "guard", "la carta oculta entra en guardia")
	_expect_equal(state["energy"]["0"]["available"], energy_before - cost, "colocar tambien paga energia")
	_expect_equal(state["cards"]["zones"]["creatures:0"]["cards"], [creature_id], "la carta ocupa una plaza de criatura")

	var public_table: Dictionary = engine.get_public_state()["game"]["card_table"]
	var rival_table: Dictionary = engine.get_player_state(1)["game"]["card_table"]
	var owner_table: Dictionary = engine.get_player_state(0)["game"]["card_table"]
	_expect_hidden_zone(public_table, "el publico")
	_expect_hidden_zone(rival_table, "el rival")
	_expect_equal(owner_table["zones"]["creatures:0"]["cards"].size(), 1, "el propietario ve su criatura oculta")
	_expect_equal(owner_table["zones"]["creatures:0"]["cards"][0]["definition"]["id"], definition_id, "el propietario conserva la identidad")
	var public_text := JSON.stringify(public_table)
	var rival_text := JSON.stringify(rival_table)
	_expect(not public_text.contains(creature_id) and not public_text.contains(display_name), "la vista publica no filtra identidad ni nombre")
	_expect(not rival_text.contains(creature_id) and not rival_text.contains(display_name), "la vista rival no filtra identidad ni nombre")

	var public_events: Array = engine.get_events(0, -1)
	var rival_events: Array = engine.get_events(0, 1)
	var owner_events: Array = engine.get_events(0, 0)
	_expect_equal(_count_events(public_events, "private_creature_set"), 0, "el publico no recibe el aviso privado")
	_expect_equal(_count_events(rival_events, "private_creature_set"), 0, "el rival no recibe el aviso privado")
	_expect_equal(_count_events(owner_events, "private_creature_set"), 1, "el propietario recibe el aviso privado")
	var public_event_text := JSON.stringify(public_events)
	var rival_event_text := JSON.stringify(rival_events)
	_expect(not public_event_text.contains(creature_id) and not public_event_text.contains(definition_id), "los eventos publicos no filtran la carta colocada")
	_expect(not rival_event_text.contains(creature_id) and not rival_event_text.contains(definition_id), "los eventos rivales no filtran la carta colocada")

	var premature = engine.perform_action(GameAction.new(
		"change_position",
		0,
		{"instance_id": creature_id, "target_position": "attack"},
		_next_request("premature")
	))
	_expect(not premature.success, "no se revela durante el turno en que entra")
	_expect_equal(premature.code, "JCP_POSITION_SUMMONED_THIS_TURN", "el rechazo identifica el limite de entrada")

	# Completa el turno de jugador 0 y el turno entero de jugador 1.
	for index in range(4):
		_expect(_advance(engine, 0), "el jugador 0 completa su turno (%d)" % index)
	for index in range(6):
		_expect(_advance(engine, 1), "el jugador 1 completa su turno (%d)" % index)
	_expect(_advance(engine, 0), "el jugador 0 entra en Robo en su segundo turno")
	_expect(_advance(engine, 0), "el jugador 0 vuelve a Principal 1")

	var legal_actions: Array = engine.get_legal_actions(0)
	_expect(_has_position_action(legal_actions, creature_id, "attack"), "la accion legal ofrece revelar y pasar a ataque")
	var reveal = engine.perform_action(GameAction.new(
		"change_position",
		0,
		{"instance_id": creature_id, "target_position": "attack"},
		_next_request("reveal")
	))
	_expect(reveal.success, "la criatura se revela en un turno posterior")
	state = engine.export_module_state()
	metadata = state["cards"]["instances"][creature_id]["metadata"]
	_expect(metadata["face_up"], "la criatura queda boca arriba")
	_expect_equal(metadata["position"], "attack", "la criatura pasa a ataque")
	public_table = engine.get_public_state()["game"]["card_table"]
	_expect_equal(public_table["zones"]["creatures:0"]["cards"].size(), 1, "la criatura revelada ya es publica")
	_expect_equal(public_table["zones"]["creatures:0"]["cards"][0]["definition"]["id"], definition_id, "la revelacion publica la identidad correcta")

	var second_change = engine.perform_action(GameAction.new(
		"change_position",
		0,
		{"instance_id": creature_id, "target_position": "guard"},
		_next_request("second-change")
	))
	_expect(not second_change.success, "no se cambia dos veces en el mismo turno")
	_expect_equal(second_change.code, "JCP_POSITION_ALREADY_CHANGED", "el segundo cambio tiene un rechazo explicito")
	_expect(CardState.validate(state["cards"])["ok"], "las cartas se conservan tras colocar y revelar")
	_expect(engine.validate_internal_consistency()["ok"], "el motor mantiene su integridad")
	_attack_then_main2_does_not_advertise_position_change()


func _attack_then_main2_does_not_advertise_position_change() -> void:
	var engine = _engine_with_affordable_opening()
	_expect(engine != null, "se prepara el escenario de postura posterior al ataque")
	if engine == null:
		return
	_expect(_advance(engine, 0) and _advance(engine, 0), "el escenario entra en Principal 1")
	var creature_id := _find_affordable_creature(engine.export_module_state(), 0)
	var summoned = engine.perform_action(GameAction.new(
		"summon_creature", 0, {"instance_id": creature_id}, _next_request("attack-summon")
	))
	_expect(summoned.success, "la criatura atacante entra boca arriba")
	for _index in range(4):
		_expect(_advance(engine, 0), "el atacante completa su primer turno")
	for _index in range(6):
		_expect(_advance(engine, 1), "el rival completa su turno")
	_expect(_advance(engine, 0) and _advance(engine, 0) and _advance(engine, 0), "el atacante alcanza Combate en su segundo turno")
	var attack = engine.perform_action(GameAction.new(
		"attack", 0, {"attacker_id": creature_id, "target_slot": -1}, _next_request("attack")
	))
	_expect(attack.success, "la criatura declara un ataque directo")
	for player_id in [1, 0]:
		if _has_action_type(engine.get_legal_actions(player_id), "pass_reaction"):
			_expect(engine.perform_action(GameAction.new("pass_reaction", player_id, {}, _next_request("pass"))).success, "se cierra la respuesta opcional al ataque")
	_expect(_advance(engine, 0), "la partida entra en Principal 2")
	_expect(not _has_position_action(engine.get_legal_actions(0), creature_id, "guard"), "Principal 2 no anuncia el cambio prohibido tras atacar")
	var rejected = engine.perform_action(GameAction.new(
		"change_position", 0, {"instance_id": creature_id, "target_position": "guard"}, _next_request("after-attack")
	))
	_expect(not rejected.success, "el intento directo de cambiar tras atacar sigue rechazado")
	_expect_equal(rejected.code, "JCP_POSITION_AFTER_ATTACK", "enumeracion y validacion comparten la misma restriccion")


func _expect_hidden_zone(table: Dictionary, viewer_label: String) -> void:
	var zone: Dictionary = table["zones"]["creatures:0"]
	_expect_equal(zone["count"], 1, "%s conoce que hay una criatura" % viewer_label)
	_expect_equal(zone["cards"].size(), 0, "%s no conoce su identidad" % viewer_label)
	_expect_equal(zone["slots"].size(), 1, "%s conserva la plaza fisica" % viewer_label)
	_expect(not zone["slots"][0]["visible"] and zone["slots"][0]["card"] == null, "%s solo recibe un reverso anonimo" % viewer_label)


func _engine_with_affordable_opening():
	for seed in range(100):
		var candidate = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
		var started = candidate.start(seed)
		if started.success and not _find_affordable_creature(candidate.export_module_state(), 0).is_empty():
			return candidate
	return null


func _find_affordable_creature(state: Dictionary, player_id: int) -> String:
	var available: int = state["energy"][str(player_id)]["available"]
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
		var attributes: Dictionary = state["cards"]["definitions"][definition_id]["attributes"]
		if attributes["card_type"] == "creature" and attributes["cost"] <= available:
			return instance_id
	return ""


func _advance(engine, player_id: int) -> bool:
	var result = engine.perform_action(GameAction.new(
		"advance_phase",
		player_id,
		{},
		_next_request("advance")
	))
	return result.success


func _has_position_action(actions: Array, instance_id: String, target_position: String) -> bool:
	for action in actions:
		if action.type == "change_position" and action.payload == {
			"instance_id": instance_id,
			"target_position": target_position,
		}:
			return true
	return false


func _has_action_type(actions: Array, action_type: String) -> bool:
	for action in actions:
		if action.type == action_type:
			return true
	return false


func _count_events(events: Array, event_type: String) -> int:
	var count := 0
	for event in events:
		if event["type"] == event_type:
			count += 1
	return count


func _next_request(prefix: String) -> String:
	_request_sequence += 1
	return "%s-%d" % [prefix, _request_sequence]


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
