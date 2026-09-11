extends SceneTree
## Partidas verticales reales para las ocho Fusiones iniciales mediante UCE.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")

const CONFIG := {"player_names": ["Lucia", "Alex"]}

var _checks := 0
var _failures: Array = []
var _request := 0


func _init() -> void:
	_run_vertical_match()
	_run_torch_band_vertical()
	_run_thicket_vertical()
	_run_two_headed_troll_vertical()
	_run_steam_vertical()
	_run_dragon_vertical()
	if _failures.is_empty():
		print("JCP-EIGHT-FUSIONS-VERTICAL PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-EIGHT-FUSIONS-VERTICAL FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_dragon_vertical() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	_expect(engine.start(1818).success, "la partida vertical de F005 arranca")
	var ready := false
	for _step in range(500):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		var dragon := _fusion_carrier(state, 0, "fusion.f005_fire_dragon")
		if not dragon.is_empty() and actor == 0 and state["phase"]["current"] == "COMBAT" and state["cards"]["zones"]["creatures:1"]["cards"].size() >= 2:
			if state["cards"]["instances"][dragon]["metadata"]["summoned_turn"] != state["turn"]["turn_number"]:
				ready = true
				break
		if state["phase"]["current"] == "MAIN_1":
			if actor == 0:
				_deploy_from_list(engine, actor, ["M17", "M18"])
				_form_specific_pair(engine, actor, ["M17", "M18"])
			else:
				_deploy_from_list(engine, actor, ["M04", "M09"])
		var advanced = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("dragon-advance")))
		if not advanced.success:
			_failures.append("F005 no pudo avanzar: %s" % advanced.code)
			break
	_expect(ready, "F005 llega al combate con energia, robos y espera naturales")
	if not ready:
		return
	var dragon := _fusion_carrier(engine.export_module_state(), 0, "fusion.f005_fire_dragon")
	_expect_equal(_public_creature(engine, 0, dragon)["effective_stats"], {"attack": 8, "defense": 8, "base_attack": 8, "base_defense": 8}, "la vista presenta las cifras de F005")
	for _attack in range(2):
		var applied = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": 0}, _next_request("dragon-attack")))
		_expect(applied.success, "el motor confirma un ataque de F005")
	_expect_equal(_count_events(engine.get_events(0, -1), "fusion_extra_attack_granted"), 1, "el registro concede exactamente un ataque extra")
	var before: Dictionary = engine.export_runtime_snapshot()
	var rejected = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": dragon, "target_slot": -1}, _next_request("dragon-third")))
	_expect(not rejected.success, "el motor rechaza un tercer ataque")
	_expect_equal(engine.export_runtime_snapshot(), before, "el rechazo no modifica snapshot ni registro")
	_expect(engine.validate_internal_consistency()["ok"], "F005 conserva consistencia interna")
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, engine.export_runtime_snapshot())
	_expect(replay["ok"], "el replay reconstruye los dos ataques de F005")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "F005 coincide bit a bit tras replay")


