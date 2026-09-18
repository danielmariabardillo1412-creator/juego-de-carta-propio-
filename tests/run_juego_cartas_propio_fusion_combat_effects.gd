extends SceneTree
## Verifica liderazgo de F001 y eleccion de combate de F067 en ambos lados.

const GameAction = preload("res://src/core/game_action.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_test_fusion_formed_in_main1_can_attack()
	_test_g07_cannot_return_generated_fusion()
	_test_alpha_leadership_once_per_turn()
	_test_dragon_extra_attack()
	_test_dragon_no_false_trigger()
	_test_dragon_t06()
	_test_torch_band_without_other_goblin()
	_test_torch_band_with_other_goblin()
	_test_thicket_company_once_per_turn()
	_test_steam_elemental_entry_duration()
	_test_two_headed_troll_regeneration_and_t06()
	_test_two_headed_troll_regenerates_once_per_turn()
	_test_water_major_attack_bonus()
	_test_water_major_attacker_choice()
	_test_water_major_defender_choice()
	_test_water_major_choice_precedes_reactions()
	if _failures.is_empty():
		print("JCP-FUSION-COMBAT-EFFECTS PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-FUSION-COMBAT-EFFECTS FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_fusion_formed_in_main1_can_attack() -> void:
	var prepared := _prepared_state({0: ["M04", "M09"]})
	_expect(prepared["ok"], "se prepara una Fusion en Principal 1")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var carrier: String = prepared["ids"]["0:M04"]
	var fused: Dictionary = module.reduce(state, GameAction.new("fuse_creatures", 0, {
		"material_instance_ids": [carrier, prepared["ids"]["0:M09"]],
		"position": "attack",
	}))
	_expect(fused["ok"], "F010 se forma en Principal 1")
	if not fused["ok"]:
		return
	state = fused["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var attack = GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": -1})
	_expect(module.validate_action(state, attack)["ok"], "una Fusion formada en Principal 1 puede atacar ese turno")
	var result: Dictionary = module.reduce(state, attack)
	_expect(result["ok"], "el ataque de la Fusion recien formada se resuelve")
	_expect_equal(_count_events(result["events"], "direct_attack_resolved"), 1, "la Fusion produce un ataque directo normal")


func _test_g07_cannot_return_generated_fusion() -> void:
	var prepared := _prepared_state({0: ["M17"], 1: ["M04", "M09"]})
	_expect(prepared["ok"], "se prepara una Fusion defensora frente a G07")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var fusion_carrier: String = prepared["ids"]["1:M04"]
	var fused: Dictionary = module.reduce(state, GameAction.new("fuse_creatures", 1, {
		"material_instance_ids": [fusion_carrier, prepared["ids"]["1:M09"]],
		"position": "guard",
	}))
	_expect(fused["ok"], "el defensor forma F010")
	if not fused["ok"]:
		return
	state = fused["state"]
	var support: Dictionary = _place_support(state, _instance_for(state, "G07", 1), 1)
	_expect(support["ok"], "G07 queda preparada desde un turno anterior")
	if not support["ok"]:
		return
	state = support["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var attack = GameAction.new("attack", 0, {"attacker_id": prepared["ids"]["0:M17"], "target_slot": 0})
	_expect(module.validate_action(state, attack)["ok"], "se declara ataque contra la Fusion generada")
	var result: Dictionary = module.reduce(state, attack)
	_expect(result["ok"], "el combate contra la Fusion se resuelve sin ventana G07")
	_expect(result["state"]["pending_response"].is_empty(), "G07 no aparece como respuesta legal contra una Fusion generada")
	_expect(_instance_for(result["state"], "G07", 1) in result["state"]["cards"]["zones"]["support:1"]["cards"], "G07 permanece preparada y no se consume")
	_expect_equal(_count_events(result["events"], "creature_combat_resolved"), 1, "el ataque no se cancela por un retorno ilegal")


func _test_alpha_leadership_once_per_turn() -> void:
	var prepared := _prepared_state({0: ["M01", "M07", "M04", "M09"], 1: ["M07", "M02"]})
	_expect(prepared["ok"], "se prepara el combate del Alfa")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [ids["0:M01"], ids["0:M07"]], "position": "guard"}))["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var first: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M04"], "target_slot": 0}))
	_expect(first["ok"], "otra criatura propia puede recibir el liderazgo")
	state = first["state"]
	_expect(ids["1:M07"] in state["cards"]["zones"]["graveyard:1"]["cards"], "el +1 ATQ del Alfa cambia el primer combate")
	_expect_equal(_count_events(first["events"], "fusion_leadership_triggered"), 1, "el Alfa publica su disparo")
	var second: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M09"], "target_slot": 0}))
	_expect(second["ok"], "una segunda criatura puede atacar el mismo turno")
	state = second["state"]
	_expect(ids["1:M02"] in state["cards"]["zones"]["creatures:1"]["cards"], "el liderazgo no se repite en el segundo ataque")
	_expect_equal(_count_events(second["events"], "fusion_leadership_triggered"), 0, "el segundo ataque no vuelve a disparar el Alfa")
	_expect(module.validate_state(state)["ok"], "F001 conserva un estado valido tras ambos combates")


