extends SceneTree
## Verifica T04, T05 y T06 sobre disparadores posteriores a acciones y combate.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_t04_reverses_guard_to_attack()
	_test_t04_is_optional()
	_test_t05_destroys_new_equipment()
	_test_t06_destroys_combat_survivor()
	_test_t06_is_optional()
	if _failures.is_empty():
		print("JCP-TRIGGER-REACTIONS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-TRIGGER-REACTIONS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_t04_reverses_guard_to_attack() -> void:
	var prepared: Dictionary = _prepare_position_response()
	_expect(prepared["ok"], "se prepara el cambio de postura frente a T04")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_change_position(engine, prepared["creature_id"], "attack"), "el rival declara guardia a ataque")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "position_change", "el cambio abre su ventana especifica")
	_expect_equal(state["cards"]["instances"][prepared["creature_id"]]["metadata"]["position"], "attack", "la criatura adopta ataque mientras se responde")
	_expect(_has_reaction(engine, 1, prepared["trap_slot"]), "T04 aparece como respuesta opcional")
	_expect(_activate(engine, 1, prepared["trap_slot"]), "el defensor activa T04")
	_expect(_pass(engine, 0) and _pass(engine, 1), "dos pases resuelven T04")
	state = engine.export_module_state()
	var metadata: Dictionary = state["cards"]["instances"][prepared["creature_id"]]["metadata"]
	_expect_equal(metadata["position"], "guard", "T04 devuelve la criatura a guardia")
	_expect_equal(metadata["last_position_change_turn"], state["turn"]["turn_number"], "T04 no devuelve el cambio voluntario consumido")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "T04 termina en el cementerio")
	_expect(_has_event(engine, "position_change_reversed"), "se publica la reversion de postura")
	_expect(engine.validate_internal_consistency()["ok"], "T04 conserva la consistencia interna")


func _test_t04_is_optional() -> void:
	var prepared: Dictionary = _prepare_position_response()
	_expect(prepared["ok"], "se prepara la rama opcional de T04")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_change_position(engine, prepared["creature_id"], "attack"), "el cambio vuelve a abrir respuesta")
	_expect(_pass(engine, 1) and _pass(engine, 0), "ambos jugadores pueden cerrar sin activar T04")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["instances"][prepared["creature_id"]]["metadata"]["position"], "attack", "la criatura permanece en ataque al declinar T04")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["support:1"]["cards"], "T04 sigue preparada si no se usa")
	_expect_equal(state["cards"]["instances"][prepared["trap_id"]]["metadata"]["face_up"], false, "T04 permanece oculta al pasar")
	_expect(engine.validate_internal_consistency()["ok"], "declinar T04 conserva la consistencia")


func _test_t05_destroys_new_equipment() -> void:
	var prepared: Dictionary = _prepare_equipment_response()
	_expect(prepared["ok"], "se prepara un equipo frente a T05")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_perform(engine, "equip_item", 0, {
		"instance_id": prepared["equipment_id"],
		"target_instance_id": prepared["creature_id"],
	}, "equip"), "E02 se vincula antes de la respuesta")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "equipment", "equipar abre la ventana de T05")
	_expect(prepared["equipment_id"] in state["cards"]["zones"]["attachments:0"]["cards"], "el equipo esta vinculado mientras se responde")
	_expect_equal(_effective_defense(engine, 0), 1, "el equipo aplica temporalmente su defensa")
	_expect(_has_reaction(engine, 1, prepared["trap_slot"]), "T05 aparece como respuesta legal")
	_expect(_activate(engine, 1, prepared["trap_slot"]), "el rival activa T05")
	_expect(_pass(engine, 0) and _pass(engine, 1), "dos pases resuelven T05")
	state = engine.export_module_state()
	_expect(prepared["equipment_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "T05 destruye el equipo recien vinculado")
	_expect_equal(state["cards"]["instances"][prepared["equipment_id"]]["metadata"]["linked_to"], "", "el equipo destruido pierde su vinculo")
	_expect_equal(_effective_defense(engine, 0), 0, "la criatura recupera su defensa base")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "T05 termina en el cementerio")
	_expect(_has_event(engine, "newly_equipped_item_destroyed"), "se publica la destruccion del equipo")
	_expect(engine.validate_internal_consistency()["ok"], "T05 conserva la consistencia interna")


func _test_t06_destroys_combat_survivor() -> void:
	var prepared: Dictionary = _prepare_combat_destruction_response()
	_expect(prepared["ok"], "se prepara un combate frente a T06")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_attack(engine, prepared["attacker_id"]), "el ataque se resuelve y destruye al defensor")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "combat_destruction", "la ventana de T06 aparece despues del combate")
	_expect_equal(state["pending_response"]["priority_player_id"], 1, "el propietario destruido recibe prioridad")
	_expect(prepared["target_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "la criatura derrotada ya esta en el cementerio")
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["creatures:0"]["cards"], "el superviviente espera en campo mientras se responde")
	_expect(_has_reaction(engine, 1, prepared["trap_slot"]), "T06 aparece como respuesta legal")
	_expect(_activate(engine, 1, prepared["trap_slot"]), "el defensor activa T06")
	_expect(_pass(engine, 0) and _pass(engine, 1), "dos pases resuelven T06")
	state = engine.export_module_state()
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "T06 destruye a la criatura superviviente")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "T06 termina en el cementerio")
	_expect(_has_event(engine, "creature_combat_resolved"), "el combate se publica antes del efecto posterior")
	_expect(_event_before(engine, "creature_combat_resolved", "combat_survivor_destroyed"), "la destruccion de T06 ocurre despues del combate")
	_expect(engine.validate_internal_consistency()["ok"], "T06 conserva la consistencia interna")