func _run_vertical_match() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	# Las seis cartas necesarias aparecen entre las seis primeras de cada jugador.
	_expect(engine.start(53927).success, "la partida vertical arranca")
	var ready := false
	for _step in range(700):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		if _three_fusions_present(state) and actor == 0 and state["phase"]["current"] == "MAIN_1":
			var band_id := _fusion_carrier(state, 0, "fusion.f010_neutral_band")
			if state["cards"]["instances"][band_id]["metadata"].get("summoned_turn", -1) != state["turn"]["turn_number"]:
				ready = true
				break
		if state["phase"]["current"] == "MAIN_1":
			_deploy_for_plan(engine, actor)
			_form_available_fusion(engine, actor)
		var advance = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("advance")))
		if not advance.success:
			_failures.append("la progresion vertical se detuvo: %s — %s" % [advance.code, advance.message])
			_failures.append("diagnostico vertical: %s" % JSON.stringify(_vertical_diagnostic(engine)))
			break
	_expect(ready, "la partida reune las tres Fusiones sin preparar el estado a mano")
	if not ready:
		return
	var state: Dictionary = engine.export_module_state()
	var alpha_id := _fusion_carrier(state, 0, "fusion.f001_nature_alpha")
	var band_id := _fusion_carrier(state, 0, "fusion.f010_neutral_band")
	var water_id := _fusion_carrier(state, 1, "fusion.f067_water_major")
	_expect(not alpha_id.is_empty() and not band_id.is_empty() and not water_id.is_empty(), "F001, F010 y F067 coexisten como identidades generadas")
	var public_cards: String = JSON.stringify(engine.get_public_state()["game"]["card_table"])
	_expect(public_cards.contains("fusion.f001_nature_alpha") and public_cards.contains("fusion.f010_neutral_band") and public_cards.contains("fusion.f067_water_major"), "la vista publica presenta las tres identidades")
	var ability = engine.perform_action(GameAction.new("activate_fusion_ability", 0, {"source_instance_id": band_id, "target_instance_id": band_id}, _next_request("band")))
	_expect(ability.success, "Banda Goblin usa su habilidad dentro de la partida real")
	_expect(engine.perform_action(GameAction.new("advance_phase", 0, {}, _next_request("combat"))).success, "la partida entra en Combate")
	state = engine.export_module_state()
	var target_slot: int = state["cards"]["zones"]["creatures:1"]["cards"].find(water_id)
	var attack = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": band_id, "target_slot": target_slot}, _next_request("attack")))
	_expect(attack.success, "Banda Goblin ataca bajo el liderazgo del Alfa")
	state = engine.export_module_state()
	_expect_equal(state["pending_response"]["kind"], "fusion_combat_choice", "F067 detiene el combate para su controlador")
	_expect_equal(state["pending_response"]["priority_player_id"], 1, "la eleccion pertenece al defensor")
	var choice = engine.perform_action(GameAction.new("choose_fusion_combat_bonus", 1, {"choice": "defense"}, _next_request("water-defense")))
	_expect(choice.success, "F067 elige defensa y el combate termina")
	state = engine.export_module_state()
	_expect(band_id not in state["cards"]["zones"]["creatures:0"]["cards"], "Banda Goblin es destruida por el contraataque")
	var band_materials: Array = _owned_definition_ids(state, 0, ["M04", "M09"])
	_expect(_all_in_zone(state, band_materials, "graveyard:0"), "los dos Goblins contenidos terminan en el Cementerio")
	_expect(water_id in state["cards"]["zones"]["creatures:1"]["cards"], "F067 sobrevive gracias a la igualdad defensiva")
	_expect(alpha_id in state["cards"]["zones"]["creatures:0"]["cards"], "F001 permanece como apoyo de la mesa")
	var events: Array = engine.get_events(0, -1)
	_expect(_count_events(events, "creatures_fused") == 3, "el registro contiene exactamente tres Fusiones")
	_expect(_count_events(events, "fusion_ability_activated") == 1, "el registro contiene la habilidad de F010")
	_expect(_count_events(events, "fusion_leadership_triggered") == 1, "el registro contiene el liderazgo de F001")
	_expect(_count_events(events, "fusion_combat_bonus_chosen") == 1, "el registro contiene la eleccion de F067")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva consistencia tras el recorrido completo")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, snapshot)
	_expect(replay["ok"], "el replay reconstruye la partida vertical exactamente")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "el digest del replay coincide bit a bit")