func _test_torch_band_without_other_goblin() -> void:
	var prepared := _prepared_state({0: ["M05", "M04"], 1: ["M12"]})
	_expect(prepared["ok"], "se prepara F011 sin otro Goblin")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M05"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M04"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var combat: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(combat["ok"], "F011 puede atacar sin otro Goblin")
	var trigger: Dictionary = _event(combat["events"], "fusion_torch_band_triggered")
	var resolved: Dictionary = _event(combat["events"], "creature_combat_resolved")
	_expect_equal(trigger["payload"]["defense_bonus"], 0, "sin otro Goblin no obtiene DEF")
	_expect_equal(resolved["payload"]["attacker_attack"], 4, "F011 obtiene siempre +1 ATQ al atacar")
	_expect_equal(resolved["payload"]["attacker_defense"], 2, "su DEF base no cambia sin companero")
	_expect(carrier in combat["state"]["cards"]["zones"]["graveyard:0"]["cards"], "la falta de DEF permite el contraataque")


func _test_torch_band_with_other_goblin() -> void:
	var prepared := _prepared_state({0: ["M05", "M04", "M09"], 1: ["M12"]})
	_expect(prepared["ok"], "se prepara F011 con otro Goblin visible")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M05"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M04"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var combat: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(combat["ok"], "F011 ataca junto a otro Goblin")
	var trigger: Dictionary = _event(combat["events"], "fusion_torch_band_triggered")
	var resolved: Dictionary = _event(combat["events"], "creature_combat_resolved")
	_expect_equal(trigger["payload"]["defense_bonus"], 1, "otro Goblin visible habilita +1 DEF")
	_expect_equal([resolved["payload"]["attacker_attack"], resolved["payload"]["attacker_defense"]], [4, 3], "F011 combate como 4/3 con companero")
	_expect(carrier in combat["state"]["cards"]["zones"]["creatures:0"]["cards"], "la DEF adicional permite sobrevivir por igualdad")
	_expect(module.validate_state(combat["state"])["ok"], "F011 conserva el estado valido tras combatir")


func _test_thicket_company_once_per_turn() -> void:
	var prepared := _prepared_state({0: ["M18", "M17"], 1: ["M10", "M09"]})
	_expect(prepared["ok"], "se prepara F012 frente a dos atacantes")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["1:M10"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 1, {"material_instance_ids": [carrier, ids["1:M09"]], "position": "guard"}))["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var first: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M18"], "target_slot": 0}))
	_expect(first["ok"], "el primer atacante combate contra F012")
	state = first["state"]
	var first_event: Dictionary = _event(first["events"], "creature_combat_resolved")
	_expect_equal(first_event["payload"]["attacker_attack"], 4, "F012 reduce de 5 a 4 el primer ATQ")
	_expect_equal(_count_events(first["events"], "fusion_thicket_guard_triggered"), 1, "F012 publica su defensa reactiva")
	_expect(carrier in state["cards"]["zones"]["creatures:1"]["cards"], "la penalizacion permite sobrevivir por igualdad")
	var second: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M17"], "target_slot": 0}))
	_expect(second["ok"], "un segundo atacante puede combatir el mismo turno")
	var second_event: Dictionary = _event(second["events"], "creature_combat_resolved")
	_expect_equal(second_event["payload"]["attacker_attack"], 7, "F012 no reduce un segundo ataque en el mismo turno")
	_expect_equal(_count_events(second["events"], "fusion_thicket_guard_triggered"), 0, "la defensa reactiva queda consumida hasta el siguiente turno")
	_expect(carrier in second["state"]["cards"]["zones"]["graveyard:1"]["cards"], "el segundo ataque puede destruir F012")
	_expect(module.validate_state(second["state"])["ok"], "F012 conserva el estado valido tras ambos combates")


