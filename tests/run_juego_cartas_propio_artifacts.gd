extends SceneTree
## Verifica la activacion de E04, sus requisitos y su interaccion con T05.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_e04_relocates_once_per_turn()
	_test_e04_preserves_equipment_requirements()
	_test_t05_can_answer_e04_relocation()
	if _failures.is_empty():
		print("JCP-ARTIFACTS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-ARTIFACTS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_e04_relocates_once_per_turn() -> void:
	var prepared: Dictionary = _prepare_basic_e04(487)
	_expect(prepared["ok"], "se prepara E04 con dos criaturas y E02")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	var action = _find_relocation(engine, prepared["artifact_id"], prepared["equipment_id"], prepared["target_id"])
	_expect(action != null, "las acciones legales ofrecen el traslado exacto")
	if action == null:
		return
	_expect(_perform(engine, action.type, 0, action.payload, "relocate"), "E04 traslada E02 a la segunda criatura")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["instances"][prepared["equipment_id"]]["metadata"]["linked_to"], prepared["target_id"], "el vinculo apunta a la nueva portadora")
	_expect_equal(_effective_defense(engine, prepared["source_id"]), 0, "la antigua portadora pierde el bono")
	_expect_equal(_effective_defense(engine, prepared["target_id"]), 3, "la nueva portadora recibe el bono de E02")
	_expect_equal(state["cards"]["instances"][prepared["artifact_id"]]["metadata"]["last_activation_turn"], state["turn"]["turn_number"], "E04 registra el turno de activacion")
	_expect(_has_event(engine, "equipment_relocated"), "el traslado emite un evento publico")
	var version_before: int = engine.state_version()
	var repeated = _perform_result(engine, "relocate_equipment", 0, {
		"artifact_instance_id": prepared["artifact_id"],
		"equipment_instance_id": prepared["equipment_id"],
		"target_instance_id": prepared["source_id"],
	}, "repeat")
	_expect(not repeated.success, "el mismo E04 no se usa dos veces en un turno")
	_expect_equal(repeated.code, "JCP_RELOCATE_ALREADY_USED", "el segundo uso tiene rechazo especifico")
	_expect_equal(engine.state_version(), version_before, "el uso rechazado es atomico")
	_expect(_finish_turn_from_main(engine, 0), "el jugador termina el turno del primer traslado")
	_expect(_play_empty_turn(engine, 1), "el rival completa su turno")
	_expect(_advance(engine, 0) and _advance(engine, 0), "E04 vuelve a una fase principal propia")
	_expect(_perform(engine, "relocate_equipment", 0, {
		"artifact_instance_id": prepared["artifact_id"],
		"equipment_instance_id": prepared["equipment_id"],
		"target_instance_id": prepared["source_id"],
	}, "next-turn"), "E04 puede volver a usarse en un turno posterior")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["instances"][prepared["equipment_id"]]["metadata"]["linked_to"], prepared["source_id"], "el segundo traslado cambia realmente el vinculo")
	_expect(engine.validate_internal_consistency()["ok"], "los traslados de E04 conservan la consistencia")


func _test_e04_preserves_equipment_requirements() -> void:
	var prepared: Dictionary = _prepare_restricted_e04(10770)
	_expect(prepared["ok"], "se prepara E01 sobre Manipulador frente a objetivo incompatible")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_find_relocation(engine, prepared["artifact_id"], prepared["equipment_id"], prepared["target_id"]) == null, "la accion incompatible no se ofrece como legal")
	var state_before: Dictionary = engine.export_module_state()
	var version_before: int = engine.state_version()
	var rejected = _perform_result(engine, "relocate_equipment", 0, {
		"artifact_instance_id": prepared["artifact_id"],
		"equipment_instance_id": prepared["equipment_id"],
		"target_instance_id": prepared["target_id"],
	}, "incompatible")
	_expect(not rejected.success, "E04 rechaza trasladar un arma a una criatura no manipuladora")
	_expect_equal(rejected.code, "JCP_RELOCATE_REQUIREMENT_FAILED", "el rechazo conserva la causa de compatibilidad")
	_expect_equal(engine.state_version(), version_before, "el traslado incompatible no avanza la version")
	_expect_equal(engine.export_module_state(), state_before, "el traslado incompatible no muta ninguna carta")
	_expect(engine.validate_internal_consistency()["ok"], "el rechazo compatible conserva la consistencia")