func _run_torch_band_vertical() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	# M09 comienza en mano; M05 y M04 llegan mediante los robos sexto y octavo.
	_expect(engine.start(243).success, "la partida vertical de F011 arranca")
	var ready := false
	for _step in range(500):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		var torch_id := _fusion_carrier(state, 0, "fusion.f011_torch_band")
		if not torch_id.is_empty() and actor == 0 and state["phase"]["current"] == "MAIN_1":
			if state["cards"]["instances"][torch_id]["metadata"].get("summoned_turn", -1) != state["turn"]["turn_number"]:
				ready = true
				break
		if state["phase"]["current"] == "MAIN_1":
			if actor == 0:
				_deploy_from_list(engine, actor, ["M09", "M05", "M04"])
				_form_specific_pair(engine, actor, ["M05", "M04"])
			else:
				_deploy_from_list(engine, actor, ["M12"])
		var advance = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("torch-advance")))
		if not advance.success:
			_failures.append("la progresion vertical de F011 se detuvo: %s — %s" % [advance.code, advance.message])
			break
	_expect(ready, "F011 se forma tras robos, despliegues y turnos normales")
	if not ready:
		return
	var state: Dictionary = engine.export_module_state()
	var torch_id := _fusion_carrier(state, 0, "fusion.f011_torch_band")
	var companion_id := _definition_in_zone(state, 0, "M09", "creatures")
	var target_id := _definition_in_zone(state, 1, "M12", "creatures")
	_expect(not torch_id.is_empty() and not companion_id.is_empty() and not target_id.is_empty(), "F011, su companero y el objetivo coexisten en la mesa")
	_expect(JSON.stringify(engine.get_public_state()["game"]["card_table"]).contains("fusion.f011_torch_band"), "la vista publica presenta Banda de Antorchas")
	_expect(engine.perform_action(GameAction.new("advance_phase", 0, {}, _next_request("torch-combat"))).success, "F011 entra en la fase de Combate")
	state = engine.export_module_state()
	var target_slot: int = state["cards"]["zones"]["creatures:1"]["cards"].find(target_id)
	var attack = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": torch_id, "target_slot": target_slot}, _next_request("torch-attack")))
	_expect(attack.success, "Banda de Antorchas ataca mediante el motor real")
	state = engine.export_module_state()
	var combat_event: Dictionary = _last_event(engine.get_events(0, -1), "creature_combat_resolved")
	_expect_equal([combat_event["payload"]["attacker_attack"], combat_event["payload"]["attacker_defense"]], [4, 3], "el companero Goblin convierte F011 en 4/3 durante el combate")
	_expect(torch_id in state["cards"]["zones"]["creatures:0"]["cards"], "F011 sobrevive al contraataque por igualdad")
	_expect(target_id in state["cards"]["zones"]["graveyard:1"]["cards"], "el objetivo derrotado llega al Cementerio")
	_expect(_count_events(engine.get_events(0, -1), "fusion_torch_band_triggered") == 1, "el registro contiene el disparo de F011")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva consistencia tras F011")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, snapshot)
	_expect(replay["ok"], "el replay reconstruye la partida vertical de F011")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "el replay de F011 coincide bit a bit")


func _run_thicket_vertical() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	# M10 comienza en mano, M09 llega en el sexto robo y M14 en el sexto robo rival.
	_expect(engine.start(550).success, "la partida vertical de F012 arranca")
	var ready := false
	for _step in range(500):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		var thicket_id := _fusion_carrier(state, 0, "fusion.f012_thicket_company")
		if not thicket_id.is_empty() and actor == 1 and state["phase"]["current"] == "MAIN_1":
			var deployed_attacker := _definition_in_zone(state, 1, "M14", "creatures")
			if not deployed_attacker.is_empty() and state["cards"]["instances"][deployed_attacker]["metadata"].get("summoned_turn", -1) != state["turn"]["turn_number"]:
				ready = true
				break
		if state["phase"]["current"] == "MAIN_1":
			if actor == 0:
				_deploy_from_list(engine, actor, ["M09", "M10"])
				_form_specific_pair(engine, actor, ["M10", "M09"])
			else:
				_deploy_from_list(engine, actor, ["M14"])
		var advance = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("thicket-advance")))
		if not advance.success:
			_failures.append("la progresion vertical de F012 se detuvo: %s — %s" % [advance.code, advance.message])
			break
	_expect(ready, "F012 se forma tras robos, despliegues y turnos normales")
	if not ready:
		return
	var state: Dictionary = engine.export_module_state()
	var thicket_id := _fusion_carrier(state, 0, "fusion.f012_thicket_company")
	var attacker_id := _definition_in_zone(state, 1, "M14", "creatures")
	_expect(not thicket_id.is_empty() and not attacker_id.is_empty(), "F012 y su atacante coexisten en la mesa")
	_expect(JSON.stringify(engine.get_public_state()["game"]["card_table"]).contains("fusion.f012_thicket_company"), "la vista publica presenta Cuadrilla del Matorral")
	_expect(engine.perform_action(GameAction.new("advance_phase", 1, {}, _next_request("thicket-combat"))).success, "el rival entra en Combate contra F012")
	state = engine.export_module_state()
	var target_slot: int = state["cards"]["zones"]["creatures:0"]["cards"].find(thicket_id)
	var attack = engine.perform_action(GameAction.new("attack", 1, {"attacker_id": attacker_id, "target_slot": target_slot}, _next_request("thicket-attack")))
	_expect(attack.success, "el rival ataca F012 mediante el motor real")
	if not attack.success:
		return
	state = engine.export_module_state()
	var combat_event: Dictionary = _last_event(engine.get_events(0, -1), "creature_combat_resolved")
	_expect_equal(combat_event["payload"]["attacker_attack"], 3, "F012 reduce el ATQ rival de 4 a 3 durante el combate")
	_expect(thicket_id in state["cards"]["zones"]["creatures:0"]["cards"], "F012 sobrevive gracias a la igualdad defensiva")
	_expect(attacker_id in state["cards"]["zones"]["creatures:1"]["cards"], "el atacante tambien sobrevive al contraataque")
	_expect(_count_events(engine.get_events(0, -1), "fusion_thicket_guard_triggered") == 1, "el registro contiene la defensa reactiva de F012")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva consistencia tras F012")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, snapshot)
	_expect(replay["ok"], "el replay reconstruye la partida vertical de F012")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "el replay de F012 coincide bit a bit")