func _test_t06_is_optional() -> void:
	var prepared: Dictionary = _prepare_combat_destruction_response()
	_expect(prepared["ok"], "se prepara la rama opcional de T06")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_attack(engine, prepared["attacker_id"]), "el combate abre otra ventana posterior")
	_expect(_pass(engine, 1) and _pass(engine, 0), "se puede declinar T06")
	var state: Dictionary = engine.export_module_state()
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["creatures:0"]["cards"], "el superviviente permanece si T06 no se activa")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["support:1"]["cards"], "T06 permanece preparada al pasar")
	_expect(engine.validate_internal_consistency()["ok"], "declinar T06 conserva la consistencia")


func _prepare_position_response() -> Dictionary:
	var opening: Dictionary = _engine_with_seed(12)
	if not opening["ok"]:
		return opening
	var engine = opening["engine"]
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_in_hand(state, 0, "M01")
	var trap_id: String = _find_in_hand(state, 1, "T04")
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	if not _perform(engine, "set_creature", 0, {"instance_id": creature_id}, "set-creature"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0):
		return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	if not _perform(engine, "set_support", 1, {"instance_id": trap_id}, "set-t04"):
		return {"ok": false}
	state = engine.export_module_state()
	var trap_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(trap_id)
	if not _finish_turn_from_main(engine, 1):
		return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	return {"ok": true, "engine": engine, "creature_id": creature_id, "trap_id": trap_id, "trap_slot": trap_slot}


func _prepare_equipment_response() -> Dictionary:
	var opening: Dictionary = _engine_with_seed(499)
	if not opening["ok"]:
		return opening
	var engine = opening["engine"]
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_in_hand(state, 0, "M01")
	var equipment_id: String = _find_in_hand(state, 0, "E02")
	var trap_id: String = _find_in_hand(state, 1, "T05")
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": creature_id}, "summon"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0):
		return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	if not _perform(engine, "set_support", 1, {"instance_id": trap_id}, "set-t05"):
		return {"ok": false}
	state = engine.export_module_state()
	var trap_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(trap_id)
	if not _finish_turn_from_main(engine, 1):
		return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	return {"ok": true, "engine": engine, "creature_id": creature_id, "equipment_id": equipment_id, "trap_id": trap_id, "trap_slot": trap_slot}


func _prepare_combat_destruction_response() -> Dictionary:
	var opening: Dictionary = _engine_with_seed(262)
	if not opening["ok"]:
		return opening
	var engine = opening["engine"]
	var state: Dictionary = engine.export_module_state()
	var attacker_id: String = _find_in_hand(state, 0, "M01")
	var target_id: String = _find_in_hand(state, 1, "M07")
	var trap_id: String = _find_in_hand(state, 1, "T06")
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": attacker_id}, "summon-attacker"):
		return {"ok": false}
	if not _finish_turn_from_main(engine, 0):
		return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	if not _perform(engine, "set_creature", 1, {"instance_id": target_id}, "set-target"):
		return {"ok": false}
	if not _perform(engine, "set_support", 1, {"instance_id": trap_id}, "set-t06"):
		return {"ok": false}
	state = engine.export_module_state()
	var trap_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(trap_id)
	if not _finish_turn_from_main(engine, 1):
		return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	return {"ok": true, "engine": engine, "attacker_id": attacker_id, "target_id": target_id, "trap_id": trap_id, "trap_slot": trap_slot}


func _engine_with_seed(seed: int) -> Dictionary:
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(seed).success:
		return {"ok": false}
	return {"ok": true, "engine": engine, "seed": seed}


func _finish_turn_from_main(engine, player_id: int) -> bool:
	for unused in range(4):
		if not _advance(engine, player_id):
			return false
	return true


func _change_position(engine, creature_id: String, position: String) -> bool:
	return _perform(engine, "change_position", 0, {"instance_id": creature_id, "target_position": position}, "position")


func _attack(engine, attacker_id: String) -> bool:
	return _perform(engine, "attack", 0, {"attacker_id": attacker_id, "target_slot": 0}, "attack")


func _activate(engine, player_id: int, support_slot: int) -> bool:
	return _perform(engine, "activate_reaction", player_id, {"support_slot": support_slot}, "activate")


func _pass(engine, player_id: int) -> bool:
	return _perform(engine, "pass_reaction", player_id, {}, "pass")


func _advance(engine, player_id: int) -> bool:
	return _perform(engine, "advance_phase", player_id, {}, "advance")


func _perform(engine, type: String, player_id: int, payload: Dictionary, prefix: String) -> bool:
	return engine.perform_action(GameAction.new(type, player_id, payload, _next_request(prefix))).success


func _find_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _effective_defense(engine, player_id: int) -> int:
	return engine.get_public_state()["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"][0]["effective_stats"]["defense"]


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


func _event_before(engine, first_type: String, second_type: String) -> bool:
	var first_sequence := -1
	var second_sequence := -1
	for event in engine.get_events(0, -1):
		if event["type"] == first_type:
			first_sequence = event["sequence"]
		if event["type"] == second_type:
			second_sequence = event["sequence"]
	return first_sequence >= 0 and second_sequence > first_sequence


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