func _test_steam_elemental_entry_duration() -> void:
	var prepared := _prepared_state({0: ["M03", "M06"], 1: ["M14"]})
	_expect(prepared["ok"], "se prepara F068 con objetivo enemigo")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var action = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [ids["0:M03"], ids["0:M06"]], "position": "guard", "target_instance_id": ids["1:M14"]})
	var missing_target = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [ids["0:M03"], ids["0:M06"]], "position": "guard"})
	_expect_equal(module.validate_action(state, missing_target)["code"], "JCP_FUSION_TARGET_INVALID", "F068 exige objetivo cuando existe uno visible")
	_expect(module.validate_action(state, action)["ok"], "F068 acepta una criatura enemiga visible")
	var fused: Dictionary = module.reduce(state, action)
	_expect(fused["ok"], "el efecto de entrada de F068 se resuelve")
	state = fused["state"]
	_expect_equal(module.call("_effective_stats", state, ids["1:M14"])["attack"], 3, "el objetivo pierde 1 ATQ")
	_expect_equal(_count_events(fused["events"], "fusion_entry_effect_applied"), 1, "F068 publica el efecto de entrada")
	_expect(module.validate_state(state)["ok"], "la duracion de Vapor conserva el estado valido")
	for _phase in range(4):
		state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	_expect_equal(state["phase"]["current"], "START", "comienza el siguiente turno del objetivo")
	_expect_equal(module.call("_effective_stats", state, ids["1:M14"])["attack"], 3, "la penalizacion sigue activa durante su siguiente turno")
	for _phase in range(5):
		state = module.reduce(state, GameAction.new("advance_phase", 1, {}))["state"]
	_expect_equal(state["phase"]["current"], "END", "el turno del objetivo llega a Final")
	_expect_equal(module.call("_effective_stats", state, ids["1:M14"])["attack"], 3, "la penalizacion dura hasta completar la fase Final")
	var expired: Dictionary = module.reduce(state, GameAction.new("advance_phase", 1, {}))
	_expect(expired["ok"], "el final de turno expira la penalizacion")
	state = expired["state"]
	_expect_equal(module.call("_effective_stats", state, ids["1:M14"])["attack"], 4, "el ATQ se restaura tras el turno de su controlador")
	_expect_equal(_count_events(expired["events"], "timed_attack_penalty_expired"), 1, "la expiracion queda registrada")
	_expect(module.validate_state(state)["ok"], "el estado sigue valido tras expirar Vapor")


