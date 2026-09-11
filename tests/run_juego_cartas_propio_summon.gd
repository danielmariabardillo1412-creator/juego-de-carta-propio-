extends SceneTree
## Verifica la primera accion de carta: invocacion normal con coste y limite por turno.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("JCP-SUMMON PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-SUMMON FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var engine = _engine_with_affordable_opening()
	_expect(engine != null, "se encuentra una mano inicial con criatura de coste 1")
	if engine == null:
		return
	var to_draw = engine.perform_action(GameAction.new("advance_phase", 0, {}, "draw"))
	var to_main = engine.perform_action(GameAction.new("advance_phase", 0, {}, "main"))
	_expect(to_draw.success and to_main.success, "el jugador llega a Principal 1")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_affordable_creature(state, 0)
	_expect(not creature_id.is_empty(), "la criatura asequible sigue en la mano")
	if creature_id.is_empty():
		return
	var definition_id: String = state["cards"]["instances"][creature_id]["definition_id"]
	var cost: int = state["cards"]["definitions"][definition_id]["attributes"]["cost"]
	var hand_before: int = state["cards"]["zones"]["hand:0"]["cards"].size()
	var energy_before: int = state["energy"]["0"]["available"]

	var summon = engine.perform_action(GameAction.new(
		"summon_creature",
		0,
		{"instance_id": creature_id},
		"summon-one"
	))
	_expect(summon.success, "la criatura se invoca")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["hand:0"]["cards"].size(), hand_before - 1, "la carta abandona la mano")
	_expect_equal(state["cards"]["zones"]["creatures:0"]["cards"], [creature_id], "la carta ocupa la fila de criaturas")
	_expect_equal(state["energy"]["0"]["available"], energy_before - cost, "se paga el coste de energia")
	_expect(state["turn_usage"]["normal_summon_used"], "se registra la invocacion normal")
	_expect_equal(state["cards"]["instances"][creature_id]["metadata"]["position"], "attack", "la criatura entra en ataque")
	_expect(state["cards"]["instances"][creature_id]["metadata"]["face_up"], "la criatura entra boca arriba")

	var second_candidate: String = _find_any_creature_in_hand(state, 0)
	if not second_candidate.is_empty():
		var second = engine.perform_action(GameAction.new(
			"summon_creature",
			0,
			{"instance_id": second_candidate},
			"summon-two"
		))
		_expect(not second.success, "no se permite una segunda invocacion normal")
		_expect_equal(second.code, "JCP_NORMAL_SUMMON_USED", "el rechazo identifica el limite del turno")

	var public_cards: Dictionary = engine.get_public_state()["game"]["card_table"]
	_expect_equal(public_cards["zones"]["creatures:0"]["cards"].size(), 1, "la criatura invocada es visible publicamente")
	_expect_equal(public_cards["zones"]["creatures:0"]["cards"][0]["definition"]["id"], definition_id, "la identidad publica es correcta")
	_expect(CardState.validate(state["cards"])["ok"], "la invocacion conserva todas las cartas")
	_expect(engine.validate_internal_consistency()["ok"], "el motor queda integro tras la invocacion")
	_expect(_advance(engine, 0, "initial-combat"), "el jugador inicial llega a Combate")
	_expect(not _has_attack_for(engine, 0, creature_id), "el primer jugador no puede atacar en el primer turno")
	var forbidden_initial = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": creature_id, "target_slot": -1}, "initial-attack"))
	_expect(not forbidden_initial.success and forbidden_initial.code == "JCP_ATTACK_INITIAL_TURN", "el rechazo identifica la excepcion del primer turno")

	var second_engine = _engine_with_affordable_second_player()
	_expect(second_engine != null, "se encuentra una apertura asequible para el segundo jugador")
	if second_engine == null:
		return
	for index in range(6):
		_expect(_advance(second_engine, 0, "p0-pass-%d" % index), "el jugador inicial completa su fase %d" % index)
	_expect(_advance(second_engine, 1, "p1-draw") and _advance(second_engine, 1, "p1-main"), "el segundo jugador llega a Principal 1")
	var second_state: Dictionary = second_engine.export_module_state()
	var second_creature: String = _find_affordable_creature(second_state, 1)
	var second_summon = second_engine.perform_action(GameAction.new("summon_creature", 1, {"instance_id": second_creature}, "p1-summon"))
	_expect(second_summon.success, "el segundo jugador invoca boca arriba")
	_expect(_advance(second_engine, 1, "p1-combat"), "el segundo jugador llega a Combate")
	_expect(_has_attack_for(second_engine, 1, second_creature), "una criatura boca arriba puede atacar el mismo turno en que es invocada")
	var immediate_attack = second_engine.perform_action(GameAction.new("attack", 1, {"attacker_id": second_creature, "target_slot": -1}, "p1-immediate-attack"))
	_expect(immediate_attack.success, "el ataque inmediato atraviesa el motor")
	_expect(second_engine.validate_internal_consistency()["ok"], "el ataque inmediato conserva la integridad")


func _engine_with_affordable_opening():
	for seed in range(100):
		var candidate = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
		var started = candidate.start(seed)
		if started.success and not _find_affordable_creature(candidate.export_module_state(), 0).is_empty():
			return candidate
	return null


func _engine_with_affordable_second_player():
	for seed in range(100):
		var candidate = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
		var started = candidate.start(seed)
		if started.success and not _find_cost_one_creature(candidate.export_module_state(), 1).is_empty():
			return candidate
	return null


func _advance(engine, player_id: int, request_id: String) -> bool:
	return engine.perform_action(GameAction.new("advance_phase", player_id, {}, request_id)).success


func _has_attack_for(engine, player_id: int, creature_id: String) -> bool:
	for action in engine.get_legal_actions(player_id):
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == creature_id:
			return true
	return false


func _find_affordable_creature(state: Dictionary, player_id: int) -> String:
	var available: int = state["energy"][str(player_id)]["available"]
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
		var attributes: Dictionary = state["cards"]["definitions"][definition_id]["attributes"]
		if attributes["card_type"] == "creature" and attributes["cost"] <= available:
			return instance_id
	return ""


func _find_any_creature_in_hand(state: Dictionary, player_id: int) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
		if state["cards"]["definitions"][definition_id]["attributes"]["card_type"] == "creature":
			return instance_id
	return ""


func _find_cost_one_creature(state: Dictionary, player_id: int) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
		var attributes: Dictionary = state["cards"]["definitions"][definition_id]["attributes"]
		if attributes["card_type"] == "creature" and attributes["cost"] == 1:
			return instance_id
	return ""


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
