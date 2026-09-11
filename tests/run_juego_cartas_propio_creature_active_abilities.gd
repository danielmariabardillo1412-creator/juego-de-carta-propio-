extends SceneTree
## Habilidades con activación, objetivo de entrada o información privada: M09, M12 y M15.

const GameAction = preload("res://src/core/game_action.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_test_m09_paid_boost()
	_test_m12_private_inspection()
	_test_m15_entry_bonus()
	_test_m13_redirect_and_decline()
	if _failures.is_empty():
		print("JCP-CREATURE-ACTIVE-ABILITIES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-CREATURE-ACTIVE-ABILITIES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_m09_paid_boost() -> void:
	var prepared := _prepared_state({0: ["M09"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var source: String = prepared["ids"]["0:M09"]
	state["energy"]["0"] = {"maximum": 3, "available": 2}
	var action = GameAction.new("activate_creature_ability", 0, {"source_instance_id": source})
	_expect(module.validate_action(state, action)["ok"], "M09 puede pagar su habilidad en fase principal")
	_expect(_has_legal(module.get_legal_actions(state, 0), action.type, action.payload), "M09 aparece en acciones legales")
	var result: Dictionary = module.reduce(state, action)
	state = result["state"]
	_expect_equal(state["energy"]["0"]["available"], 1, "M09 paga una Energia")
	_expect_equal(module.call("_effective_stats", state, source)["attack"], 3, "M09 obtiene +1 ATQ hasta fin de turno")
	_expect(not module.validate_action(state, action)["ok"], "M09 no repite la habilidad el mismo turno")
	_expect_equal(_count_events(result["events"], "creature_ability_activated"), 1, "M09 publica la activacion")
	_expect(module.validate_state(state)["ok"], "M09 conserva un estado valido")


func _test_m12_private_inspection() -> void:
	var prepared := _prepared_state({})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var oracle: String = _instance_for(state, "M12", 0)
	var support: String = _instance_for(state, "G06", 1)
	state = _move_to_hand(state, oracle, 0)
	state = _move_hidden_support(state, support, 1)
	state["energy"]["0"] = {"maximum": 5, "available": 5}
	var missing = GameAction.new("summon_creature", 0, {"instance_id": oracle})
	_expect_equal(module.validate_action(state, missing)["code"], "JCP_CREATURE_ENTRY_PEEK_INVALID", "M12 exige elegir cuando hay apoyo oculto")
	var action = GameAction.new("summon_creature", 0, {"instance_id": oracle, "peek_support_slot": 0})
	_expect(module.validate_action(state, action)["ok"], "M12 puede elegir el apoyo oculto")
	_expect(_has_legal(module.get_legal_actions(state, 0), action.type, action.payload), "la inspeccion figura en acciones legales")
	var result: Dictionary = module.reduce(state, action)
	var public_event := _event(result["events"], "creature_private_inspection")
	var private_event := _event(result["events"], "private_support_inspected")
	_expect(not public_event.is_empty() and not public_event["payload"].has("support_definition_id"), "el evento publico no revela la identidad")
	_expect_equal(private_event["visible_to"], [0], "solo el controlador recibe el resultado")
	_expect_equal(private_event["payload"]["support_definition_id"], "G06", "M12 conoce la carta elegida")
	_expect(not result["state"]["cards"]["instances"][support]["metadata"]["face_up"], "mirar no revela ni activa el apoyo")
	_expect(module.validate_state(result["state"])["ok"], "M12 conserva privacidad y estado valido")


func _test_m15_entry_bonus() -> void:
	var prepared := _prepared_state({0: ["M04"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var shaman: String = _instance_for(state, "M15", 0)
	var target: String = prepared["ids"]["0:M04"]
	state = _move_to_hand(state, shaman, 0)
	state["energy"]["0"] = {"maximum": 6, "available": 6}
	var missing = GameAction.new("summon_creature", 0, {"instance_id": shaman})
	_expect_equal(module.validate_action(state, missing)["code"], "JCP_CREATURE_ENTRY_TARGET_INVALID", "M15 exige otra criatura si existe")
	var action = GameAction.new("summon_creature", 0, {"instance_id": shaman, "target_instance_id": target})
	_expect(module.validate_action(state, action)["ok"], "M15 puede elegir otra criatura propia")
	_expect(_has_legal(module.get_legal_actions(state, 0), action.type, action.payload), "la entrada dirigida figura en acciones legales")
	var result: Dictionary = module.reduce(state, action)
	_expect_equal(module.call("_effective_stats", result["state"], target)["attack"], 2, "M15 concede +1 ATQ")
	_expect_equal(module.call("_effective_stats", result["state"], target)["defense"], 2, "M15 concede +1 DEF")
	_expect_equal(_count_events(result["events"], "creature_entry_bonus_applied"), 1, "M15 publica objetivo y bono")
	_expect(module.validate_state(result["state"])["ok"], "M15 conserva el estado valido")
	var alone := _prepared_state({})
	alone["state"]["energy"]["0"] = {"maximum": 6, "available": 6}
	var alone_id: String = _instance_for(alone["state"], "M15", 0)
	alone["state"] = _move_to_hand(alone["state"], alone_id, 0)
	_expect(alone["module"].validate_action(alone["state"], GameAction.new("summon_creature", 0, {"instance_id": alone_id}))["ok"], "M15 puede entrar sin objetivo si esta solo")


func _test_m13_redirect_and_decline() -> void:
	var prepared := _prepared_state({0: ["M01", "M17"], 1: ["M07", "M13"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var attack = GameAction.new("attack", 0, {"attacker_id": ids["0:M01"], "target_slot": 0})
	state = module.reduce(state, attack)["state"]
	_expect_equal(state["pending_response"]["kind"], "creature_redirect_choice", "M13 decide antes de las trampas")
	var redirect = GameAction.new("redirect_attack", 1, {"guardian_id": ids["1:M13"]})
	_expect(module.validate_action(state, redirect)["ok"], "el defensor puede elegir M13")
	_expect(_has_legal(module.get_legal_actions(state, 1), redirect.type, redirect.payload), "redirigir figura en acciones legales")
	var redirected: Dictionary = module.reduce(state, redirect)
	state = redirected["state"]
	_expect(ids["1:M07"] in state["cards"]["zones"]["creatures:1"]["cards"], "el objetivo original queda intacto")
	_expect(ids["0:M01"] in state["cards"]["zones"]["graveyard:0"]["cards"], "M13 recibe el ataque y contraataca")
	_expect_equal(_count_events(redirected["events"], "creature_attack_redirected"), 1, "la redireccion queda publicada")
	_expect(module.validate_state(state)["ok"], "el uso de M13 conserva el estado")
	var second = GameAction.new("attack", 0, {"attacker_id": ids["0:M17"], "target_slot": 0})
	var second_result: Dictionary = module.reduce(state, second)
	_expect(second_result["state"]["pending_response"].is_empty(), "M13 no vuelve a ofrecerse el mismo turno")
	_expect(ids["1:M07"] in second_result["state"]["cards"]["zones"]["graveyard:1"]["cards"], "el segundo ataque mantiene su objetivo")
	var declined := _prepared_state({0: ["M01"], 1: ["M07", "M13"]})
	declined["state"] = declined["module"].reduce(declined["state"], GameAction.new("advance_phase", 0, {}))["state"]
	declined["state"] = declined["module"].reduce(declined["state"], GameAction.new("attack", 0, {"attacker_id": declined["ids"]["0:M01"], "target_slot": 0}))["state"]
	var decline = GameAction.new("decline_redirect", 1, {})
	_expect(declined["module"].validate_action(declined["state"], decline)["ok"], "el defensor puede rechazar M13")
	var decline_result: Dictionary = declined["module"].reduce(declined["state"], decline)
	_expect(declined["ids"]["1:M07"] in decline_result["state"]["cards"]["zones"]["graveyard:1"]["cards"], "rechazar conserva el objetivo original")
	_expect_equal(_count_events(decline_result["events"], "creature_redirect_declined"), 1, "rechazar tambien queda registrado")
	var trapped := _prepared_state({0: ["M01"], 1: ["M07", "M13"]})
	var trap_id: String = _instance_for(trapped["state"], "G06", 1)
	trapped["state"] = _move_hidden_support(trapped["state"], trap_id, 1)
	trapped["state"] = trapped["module"].reduce(trapped["state"], GameAction.new("advance_phase", 0, {}))["state"]
	trapped["state"] = trapped["module"].reduce(trapped["state"], GameAction.new("attack", 0, {"attacker_id": trapped["ids"]["0:M01"], "target_slot": 0}))["state"]
	var trapped_redirect: Dictionary = trapped["module"].reduce(trapped["state"], GameAction.new("redirect_attack", 1, {"guardian_id": trapped["ids"]["1:M13"]}))
	_expect_equal(trapped_redirect["state"]["pending_response"]["kind"], "attack", "tras M13 se abre la ventana normal de trampas")
	_expect_equal(trapped_redirect["state"]["pending_response"]["context"]["target_id"], trapped["ids"]["1:M13"], "la trampa recibe como objetivo al guardian")
	var hidden := _prepared_state({0: ["M01"], 1: ["M07", "M13"]})
	var hidden_target: String = hidden["ids"]["1:M07"]
	var hidden_metadata: Dictionary = hidden["state"]["cards"]["instances"][hidden_target]["metadata"].duplicate(true)
	hidden_metadata["face_up"] = false
	hidden_metadata["position"] = "guard"
	hidden["state"]["cards"] = CardState.update_instance_metadata(hidden["state"]["cards"], hidden_target, hidden_metadata)["value"]
	hidden["state"] = hidden["module"].reduce(hidden["state"], GameAction.new("advance_phase", 0, {}))["state"]
	var hidden_offer: Dictionary = hidden["module"].reduce(hidden["state"], GameAction.new("attack", 0, {"attacker_id": hidden["ids"]["0:M01"], "target_slot": 0}))
	_expect(not JSON.stringify(hidden_offer["events"]).contains(hidden_target), "la oferta publica no filtra el objetivo oculto")
	var hidden_redirect: Dictionary = hidden["module"].reduce(hidden_offer["state"], GameAction.new("redirect_attack", 1, {"guardian_id": hidden["ids"]["1:M13"]}))
	_expect(not JSON.stringify(hidden_redirect["events"]).contains(hidden_target), "redirigir tampoco filtra el objetivo oculto")


func _prepared_state(layout: Dictionary) -> Dictionary:
	var module = GameModule.new()
	var state: Dictionary = module.create_initial_state({"player_names": ["Lucia", "Alex"]}, 72007)
	for _index in range(2):
		state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var ids: Dictionary = {}
	for player_id in layout:
		for definition_id in layout[player_id]:
			var instance_id := _instance_for(state, definition_id, player_id)
			ids["%d:%s" % [player_id, definition_id]] = instance_id
			var located: Dictionary = CardState.locate_card(state["cards"], instance_id)
			var metadata: Dictionary = state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
			metadata.merge({"face_up": true, "position": "attack", "summoned_turn": -1, "last_attack_turn": -1, "last_position_change_turn": -1}, true)
			var update: Dictionary = CardState.update_instance_metadata(state["cards"], instance_id, metadata)
			state["cards"] = CardState.move_card(update["value"], instance_id, located["zone_id"], "creatures:%d" % player_id)["value"]
	return {"module": module, "state": state, "ids": ids}


func _move_hidden_support(state: Dictionary, instance_id: String, player_id: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var located: Dictionary = CardState.locate_card(next_state["cards"], instance_id)
	var metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata.merge({"face_up": false, "active": false, "set_turn": 0}, true)
	var update: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	next_state["cards"] = CardState.move_card(update["value"], instance_id, located["zone_id"], "support:%d" % player_id)["value"]
	return next_state


func _move_to_hand(state: Dictionary, instance_id: String, player_id: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var located: Dictionary = CardState.locate_card(next_state["cards"], instance_id)
	if located["zone_id"] != "hand:%d" % player_id:
		next_state["cards"] = CardState.move_card(next_state["cards"], instance_id, located["zone_id"], "hand:%d" % player_id)["value"]
	return next_state


func _instance_for(state: Dictionary, definition_id: String, owner_id: int) -> String:
	for instance_id in state["cards"]["instances"]:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		if instance["definition_id"] == definition_id and instance["metadata"]["owner_id"] == owner_id:
			return instance_id
	return ""


func _has_legal(actions: Array, type: String, payload: Dictionary) -> bool:
	for action in actions:
		if action.type == type and action.payload == payload:
			return true
	return false


func _event(events: Array, type: String) -> Dictionary:
	for event in events:
		if event["type"] == type:
			return event
	return {}


func _count_events(events: Array, type: String) -> int:
	var count := 0
	for event in events:
		if event["type"] == type:
			count += 1
	return count


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
