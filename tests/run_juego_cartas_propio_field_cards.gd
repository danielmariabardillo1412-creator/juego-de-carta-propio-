extends SceneTree
## Verifica la primera capa fisica de apoyos, equipos y terrenos.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_hidden_support()
	_test_visible_persistent()
	_test_equipment_link()
	_test_equipment_requirement()
	_test_hidden_equipment_contract()
	_test_manual_weapon_compatibility()
	_test_terrain()
	if _failures.is_empty():
		print("JCP-FIELD-CARDS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-FIELD-CARDS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_hidden_support() -> void:
	var prepared: Dictionary = _engine_with_opening(["T01"])
	_expect(prepared["ok"], "se encuentra una apertura con Trampa")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para preparar apoyo")
	var state: Dictionary = engine.export_module_state()
	var trap_id: String = _find_definition_in_hand(state, 0, "T01")
	var action = _find_action(engine.get_legal_actions(0), "set_support", trap_id)
	_expect(action != null, "la Trampa ofrece la accion de preparacion")
	var set_result = engine.perform_action(GameAction.new(
		"set_support", 0, {"instance_id": trap_id}, _next_request("set-trap")
	))
	_expect(set_result.success, "la Trampa se coloca")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["support:0"]["cards"], [trap_id], "la carta ocupa la fila de apoyo")
	_expect(not state["cards"]["instances"][trap_id]["metadata"]["face_up"], "la Trampa queda boca abajo")
	_expect(not state["cards"]["instances"][trap_id]["metadata"]["active"], "preparar no activa la Trampa")
	var public_zone: Dictionary = engine.get_public_state()["game"]["card_table"]["zones"]["support:0"]
	var rival_zone: Dictionary = engine.get_player_state(1)["game"]["card_table"]["zones"]["support:0"]
	var owner_zone: Dictionary = engine.get_player_state(0)["game"]["card_table"]["zones"]["support:0"]
	_expect_equal(public_zone["count"], 1, "el publico conoce el numero de apoyos")
	_expect_equal(public_zone["cards"].size(), 0, "el publico no conoce la Trampa")
	_expect_equal(rival_zone["cards"].size(), 0, "el rival no conoce la Trampa")
	_expect_equal(owner_zone["cards"][0]["definition"]["id"], "T01", "el propietario ve su propia Trampa")
	_expect(not JSON.stringify(engine.get_events(0, -1)).contains(trap_id), "los eventos publicos no filtran la Trampa")
	_expect(_count_events(engine.get_events(0, 0), "private_support_set") == 1, "el propietario recibe el comprobante privado")
	_expect(engine.validate_internal_consistency()["ok"], "el apoyo oculto conserva la integridad")


func _test_visible_persistent() -> void:
	var prepared: Dictionary = _engine_with_opening(["G04"])
	_expect(prepared["ok"], "se encuentra una apertura con Magia persistente")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para la persistente")
	var card_id: String = _find_definition_in_hand(engine.export_module_state(), 0, "G04")
	var play = engine.perform_action(GameAction.new(
		"play_persistent", 0, {"instance_id": card_id}, _next_request("persistent")
	))
	_expect(play.success, "la Magia persistente se juega")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["support:0"]["cards"], [card_id], "la persistente ocupa apoyo")
	_expect(state["cards"]["instances"][card_id]["metadata"]["face_up"], "la persistente queda boca arriba")
	_expect(state["cards"]["instances"][card_id]["metadata"]["active"], "la persistente queda activa")
	var public_cards: Array = engine.get_public_state()["game"]["card_table"]["zones"]["support:0"]["cards"]
	_expect_equal(public_cards.size(), 1, "la persistente es visible publicamente")
	_expect_equal(public_cards[0]["definition"]["id"], "G04", "la identidad publica es correcta")
	_expect(engine.validate_internal_consistency()["ok"], "la persistente conserva la integridad")