func _test_two_headed_troll_regeneration_and_t06() -> void:
	var prepared := _prepared_state({0: ["M11", "M13"], 1: ["M17"]})
	_expect(prepared["ok"], "se prepara F018 frente a una destruccion mutua")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M11"]
	var trap_id: String = _instance_for(state, "T06", 1)
	var trap: Dictionary = _place_support(state, trap_id, 1)
	_expect(trap["ok"], "T06 queda preparada antes del combate de F018")
	state = trap["state"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M13"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var combat: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(combat["ok"], "F018 combate contra una criatura que destruiria al Troll")
	state = combat["state"]
	var resolved: Dictionary = _event(combat["events"], "creature_combat_resolved")
	_expect_equal([resolved["payload"]["attacker_destroyed"], resolved["payload"]["target_destroyed"]], [false, true], "la regeneracion reemplaza solo la destruccion de F018")
	_expect_equal(state["cards"]["instances"][carrier]["metadata"]["position"], "guard", "F018 pasa forzosamente a guardia")
	_expect_equal(_count_events(combat["events"], "fusion_combat_destruction_prevented"), 1, "la prevencion queda publicada")
	_expect_equal(state["pending_response"].get("kind", ""), "combat_destruction", "la criatura rival destruida permite responder con T06")
	var activated: Dictionary = module.reduce(state, GameAction.new("activate_reaction", 1, {"support_slot": 0}))
	_expect(activated["ok"], "el rival puede activar T06 contra el Troll superviviente")
	state = activated["state"]
	state = module.reduce(state, GameAction.new("pass_reaction", 0, {}))["state"]
	var retaliation: Dictionary = module.reduce(state, GameAction.new("pass_reaction", 1, {}))
	_expect(retaliation["ok"], "T06 se resuelve tras ambos pases")
	state = retaliation["state"]
	_expect(carrier in state["cards"]["zones"]["graveyard:0"]["cards"], "T06 puede destruir F018 despues de que regenere")
	_expect(module.validate_state(state)["ok"], "la interaccion F018-T06 conserva el estado valido")


func _test_two_headed_troll_regenerates_once_per_turn() -> void:
	var prepared := _prepared_state({0: ["M11", "M13"], 1: ["M17", "M18"]})
	_expect(prepared["ok"], "se prepara el limite por turno de F018")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M11"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M13"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var first: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(first["ok"] and carrier in first["state"]["cards"]["zones"]["creatures:0"]["cards"], "F018 evita la primera destruccion del turno")
	state = first["state"]
	var carrier_metadata: Dictionary = state["cards"]["instances"][carrier]["metadata"]
	carrier_metadata["position"] = "attack"
	carrier_metadata["last_attack_turn"] = -1
	var second_target: String = ids["1:M18"]
	var second_metadata: Dictionary = state["cards"]["instances"][second_target]["metadata"]
	second_metadata["temporary_attack_bonus"] = 2
	second_metadata["temporary_bonus_turn"] = state["turn"]["turn_number"]
	var second: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(second["ok"], "se fuerza un segundo combate destructivo en el mismo turno")
	_expect(carrier in second["state"]["cards"]["zones"]["graveyard:0"]["cards"], "F018 no regenera una segunda vez durante ese turno")
	_expect_equal(_count_events(second["events"], "fusion_combat_destruction_prevented"), 0, "el segundo combate no publica otra prevencion")
	_expect(module.validate_state(second["state"])["ok"], "el limite de F018 conserva el estado valido")


func _test_water_major_attacker_choice() -> void:
	var prepared := _prepared_state({0: ["M06", "M08"], 1: ["M18"]})
	_expect(prepared["ok"], "se prepara F067 como atacante")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M06"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M08"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var declared: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))
	_expect(declared["ok"], "F067 declara su primer combate")
	state = declared["state"]
	_expect_equal(state["pending_response"]["kind"], "fusion_combat_choice", "el combate se detiene antes de respuestas")
	_expect_equal(state["pending_response"]["priority_player_id"], 0, "el atacante controla su eleccion")
	_expect_equal(module.get_legal_actions(state, 0).size(), 2, "solo se ofrecen ATQ o DEF")
	_expect(module.get_legal_actions(state, 1).is_empty(), "el rival no decide por F067 atacante")
	var chosen: Dictionary = module.reduce(state, GameAction.new("choose_fusion_combat_bonus", 0, {"choice": "defense"}))
	_expect(chosen["ok"], "la eleccion defensiva se resuelve")
	state = chosen["state"]
	var combat_event: Dictionary = _event(chosen["events"], "creature_combat_resolved")
	_expect_equal(combat_event["payload"]["attacker_defense"], 5, "F067 obtiene DEF 5 solo en ese combate")
	_expect(carrier in state["cards"]["zones"]["creatures:0"]["cards"], "la eleccion defensiva evita su destruccion frente a ATQ 5")
	_expect(ids["1:M18"] in state["cards"]["zones"]["creatures:1"]["cards"], "la defensa no aumenta por accidente el ataque")
	_expect(module.validate_state(state)["ok"], "la eleccion atacante conserva el estado valido")


func _test_water_major_attack_bonus() -> void:
	var prepared := _prepared_state({0: ["M06", "M08"], 1: ["M14"]})
	_expect(prepared["ok"], "se prepara la variante ofensiva de F067")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M06"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M08"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	state = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))["state"]
	var chosen: Dictionary = module.reduce(state, GameAction.new("choose_fusion_combat_bonus", 0, {"choice": "attack"}))
	_expect(chosen["ok"], "F067 puede elegir ATQ")
	var combat_event: Dictionary = _event(chosen["events"], "creature_combat_resolved")
	_expect_equal(combat_event["payload"]["attacker_attack"], 5, "la eleccion ofensiva produce ATQ 5")
	_expect(ids["1:M14"] in chosen["state"]["cards"]["zones"]["graveyard:1"]["cards"], "ATQ 5 supera la DEF 4 rival")
	_expect(carrier in chosen["state"]["cards"]["zones"]["creatures:0"]["cards"], "el Elemental sobrevive al contraataque igualado")


