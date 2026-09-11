extends SceneTree
## Verifica Magias principales y modificadores numericos persistentes.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_g01_changes_real_combat()
	_test_g02_defense_bonus()
	_test_g03_returns_creature_and_breaks_links()
	_test_persistent_guard_and_reveal_bonus()
	_test_terrain_bonus_without_identity_leak()
	if _failures.is_empty():
		print("JCP-EFFECTS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-EFFECTS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_g01_changes_real_combat() -> void:
	# M01 (2 ATQ) no supera a M03 (3 DEF) sin G01; con +2 si la destruye.
	var prepared: Dictionary = _engine_with_openings(["M01", "G01"], ["M03"])
	_expect(prepared["ok"], "se encuentra la apertura para probar G01")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine, 0), "jugador 0 llega a Principal 1")
	var state: Dictionary = engine.export_module_state()
	var attacker_id: String = _find_definition_in_hand(state, 0, "M01")
	var spell_id: String = _find_definition_in_hand(state, 0, "G01")
	_expect(_perform(engine, "summon_creature", 0, {"instance_id": attacker_id}, "summon-m01"), "M01 entra en ataque")
	_expect(_advance_many(engine, 0, 4), "jugador 0 entrega el turno")
	_expect(_reach_main(engine, 1), "jugador 1 llega a Principal 1")
	state = engine.export_module_state()
	var defender_id: String = _find_definition_in_hand(state, 1, "M03")
	_expect(_perform(engine, "set_creature", 1, {"instance_id": defender_id}, "set-m03"), "M03 se coloca en guardia")
	_expect(_advance_many(engine, 1, 4), "jugador 1 entrega el turno")
	_expect(_reach_main(engine, 0), "jugador 0 vuelve a Principal 1")
	var spell = engine.perform_action(GameAction.new(
		"play_main_spell",
		0,
		{"instance_id": spell_id, "target_player_id": 0, "target_slot": 0},
		_next_request("g01")
	))
	_expect(spell.success, "G01 se resuelve sobre la criatura propia")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["graveyard:0"]["cards"], [spell_id], "G01 va al cementerio tras resolverse")
	_expect_equal(_visible_stats(engine, 0)["attack"], 4, "la vista muestra el ataque temporal correcto")
	_expect_equal(_visible_stats(engine, 0)["base_attack"], 2, "la vista conserva por separado el ataque impreso")
	_expect(_advance(engine, 0), "se entra en Combate")
	var attack = engine.perform_action(GameAction.new(
		"attack", 0, {"attacker_id": attacker_id, "target_slot": 0}, _next_request("buffed-attack")
	))
	_expect(attack.success, "el combate usa el ataque mejorado")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["graveyard:1"]["cards"], [defender_id], "G01 permite superar los 3 puntos de defensa")
	_expect_equal(state["life"]["1"], 30, "la criatura en guardia evita dano sobrante")
	_expect(_advance_many(engine, 0, 3), "termina el turno de la mejora")
	_expect_equal(_visible_stats(engine, 0)["attack"], 2, "la mejora temporal expira al cambiar el turno")
	_expect(engine.validate_internal_consistency()["ok"], "G01 conserva la integridad del motor")


func _test_g02_defense_bonus() -> void:
	var prepared: Dictionary = _engine_with_openings(["M01", "G02"], [])
	_expect(prepared["ok"], "se encuentra la apertura para probar G02")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine, 0), "se alcanza Principal 1 para G02")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M01")
	var spell_id: String = _find_definition_in_hand(state, 0, "G02")
	_expect(_perform(engine, "summon_creature", 0, {"instance_id": creature_id}, "summon-g02-target"), "entra el objetivo de G02")
	_expect(_perform(engine, "play_main_spell", 0, {
		"instance_id": spell_id,
		"target_player_id": 0,
		"target_slot": 0,
	}, "g02"), "G02 se resuelve")
	_expect_equal(_visible_stats(engine, 0)["attack"], 2, "G02 no altera el ataque")
	_expect_equal(_visible_stats(engine, 0)["defense"], 2, "G02 concede dos puntos de defensa")
	_expect(spell_id in engine.export_module_state()["cards"]["zones"]["graveyard:0"]["cards"], "G02 va al cementerio")
	_expect(engine.validate_internal_consistency()["ok"], "G02 conserva la integridad")


