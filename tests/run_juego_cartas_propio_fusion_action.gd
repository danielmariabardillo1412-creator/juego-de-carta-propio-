extends SceneTree
## Verifica F010 como accion de duelo, su habilidad y el ciclo fisico de materiales.

const GameAction = preload("res://src/core/game_action.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_test_fusion_action_and_ability()
	_test_validation_guards()
	_test_additional_enabled_recipes()
	_test_destroy_releases_everything_to_graveyard()
	_test_return_restores_materials_to_hand()
	if _failures.is_empty():
		print("JCP-FUSION-ACTION PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-FUSION-ACTION FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_fusion_action_and_ability() -> void:
	var prepared: Dictionary = _prepared_main_state(["M04", "M09", "M01"])
	_expect(prepared["ok"], "se prepara una fase principal con los dos Goblins")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var m04: String = prepared["ids"]["M04"]
	var m09: String = prepared["ids"]["M09"]
	var target_id: String = prepared["ids"]["M01"]
	var legal: Array = module.get_legal_actions(state, 0)
	_expect(_has_fusion_action(legal, [m04, m09], "attack"), "F010 aparece como Fusion legal en ataque")
	_expect(_has_fusion_action(legal, [m04, m09], "guard"), "F010 aparece como Fusion legal en guardia")
	var action = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m09], "position": "guard"})
	var validation: Dictionary = module.validate_action(state, action)
	_expect(validation["ok"], "la accion F010 valida")
	var transition: Dictionary = module.reduce(state, action)
	_expect(transition["ok"], "la accion F010 reduce")
	if not transition["ok"]:
		return
	state = transition["state"]
	_expect(module.validate_state(state)["ok"], "el estado fusionado conserva todas las invariantes")
	_expect_equal(state["cards"]["zones"]["creatures:0"]["cards"], [m04, target_id], "la Fusion ocupa una sola casilla y conserva la otra criatura")
	_expect_equal(state["cards"]["zones"]["fusion_materials:0"]["cards"], [m09], "el segundo material queda contenido en zona publica")
	_expect_equal(state["cards"]["instances"][m09]["metadata"]["contained_by"], m04, "el material referencia al portador")
	var carrier_metadata: Dictionary = state["cards"]["instances"][m04]["metadata"]
	_expect_equal(carrier_metadata["position"], "guard", "la Fusion respeta la postura elegida")
	_expect(carrier_metadata["face_up"], "la Fusion entra boca arriba")
	_expect_equal(carrier_metadata["summoned_turn"], state["turn"]["turn_number"], "la Fusion cuenta como recien llegada")
	_expect(state["turn_usage"]["fusion_used"], "la accion consume la Fusion normal del turno")
	var entity: Dictionary = carrier_metadata["fusion_entity"]
	_expect_equal(entity["id"], "fusion.p0.t1", "la identidad generada es determinista")
	_expect_equal(entity["contained_physical_ids"], [m04, m09], "la entidad conserva ambos materiales fisicos")
	var public_view: Dictionary = module.get_public_state(state)
	var carrier_view: Dictionary = _card_from_zone(public_view["card_table"]["zones"]["creatures:0"]["cards"], m04)
	_expect_equal(carrier_view["fusion_identity"]["display_name"], "Banda Goblin", "la identidad F010 es visible en la vista publica")
	_expect_equal(carrier_view["effective_stats"]["attack"], 3, "F010 usa 3 ATQ base")
	_expect_equal(carrier_view["effective_stats"]["defense"], 3, "F010 usa 3 DEF base")
	_expect_equal(public_view["card_table"]["zones"]["fusion_materials:0"]["cards"].size(), 1, "el material contenido tambien es publicamente visible")

	state["energy"]["0"]["maximum"] = 2
	state["energy"]["0"]["available"] = 2
	var ability = GameAction.new("activate_fusion_ability", 0, {"source_instance_id": m04, "target_instance_id": target_id})
	_expect(module.validate_action(state, ability)["ok"], "la habilidad puede apuntar a otra criatura propia visible")
	var ability_transition: Dictionary = module.reduce(state, ability)
	_expect(ability_transition["ok"], "la habilidad de F010 se resuelve")
	state = ability_transition["state"]
	_expect_equal(state["energy"]["0"]["available"], 1, "la habilidad paga exactamente 1 de Energia")
	var target_view: Dictionary = _card_from_zone(module.get_public_state(state)["card_table"]["zones"]["creatures:0"]["cards"], target_id)
	_expect_equal(target_view["effective_stats"]["attack"], 3, "el objetivo recibe +1 ATQ hasta final del turno")
	var repeated: Dictionary = module.validate_action(state, ability)
	_expect(not repeated["ok"], "la misma Banda no activa dos veces en un turno")
	_expect_equal(repeated["code"], "JCP_FUSION_ABILITY_ALREADY_USED", "el limite de habilidad tiene error especifico")