func _test_equipment_link() -> void:
	var prepared: Dictionary = _engine_with_opening(["M02", "E01"])
	_expect(prepared["ok"], "se encuentra criatura manipuladora y equipo")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para equipar")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M02")
	var item_id: String = _find_definition_in_hand(state, 0, "E01")
	var summon = engine.perform_action(GameAction.new(
		"summon_creature", 0, {"instance_id": creature_id}, _next_request("equip-summon")
	))
	_expect(summon.success, "se invoca la criatura manipuladora")
	var equip = engine.perform_action(GameAction.new(
		"equip_item",
		0,
		{"instance_id": item_id, "target_instance_id": creature_id},
		_next_request("equip")
	))
	_expect(equip.success, "el equipo compatible se vincula")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["attachments:0"]["cards"], [item_id], "el equipo usa la zona de vinculos")
	_expect_equal(state["cards"]["zones"]["support:0"]["cards"].size(), 0, "el equipo no consume un espacio de apoyo")
	_expect_equal(state["cards"]["instances"][item_id]["metadata"]["linked_to"], creature_id, "el vinculo apunta a su portador")
	_expect_equal(engine.get_public_state()["game"]["card_table"]["zones"]["attachments:0"]["cards"].size(), 1, "el equipo vinculado es publico")
	var creature_view: Dictionary = engine.get_public_state()["game"]["card_table"]["zones"]["creatures:0"]["cards"][0]
	_expect_equal(creature_view["effective_stats"]["attack"], 2, "E01 aumenta en uno el ataque efectivo")
	_expect_equal(creature_view["effective_stats"]["defense"], 2, "E01 no altera la defensa")
	_expect(engine.validate_internal_consistency()["ok"], "el vinculo conserva la integridad")


func _test_equipment_requirement() -> void:
	var prepared: Dictionary = _engine_with_opening(["M01", "E01"])
	_expect(prepared["ok"], "se encuentra criatura no manipuladora y equipo restringido")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para probar el requisito")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M01")
	var item_id: String = _find_definition_in_hand(state, 0, "E01")
	_expect(engine.perform_action(GameAction.new(
		"summon_creature", 0, {"instance_id": creature_id}, _next_request("incompatible-summon")
	)).success, "se invoca la criatura no manipuladora")
	var equip = engine.perform_action(GameAction.new(
		"equip_item",
		0,
		{"instance_id": item_id, "target_instance_id": creature_id},
		_next_request("incompatible-equip")
	))
	_expect(not equip.success, "una criatura no manipuladora rechaza el arma")
	_expect_equal(equip.code, "JCP_EQUIP_REQUIREMENT_FAILED", "el rechazo explica el requisito")
	_expect_equal(engine.export_module_state()["cards"]["zones"]["hand:0"]["cards"].count(item_id), 1, "el rechazo no mueve el equipo")


func _test_hidden_equipment_contract() -> void:
	var prepared: Dictionary = _engine_with_opening(["M02", "E01", "E02"])
	_expect(prepared["ok"], "se encuentra M02 con arma y coraza para probar informacion oculta")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para equipar una criatura oculta")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M02")
	var sword_id: String = _find_definition_in_hand(state, 0, "E01")
	var armor_id: String = _find_definition_in_hand(state, 0, "E02")
	var set_result = engine.perform_action(GameAction.new(
		"set_creature", 0, {"instance_id": creature_id}, _next_request("hidden-set")
	))
	_expect(set_result.success, "M02 se coloca boca abajo")
	var sword = engine.perform_action(GameAction.new(
		"equip_item", 0, {"instance_id": sword_id, "target_instance_id": creature_id}, _next_request("hidden-sword")
	))
	_expect(not sword.success, "E01 no puede comprobar Manipulador en una criatura oculta")
	_expect_equal(sword.code, "JCP_EQUIP_REQUIREMENT_FAILED", "E01 oculta falla sin filtrar la aptitud")
	var armor = engine.perform_action(GameAction.new(
		"equip_item", 0, {"instance_id": armor_id, "target_instance_id": creature_id}, _next_request("hidden-armor")
	))
	_expect(armor.success, "E02 puede vincularse sin consultar identidad oculta")
	state = engine.export_module_state()
	_expect(not state["cards"]["instances"][creature_id]["metadata"]["face_up"], "equipar E02 no revela la criatura")
	_expect_equal(state["cards"]["instances"][armor_id]["metadata"]["linked_to"], creature_id, "E02 queda vinculada a la criatura oculta")
	_expect(sword_id in state["cards"]["zones"]["hand:0"]["cards"], "E01 sigue en mano tras el intento ilegal")
	_expect(engine.validate_internal_consistency()["ok"], "el contrato de Equipo oculto conserva integridad")