func _run_steam_vertical() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	# M06 comienza en mano, M03 llega en el sexto robo y M04 empieza en la mano rival.
	_expect(engine.start(159).success, "la partida vertical de F068 arranca")
	var ready := false
	for _step in range(300):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		if not _fusion_carrier(state, 0, "fusion.f068_steam_elemental").is_empty():
			ready = true
			break
		if state["phase"]["current"] == "MAIN_1":
			if actor == 0:
				_deploy_from_list(engine, actor, ["M06", "M03"])
				_form_specific_pair(engine, actor, ["M03", "M06"])
			else:
				_deploy_from_list(engine, actor, ["M04"])
		var advance = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("steam-advance")))
		if not advance.success:
			_failures.append("la progresion vertical de F068 se detuvo: %s — %s" % [advance.code, advance.message])
			break
	_expect(ready, "F068 se forma con un objetivo desplegado legalmente")
	if not ready:
		return
	var state: Dictionary = engine.export_module_state()
	var steam_id := _fusion_carrier(state, 0, "fusion.f068_steam_elemental")
	var target_id := _definition_in_zone(state, 1, "M04", "creatures")
	_expect(not steam_id.is_empty() and not target_id.is_empty(), "F068 y su objetivo coexisten en la mesa")
	_expect_equal(_public_creature(engine, 1, target_id)["effective_stats"]["attack"], 0, "Vapor reduce el ATQ 1 del objetivo hasta cero")
	_expect(_count_events(engine.get_events(0, -1), "fusion_entry_effect_applied") == 1, "el registro contiene el efecto de entrada de F068")
	# La deteccion ocurre ya en Combate: faltan Principal 2, Final y el cambio de turno.
	for _phase in range(3):
		var advanced = engine.perform_action(GameAction.new("advance_phase", 0, {}, _next_request("steam-owner-start")))
		if not advanced.success:
			_failures.append("F068 no alcanzo el turno del objetivo: %s" % advanced.code)
			return
	_expect_equal(engine.export_module_state()["phase"]["current"], "START", "comienza el siguiente turno del objetivo de Vapor")
	_expect_equal(_public_creature(engine, 1, target_id)["effective_stats"]["attack"], 0, "la penalizacion sigue activa al comenzar ese turno")
	for _phase in range(6):
		var advanced = engine.perform_action(GameAction.new("advance_phase", 1, {}, _next_request("steam-expire")))
		if not advanced.success:
			_failures.append("F068 no completo el turno del objetivo: %s" % advanced.code)
			return
	_expect_equal(_public_creature(engine, 1, target_id)["effective_stats"]["attack"], 1, "el ATQ se restaura al terminar el turno del objetivo")
	_expect(_count_events(engine.get_events(0, -1), "timed_attack_penalty_expired") == 1, "el registro contiene la expiracion de Vapor")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva consistencia tras F068")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, snapshot)
	_expect(replay["ok"], "el replay reconstruye la partida vertical de F068")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "el replay de F068 coincide bit a bit")