func _test_water_major_defender_choice() -> void:
	var prepared := _prepared_state({0: ["M18"], 1: ["M06", "M08"]})
	_expect(prepared["ok"], "se prepara F067 como defensora")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["1:M06"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 1, {"material_instance_ids": [carrier, ids["1:M08"]], "position": "guard"}))["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var declared: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": ids["0:M18"], "target_slot": 0}))
	_expect(declared["ok"], "el rival ataca a F067")
	state = declared["state"]
	_expect_equal(state["pending_response"]["priority_player_id"], 1, "el defensor elige el bono de su propio Elemental")
	var public_context: Dictionary = module.get_public_state(state)["response_window"]["context"]
	_expect(not public_context.has("target_id") and not public_context.has("choice_queue"), "la ventana publica no filtra identificadores internos")
	var chosen: Dictionary = module.reduce(state, GameAction.new("choose_fusion_combat_bonus", 1, {"choice": "defense"}))
	_expect(chosen["ok"], "F067 defensora elige DEF")
	state = chosen["state"]
	var combat_event: Dictionary = _event(chosen["events"], "creature_combat_resolved")
	_expect_equal(combat_event["payload"]["target_defense"], 5, "el bono se aplica al lado defensor correcto")
	_expect(carrier in state["cards"]["zones"]["creatures:1"]["cards"], "la igualdad 5 contra 5 conserva a F067")
	_expect_equal(state["pending_response"], {}, "sin Trampas el combate termina tras elegir")
	_expect(module.validate_state(state)["ok"], "la eleccion defensora conserva el estado valido")


func _test_water_major_choice_precedes_reactions() -> void:
	var prepared := _prepared_state({0: ["M06", "M08"], 1: ["M14"]})
	_expect(prepared["ok"], "se prepara F067 frente a una respuesta")
	if not prepared["ok"]:
		return
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var carrier: String = ids["0:M06"]
	var support_id: String = _instance_for(state, "G06", 1)
	var support_move: Dictionary = _place_support(state, support_id, 1)
	_expect(support_move["ok"], "G06 queda preparada desde un turno anterior")
	state = support_move["state"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [carrier, ids["0:M08"]], "position": "attack"}))["state"]
	state["cards"]["instances"][carrier]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	state = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": carrier, "target_slot": 0}))["state"]
	_expect_equal(state["pending_response"]["kind"], "fusion_combat_choice", "F067 elige antes de abrir Trampas")
	var chosen: Dictionary = module.reduce(state, GameAction.new("choose_fusion_combat_bonus", 0, {"choice": "attack"}))
	_expect(chosen["ok"], "la eleccion se conserva al abrir respuestas")
	state = chosen["state"]
	_expect_equal(state["pending_response"]["kind"], "attack", "despues de elegir se abre la ventana normal de ataque")
	_expect_equal(state["pending_response"]["priority_player_id"], 1, "la prioridad pasa al defensor")
	_expect(module.validate_state(state)["ok"], "el modificador pendiente y G06 conservan un estado valido")


