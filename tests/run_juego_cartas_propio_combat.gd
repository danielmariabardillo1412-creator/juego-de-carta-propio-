extends SceneTree
## Verifica el combate basico de doble comparacion, guardia y ataques directos.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_hidden_guard_and_attack_limit()
	_test_strict_comparison_and_retaliation()
	_test_direct_attack_and_life_defeat()
	if _failures.is_empty():
		print("JCP-COMBAT PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-COMBAT FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_hidden_guard_and_attack_limit() -> void:
	# M01 (2/0) destruye a M07 (0/1), pero guardia evita el dano sobrante.
	var prepared: Dictionary = _prepare_combat("M01", "M07", false)
	_expect(prepared["ok"], "se prepara combate contra guardia oculta")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	var attacker_id: String = prepared["attacker_id"]
	var target_id: String = prepared["target_id"]
	var legal_actions: Array = engine.get_legal_actions(0)
	var targeted_action = _find_attack_action(legal_actions, attacker_id, 0)
	_expect(targeted_action != null, "la casilla rival aparece como objetivo legal")
	if targeted_action != null:
		var payload_keys: Array = targeted_action.payload.keys()
		payload_keys.sort()
		_expect_equal(payload_keys, ["attacker_id", "target_slot"], "la accion no expone el identificador de la carta oculta")
		_expect(not JSON.stringify(targeted_action.payload).contains(target_id), "la lista de acciones no filtra el objetivo oculto")

	var blocked = engine.perform_action(GameAction.new(
		"attack",
		0,
		{"attacker_id": attacker_id, "target_slot": -1},
		_next_request("blocked-direct")
	))
	_expect(not blocked.success, "una criatura rival bloquea el ataque directo")
	_expect_equal(blocked.code, "JCP_DIRECT_ATTACK_BLOCKED", "el bloqueo directo tiene un codigo explicito")
	var attack = engine.perform_action(GameAction.new(
		"attack",
		0,
		{"attacker_id": attacker_id, "target_slot": 0},
		_next_request("guard-combat")
	))
	_expect(attack.success, "el ataque contra la casilla se resuelve")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["creatures:1"]["cards"].size(), 0, "la criatura superada abandona el campo")
	_expect_equal(state["cards"]["zones"]["graveyard:1"]["cards"], [target_id], "la criatura destruida llega al cementerio")
	_expect_equal(state["cards"]["zones"]["creatures:0"]["cards"], [attacker_id], "el atacante sobrevive a una represalia de cero")
	_expect(state["cards"]["instances"][target_id]["metadata"]["face_up"], "el objetivo se revela antes de ser destruido")
	_expect_equal(state["cards"]["instances"][target_id]["metadata"]["position"], "guard", "revelar por combate conserva la guardia")
	_expect_equal(state["life"]["1"], 30, "la guardia absorbe todo el dano sobrante")
	var public_events: Array = engine.get_events(0, -1)
	_expect(_event_before(public_events, "creature_revealed", "creature_combat_resolved"), "la revelacion publica precede al calculo")

	var repeated = engine.perform_action(GameAction.new(
		"attack",
		0,
		{"attacker_id": attacker_id, "target_slot": -1},
		_next_request("repeated")
	))
	_expect(not repeated.success, "una criatura no ataca dos veces por defecto")
	_expect_equal(repeated.code, "JCP_ATTACK_ALREADY_USED", "el segundo ataque identifica el limite")
	_expect(_advance(engine, 0), "el combate avanza a Principal 2")
	var late_guard = engine.perform_action(GameAction.new(
		"change_position",
		0,
		{"instance_id": attacker_id, "target_position": "guard"},
		_next_request("guard-after-attack")
	))
	_expect(not late_guard.success, "el atacante no se refugia en guardia despues de atacar")
	_expect_equal(late_guard.code, "JCP_POSITION_AFTER_ATTACK", "el cambio posterior al ataque se rechaza expresamente")
	_expect(engine.validate_internal_consistency()["ok"], "el motor queda integro tras destruir una criatura oculta")


func _test_strict_comparison_and_retaliation() -> void:
	# M01 (2/0) iguala la defensa de M02 (1/2): M02 vive y destruye a M01.
	var prepared: Dictionary = _prepare_combat("M01", "M02", false)
	_expect(prepared["ok"], "se prepara el caso de igualdad ataque-defensa")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	var attacker_id: String = prepared["attacker_id"]
	var target_id: String = prepared["target_id"]
	var attack = engine.perform_action(GameAction.new(
		"attack",
		0,
		{"attacker_id": attacker_id, "target_slot": 0},
		_next_request("strict-comparison")
	))
	_expect(attack.success, "el combate con igualdad se resuelve")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["creatures:1"]["cards"], [target_id], "igualar defensa no destruye al objetivo")
	_expect(state["cards"]["instances"][target_id]["metadata"]["face_up"], "el defensor superviviente queda visible")
	_expect_equal(state["cards"]["zones"]["graveyard:0"]["cards"], [attacker_id], "la represalia destruye al atacante fragil")
	_expect_equal(state["life"]["0"], 29, "el atacante destruido en ataque recibe el dano diferencial")
	_expect_equal(state["life"]["1"], 30, "el defensor en guardia no recibe dano")
	_expect(engine.validate_internal_consistency()["ok"], "la comparacion estricta conserva la integridad")