func _test_g03_returns_creature_and_breaks_links() -> void:
	var prepared: Dictionary = _engine_with_openings(["G03"], ["M02", "E02"])
	_expect(prepared["ok"], "se encuentra la apertura para probar G03 y vinculos")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_advance_many(engine, 0, 6), "jugador 0 pasa su primer turno")
	_expect(_reach_main(engine, 1), "jugador 1 llega a Principal 1")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 1, "M02")
	var item_id: String = _find_definition_in_hand(state, 1, "E02")
	_expect(_perform(engine, "summon_creature", 1, {"instance_id": creature_id}, "summon-target"), "el objetivo entra visible")
	_expect(_perform(engine, "equip_item", 1, {
		"instance_id": item_id,
		"target_instance_id": creature_id,
	}, "equip-target"), "el objetivo recibe un equipo")
	_expect(_advance_many(engine, 1, 4), "jugador 1 entrega el turno")
	_expect(_reach_main(engine, 0), "jugador 0 vuelve a Principal 1")
	state = engine.export_module_state()
	var spell_id: String = _find_definition_in_hand(state, 0, "G03")
	var spell = engine.perform_action(GameAction.new(
		"play_main_spell",
		0,
		{"instance_id": spell_id, "target_player_id": 1, "target_slot": 0},
		_next_request("g03")
	))
	_expect(spell.success, "G03 devuelve una criatura visible de coste 2 o menos")
	state = engine.export_module_state()
	_expect(creature_id in state["cards"]["zones"]["hand:1"]["cards"], "la criatura regresa a la mano de su propietario")
	_expect_equal(state["cards"]["zones"]["creatures:1"]["cards"].size(), 0, "la criatura abandona el campo")
	_expect_equal(state["cards"]["zones"]["attachments:1"]["cards"].size(), 0, "el vinculo se rompe")
	_expect(item_id in state["cards"]["zones"]["graveyard:1"]["cards"], "el equipo roto va al cementerio")
	_expect(spell_id in state["cards"]["zones"]["graveyard:0"]["cards"], "G03 tambien va al cementerio")
	_expect(engine.validate_internal_consistency()["ok"], "G03 conserva la integridad y todas las cartas")


func _test_persistent_guard_and_reveal_bonus() -> void:
	var prepared: Dictionary = _engine_with_openings(["M02", "G04", "G05"], [])
	_expect(prepared["ok"], "se encuentra la apertura para probar G04 y G05")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine, 0), "se alcanza Principal 1 para preparar persistentes")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M02")
	var g04_id: String = _find_definition_in_hand(state, 0, "G04")
	var g05_id: String = _find_definition_in_hand(state, 0, "G05")
	_expect(_perform(engine, "set_creature", 0, {"instance_id": creature_id}, "set-guard"), "M02 entra oculta en guardia")
	_expect(_perform(engine, "play_persistent", 0, {"instance_id": g04_id}, "play-g04"), "G04 queda activa")
	_expect(_perform(engine, "play_persistent", 0, {"instance_id": g05_id}, "play-g05"), "G05 queda activa")
	var owner_stats: Dictionary = _owner_stats(engine, 0)
	_expect_equal(owner_stats["defense"], 3, "G04 aumenta la defensa de la criatura en guardia")
	_expect_equal(owner_stats["attack"], 1, "G04 no aumenta el ataque")
	_expect_equal(engine.get_public_state()["game"]["card_table"]["zones"]["creatures:0"]["cards"].size(), 0, "el bono no revela la criatura oculta")
	_expect(_advance_many(engine, 0, 4), "jugador 0 termina el turno de colocacion")
	_expect(_advance_many(engine, 1, 6), "jugador 1 pasa su turno")
	_expect(_reach_main(engine, 0), "jugador 0 vuelve a Principal 1")
	var reveal = engine.perform_action(GameAction.new(
		"change_position",
		0,
		{"instance_id": creature_id, "target_position": "attack"},
		_next_request("g05-reveal")
	))
	_expect(reveal.success, "la criatura pasa de guardia a ataque")
	_expect_equal(_visible_stats(engine, 0)["attack"], 2, "G05 concede +1 ATQ en la primera transicion")
	_expect_equal(_visible_stats(engine, 0)["defense"], 2, "G04 deja de aplicar fuera de guardia")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["instances"][g05_id]["metadata"]["last_trigger_turn"], state["turn"]["turn_number"], "G05 registra su uso del turno")
	_expect(_count_events(engine.get_events(0, -1), "persistent_effect_triggered") == 1, "la activacion de G05 produce un evento publico")
	_expect(engine.validate_internal_consistency()["ok"], "las persistentes conservan la integridad")