func _test_dragon_extra_attack() -> void:
	var prepared := _prepared_state({0: ["M17", "M18"], 1: ["M04", "M09", "M07"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var dragon: String = ids["0:M17"]
	var fusion = GameAction.new("fuse_creatures", 0, {"material_instance_ids": [dragon, ids["0:M18"]], "position": "attack"})
	_expect(module.validate_action(state, fusion)["ok"], "F005 es una accion validable")
	state = module.reduce(state, fusion)["state"]
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var attack = GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": 0})
	_expect(not module.validate_action(state, attack)["ok"], "F005 no ataca el turno de entrada")
	state["cards"]["instances"][dragon]["metadata"]["summoned_turn"] = -1
	for index in range(2):
		_expect(module.validate_action(state, attack)["ok"], "F005 puede declarar ataque %d" % (index + 1))
		var legal_found := false
		for legal in module.get_legal_actions(state, 0):
			if legal.type == "attack" and legal.payload == attack.payload:
				legal_found = true
		_expect(legal_found, "el ataque %d figura en acciones legales" % (index + 1))
		var result: Dictionary = module.reduce(state, attack)
		state = result["state"]
		_expect_equal(_count_events(result["events"], "fusion_extra_attack_granted"), 1 if index == 0 else 0, "solo la primera baja concede un ataque")
		_expect(module.validate_state(state)["ok"], "el marcador de F005 es valido")
		if index == 0:
			var cancelled: Dictionary = _place_support(state, _instance_for(state, "G07", 1), 1)["state"]
			cancelled = module.reduce(cancelled, attack)["state"]
			var reaction = GameAction.new("activate_reaction", 1, {"support_slot": 0})
			_expect(module.validate_action(cancelled, reaction)["ok"], "G07 puede cancelar el ataque adicional")
			cancelled = module.reduce(cancelled, reaction)["state"]
			for _pass in range(2):
				cancelled = module.reduce(cancelled, GameAction.new("pass_reaction", cancelled["pending_response"]["priority_player_id"], {}))["state"]
			_expect(not module.validate_action(cancelled, attack)["ok"], "cancelar el ataque extra no devuelve su permiso")
			_expect(module.validate_state(cancelled)["ok"], "el ataque extra cancelado conserva estado valido")
			var expired: Dictionary = state.duplicate(true)
			var original_turn: int = expired["turn"]["turn_number"]
			while expired["turn"]["turn_number"] < original_turn + 2:
				var actor: int = expired["turn"]["order"][expired["turn"]["active_index"]]
				expired = module.reduce(expired, GameAction.new("advance_phase", actor, {}))["state"]
			_expect(not module._has_dragon_extra_attack(expired, dragon), "un permiso sin gastar expira al cambiar de turno")
			_expect(module.validate_state(expired)["ok"], "el marcador historico no invalida el turno siguiente")
	_expect(not module.validate_action(state, attack)["ok"], "destruir dos criaturas no permite un tercer ataque")
	_expect_equal(state["cards"]["instances"][dragon]["metadata"]["last_attack_turn"], state["turn"]["turn_number"], "el permiso no borra el ataque realizado")
	for invalid in [{"dragon_bonus_turn": "1"}, {"dragon_bonus_available": 1}, {"dragon_bonus_turn": 999}]:
		var broken: Dictionary = state.duplicate(true)
		broken["cards"]["instances"][dragon]["metadata"].merge(invalid, true)
		_expect(not module.validate_state(broken)["ok"], "se rechazan marcadores corruptos")
	var turn_number: int = state["turn"]["turn_number"]
	while state["turn"]["turn_number"] < turn_number + 2:
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		state = module.reduce(state, GameAction.new("advance_phase", actor, {}))["state"]
	while state["phase"]["current"] != "COMBAT":
		state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	_expect(module.validate_action(state, attack)["ok"], "el siguiente turno propio devuelve el ataque normal")
	var renewed: Dictionary = module.reduce(state, attack)
	_expect_equal(_count_events(renewed["events"], "fusion_extra_attack_granted"), 1, "una nueva baja vuelve a habilitar el efecto en otro turno")


func _test_dragon_no_false_trigger() -> void:
	for scenario in ["direct", "equality", "both_die", "troll"]:
		var prepared := _prepared_state({0: ["M17", "M18"], 1: ["M11", "M13"]})
		var module = prepared["module"]
		var state: Dictionary = prepared["state"]
		var ids: Dictionary = prepared["ids"]
		var dragon: String = ids["0:M17"]
		state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [dragon, ids["0:M18"]], "position": "attack"}))["state"]
		if scenario == "troll":
			state = module.reduce(state, GameAction.new("fuse_creatures", 1, {"material_instance_ids": [ids["1:M11"], ids["1:M13"]], "position": "guard"}))["state"]
		elif scenario == "direct":
			for target in [ids["1:M11"], ids["1:M13"]]:
				state["cards"] = CardState.move_card(state["cards"], target, "creatures:1", "hand:1")["value"]
		else:
			state["cards"]["definitions"]["M11"]["attributes"]["defense"] = 8 if scenario == "equality" else 1
			state["cards"]["definitions"]["M11"]["attributes"]["attack"] = 9 if scenario == "both_die" else 1
		state["cards"]["instances"][dragon]["metadata"]["summoned_turn"] = -1
		state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
		var result: Dictionary = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": -1 if scenario == "direct" else 0}))
		_expect_equal(_count_events(result["events"], "fusion_extra_attack_granted"), 0, "F005 no dispara en %s" % scenario)
		_expect(module.validate_state(result["state"])["ok"], "estado valido tras %s" % scenario)


