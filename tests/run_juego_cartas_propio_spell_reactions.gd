extends SceneTree
## Verifica la respuesta T03 a Magias principales y su carácter opcional.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_t03_negates_main_spell()
	_test_defender_can_decline_t03()
	if _failures.is_empty():
		print("JCP-SPELL-REACTIONS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-SPELL-REACTIONS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_t03_negates_main_spell() -> void:
	var prepared: Dictionary = _prepare_t03()
	_expect(prepared["ok"], "se prepara una Magia frente a T03")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	var activation = _play_g01(engine, prepared["spell_id"], prepared["creature_id"])
	_expect(activation.success, "G01 se declara correctamente")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "spell", "la ventana conserva un contexto generico de Magia")
	_expect(prepared["spell_id"] in state["cards"]["zones"]["hand:0"]["cards"], "la Magia no se resuelve antes de cerrar respuestas")
	_expect_equal(_effective_attack(engine, 0), 2, "G01 todavia no aplica su bono")
	var public_window: Dictionary = engine.get_public_state()["game"]["response_window"]
	_expect_equal(public_window["context"]["spell_definition_id"], "G01", "la activacion publica identifica la Magia")
	_expect(not JSON.stringify(public_window).contains(prepared["spell_id"]), "la vista publica no necesita filtrar el identificador de la mano")
	var reaction = _find_action(engine.get_legal_actions(1), "activate_reaction")
	_expect(reaction != null, "T03 aparece como respuesta opcional")
	if reaction != null:
		_expect_equal(reaction.payload, {"support_slot": prepared["trap_slot"]}, "T03 se selecciona por casilla, no por id oculto")
	_expect(_activate(engine, 1, prepared["trap_slot"]), "el defensor activa T03")
	_expect(_pass(engine, 0), "el lanzador devuelve la prioridad")
	_expect(_pass(engine, 1), "el defensor cierra la cadena")
	state = engine.export_module_state()
	_expect(state["pending_response"].is_empty(), "la respuesta a la Magia queda cerrada")
	_expect(prepared["spell_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "la Magia anulada termina en el cementerio")
	_expect(prepared["trap_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "T03 termina en el cementerio")
	_expect_equal(_effective_attack(engine, 0), 2, "T03 impide por completo el efecto de G01")
	var events: Array = engine.get_events(0, -1)
	_expect(_has_event(events, "main_spell_activated"), "se publica la activacion antes de responder")
	_expect(_has_event(events, "main_spell_negated"), "se publica la anulacion")
	_expect(not _has_event(events, "main_spell_resolved"), "una Magia anulada no publica una resolucion falsa")
	_expect(engine.validate_internal_consistency()["ok"], "T03 conserva la consistencia interna")


func _test_defender_can_decline_t03() -> void:
	var prepared: Dictionary = _prepare_t03()
	_expect(prepared["ok"], "se prepara la rama voluntaria de T03")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_play_g01(engine, prepared["spell_id"], prepared["creature_id"]).success, "G01 abre la ventana opcional")
	_expect(_pass(engine, 1), "el defensor puede no gastar T03")
	_expect(_pass(engine, 0), "el lanzador cierra la ventana con el segundo pase")
	var state: Dictionary = engine.export_module_state()
	_expect(prepared["trap_id"] in state["cards"]["zones"]["support:1"]["cards"], "T03 permanece preparada al no activarse")
	_expect_equal(state["cards"]["instances"][prepared["trap_id"]]["metadata"]["face_up"], false, "T03 sigue oculta tras pasar")
	_expect(prepared["spell_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "G01 resuelta llega a su cementerio")
	_expect_equal(_effective_attack(engine, 0), 4, "G01 aplica +2 ATQ cuando nadie la anula")
	_expect(_has_event(engine.get_events(0, -1), "main_spell_resolved"), "la Magia no anulada publica su resolucion")
	_expect(engine.validate_internal_consistency()["ok"], "pasar sin activar T03 conserva la consistencia")


func _prepare_t03() -> Dictionary:
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(2345).success:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_in_hand(state, 0, "M01")
	var spell_id: String = _find_in_hand(state, 0, "G01")
	var target_id: String = _find_in_hand(state, 1, "M02")
	var trap_id: String = _find_in_hand(state, 1, "T03")
	if creature_id.is_empty() or spell_id.is_empty() or target_id.is_empty() or trap_id.is_empty():
		return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	if not _perform(engine, "summon_creature", 0, {"instance_id": creature_id}, "summon-source"):
		return {"ok": false}
	for unused in range(4):
		if not _advance(engine, 0):
			return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	if not _perform(engine, "set_creature", 1, {"instance_id": target_id}, "set-target"):
		return {"ok": false}
	if not _perform(engine, "set_support", 1, {"instance_id": trap_id}, "set-t03"):
		return {"ok": false}
	state = engine.export_module_state()
	var trap_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(trap_id)
	for unused in range(4):
		if not _advance(engine, 1):
			return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	return {
		"ok": true,
		"engine": engine,
		"creature_id": creature_id,
		"spell_id": spell_id,
		"trap_id": trap_id,
		"trap_slot": trap_slot,
	}


func _play_g01(engine, spell_id: String, creature_id: String):
	var state: Dictionary = engine.export_module_state()
	var target_slot: int = state["cards"]["zones"]["creatures:0"]["cards"].find(creature_id)
	return engine.perform_action(GameAction.new(
		"play_main_spell",
		0,
		{"instance_id": spell_id, "target_player_id": 0, "target_slot": target_slot},
		_next_request("g01")
	))


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


func _effective_attack(engine, player_id: int) -> int:
	return engine.get_public_state()["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"][0]["effective_stats"]["attack"]


func _find_action(actions: Array, type: String):
	for action in actions:
		if action.type == type:
			return action
	return null


func _has_event(events: Array, type: String) -> bool:
	for event in events:
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