func _test_terrain_bonus_without_identity_leak() -> void:
	var prepared: Dictionary = _engine_with_openings(["M02", "R02"], [])
	_expect(prepared["ok"], "se encuentra criatura de Agua y Lago")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine, 0), "se alcanza Principal 1 para el Lago")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M02")
	var terrain_id: String = _find_definition_in_hand(state, 0, "R02")
	_expect(_perform(engine, "set_creature", 0, {"instance_id": creature_id}, "set-water"), "la criatura de Agua entra oculta")
	_expect(_perform(engine, "play_terrain", 0, {"instance_id": terrain_id}, "play-lake"), "el Lago entra en juego")
	_expect_equal(_owner_stats(engine, 0)["defense"], 3, "el Lago aumenta la defensa efectiva de Agua")
	var public_table: Dictionary = engine.get_public_state()["game"]["card_table"]
	_expect_equal(public_table["zones"]["creatures:0"]["cards"].size(), 0, "el Terreno no revela la identidad oculta beneficiada")
	_expect_equal(public_table["zones"]["terrain:0"]["cards"][0]["definition"]["id"], "R02", "el Lago si es informacion publica")
	_expect(engine.validate_internal_consistency()["ok"], "el bono de Terreno conserva la integridad")


func _engine_with_openings(player_zero_defs: Array, player_one_defs: Array) -> Dictionary:
	var opening_key := "%s|%s" % [",".join(player_zero_defs), ",".join(player_one_defs)]
	var known_seeds := {
		"M01,G01|M03": 419,
		"M01,G02|": 62,
		"G03|M02,E02": 41,
		"M02,G04,G05|": 2512,
		"M02,R02|": 240,
	}
	if not known_seeds.has(opening_key):
		return {"ok": false}
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(known_seeds[opening_key]).success:
		return {"ok": false}
	var state: Dictionary = engine.export_module_state()
	if not _hand_contains_all(state, 0, player_zero_defs) or not _hand_contains_all(state, 1, player_one_defs):
		return {"ok": false}
	return {"ok": true, "engine": engine}


func _hand_contains_all(state: Dictionary, player_id: int, definition_ids: Array) -> bool:
	for definition_id in definition_ids:
		if _find_definition_in_hand(state, player_id, definition_id).is_empty():
			return false
	return true


func _find_definition_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _visible_stats(engine, player_id: int) -> Dictionary:
	return engine.get_public_state()["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"][0]["effective_stats"]


func _owner_stats(engine, player_id: int) -> Dictionary:
	return engine.get_player_state(player_id)["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"][0]["effective_stats"]


func _reach_main(engine, player_id: int) -> bool:
	return _advance(engine, player_id) and _advance(engine, player_id)


func _advance_many(engine, player_id: int, count: int) -> bool:
	for index in range(count):
		if not _advance(engine, player_id):
			return false
	return true


func _advance(engine, player_id: int) -> bool:
	return _perform(engine, "advance_phase", player_id, {}, "advance")


func _perform(engine, action_type: String, player_id: int, payload: Dictionary, label: String) -> bool:
	return engine.perform_action(GameAction.new(
		action_type, player_id, payload, _next_request(label)
	)).success


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