func _test_t05_can_answer_e04_relocation() -> void:
	var prepared: Dictionary = _prepare_e04_against_t05(31235)
	_expect(prepared["ok"], "se prepara un traslado de E04 frente a T05")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_perform(engine, "relocate_equipment", 0, {
		"artifact_instance_id": prepared["artifact_id"],
		"equipment_instance_id": prepared["equipment_id"],
		"target_instance_id": prepared["target_id"],
	}, "relocate-t05"), "el traslado se declara correctamente")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "equipment", "reubicar un equipo abre la misma respuesta de vinculacion")
	_expect_equal(state["pending_response"]["context"]["target_creature_id"], prepared["target_id"], "la respuesta conserva la nueva portadora")
	_expect(_has_reaction(engine, 1, prepared["trap_slot"]), "T05 puede responder al nuevo vinculo creado por E04")
	_expect(_activate(engine, 1, prepared["trap_slot"]), "el rival activa T05 contra el traslado")
	_expect(_pass(engine, 0) and _pass(engine, 1), "la cadena de T05 se cierra por dos pases")
	state = engine.export_module_state()
	_expect(prepared["equipment_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "T05 destruye el equipo trasladado")
	_expect_equal(state["cards"]["instances"][prepared["equipment_id"]]["metadata"]["linked_to"], "", "el equipo destruido no conserva un vinculo fantasma")
	_expect(prepared["artifact_id"] in state["cards"]["zones"]["support:0"]["cards"], "E04 permanece activo tras perder el equipo")
	_expect_equal(state["cards"]["instances"][prepared["artifact_id"]]["metadata"]["last_activation_turn"], state["turn"]["turn_number"], "T05 no devuelve el uso de E04")
	_expect(engine.validate_internal_consistency()["ok"], "la interaccion E04/T05 conserva la consistencia")


func _prepare_basic_e04(seed: int) -> Dictionary:
	var engine = _start(seed)
	if engine == null:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	var source_id: String = _find_in_hand(state, 0, "M01")
	var target_id: String = _find_in_hand(state, 0, "M02")
	var equipment_id: String = _find_in_hand(state, 0, "E02")
	if not _reach_main(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": source_id}, "source"):
		return {"ok": false}
	if not _perform(engine, "equip_item", 0, {"instance_id": equipment_id, "target_instance_id": source_id}, "equip"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0) or not _play_empty_turn(engine, 1):
		return {"ok": false}
	if not _reach_main(engine, 0):
		return {"ok": false}
	state = engine.export_module_state()
	var artifact_id: String = _find_in_hand(state, 0, "E04")
	if target_id.is_empty():
		target_id = _find_in_hand(state, 0, "M02")
	if not _perform(engine, "summon_creature", 0, {"instance_id": target_id}, "target"):
		return {"ok": false}
	if not _perform(engine, "play_persistent", 0, {"instance_id": artifact_id}, "artifact"):
		return {"ok": false}
	return {"ok": true, "engine": engine, "source_id": source_id, "target_id": target_id, "equipment_id": equipment_id, "artifact_id": artifact_id}


func _prepare_restricted_e04(seed: int) -> Dictionary:
	var engine = _start(seed)
	if engine == null:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	var source_id: String = _find_in_hand(state, 0, "M02")
	var equipment_id: String = _find_in_hand(state, 0, "E01")
	var artifact_id: String = _find_in_hand(state, 0, "E04")
	if not _reach_main(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": source_id}, "manipulator"):
		return {"ok": false}
	if not _perform(engine, "equip_item", 0, {"instance_id": equipment_id, "target_instance_id": source_id}, "weapon"):
		return {"ok": false}
	if not _perform(engine, "play_persistent", 0, {"instance_id": artifact_id}, "artifact"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0) or not _play_empty_turn(engine, 1) or not _reach_main(engine, 0):
		return {"ok": false}
	state = engine.export_module_state()
	var target_id: String = _find_in_hand(state, 0, "M01")
	if not _perform(engine, "summon_creature", 0, {"instance_id": target_id}, "non-manipulator"):
		return {"ok": false}
	return {"ok": true, "engine": engine, "source_id": source_id, "target_id": target_id, "equipment_id": equipment_id, "artifact_id": artifact_id}


func _prepare_e04_against_t05(seed: int) -> Dictionary:
	var engine = _start(seed)
	if engine == null:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	var source_id: String = _find_in_hand(state, 0, "M01")
	var equipment_id: String = _find_in_hand(state, 0, "E02")
	var artifact_id: String = _find_in_hand(state, 0, "E04")
	var trap_id: String = _find_in_hand(state, 1, "T05")
	if not _reach_main(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": source_id}, "source"):
		return {"ok": false}
	if not _perform(engine, "equip_item", 0, {"instance_id": equipment_id, "target_instance_id": source_id}, "equip"):
		return {"ok": false}
	if not _perform(engine, "play_persistent", 0, {"instance_id": artifact_id}, "artifact"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0) or not _reach_main(engine, 1):
		return {"ok": false}
	if not _perform(engine, "set_support", 1, {"instance_id": trap_id}, "set-t05"):
		return {"ok": false}
	state = engine.export_module_state()
	var trap_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(trap_id)
	if not _finish_turn_from_main(engine, 1) or not _reach_main(engine, 0):
		return {"ok": false}
	state = engine.export_module_state()
	var target_id: String = _find_in_hand(state, 0, "M02")
	if not _perform(engine, "summon_creature", 0, {"instance_id": target_id}, "target"):
		return {"ok": false}
	return {"ok": true, "engine": engine, "source_id": source_id, "target_id": target_id, "equipment_id": equipment_id, "artifact_id": artifact_id, "trap_id": trap_id, "trap_slot": trap_slot}


func _start(seed: int):
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	return engine if engine.start(seed).success else null


func _reach_main(engine, player_id: int) -> bool:
	return _advance(engine, player_id) and _advance(engine, player_id)


func _finish_turn_from_main(engine, player_id: int) -> bool:
	for unused in range(4):
		if not _advance(engine, player_id):
			return false
	return true


func _play_empty_turn(engine, player_id: int) -> bool:
	for unused in range(6):
		if not _advance(engine, player_id):
			return false
	return true


func _find_relocation(engine, artifact_id: String, equipment_id: String, target_id: String):
	var expected := {"artifact_instance_id": artifact_id, "equipment_instance_id": equipment_id, "target_instance_id": target_id}
	for action in engine.get_legal_actions(0):
		if action.type == "relocate_equipment" and action.payload == expected:
			return action
	return null


func _effective_defense(engine, creature_id: String) -> int:
	for card in engine.get_public_state()["game"]["card_table"]["zones"]["creatures:0"]["cards"]:
		if card["instance"]["id"] == creature_id:
			return card["effective_stats"]["defense"]
	return -1


func _activate(engine, player_id: int, support_slot: int) -> bool:
	return _perform(engine, "activate_reaction", player_id, {"support_slot": support_slot}, "activate")


func _pass(engine, player_id: int) -> bool:
	return _perform(engine, "pass_reaction", player_id, {}, "pass")


func _advance(engine, player_id: int) -> bool:
	return _perform(engine, "advance_phase", player_id, {}, "advance")


func _perform(engine, type: String, player_id: int, payload: Dictionary, prefix: String) -> bool:
	return _perform_result(engine, type, player_id, payload, prefix).success


func _perform_result(engine, type: String, player_id: int, payload: Dictionary, prefix: String):
	return engine.perform_action(GameAction.new(type, player_id, payload, _next_request(prefix)))


func _find_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _has_reaction(engine, player_id: int, support_slot: int) -> bool:
	for action in engine.get_legal_actions(player_id):
		if action.type == "activate_reaction" and action.payload == {"support_slot": support_slot}:
			return true
	return false


func _has_event(engine, type: String) -> bool:
	for event in engine.get_events(0, -1):
		if event["type"] == type:
			return true
	return false


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