func _test_validation_guards() -> void:
	var prepared: Dictionary = _prepared_main_state(["M04", "M09", "M05"])
	_expect(prepared["ok"], "se prepara el estado para rechazos de Fusion")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var m04: String = prepared["ids"]["M04"]
	var m09: String = prepared["ids"]["M09"]
	var valid_payload := {"material_instance_ids": [m04, m09], "position": "attack"}
	var hidden_state: Dictionary = state.duplicate(true)
	hidden_state["cards"]["instances"][m09]["metadata"]["face_up"] = false
	_expect_equal(module.validate_action(hidden_state, GameAction.new("fuse_creatures", 0, valid_payload))["code"], "JCP_FUSION_MATERIAL_HIDDEN", "un material oculto no se fusiona")
	var wrong_phase: Dictionary = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	_expect_equal(module.validate_action(wrong_phase, GameAction.new("fuse_creatures", 0, valid_payload))["code"], "JCP_FUSION_PHASE_INVALID", "la Fusion normal se rechaza fuera de fase principal")
	var duplicate = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m04], "position": "attack"})
	_expect_equal(module.validate_action(state, duplicate)["code"], "JCP_FUSION_MATERIALS_INVALID", "una carta fisica no puede pagar dos materiales")
	var enemy = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, _instance_for(state, "M09", 1)], "position": "attack"})
	_expect_equal(module.validate_action(state, enemy)["code"], "JCP_FUSION_MATERIAL_NOT_CONTROLLED", "no se usa un material rival")
	var bad_position = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m09], "position": "hidden"})
	_expect_equal(module.validate_action(state, bad_position)["code"], "JCP_FUSION_POSITION_INVALID", "la postura de salida debe ser ataque o guardia")
	var transition: Dictionary = module.reduce(state, GameAction.new("fuse_creatures", 0, valid_payload))
	var used_state: Dictionary = transition["state"]
	var second_attempt = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m09], "position": "guard"})
	var before: String = JSON.stringify(used_state)
	var rejection: Dictionary = module.validate_action(used_state, second_attempt)
	_expect_equal(rejection["code"], "JCP_FUSION_ALREADY_USED", "solo hay una accion de Fusion normal por turno")
	_expect_equal(JSON.stringify(used_state), before, "un rechazo de Fusion es atomico")
	used_state["turn_usage"]["fusion_used"] = false
	var chained_ids := [m04, prepared["ids"]["M05"]]
	_expect(not _has_fusion_action(module.get_legal_actions(used_state, 0), chained_ids, "attack"), "una Fusion previa no se anuncia como material de otra Fusion")
	_expect_equal(module.validate_action(used_state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": chained_ids, "position": "attack"}))["code"], "JCP_FUSION_CHAIN_NOT_ENABLED", "la validacion conserva el rechazo explicito de Fusion encadenada")


func _test_additional_enabled_recipes() -> void:
	for definitions in [["M01", "M07"], ["M05", "M04"], ["M10", "M09"], ["M11", "M13"], ["M06", "M08"], ["M03", "M06"]]:
		var prepared: Dictionary = _prepared_main_state(definitions)
		_expect(prepared["ok"], "se prepara una receta adicional habilitada")
		if not prepared["ok"]:
			continue
		var action = GameAction.new("fuse_creatures", 0, {
			"material_instance_ids": [prepared["ids"][definitions[0]], prepared["ids"][definitions[1]]],
			"position": "attack",
		})
		var validation: Dictionary = prepared["module"].validate_action(prepared["state"], action)
		_expect(validation["ok"], "%s + %s ya puede fusionarse en el duelo" % definitions)
		if validation["ok"]:
			var transition: Dictionary = prepared["module"].reduce(prepared["state"], action)
			_expect(transition["ok"] and prepared["module"].validate_state(transition["state"])["ok"], "la receta adicional conserva un estado valido")


func _test_destroy_releases_everything_to_graveyard() -> void:
	var prepared: Dictionary = _prepared_main_state(["M04", "M09"], {"E01": "M04", "E02": "M09"})
	_expect(prepared["ok"], "se prepara F010 con equipo en ambos materiales")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var m04: String = prepared["ids"]["M04"]
	var m09: String = prepared["ids"]["M09"]
	var fused: Dictionary = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m09], "position": "attack"}))
	_expect(fused["ok"], "F010 hereda equipo compatible")
	state = fused["state"]
	for equipment_definition in ["E01", "E02"]:
		_expect_equal(state["cards"]["instances"][prepared["ids"][equipment_definition]]["metadata"]["linked_to"], m04, "%s se religa al portador de F010" % equipment_definition)
	var destroyed: Dictionary = module.call("_destroy_creature_and_links", state, 0, m04)
	_expect(destroyed["ok"], "destruir F010 disuelve su entidad")
	state = destroyed["state"]
	for physical_id in [m04, m09, prepared["ids"]["E01"], prepared["ids"]["E02"]]:
		_expect(physical_id in state["cards"]["zones"]["graveyard:0"]["cards"], "cada material y equipo termina en Cementerio")
	_expect(state["cards"]["zones"]["fusion_materials:0"]["cards"].is_empty(), "no quedan materiales contenidos tras la destruccion")
	_expect(not state["cards"]["instances"][m04]["metadata"].has("fusion_entity"), "la identidad generada desaparece al destruirse")
	_expect(module.validate_state(state)["ok"], "la destruccion de F010 conserva el estado valido")


