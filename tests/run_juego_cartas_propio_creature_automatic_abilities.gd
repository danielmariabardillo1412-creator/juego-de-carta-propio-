extends SceneTree
## Cobertura de las habilidades automáticas y continuas M05, M06, M07, M10, M16 y M18.

const GameAction = preload("res://src/core/game_action.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_test_m05_attack_bonus()
	_test_m06_reveal_defense()
	_test_m07_destruction_draw()
	_test_m07_does_not_escape_fusion()
	_test_m10_guard_attack()
	_test_m16_energy_once_per_turn()
	_test_m18_extra_attack()
	if _failures.is_empty():
		print("JCP-CREATURE-AUTOMATIC-ABILITIES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-CREATURE-AUTOMATIC-ABILITIES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_m05_attack_bonus() -> void:
	var prepared := _prepared_state({0: ["M05"], 1: ["M02"]})
	var result: Dictionary = _attack(prepared, "0:M05", 0)
	var combat := _event(result["events"], "creature_combat_resolved")
	_expect_equal(combat["payload"]["attacker_attack"], 2, "M05 suma +1 ATQ al declarar")
	_expect_equal(_count_events(result["events"], "creature_attack_bonus_triggered"), 1, "M05 publica el disparo")
	_expect(prepared["ids"]["1:M02"] in result["state"]["cards"]["zones"]["creatures:1"]["cards"], "la igualdad contra DEF 2 no destruye")


func _test_m06_reveal_defense() -> void:
	var prepared := _prepared_state({0: ["M05"], 1: ["M06"]})
	var defender: String = prepared["ids"]["1:M06"]
	prepared["state"]["cards"]["instances"][defender]["metadata"]["face_up"] = false
	prepared["state"]["cards"]["instances"][defender]["metadata"]["position"] = "guard"
	var result: Dictionary = _attack(prepared, "0:M05", 0)
	var combat := _event(result["events"], "creature_combat_resolved")
	_expect_equal(combat["payload"]["target_defense"], 3, "M06 gana +1 DEF al revelarse por el ataque")
	_expect_equal(_count_events(result["events"], "creature_reveal_bonus_triggered"), 1, "M06 publica su defensa")
	_expect(defender in result["state"]["cards"]["zones"]["creatures:1"]["cards"], "M06 sobrevive")
	var already_visible := _prepared_state({0: ["M05"], 1: ["M06"]})
	var visible_result: Dictionary = _attack(already_visible, "0:M05", 0)
	_expect_equal(_event(visible_result["events"], "creature_combat_resolved")["payload"]["target_defense"], 2, "M06 visible no recibe el bono")


func _test_m07_destruction_draw() -> void:
	var prepared := _prepared_state({0: ["M01"], 1: ["M07"]})
	var before: int = prepared["state"]["cards"]["zones"]["hand:1"]["cards"].size()
	var result: Dictionary = _attack(prepared, "0:M01", 0)
	_expect_equal(result["state"]["cards"]["zones"]["hand:1"]["cards"].size(), before + 1, "M07 roba una carta al ser destruido")
	_expect_equal(_count_events(result["events"], "creature_destruction_draw"), 1, "el robo de M07 tiene evento publico")
	_expect_equal(_count_events(result["events"], "private_card_drawn"), 1, "la identidad robada solo viaja en evento privado")


func _test_m07_does_not_escape_fusion() -> void:
	var prepared := _prepared_state({0: ["M17"], 1: ["M07", "M01"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 1, {"material_instance_ids": [ids["1:M07"], ids["1:M01"]], "position": "guard"}))["state"]
	var before: int = state["cards"]["zones"]["hand:1"]["cards"].size()
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var result: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M17"], "target_slot": 0}))
	_expect_equal(result["state"]["cards"]["zones"]["hand:1"]["cards"].size(), before, "M07 contenido no conserva su habilidad")
	_expect_equal(_count_events(result["events"], "creature_destruction_draw"), 0, "la Fusion destruida no dispara M07")


func _test_m10_guard_attack() -> void:
	var prepared := _prepared_state({0: ["M01"], 1: ["M10"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var defender: String = prepared["ids"]["1:M10"]
	state["cards"]["instances"][defender]["metadata"]["position"] = "guard"
	_expect_equal(module.call("_effective_stats", state, defender)["attack"], 2, "M10 tiene 2 ATQ en guardia")
	state["cards"]["instances"][defender]["metadata"]["position"] = "attack"
	_expect_equal(module.call("_effective_stats", state, defender)["attack"], 1, "M10 vuelve a 1 ATQ en ataque")
	state["cards"]["instances"][defender]["metadata"]["position"] = "guard"
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var result: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": prepared["ids"]["0:M01"], "target_slot": 0}))
	_expect(result["state"]["cards"]["zones"]["graveyard:0"]["cards"].has(prepared["ids"]["0:M01"]), "M10 contraataca con el bono continuo")


func _test_m16_energy_once_per_turn() -> void:
	var prepared := _prepared_state({0: ["M16"], 1: ["M04", "M07"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var collector: String = prepared["ids"]["0:M16"]
	state["energy"]["0"] = {"maximum": 5, "available": 2}
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var first: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": collector, "target_slot": 0}))
	state = first["state"]
	_expect_equal(state["energy"]["0"]["available"], 3, "M16 recupera 1 Energia")
	_expect_equal(_count_events(first["events"], "creature_energy_recovered"), 1, "M16 publica la recuperacion")
	state["cards"]["instances"][collector]["metadata"]["last_attack_turn"] = -1
	var second: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": collector, "target_slot": 0}))
	_expect_equal(second["state"]["energy"]["0"]["available"], 3, "M16 no recupera dos veces el mismo turno")
	_expect(module.validate_state(second["state"])["ok"], "el marcador de M16 conserva el estado")


func _test_m18_extra_attack() -> void:
	var prepared := _prepared_state({0: ["M18"], 1: ["M04", "M07"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var dragon: String = prepared["ids"]["0:M18"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var first_events: Array = []
	for _index in range(2):
		var action = GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": 0})
		_expect(module.validate_action(state, action)["ok"], "M18 puede declarar sus dos ataques")
		var result: Dictionary = module.reduce(state, action)
		if _index == 0:
			first_events = result["events"]
		state = result["state"]
	_expect(not module.validate_action(state, GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": -1}))["ok"], "M18 no obtiene un tercer ataque")
	_expect_equal(_count_events(first_events, "extra_attack_granted"), 1, "M18 publica el permiso adicional")
	_expect_equal(_count_events(first_events, "fusion_extra_attack_granted"), 0, "M18 no se presenta como F005")
	_expect(module.validate_state(state)["ok"], "M18 conserva un estado valido")


func _attack(prepared: Dictionary, attacker_key: String, slot: int) -> Dictionary:
	var state: Dictionary = prepared["module"].reduce(prepared["state"], GameAction.new("advance_phase", 0, {}))["state"]
	return prepared["module"].reduce(state, GameAction.new("attack", 0, {"attacker_id": prepared["ids"][attacker_key], "target_slot": slot}))


func _prepared_state(layout: Dictionary) -> Dictionary:
	var module = GameModule.new()
	var state: Dictionary = module.create_initial_state({"player_names": ["Lucia", "Alex"]}, 71007)
	# Los escenarios unitarios de combate representan una ronda posterior.
	state["turn"]["turn_number"] = 3
	state["turn"]["round_number"] = 2
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
			var move: Dictionary = CardState.move_card(update["value"], instance_id, located["zone_id"], "creatures:%d" % player_id)
			state["cards"] = move["value"]
	return {"ok": true, "module": module, "state": state, "ids": ids}


func _instance_for(state: Dictionary, definition_id: String, owner_id: int) -> String:
	for instance_id in state["cards"]["instances"]:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		if instance["definition_id"] == definition_id and instance["metadata"]["owner_id"] == owner_id:
			return instance_id
	return ""


func _event(events: Array, event_type: String) -> Dictionary:
	for item in events:
		if item["type"] == event_type:
			return item
	return {}


func _count_events(events: Array, event_type: String) -> int:
	var count := 0
	for item in events:
		if item["type"] == event_type:
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