func _run_two_headed_troll_vertical() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), CONFIG)
	_expect(engine.start(1818).success, "la partida vertical de F018 arranca")
	var ready := false
	for _step in range(500):
		var state: Dictionary = engine.export_module_state()
		var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
		var troll_id := _fusion_carrier(state, 0, "fusion.f018_two_headed_troll")
		var rival_id := _definition_in_zone(state, 1, "M17", "creatures")
		if not troll_id.is_empty() and not rival_id.is_empty() and actor == 0 and state["phase"]["current"] == "MAIN_1" and state["cards"]["instances"][troll_id]["metadata"].get("summoned_turn", -1) != state["turn"]["turn_number"]:
			ready = true
			break
		if state["phase"]["current"] == "MAIN_1":
			if actor == 0:
				_deploy_from_list(engine, actor, ["M11", "M13"])
				_form_specific_pair(engine, actor, ["M11", "M13"])
			else:
				_deploy_from_list(engine, actor, ["M17"])
		var advance = engine.perform_action(GameAction.new("advance_phase", actor, {}, _next_request("troll-advance")))
		if not advance.success:
			_failures.append("la progresion vertical de F018 se detuvo: %s — %s" % [advance.code, advance.message])
			break
	_expect(ready, "F018 se forma y alcanza un turno posterior con rival legal")
	if not ready:
		return
	var state: Dictionary = engine.export_module_state()
	var troll_id := _fusion_carrier(state, 0, "fusion.f018_two_headed_troll")
	var rival_id := _definition_in_zone(state, 1, "M17", "creatures")
	_expect(JSON.stringify(engine.get_public_state()["game"]["card_table"]).contains("fusion.f018_two_headed_troll"), "la vista publica presenta Troll Bicéfalo")
	_expect(engine.perform_action(GameAction.new("advance_phase", 0, {}, _next_request("troll-combat"))).success, "F018 entra en Combate")
	state = engine.export_module_state()
	var target_slot: int = state["cards"]["zones"]["creatures:1"]["cards"].find(rival_id)
	var attack = engine.perform_action(GameAction.new("attack", 0, {"attacker_id": troll_id, "target_slot": target_slot}, _next_request("troll-attack")))
	_expect(attack.success, "F018 resuelve un combate destructivo mediante UCE")
	state = engine.export_module_state()
	_expect(troll_id in state["cards"]["zones"]["creatures:0"]["cards"], "F018 evita su primera destruccion de combate")
	_expect_equal(state["cards"]["instances"][troll_id]["metadata"]["position"], "guard", "F018 termina el combate en guardia")
	_expect(rival_id in state["cards"]["zones"]["graveyard:1"]["cards"], "el rival destruido llega al Cementerio")
	_expect(_count_events(engine.get_events(0, -1), "fusion_combat_destruction_prevented") == 1, "el registro contiene la regeneracion de F018")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva consistencia tras F018")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(GameModule.new(), CONFIG, snapshot)
	_expect(replay["ok"], "el replay reconstruye la partida vertical de F018")
	if replay["ok"]:
		_expect_equal(replay["expected_digest"], replay["actual_digest"], "el replay de F018 coincide bit a bit")


func _deploy_for_plan(engine, player_id: int) -> void:
	var desired: Array = ["M01", "M07", "M04", "M09"] if player_id == 0 else ["M06", "M08"]
	_deploy_from_list(engine, player_id, desired)


func _deploy_from_list(engine, player_id: int, desired: Array) -> void:
	var state: Dictionary = engine.export_module_state()
	for definition_id in desired:
		if _definition_is_deployed_or_contained(state, player_id, definition_id):
			continue
		var instance_id := _definition_in_zone(state, player_id, definition_id, "hand")
		if instance_id.is_empty():
			continue
		var action = _legal_action(engine.get_legal_actions(player_id), "summon_creature", {"instance_id": instance_id})
		if action != null:
			engine.perform_action(GameAction.new(action.type, player_id, action.payload, _next_request("summon")))
		return


func _form_specific_pair(engine, player_id: int, pair: Array) -> void:
	var state: Dictionary = engine.export_module_state()
	var ids: Array = [_definition_in_zone(state, player_id, pair[0], "creatures"), _definition_in_zone(state, player_id, pair[1], "creatures")]
	if ids[0].is_empty() or ids[1].is_empty():
		return
	for legal in engine.get_legal_actions(player_id):
		if legal.type == "fuse_creatures" and legal.payload.get("position", "") == "attack" and _same_members(legal.payload["material_instance_ids"], ids):
			var applied = engine.perform_action(GameAction.new(legal.type, player_id, legal.payload, _next_request("fuse-specific")))
			if not applied.success:
				_failures.append("la Fusion especifica legal fue rechazada: %s — %s" % [applied.code, applied.message])
			return