func _test_manual_weapon_compatibility() -> void:
	var prepared: Dictionary = _engine_with_opening(["M02", "E01", "E06"])
	_expect(prepared["ok"], "se encuentra una manipuladora con dos armas manuales")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para compatibilidad manual")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_definition_in_hand(state, 0, "M02")
	var sword_id: String = _find_definition_in_hand(state, 0, "E01")
	var hammer_id: String = _find_definition_in_hand(state, 0, "E06")
	_expect(engine.perform_action(GameAction.new(
		"summon_creature", 0, {"instance_id": creature_id}, _next_request("manual-summon")
	)).success, "M02 entra boca arriba")
	_expect(engine.perform_action(GameAction.new(
		"equip_item", 0, {"instance_id": sword_id, "target_instance_id": creature_id}, _next_request("manual-first")
	)).success, "la primera arma manual se vincula")
	var second = engine.perform_action(GameAction.new(
		"equip_item", 0, {"instance_id": hammer_id, "target_instance_id": creature_id}, _next_request("manual-second")
	))
	_expect(not second.success, "una segunda arma manual incompatible se rechaza")
	_expect_equal(second.code, "JCP_EQUIP_REQUIREMENT_FAILED", "el conflicto manual usa el contrato normal de compatibilidad")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["attachments:0"]["cards"].size(), 1, "solo una arma manual permanece vinculada")
	_expect(hammer_id in state["cards"]["zones"]["hand:0"]["cards"], "E06 no se mueve tras el rechazo")
	_expect(engine.validate_internal_consistency()["ok"], "la compatibilidad manual conserva integridad")


func _test_terrain() -> void:
	var prepared: Dictionary = _engine_with_opening(["R01"])
	_expect(prepared["ok"], "se encuentra una apertura con Terreno")
	if not prepared["ok"]:
		return
	var engine = prepared["engine"]
	_expect(_reach_main(engine), "se alcanza Principal 1 para jugar Terreno")
	var terrain_id: String = _find_definition_in_hand(engine.export_module_state(), 0, "R01")
	var play = engine.perform_action(GameAction.new(
		"play_terrain", 0, {"instance_id": terrain_id}, _next_request("terrain")
	))
	_expect(play.success, "el primer Terreno entra en juego")
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["terrain:0"]["cards"], [terrain_id], "el Terreno ocupa su unica zona")
	_expect(state["cards"]["instances"][terrain_id]["metadata"]["active"], "el Terreno queda activo")
	_expect_equal(engine.get_public_state()["game"]["card_table"]["zones"]["terrain:0"]["cards"][0]["definition"]["id"], "R01", "el Terreno es publico")
	_expect(engine.validate_internal_consistency()["ok"], "el Terreno conserva la integridad")


func _engine_with_opening(required_definitions: Array) -> Dictionary:
	for seed in range(5000):
		var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
		if not engine.start(seed).success:
			continue
		var state: Dictionary = engine.export_module_state()
		var found_all := true
		for definition_id in required_definitions:
			if _find_definition_in_hand(state, 0, definition_id).is_empty():
				found_all = false
				break
		if found_all:
			return {"ok": true, "engine": engine}
	return {"ok": false}


func _reach_main(engine) -> bool:
	return _advance(engine, 0) and _advance(engine, 0)


func _find_definition_in_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _find_action(actions: Array, action_type: String, instance_id: String):
	for action in actions:
		if action.type == action_type and action.payload.get("instance_id", "") == instance_id:
			return action
	return null


func _count_events(events: Array, event_type: String) -> int:
	var count := 0
	for event in events:
		if event["type"] == event_type:
			count += 1
	return count


func _advance(engine, player_id: int) -> bool:
	return engine.perform_action(GameAction.new(
		"advance_phase", player_id, {}, _next_request("advance")
	)).success


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
