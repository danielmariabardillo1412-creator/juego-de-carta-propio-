extends SceneTree
## Verifica respuestas opcionales a ataques, prioridad alterna y privacidad.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_g06_defense_response_and_priority()
	_test_g07_returns_target_and_cancels_attack()
	_test_t01_destroys_low_cost_attacker()
	_test_t02_reduces_attack_during_combat()
	if _failures.is_empty():
		print("JCP-REACTIONS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-REACTIONS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_g06_defense_response_and_priority() -> void:
	var prepared: Dictionary = _prepare_reaction(555, "G06")
	_expect(prepared["ok"], "se prepara G06 frente a un ataque")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	var declaration = _attack(engine, prepared["attacker_id"])
	_expect(declaration.success, "declarar el ataque abre la respuesta")
	var state: Dictionary = engine.export_module_state()
	_expect(not state["pending_response"].is_empty(), "el ataque queda pendiente antes del combate")
	_expect_equal(state["pending_response"]["priority_player_id"], 1, "el defensor recibe la primera prioridad")
	_expect_equal(state["cards"]["instances"][prepared["target_id"]]["metadata"]["face_up"], false, "el objetivo sigue oculto durante la respuesta")
	var public_json := JSON.stringify(engine.get_public_state()["game"]["response_window"])
	_expect(not public_json.contains(prepared["target_id"]), "la ventana publica no filtra el identificador oculto")
	var wrong_priority = engine.perform_action(GameAction.new(
		"pass_reaction", 0, {}, _next_request("wrong-priority")
	))
	_expect(not wrong_priority.success, "el atacante no actua fuera de prioridad")
	_expect_equal(wrong_priority.code, "JCP_REACTION_WRONG_PRIORITY", "la prioridad incorrecta tiene codigo propio")
	var reaction_action = _find_reaction_action(engine.get_legal_actions(1), prepared["reaction_slot"])
	_expect(reaction_action != null, "G06 aparece como respuesta opcional")
	_expect(_activate(engine, 1, prepared["reaction_slot"]), "el defensor activa G06")
	var public_after: Dictionary = engine.get_public_state()["game"]["response_window"]
	_expect_equal(public_after["chain"][0]["definition_id"], "G06", "la carta se hace publica al activarse")
	_expect(not public_after["chain"][0].has("support_id"), "la vista publica no expone identificadores internos")
	_expect_equal(engine.get_legal_actions(0).size(), 1, "el atacante solo puede pasar con esta primera familia de respuestas")
	_expect(_pass(engine, 0), "el atacante devuelve la prioridad")
	_expect(_pass(engine, 1), "el segundo pase consecutivo resuelve la cadena")
	state = engine.export_module_state()
	_expect(state["pending_response"].is_empty(), "la ventana se cierra tras dos pases")
	_expect(prepared["reaction_id"] in state["cards"]["zones"]["graveyard:1"]["cards"], "G06 va al cementerio al resolverse")
	_expect(prepared["target_id"] in state["cards"]["zones"]["creatures:1"]["cards"], "el +2 DEF salva al objetivo")
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "la represalia aun destruye al atacante fragil")
	_expect_equal(state["life"]["0"], 29, "la represalia conserva su dano diferencial")
	_expect(engine.validate_internal_consistency()["ok"], "G06 deja el motor consistente")


func _test_g07_returns_target_and_cancels_attack() -> void:
	var prepared: Dictionary = _prepare_reaction(157, "G07")
	_expect(prepared["ok"], "se prepara G07 frente a un ataque")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_attack(engine, prepared["attacker_id"]).success, "G07 recibe una declaracion de ataque")
	_expect(_activate(engine, 1, prepared["reaction_slot"]), "se activa G07")
	_expect(_pass(engine, 0) and _pass(engine, 1), "la cadena de G07 se cierra por pases")
	var state: Dictionary = engine.export_module_state()
	_expect(prepared["target_id"] in state["cards"]["zones"]["hand:1"]["cards"], "G07 devuelve la criatura atacada a la mano")
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["creatures:0"]["cards"], "el atacante permanece al cancelarse el combate")
	_expect_equal(state["cards"]["instances"][prepared["attacker_id"]]["metadata"]["last_attack_turn"], state["turn"]["turn_number"], "el ataque cancelado queda consumido")
	_expect(_has_event(engine.get_events(0, -1), "attack_canceled"), "G07 publica la cancelacion del ataque")
	_expect(not _has_event(engine.get_events(0, -1), "creature_combat_resolved"), "G07 evita una falsa resolucion de combate")
	_expect(engine.validate_internal_consistency()["ok"], "G07 deja el motor consistente")