func _test_dragon_t06() -> void:
	var prepared := _prepared_state({0: ["M17", "M18"], 1: ["M04"]})
	var module = prepared["module"]
	var state: Dictionary = prepared["state"]
	var ids: Dictionary = prepared["ids"]
	var dragon: String = ids["0:M17"]
	var trap: String = _instance_for(state, "T06", 1)
	state = _place_support(state, trap, 1)["state"]
	state = module.reduce(state, GameAction.new("fuse_creatures", 0, {"material_instance_ids": [dragon, ids["0:M18"]], "position": "attack"}))["state"]
	state["cards"]["instances"][dragon]["metadata"]["summoned_turn"] = -1
	state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	state = module.reduce(state, GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": 0}))["state"]
	_expect_equal(state["pending_response"]["kind"], "combat_destruction", "T06 recibe prioridad antes del segundo ataque")
	_expect(not module.validate_action(state, GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": -1}))["ok"], "no se salta la ventana con el permiso adicional")
	var response = GameAction.new("activate_reaction", 1, {"support_slot": 0})
	_expect(module.validate_action(state, response)["ok"], "T06 puede responder contra F005")
	state = module.reduce(state, response)["state"]
	while not state["pending_response"].is_empty():
		state = module.reduce(state, GameAction.new("pass_reaction", state["pending_response"]["priority_player_id"], {}))["state"]
	_expect(dragon in state["cards"]["zones"]["graveyard:0"]["cards"], "T06 destruye el dragon antes del ataque extra")
	_expect(ids["0:M18"] in state["cards"]["zones"]["graveyard:0"]["cards"], "T06 libera tambien el segundo material")
	_expect(not state["cards"]["instances"][dragon]["metadata"].has("dragon_bonus_turn"), "la salida limpia el permiso")
	_expect(module.validate_state(state)["ok"], "la destruccion por T06 conserva el estado")


func _prepared_state(layout: Dictionary) -> Dictionary:
	var module = GameModule.new()
	var state: Dictionary = module.create_initial_state({"player_names": ["Lucia", "Alex"]}, 67001)
	# Los escenarios de efectos representan una ronda posterior, no el primer turno
	# real en el que el jugador inicial tiene prohibido atacar.
	state["turn"]["turn_number"] = 3
	state["turn"]["round_number"] = 2
	for _index in range(2):
		state = module.reduce(state, GameAction.new("advance_phase", 0, {}))["state"]
	var ids: Dictionary = {}
	for player_id in layout:
		for definition_id in layout[player_id]:
			var instance_id := _instance_for(state, definition_id, player_id)
			ids["%d:%s" % [player_id, definition_id]] = instance_id
			var located: Dictionary = CardState.locate_card(state["cards"], instance_id)
			var metadata: Dictionary = state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
			metadata.merge({"face_up": true, "position": "attack", "summoned_turn": -1, "last_attack_turn": -1, "last_position_change_turn": -1}, true)
			var update: Dictionary = CardState.update_instance_metadata(state["cards"], instance_id, metadata)
			var move: Dictionary = CardState.move_card(update["value"], instance_id, located["zone_id"], "creatures:%d" % player_id)
			if not move["ok"]:
				return move
			state["cards"] = move["value"]
	var check: Dictionary = module.validate_state(state)
	if not check["ok"]:
		return check
	return {"ok": true, "module": module, "state": state, "ids": ids}


func _place_support(state: Dictionary, instance_id: String, player_id: int) -> Dictionary:
	var located: Dictionary = CardState.locate_card(state["cards"], instance_id)
	if not located["ok"]:
		return located
	var metadata: Dictionary = state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata.merge({"face_up": false, "active": false, "set_turn": 0}, true)
	var update: Dictionary = CardState.update_instance_metadata(state["cards"], instance_id, metadata)
	if not update["ok"]:
		return update
	var move: Dictionary = CardState.move_card(update["value"], instance_id, located["zone_id"], "support:%d" % player_id)
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


func _event(events: Array, event_type: String) -> Dictionary:
	for item in events:
		if item["type"] == event_type:
			return item
	return {}


func _count_events(events: Array, event_type: String) -> int:
	var count := 0
	for item in events:
		if item["type"] == event_type:
			count += 1
	return count


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