func _test_direct_attack_and_life_defeat() -> void:
	var seed: int = _find_seed("M01", "")
	_expect(seed >= 0, "se encuentra una apertura para el ataque directo")
	if seed < 0:
		return
	var engine = UniversalCardEngine.new(GameModule.new(), {
		"player_names": ["Lucia", "Alex"],
		"starting_life": 2,
	})
	_expect(engine.start(seed).success, "arranca la partida de vida reducida")
	var attacker_id: String = _find_definition_in_hand(engine.export_module_state(), 0, "M01")
	_expect(_advance(engine, 0) and _advance(engine, 0), "el jugador llega a Principal 1")
	var summon = engine.perform_action(GameAction.new(
		"summon_creature",
		0,
		{"instance_id": attacker_id},
		_next_request("direct-summon")
	))
	_expect(summon.success, "se invoca el atacante directo")
	for index in range(4):
		_expect(_advance(engine, 0), "el jugador 0 termina su primer turno (%d)" % index)
	for index in range(6):
		_expect(_advance(engine, 1), "el jugador 1 pasa sin criaturas (%d)" % index)
	for index in range(3):
		_expect(_advance(engine, 0), "el jugador 0 alcanza Combate (%d)" % index)
	_expect(_find_attack_action(engine.get_legal_actions(0), attacker_id, -1) != null, "sin defensores se ofrece el ataque directo")
	var direct = engine.perform_action(GameAction.new(
		"attack",
		0,
		{"attacker_id": attacker_id, "target_slot": -1},
		_next_request("direct-lethal")
	))
	_expect(direct.success, "el ataque directo se aplica")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["life"]["1"], 0, "el ataque reduce la vida hasta cero sin negativos")
	_expect_equal(state["winner_ids"], [0], "el atacante es declarado ganador")
	_expect_equal(state["finished_reason"], "life_zero", "la derrota registra su causa")
	_expect_equal(state["phase"]["current"], "FINISHED", "la partida termina inmediatamente")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "el nucleo universal tambien queda finalizado")
	_expect(engine.validate_internal_consistency()["ok"], "la derrota por vida conserva un estado valido")


func _prepare_combat(attacker_definition: String, target_definition: String, target_face_up: bool) -> Dictionary:
	var seed: int = _find_seed(attacker_definition, target_definition)
	if seed < 0:
		return {"ok": false}
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(seed).success:
		return {"ok": false}
	var attacker_id: String = _find_definition_in_hand(engine.export_module_state(), 0, attacker_definition)
	var target_id: String = _find_definition_in_hand(engine.export_module_state(), 1, target_definition)
	if not _advance(engine, 0) or not _advance(engine, 0):
		return {"ok": false}
	var summon = engine.perform_action(GameAction.new(
		"summon_creature",
		0,
		{"instance_id": attacker_id},
		_next_request("prepare-attacker")
	))
	if not summon.success:
		return {"ok": false}
	for index in range(4):
		if not _advance(engine, 0):
			return {"ok": false}
	if not _advance(engine, 1) or not _advance(engine, 1):
		return {"ok": false}
	var entry_type := "summon_creature" if target_face_up else "set_creature"
	var target_entry = engine.perform_action(GameAction.new(
		entry_type,
		1,
		{"instance_id": target_id},
		_next_request("prepare-target")
	))
	if not target_entry.success:
		return {"ok": false}
	for index in range(4):
		if not _advance(engine, 1):
			return {"ok": false}
	for index in range(3):
		if not _advance(engine, 0):
			return {"ok": false}
	return {
		"ok": true,
		"engine": engine,
		"attacker_id": attacker_id,
		"target_id": target_id,
	}


func _find_seed(player_zero_definition: String, player_one_definition: String) -> int:
	for seed in range(2000):
		var candidate = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
		if not candidate.start(seed).success:
			continue
		var state: Dictionary = candidate.export_module_state()
		if _find_definition_in_hand(state, 0, player_zero_definition).is_empty():
			continue
		if not player_one_definition.is_empty() and _find_definition_in_hand(state, 1, player_one_definition).is_empty():
			continue
		return seed
	return -1


func _find_definition_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _find_attack_action(actions: Array, attacker_id: String, target_slot: int):
	for action in actions:
		if action.type == "attack" and action.payload == {
			"attacker_id": attacker_id,
			"target_slot": target_slot,
		}:
			return action
	return null


func _event_before(events: Array, first_type: String, second_type: String) -> bool:
	var first_sequence := -1
	var second_sequence := -1
	for event in events:
		if event["type"] == first_type:
			first_sequence = event["sequence"]
		if event["type"] == second_type:
			second_sequence = event["sequence"]
	return first_sequence >= 0 and second_sequence > first_sequence


func _advance(engine, player_id: int) -> bool:
	var result = engine.perform_action(GameAction.new(
		"advance_phase",
		player_id,
		{},
		_next_request("advance")
	))
	return result.success


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