func _test_t01_destroys_low_cost_attacker() -> void:
	var prepared: Dictionary = _prepare_reaction(417, "T01")
	_expect(prepared["ok"], "se prepara T01 contra una criatura de coste 1")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_attack(engine, prepared["attacker_id"]).success, "T01 recibe una declaracion valida")
	_expect(_activate(engine, 1, prepared["reaction_slot"]), "se activa T01")
	_expect(_pass(engine, 0) and _pass(engine, 1), "la cadena de T01 se resuelve")
	var state: Dictionary = engine.export_module_state()
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "T01 destruye al atacante de coste bajo")
	_expect(prepared["target_id"] in state["cards"]["zones"]["creatures:1"]["cards"], "el objetivo no entra en combate")
	_expect_equal(state["cards"]["instances"][prepared["target_id"]]["metadata"]["face_up"], false, "T01 no revela innecesariamente al objetivo")
	_expect(engine.validate_internal_consistency()["ok"], "T01 deja el motor consistente")


func _test_t02_reduces_attack_during_combat() -> void:
	var prepared: Dictionary = _prepare_reaction(462, "T02")
	_expect(prepared["ok"], "se prepara T02 frente a un ataque")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_attack(engine, prepared["attacker_id"]).success, "T02 recibe una declaracion valida")
	_expect(_activate(engine, 1, prepared["reaction_slot"]), "se activa T02")
	_expect(_pass(engine, 0) and _pass(engine, 1), "la cadena de T02 se resuelve")
	var combat_event: Dictionary = _last_event(engine.get_events(0, -1), "creature_combat_resolved")
	_expect(not combat_event.is_empty(), "T02 termina en una resolucion normal de combate")
	if not combat_event.is_empty():
		_expect_equal(combat_event["payload"]["attacker_attack"], 0, "T02 reduce dos puntos sin permitir ATQ negativo")
	var state: Dictionary = engine.export_module_state()
	_expect(prepared["target_id"] in state["cards"]["zones"]["creatures:1"]["cards"], "el objetivo sobrevive al ataque debilitado")
	_expect(prepared["attacker_id"] in state["cards"]["zones"]["graveyard:0"]["cards"], "el defensor sigue pudiendo contraatacar")
	_expect(engine.validate_internal_consistency()["ok"], "T02 deja el motor consistente")


func _prepare_reaction(seed: int, reaction_definition: String) -> Dictionary:
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(seed).success:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	var attacker_id: String = _find_definition_in_hand(state, 0, "M01")
	var target_id: String = _find_definition_in_hand(state, 1, "M02")
	var reaction_id: String = _find_definition_in_hand(state, 1, reaction_definition)
	if attacker_id.is_empty() or target_id.is_empty() or reaction_id.is_empty():
		return {"ok": false}
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	if not engine.perform_action(GameAction.new("summon_creature", 0, {"instance_id": attacker_id}, _next_request("attacker"))).success:
		return {"ok": false}
	for unused in range(4):
		if not _advance(engine, 0):
			return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	if not engine.perform_action(GameAction.new("set_creature", 1, {"instance_id": target_id}, _next_request("target"))).success:
		return {"ok": false}
	if not engine.perform_action(GameAction.new("set_support", 1, {"instance_id": reaction_id}, _next_request("reaction"))).success:
		return {"ok": false}
	state = engine.export_module_state()
	var reaction_slot: int = state["cards"]["zones"]["support:1"]["cards"].find(reaction_id)
	for unused in range(4):
		if not _advance(engine, 1):
			return {"ok": false}
	for unused in range(3):
		if not _advance(engine, 0):
			return {"ok": false}
	return {
		"ok": true,
		"engine": engine,
		"attacker_id": attacker_id,
		"target_id": target_id,
		"reaction_id": reaction_id,
		"reaction_slot": reaction_slot,
	}


func _attack(engine, attacker_id: String):
	return engine.perform_action(GameAction.new(
		"attack", 0, {"attacker_id": attacker_id, "target_slot": 0}, _next_request("attack")
	))


func _activate(engine, player_id: int, support_slot: int) -> bool:
	return engine.perform_action(GameAction.new(
		"activate_reaction", player_id, {"support_slot": support_slot}, _next_request("activate")
	)).success


func _pass(engine, player_id: int) -> bool:
	return engine.perform_action(GameAction.new(
		"pass_reaction", player_id, {}, _next_request("pass")
	)).success


func _advance(engine, player_id: int) -> bool:
	return engine.perform_action(GameAction.new(
		"advance_phase", player_id, {}, _next_request("advance")
	)).success


func _find_definition_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _find_reaction_action(actions: Array, support_slot: int):
	for action in actions:
		if action.type == "activate_reaction" and action.payload == {"support_slot": support_slot}:
			return action
	return null


func _has_event(events: Array, event_type: String) -> bool:
	return not _last_event(events, event_type).is_empty()


func _last_event(events: Array, event_type: String) -> Dictionary:
	for index in range(events.size() - 1, -1, -1):
		if events[index]["type"] == event_type:
			return events[index]
	return {}


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