func _form_available_fusion(engine, player_id: int) -> void:
	var priorities: Array = [["M01", "M07"], ["M04", "M09"]] if player_id == 0 else [["M06", "M08"]]
	var state: Dictionary = engine.export_module_state()
	for pair in priorities:
		var ids: Array = [_definition_in_zone(state, player_id, pair[0], "creatures"), _definition_in_zone(state, player_id, pair[1], "creatures")]
		if ids[0].is_empty() or ids[1].is_empty():
			continue
		for legal in engine.get_legal_actions(player_id):
			if legal.type == "fuse_creatures" and legal.payload.get("position", "") == "attack" and _same_members(legal.payload["material_instance_ids"], ids):
				var applied = engine.perform_action(GameAction.new(legal.type, player_id, legal.payload, _next_request("fuse")))
				if not applied.success:
					_failures.append("una Fusion legal fue rechazada: %s — %s" % [applied.code, applied.message])
				return


func _three_fusions_present(state: Dictionary) -> bool:
	return not _fusion_carrier(state, 0, "fusion.f001_nature_alpha").is_empty() and not _fusion_carrier(state, 0, "fusion.f010_neutral_band").is_empty() and not _fusion_carrier(state, 1, "fusion.f067_water_major").is_empty()


func _vertical_diagnostic(engine) -> Dictionary:
	var state: Dictionary = engine.export_module_state()
	var result: Dictionary = {"phase": state["phase"]["current"], "turn": state["turn"]["turn_number"]}
	for player_id in [0, 1]:
		var key := str(player_id)
		result[key] = {"hand": [], "field": [], "materials": []}
		for pair in [["hand", "hand"], ["creatures", "field"], ["fusion_materials", "materials"]]:
			for instance_id in state["cards"]["zones"]["%s:%d" % [pair[0], player_id]]["cards"]:
				result[key][pair[1]].append(state["cards"]["instances"][instance_id]["definition_id"])
	result["legal"] = []
	var actor: int = state["turn"]["order"][state["turn"]["active_index"]]
	for action in engine.get_legal_actions(actor):
		result["legal"].append({"type": action.type, "payload": action.payload})
	return result


func _fusion_carrier(state: Dictionary, player_id: int, identity_id: String) -> String:
	for instance_id in state["cards"]["zones"]["creatures:%d" % player_id]["cards"]:
		var entity: Variant = state["cards"]["instances"][instance_id]["metadata"].get("fusion_entity", null)
		if entity is Dictionary and entity.get("fusion_identity_id", "") == identity_id:
			return instance_id
	return ""


func _definition_is_deployed_or_contained(state: Dictionary, player_id: int, definition_id: String) -> bool:
	return not _definition_in_zone(state, player_id, definition_id, "creatures").is_empty() or not _definition_in_zone(state, player_id, definition_id, "fusion_materials").is_empty()


func _definition_in_zone(state: Dictionary, player_id: int, definition_id: String, zone_kind: String) -> String:
	for instance_id in state["cards"]["zones"]["%s:%d" % [zone_kind, player_id]]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _owned_definition_ids(state: Dictionary, player_id: int, definitions: Array) -> Array:
	var result: Array = []
	for definition_id in definitions:
		for instance_id in state["cards"]["instances"]:
			var instance: Dictionary = state["cards"]["instances"][instance_id]
			if instance["definition_id"] == definition_id and instance["metadata"]["owner_id"] == player_id:
				result.append(instance_id)
				break
	return result


func _all_in_zone(state: Dictionary, ids: Array, zone_id: String) -> bool:
	for instance_id in ids:
		if instance_id not in state["cards"]["zones"][zone_id]["cards"]:
			return false
	return true


func _same_members(left: Array, right: Array) -> bool:
	return left.size() == right.size() and left.all(func(value): return value in right)


func _legal_action(actions: Array, type: String, payload: Dictionary):
	for action in actions:
		if action.type == type and action.payload == payload:
			return action
	return null


func _count_events(events: Array, type: String) -> int:
	var count := 0
	for event in events:
		if event["type"] == type:
			count += 1
	return count


func _last_event(events: Array, type: String) -> Dictionary:
	for index in range(events.size() - 1, -1, -1):
		if events[index]["type"] == type:
			return events[index]
	return {}


func _public_creature(engine, player_id: int, instance_id: String) -> Dictionary:
	for card in engine.get_public_state()["game"]["card_table"]["zones"]["creatures:%d" % player_id]["cards"]:
		if card["instance"]["id"] == instance_id:
			return card
	return {}


func _next_request(prefix: String) -> String:
	_request += 1
	return "%s-%d" % [prefix, _request]


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
