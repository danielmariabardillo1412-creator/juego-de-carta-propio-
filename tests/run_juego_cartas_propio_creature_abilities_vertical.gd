extends SceneTree
## Recorridos UCE y replay para las nuevas fronteras de acción, privacidad y objetivo.

const GameAction = preload("res://src/core/game_action.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")

const CONFIG := {"player_names": ["Lucia", "Alex"]}

var _checks := 0
var _failures: Array = []
var _request := 0


func _init() -> void:
	_vertical_m09()
	_vertical_m12_privacy()
	_vertical_m15()
	_vertical_m13()
	if _failures.is_empty():
		print("JCP-CREATURE-ABILITIES-VERTICAL PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-CREATURE-ABILITIES-VERTICAL FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _vertical_m09() -> void:
	var engine = _engine_with_opening(19, ["M09"], [])
	_advance_to(engine, 3, "MAIN_1")
	var source := _in_zone(engine.export_module_state(), 0, "M09", "hand")
	_apply(engine, "summon_creature", 0, {"instance_id": source}, "M09 se invoca por UCE")
	_advance_to(engine, 5, "MAIN_1")
	_apply(engine, "activate_creature_ability", 0, {"source_instance_id": source}, "M09 activa su habilidad por UCE")
	_expect_equal(_public_creature(engine, 0, source)["effective_stats"]["attack"], 3, "la vista publica calcula el ATQ de M09")
	_check_replay(engine, "M09")


func _vertical_m12_privacy() -> void:
	var engine = _engine_with_opening(123, ["M12"], ["G06"])
	_advance_to(engine, 2, "MAIN_1")
	var support := _in_zone(engine.export_module_state(), 1, "G06", "hand")
	_apply(engine, "set_support", 1, {"instance_id": support}, "el rival prepara G06")
	_advance_to(engine, 5, "MAIN_1")
	var oracle := _in_zone(engine.export_module_state(), 0, "M12", "hand")
	_apply(engine, "summon_creature", 0, {"instance_id": oracle, "peek_support_slot": 0}, "M12 inspecciona mediante UCE")
	var public_text := JSON.stringify(engine.get_events(0, 1))
	var owner_text := JSON.stringify(engine.get_events(0, 0))
	_expect(not public_text.contains("private_support_inspected"), "el rival no recibe el resultado de la inspeccion")
	_expect(owner_text.contains("private_support_inspected") and owner_text.contains("G06"), "el controlador recibe la informacion privada")
	_check_replay(engine, "M12")


func _vertical_m15() -> void:
	var engine = _engine_with_opening(58, ["M04", "M15"], [])
	_advance_to(engine, 1, "MAIN_1")
	var target := _in_zone(engine.export_module_state(), 0, "M04", "hand")
	_apply(engine, "summon_creature", 0, {"instance_id": target}, "M04 prepara el objetivo")
	_advance_to(engine, 7, "MAIN_1")
	var shaman := _in_zone(engine.export_module_state(), 0, "M15", "hand")
	_apply(engine, "summon_creature", 0, {"instance_id": shaman, "target_instance_id": target}, "M15 entra con objetivo")
	_expect_equal([_public_creature(engine, 0, target)["effective_stats"]["attack"], _public_creature(engine, 0, target)["effective_stats"]["defense"]], [2, 2], "UCE presenta el +1/+1 de M15")
	_check_replay(engine, "M15")


func _vertical_m13() -> void:
	var engine = _engine_with_opening(767, ["M01"], ["M07", "M13"])
	_advance_to(engine, 1, "MAIN_1")
	var attacker := _in_zone(engine.export_module_state(), 0, "M01", "hand")
	_apply(engine, "summon_creature", 0, {"instance_id": attacker}, "M01 entra")
	_advance_to(engine, 2, "MAIN_1")
	var original := _in_zone(engine.export_module_state(), 1, "M07", "hand")
	_apply(engine, "summon_creature", 1, {"instance_id": original}, "M07 entra")
	_advance_to(engine, 6, "MAIN_1")
	var guardian := _in_zone(engine.export_module_state(), 1, "M13", "hand")
	_apply(engine, "summon_creature", 1, {"instance_id": guardian}, "M13 entra")
	_advance_to(engine, 7, "COMBAT")
	_apply(engine, "attack", 0, {"attacker_id": attacker, "target_slot": 0}, "M01 declara contra M07")
	_expect_equal(engine.export_module_state()["pending_response"]["kind"], "creature_redirect_choice", "UCE detiene el ataque para M13")
	_apply(engine, "redirect_attack", 1, {"guardian_id": guardian}, "M13 redirige mediante UCE")
	var state: Dictionary = engine.export_module_state()
	_expect(original in state["cards"]["zones"]["creatures:1"]["cards"], "M07 permanece tras la redireccion")
	_expect(attacker in state["cards"]["zones"]["graveyard:0"]["cards"], "M13 recibe y responde al ataque")
	_check_replay(engine, "M13")


func _engine_with_opening(seed: int, left: Array, right: Array):
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	_expect(engine.start(seed).success, "la partida vertical arranca")
	_expect(_zone_has_all(engine.export_module_state(), 0, left, "hand") and _zone_has_all(engine.export_module_state(), 1, right, "hand"), "la semilla conserva la apertura documentada")
	return engine


func _zone_has_all(state: Dictionary, player_id: int, definitions: Array, kind: String) -> bool:
	var available: Array = []
	for instance_id in state["cards"]["zones"]["%s:%d" % [kind, player_id]]["cards"]:
		available.append(state["cards"]["instances"][instance_id]["definition_id"])
	for definition_id in definitions:
		if definition_id not in available:
			return false
	return true


func _advance_to(engine, turn_number: int, phase: String) -> void:
	for _step in range(100):
		var state: Dictionary = engine.export_module_state()
		if state["turn"]["turn_number"] == turn_number and state["phase"]["current"] == phase:
			return
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		var result = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("advance")))
		if not result.success:
			_failures.append("no se pudo avanzar a t%d %s: %s" % [turn_number, phase, result.code])
			return
	_failures.append("se agoto la progresion hacia t%d %s" % [turn_number, phase])


func _apply(engine, type: String, actor: int, payload: Dictionary, description: String) -> void:
	var result = engine.perform_action(GameAction.new(type, actor, payload, _next_request(type)))
	_expect(result.success, "%s: %s — %s" % [description, result.code, result.message])


func _check_replay(engine, label: String) -> void:
	_expect(engine.validate_internal_consistency()["ok"], "%s conserva consistencia" % label)
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, engine.export_runtime_snapshot())
	_expect(replay["ok"], "el replay reconstruye %s" % label)
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "%s coincide bit a bit" % label)


func _in_zone(state: Dictionary, player_id: int, definition_id: String, kind: String) -> String:
	for instance_id in state["cards"]["zones"]["%s:%d" % [kind, player_id]]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _public_creature(engine, player_id: int, instance_id: String) -> Dictionary:
	for card in engine.get_public_state()["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"]:
		if card["instance"]["id"] == instance_id:
			return card
	return {}


func _next_request(prefix: String) -> String:
	_request += 1
	return "%s-%d" % [prefix, _request]


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
