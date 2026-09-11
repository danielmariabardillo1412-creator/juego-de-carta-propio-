extends SceneTree
## Verifica las seis combinaciones ordenadas de Terreno y su sustitucion posterior.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

const RECIPES := [
	["R01", "R02", "RT01", "Bosque Inundado"],
	["R02", "R01", "RT02", "Humedal Fértil"],
	["R01", "R03", "RT03", "Bosque Ardiente"],
	["R03", "R01", "RT04", "Bosque Volcánico"],
	["R02", "R03", "RT05", "Caldera de Vapor"],
	["R03", "R02", "RT06", "Llanura de Obsidiana"],
]

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_all_ordered_recipes()
	_test_transformed_terrain_is_replaced()
	_test_transformed_identity_has_no_invented_bonus()
	_test_invalid_transformed_metadata_is_rejected()
	if _failures.is_empty():
		print("JCP-TERRAIN-COMBINATIONS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-TERRAIN-COMBINATIONS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_all_ordered_recipes() -> void:
	for recipe in RECIPES:
		var engine = _start_with_all_base_terrains()
		_expect(engine != null, "%s se prepara con los tres Terrenos" % recipe[2])
		if engine == null:
			continue
		_expect(_reach_main(engine), "%s alcanza Principal 1" % recipe[2])
		var state: Dictionary = engine.export_module_state()
		var first_id: String = _find_in_hand(state, recipe[0])
		var second_id: String = _find_in_hand(state, recipe[1])
		_expect(_perform(engine, first_id, "first"), "%s juega el primer componente" % recipe[2])
		_expect(_legal_terrain_exists(engine, second_id), "%s ofrece el segundo Terreno aunque la zona este ocupada" % recipe[2])
		_expect(_perform(engine, second_id, "second"), "%s transforma el Terreno" % recipe[2])
		state = engine.export_module_state()
		_expect_equal(state["cards"]["zones"]["terrain:0"]["cards"], [second_id], "%s conserva como soporte fisico la carta entrante" % recipe[2])
		_expect(first_id in state["cards"]["zones"]["graveyard:0"]["cards"], "%s envia el Terreno anterior al Cementerio" % recipe[2])
		var metadata: Dictionary = state["cards"]["instances"][second_id]["metadata"]
		_expect_equal(metadata.get("terrain_form_id", ""), recipe[2], "%s guarda su identidad canonica" % recipe[2])
		_expect_equal(metadata.get("terrain_form_name", ""), recipe[3], "%s guarda su nombre canonico" % recipe[2])
		_expect_equal(metadata.get("terrain_components", []), [recipe[0], recipe[1]], "%s conserva el orden de la receta" % recipe[2])
		var public_card: Dictionary = engine.get_public_state()["game"]["card_table"]["zones"]["terrain:0"]["cards"][0]
		_expect_equal(public_card["terrain_identity"], {
			"id": recipe[2],
			"display_name": recipe[3],
			"transformed": true,
			"components": [recipe[0], recipe[1]],
		}, "%s publica una identidad estable y completa" % recipe[2])
		var event: Dictionary = _last_event(engine, "terrain_transformed")
		_expect(not event.is_empty(), "%s emite terrain_transformed" % recipe[2])
		if not event.is_empty():
			_expect_equal(event["payload"]["result_id"], recipe[2], "%s identifica el resultado en el evento" % recipe[2])
			_expect_equal(event["payload"]["components"], [recipe[0], recipe[1]], "%s conserva el orden tambien en el evento" % recipe[2])
		_expect(engine.validate_internal_consistency()["ok"], "%s conserva la consistencia interna" % recipe[2])


func _test_transformed_terrain_is_replaced() -> void:
	var engine = _start_with_all_base_terrains()
	_expect(engine != null and _reach_main(engine), "se prepara la sustitucion de un Terreno transformado")
	if engine == null:
		return
	var state: Dictionary = engine.export_module_state()
	var forest_id: String = _find_in_hand(state, "R01")
	var lake_id: String = _find_in_hand(state, "R02")
	var volcano_id: String = _find_in_hand(state, "R03")
	_expect(_perform(engine, forest_id, "forest") and _perform(engine, lake_id, "lake"), "se forma Bosque Inundado")
	_expect(_perform(engine, volcano_id, "volcano"), "un tercer Terreno sin receta sustituye al transformado")
	state = engine.export_module_state()
	_expect_equal(state["cards"]["zones"]["terrain:0"]["cards"], [volcano_id], "la sustitucion deja un unico Terreno base")
	_expect(lake_id in state["cards"]["zones"]["graveyard:0"]["cards"], "el soporte del transformado termina en el Cementerio")
	_expect(not state["cards"]["instances"][lake_id]["metadata"].has("terrain_form_id"), "el soporte descartado no conserva una forma activa")
	var identity: Dictionary = engine.get_public_state()["game"]["card_table"]["zones"]["terrain:0"]["cards"][0]["terrain_identity"]
	_expect_equal(identity, {"id": "R03", "display_name": "Volcan", "transformed": false, "components": ["R03"]}, "la vista vuelve a una identidad de Terreno base")
	var event: Dictionary = _last_event(engine, "terrain_replaced")
	_expect(not event.is_empty(), "la sustitucion emite terrain_replaced")
	if not event.is_empty():
		_expect_equal(event["payload"]["previous_identity_id"], "RT01", "el evento recuerda la identidad transformada sustituida")
	_expect(engine.validate_internal_consistency()["ok"], "la sustitucion conserva la consistencia")


func _test_transformed_identity_has_no_invented_bonus() -> void:
	var engine = _start_with_all_base_terrains()
	_expect(engine != null and _reach_main(engine), "se prepara la comprobacion de efectos pospuestos")
	if engine == null:
		return
	_expect(_finish_turn_from_main(engine, 0), "el primer jugador termina su turno inicial")
	_expect(_play_empty_turn(engine, 1), "el rival completa un turno sin alterar la preparacion")
	_expect(_reach_main(engine), "el primer jugador alcanza Principal 1 con dos energias")
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_in_hand(state, "M10")
	var forest_id: String = _find_in_hand(state, "R01")
	var lake_id: String = _find_in_hand(state, "R02")
	_expect(not creature_id.is_empty(), "la apertura determinista contiene M10 de Naturaleza")
	_expect(_perform_action(engine, "summon_creature", {"instance_id": creature_id}, "creature"), "M10 se invoca legalmente con dos energias")
	_expect(_perform(engine, forest_id, "forest-bonus"), "Bosque entra para comprobar su efecto base")
	_expect_equal(_owner_creature_defense(engine), 4, "Bosque concede +1 DEF a Naturaleza")
	_expect(_perform(engine, lake_id, "transform-no-bonus"), "Lago transforma Bosque en Bosque Inundado")
	_expect_equal(_owner_creature_defense(engine), 3, "la forma transformada no hereda ni inventa bonos pendientes de definir")


func _test_invalid_transformed_metadata_is_rejected() -> void:
	var engine = _start_with_all_base_terrains()
	_expect(engine != null and _reach_main(engine), "se prepara un estado transformado para validar")
	if engine == null:
		return
	var state: Dictionary = engine.export_module_state()
	var first_id: String = _find_in_hand(state, "R01")
	var second_id: String = _find_in_hand(state, "R02")
	_expect(_perform(engine, first_id, "valid-first") and _perform(engine, second_id, "valid-second"), "se crea una forma valida antes de alterarla")
	var tampered: Dictionary = engine.export_module_state()
	tampered["cards"]["instances"][second_id]["metadata"]["terrain_components"] = ["R02", "R01"]
	var validation: Dictionary = GameModule.new().validate_state(tampered)
	_expect(not validation["ok"], "una receta reordenada manualmente se rechaza")
	_expect_equal(validation["code"], "JCP_TERRAIN_FORM_RECIPE_MISMATCH", "el rechazo distingue una receta incoherente")


func _start_with_all_base_terrains():
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(140).success:
		return null
	var state: Dictionary = engine.export_module_state()
	for definition_id in ["R01", "R02", "R03", "M10"]:
		if _find_in_hand(state, definition_id).is_empty():
			return null
	return engine


func _reach_main(engine) -> bool:
	return _perform_action(engine, "advance_phase", {}, "advance") and _perform_action(engine, "advance_phase", {}, "advance")


func _finish_turn_from_main(engine, player_id: int) -> bool:
	for unused in range(4):
		if not engine.perform_action(GameAction.new("advance_phase", player_id, {}, _next_request("finish"))).success:
			return false
	return true


func _play_empty_turn(engine, player_id: int) -> bool:
	for unused in range(6):
		if not engine.perform_action(GameAction.new("advance_phase", player_id, {}, _next_request("empty"))).success:
			return false
	return true


func _perform(engine, instance_id: String, prefix: String) -> bool:
	return _perform_action(engine, "play_terrain", {"instance_id": instance_id}, prefix)


func _perform_action(engine, type: String, payload: Dictionary, prefix: String) -> bool:
	return engine.perform_action(GameAction.new(type, 0, payload, _next_request(prefix))).success


func _find_in_hand(state: Dictionary, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:0"]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _legal_terrain_exists(engine, instance_id: String) -> bool:
	for action in engine.get_legal_actions(0):
		if action.type == "play_terrain" and action.payload == {"instance_id": instance_id}:
			return true
	return false


func _owner_creature_defense(engine) -> int:
	var cards: Array = engine.get_player_state(0)["game"]["card_table"]["zones"]["creatures:0"]["cards"]
	return cards[0]["effective_stats"]["defense"] if not cards.is_empty() else -1


func _last_event(engine, type: String) -> Dictionary:
	var events: Array = engine.get_events(0, -1)
	for index in range(events.size() - 1, -1, -1):
		if events[index]["type"] == type:
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