func _test_return_restores_materials_to_hand() -> void:
	var prepared: Dictionary = _prepared_main_state(["M04", "M09"], {"E01": "M04"})
	_expect(prepared["ok"], "se prepara F010 para devolverla")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var m04: String = prepared["ids"]["M04"]
	var m09: String = prepared["ids"]["M09"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [m04, m09], "position": "guard"}))["state"]
	var returned: Dictionary = module.call("_return_creature_and_break_links", state, 0, m04)
	_expect(returned["ok"], "devolver F010 disuelve su entidad")
	state = returned["state"]
	_expect(m04 in state["cards"]["zones"]["hand:0"]["cards"] and m09 in state["cards"]["zones"]["hand:0"]["cards"], "ambos materiales vuelven a la mano")
	_expect(prepared["ids"]["E01"] in state["cards"]["zones"]["graveyard:0"]["cards"], "el equipo se rompe y va al Cementerio")
	_expect(state["cards"]["zones"]["fusion_materials:0"]["cards"].is_empty(), "la zona de contenidos queda vacia")
	_expect(not state["cards"]["instances"][m09]["metadata"].has("contained_by"), "el material liberado pierde el enlace interno")
	_expect(module.validate_state(state)["ok"], "la devolucion de F010 conserva el estado valido")


func _prepared_main_state(creature_definitions: Array, equipment_links: Dictionary = {}) -> Dictionary:
	var module = GameModule.new()
	var state: Dictionary = module.create_initial_state({"player_names": ["Lucia", "Alex"]}, 41010)
	for _index in range(2):
		var advance = GameAction.new("advance_phase", 0, {})
		var validation: Dictionary = module.validate_action(state, advance)
		if not validation["ok"]:
			return {"ok": false, "code": validation["code"]}
		var transition: Dictionary = module.reduce(state, advance)
		if not transition["ok"]:
			return {"ok": false, "code": transition["code"]}
		state = transition["state"]
	var ids: Dictionary = {}
	for definition_id in creature_definitions:
		var instance_id: String = _instance_for(state, definition_id, 0)
		ids[definition_id] = instance_id
		var moved: Dictionary = _move_to_field(state, instance_id, "creatures:0", {"face_up": true, "position": "attack", "summoned_turn": -1})
		if not moved["ok"]:
			return moved
		state = moved["state"]
	for equipment_definition in equipment_links:
		var equipment_id: String = _instance_for(state, equipment_definition, 0)
		ids[equipment_definition] = equipment_id
		var target_definition: String = equipment_links[equipment_definition]
		var moved_equipment: Dictionary = _move_to_field(state, equipment_id, "attachments:0", {"face_up": true, "active": true, "linked_to": ids[target_definition]})
		if not moved_equipment["ok"]:
			return moved_equipment
		state = moved_equipment["state"]
	var state_check: Dictionary = module.validate_state(state)
	if not state_check["ok"]:
		return {"ok": false, "code": state_check["code"]}
	return {"ok": true, "module": module, "state": state, "ids": ids}


func _move_to_field(state: Dictionary, instance_id: String, destination_zone: String, metadata_patch: Dictionary) -> Dictionary:
	var located: Dictionary = CardState.locate_card(state["cards"], instance_id)
	if not located["ok"]:
		return located
	var metadata: Dictionary = state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata.merge(metadata_patch, true)
	var update: Dictionary = CardState.update_instance_metadata(state["cards"], instance_id, metadata)
	if not update["ok"]:
		return update
	var move: Dictionary = CardState.move_card(update["value"], instance_id, located["zone_id"], destination_zone)
	if not move["ok"]:
		return move
	var next_state: Dictionary = state.duplicate(true)
	next_state["cards"] = move["value"]
	return {"ok": true, "state": next_state}


func _instance_for(state: Dictionary, definition_id: String, owner_id: int) -> String:
	for instance_id in state["cards"]["instances"]:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		if instance["definition_id"] == definition_id and instance["metadata"]["owner_id"] == owner_id:
			return instance_id
	return ""


func _has_fusion_action(actions: Array, material_ids: Array, position: String) -> bool:
	for action in actions:
		if action.type == "fuse_creatures" and action.payload.get("material_instance_ids", []) == material_ids and action.payload.get("position", "") == position:
			return true
	return false


func _card_from_zone(cards: Array, instance_id: String) -> Dictionary:
	for card in cards:
		if card["instance"]["id"] == instance_id:
			return card
	return {}


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
