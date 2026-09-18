extends RefCounted
## Primer modulo jugable del juego de cartas propio.
##
## Implementacion aislada del reglamento provisional, sin interfaz ni arte.

const PlayerRegistry = preload("res://src/session/player_registry.gd")
const TurnState = preload("res://src/turns/turn_state.gd")
const PhaseMachine = preload("res://src/turns/phase_machine.gd")
const LegalAction = preload("res://src/core/legal_action.gd")
const CardState = preload("res://src/cards/card_state.gd")
const CardRandomizer = preload("res://src/cards/card_randomizer.gd")
const CardOperations = preload("res://src/cards/card_operations.gd")
const DeckBuilder = preload("res://src/cards/deck_builder.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")
const FusionCatalog = preload("res://games/juego_cartas_propio/fusion_catalog.gd")
const FusionRecipeService = preload("res://games/juego_cartas_propio/fusion_recipe_service.gd")

const PHASE_START := "START"
const PHASE_DRAW := "DRAW"
const PHASE_MAIN_1 := "MAIN_1"
const PHASE_COMBAT := "COMBAT"
const PHASE_MAIN_2 := "MAIN_2"
const PHASE_END := "END"
const PHASE_FINISHED := "FINISHED"

const ACTION_ADVANCE_PHASE := "advance_phase"
const ACTION_ACTIVATE_FUSION_ABILITY := "activate_fusion_ability"
const ACTION_ACTIVATE_CREATURE_ABILITY := "activate_creature_ability"
const ACTION_ACTIVATE_REACTION := "activate_reaction"
const ACTION_ATTACK := "attack"
const ACTION_CHANGE_POSITION := "change_position"
const ACTION_CHOOSE_FUSION_COMBAT_BONUS := "choose_fusion_combat_bonus"
const ACTION_REDIRECT_ATTACK := "redirect_attack"
const ACTION_DECLINE_REDIRECT := "decline_redirect"
const ACTION_CONCEDE := "concede"
const ACTION_EQUIP_ITEM := "equip_item"
const ACTION_FUSE_CREATURES := "fuse_creatures"
const ACTION_PLAY_MAIN_SPELL := "play_main_spell"
const ACTION_PLAY_PERSISTENT := "play_persistent"
const ACTION_PLAY_TERRAIN := "play_terrain"
const ACTION_PASS_REACTION := "pass_reaction"
const ACTION_RELOCATE_EQUIPMENT := "relocate_equipment"
const ACTION_SET_CREATURE := "set_creature"
const ACTION_SET_SUPPORT := "set_support"
const ACTION_SUMMON_CREATURE := "summon_creature"

const TERRAIN_RECIPES := {
	"R01>R02": {"id": "RT01", "display_name": "Bosque Inundado", "components": ["R01", "R02"]},
	"R02>R01": {"id": "RT02", "display_name": "Humedal Fértil", "components": ["R02", "R01"]},
	"R01>R03": {"id": "RT03", "display_name": "Bosque Ardiente", "components": ["R01", "R03"]},
	"R03>R01": {"id": "RT04", "display_name": "Bosque Volcánico", "components": ["R03", "R01"]},
	"R02>R03": {"id": "RT05", "display_name": "Caldera de Vapor", "components": ["R02", "R03"]},
	"R03>R02": {"id": "RT06", "display_name": "Llanura de Obsidiana", "components": ["R03", "R02"]},
}

const KNOWN_ANATOMIES := [
	"unassigned",
	"humanoid",
	"quadruped",
	"winged",
	"serpentine",
	"amorphous",
	"spectral",
	"colossal",
]
const KNOWN_APTITUDES := ["bestial", "sapient", "reader", "channeler", "manipulator"]

const PHASE_ORDER := [
	PHASE_START,
	PHASE_DRAW,
	PHASE_MAIN_1,
	PHASE_COMBAT,
	PHASE_MAIN_2,
	PHASE_END,
]

const STATE_KEYS := [
	"cards",
	"config",
	"energy",
	"finished_reason",
	"life",
	"pending_response",
	"phase",
	"players",
	"seed",
	"turn",
	"turn_usage",
	"winner_ids",
]


func module_id() -> String:
	return "zapiti.juego_cartas_propio"


func module_version() -> String:
	return "0.24.0-stress-hardening"


func validate_config(config: Dictionary) -> Dictionary:
	var normalized: Dictionary = _normalize_config(config)
	if not normalized["ok"]:
		return normalized
	return _success()


func create_initial_state(config: Dictionary, seed: int) -> Dictionary:
	var normalized: Dictionary = _normalize_config(config)
	if not normalized["ok"]:
		return {"initialization_error": normalized}
	var game_config: Dictionary = normalized["value"]
	var players: Array = []
	var player_ids: Array = []
	for index in range(game_config["player_names"].size()):
		players.append(PlayerRegistry.make_player(index, game_config["player_names"][index], index))
		player_ids.append(index)
	var registry_result: Dictionary = PlayerRegistry.create(players)
	if not registry_result["ok"]:
		return {"initialization_error": registry_result}
	var turn_result: Dictionary = TurnState.create(player_ids, game_config["starting_player"])
	if not turn_result["ok"]:
		return {"initialization_error": turn_result}
	var phase_result: Dictionary = _new_phase_state()
	if not phase_result["ok"]:
		return {"initialization_error": phase_result}

	var life: Dictionary = {}
	var energy: Dictionary = {}
	for player_id in player_ids:
		life[_player_key(player_id)] = game_config["starting_life"]
		energy[_player_key(player_id)] = {"maximum": 0, "available": 0}

	var cards_result: Dictionary = _create_card_state(player_ids, seed)
	if not cards_result["ok"]:
		return {"initialization_error": cards_result}
	var state := {
		"seed": seed,
		"config": game_config,
		"players": registry_result["value"],
		"cards": cards_result["value"],
		"turn": turn_result["value"],
		"turn_usage": {"fusion_sequence": 0, "normal_summon_used": false, "terrain_used": false},
		"phase": phase_result["value"],
		"life": life,
		"pending_response": {},
		"energy": energy,
		"winner_ids": [],
		"finished_reason": "",
	}
	_begin_turn(state)
	return state


func validate_state(state: Dictionary) -> Dictionary:
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _failure("JCP_STATE_KEYS_INVALID", "El estado contiene claves ausentes o desconocidas.")
	if not state["seed"] is int or state["seed"] < 0:
		return _failure("JCP_SEED_INVALID", "La semilla debe ser un entero no negativo.")
	var normalized: Dictionary = _normalize_config(state["config"])
	if not normalized["ok"] or normalized["value"] != state["config"]:
		return _failure("JCP_CONFIG_INVALID", "La configuracion guardada no es valida.")
	var player_check: Dictionary = PlayerRegistry.validate(state["players"])
	if not player_check["ok"]:
		return player_check
	var turn_check: Dictionary = TurnState.validate(state["turn"])
	if not turn_check["ok"]:
		return turn_check
	var turn_usage_keys: Array = state["turn_usage"].keys() if state["turn_usage"] is Dictionary else []
	turn_usage_keys.sort()
	if not state["turn_usage"] is Dictionary or turn_usage_keys != ["fusion_sequence", "normal_summon_used", "terrain_used"]:
		return _failure("JCP_TURN_USAGE_INVALID", "El registro de acciones del turno no es valido.")
	if not state["turn_usage"]["normal_summon_used"] is bool or not state["turn_usage"]["terrain_used"] is bool:
		return _failure("JCP_TURN_USAGE_FLAG_INVALID", "Los indicadores de acciones del turno deben ser booleanos.")
	if not state["turn_usage"]["fusion_sequence"] is int or state["turn_usage"]["fusion_sequence"] < 0:
		return _failure("JCP_TURN_USAGE_FUSION_SEQUENCE_INVALID", "La secuencia tecnica de Fusion debe ser un entero no negativo.")
	var phase_check: Dictionary = PhaseMachine.validate(state["phase"])
	if not phase_check["ok"]:
		return phase_check
	var card_check: Dictionary = CardState.validate(state["cards"])
	if not card_check["ok"]:
		return card_check
	var compatibility_catalog_check: Dictionary = _validate_compatibility_catalog(state)
	if not compatibility_catalog_check["ok"]:
		return compatibility_catalog_check

	var player_ids: Array = PlayerRegistry.player_ids(state["players"])
	if state["turn"]["order"] != player_ids:
		return _failure("JCP_TURN_PLAYERS_MISMATCH", "El turno no contiene los jugadores registrados.")
	if not state["life"] is Dictionary or not state["energy"] is Dictionary:
		return _failure("JCP_RESOURCES_INVALID", "Vida y energia deben ser diccionarios.")
	for player_id in player_ids:
		var player_key: String = _player_key(player_id)
		if not state["life"].has(player_key) or not state["life"][player_key] is int or state["life"][player_key] < 0:
			return _failure("JCP_LIFE_INVALID", "La vida de un jugador no es valida.")
		if not state["energy"].has(player_key) or not state["energy"][player_key] is Dictionary:
			return _failure("JCP_ENERGY_INVALID", "Falta el estado de energia de un jugador.")
		var resource: Dictionary = state["energy"][player_key]
		var resource_keys: Array = resource.keys()
		resource_keys.sort()
		if resource_keys != ["available", "maximum"]:
			return _failure("JCP_ENERGY_KEYS_INVALID", "La energia tiene una estructura desconocida.")
		if not resource["maximum"] is int or not resource["available"] is int:
			return _failure("JCP_ENERGY_INVALID", "La energia debe utilizar numeros enteros.")
		if resource["maximum"] < 0 or resource["maximum"] > state["config"]["energy_cap"]:
			return _failure("JCP_ENERGY_MAX_INVALID", "La energia maxima queda fuera de sus limites.")
		if resource["available"] < 0 or resource["available"] > resource["maximum"]:
			return _failure("JCP_ENERGY_AVAILABLE_INVALID", "La energia disponible queda fuera de sus limites.")
	if state["life"].size() != player_ids.size() or state["energy"].size() != player_ids.size():
		return _failure("JCP_RESOURCE_PLAYERS_MISMATCH", "Vida y energia contienen jugadores desconocidos.")
	var required_zones: Array = []
	for player_id in player_ids:
		for zone_kind in ["deck", "hand", "creatures", "fusion_materials", "support", "attachments", "terrain", "graveyard"]:
			required_zones.append(_zone_id(zone_kind, player_id))
	for zone_id in required_zones:
		if not state["cards"]["zones"].has(zone_id):
			return _failure("JCP_ZONE_MISSING", "Falta la zona obligatoria: %s" % zone_id)
	if state["cards"]["zones"].size() != required_zones.size():
		return _failure("JCP_ZONE_EXTRA", "El estado contiene zonas no declaradas.")
	if state["cards"]["definitions"].size() != 40 or state["cards"]["instances"].size() != 80:
		return _failure("JCP_DECK_SHAPE_INVALID", "El prototipo requiere 40 definiciones y dos copias fisicas de cada una.")
	for player_id in player_ids:
		var owned_count := 0
		for instance in state["cards"]["instances"].values():
			if instance["metadata"].get("owner_id", -1) == player_id:
				owned_count += 1
		if owned_count != 40:
			return _failure("JCP_DECK_OWNER_INVALID", "Cada jugador debe conservar exactamente 40 cartas propias.")
		var field_check: Dictionary = _validate_field_zones(state, player_id)
		if not field_check["ok"]:
			return field_check
	if not state["winner_ids"] is Array or not state["finished_reason"] is String:
		return _failure("JCP_FINISH_DATA_INVALID", "El resultado final no es valido.")
	if is_finished(state) != (state["phase"]["current"] == PHASE_FINISHED):
		return _failure("JCP_FINISH_PHASE_MISMATCH", "El resultado y la fase final no coinciden.")
	var pending_check: Dictionary = _validate_pending_response_state(state)
	if not pending_check["ok"]:
		return pending_check
	return _success()


func _validate_field_zones(state: Dictionary, player_id: int) -> Dictionary:
	var creature_ids: Array = state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]
	for instance_id in creature_ids:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		if instance["metadata"].get("owner_id", -1) != player_id:
			return _failure("JCP_FIELD_OWNER_INVALID", "Una criatura esta en el campo de otro propietario.")
		if _definition_for_instance(state, instance_id)["attributes"]["card_type"] != "creature":
			return _failure("JCP_CREATURE_ZONE_TYPE_INVALID", "La fila de criaturas contiene otro tipo de carta.")
		if not instance["metadata"].get("face_up", null) is bool or instance["metadata"].get("position", "") not in ["attack", "guard"]:
			return _failure("JCP_CREATURE_FIELD_METADATA_INVALID", "Una criatura en campo no tiene visibilidad o postura valida.")
		var metadata: Dictionary = instance["metadata"]
		if metadata.has("dragon_bonus_turn") or metadata.has("dragon_bonus_available"):
			if not _can_gain_extra_attack(state, instance_id) or not metadata.get("dragon_bonus_turn", null) is int or not metadata.get("dragon_bonus_available", null) is bool:
				return _failure("JCP_DRAGON_BONUS_METADATA_INVALID", "El permiso de ataque adicional esta incompleto o no pertenece a M18/F005.")
			if metadata["dragon_bonus_turn"] < 1 or metadata["dragon_bonus_turn"] > state["turn"]["turn_number"]:
				return _failure("JCP_DRAGON_BONUS_METADATA_INVALID", "El turno del ataque adicional no es valido.")
		if metadata.has("energy_recovery_turn"):
			if _active_base_definition_id(state, instance_id) != "M16" or not metadata["energy_recovery_turn"] is int or metadata["energy_recovery_turn"] < 1 or metadata["energy_recovery_turn"] > state["turn"]["turn_number"]:
				return _failure("JCP_ENERGY_RECOVERY_METADATA_INVALID", "El uso de recuperacion de M16 no es valido.")
		if metadata.has("creature_ability_turn"):
			if _active_base_definition_id(state, instance_id) != "M09" or not metadata["creature_ability_turn"] is int or metadata["creature_ability_turn"] < 1 or metadata["creature_ability_turn"] > state["turn"]["turn_number"]:
				return _failure("JCP_CREATURE_ABILITY_METADATA_INVALID", "El uso de habilidad de M09 no es valido.")
		if metadata.has("redirect_turn"):
			if _active_base_definition_id(state, instance_id) != "M13" or not metadata["redirect_turn"] is int or metadata["redirect_turn"] < 1 or metadata["redirect_turn"] > state["turn"]["turn_number"]:
				return _failure("JCP_CREATURE_REDIRECT_METADATA_INVALID", "El uso de redireccion de M13 no es valido.")
		var has_steam_penalty: bool = instance["metadata"].has("steam_attack_penalty")
		var has_steam_duration: bool = instance["metadata"].has("steam_penalty_owner_turns_remaining")
		if has_steam_penalty != has_steam_duration:
			return _failure("JCP_STEAM_PENALTY_METADATA_INVALID", "La penalizacion de Vapor esta incompleta.")
		if has_steam_penalty:
			if not instance["metadata"]["steam_attack_penalty"] is int or instance["metadata"]["steam_attack_penalty"] < 1 or instance["metadata"]["steam_attack_penalty"] > 5:
				return _failure("JCP_STEAM_PENALTY_VALUE_INVALID", "La penalizacion de Vapor queda fuera de sus limites.")
			if instance["metadata"]["steam_penalty_owner_turns_remaining"] != 1:
				return _failure("JCP_STEAM_PENALTY_DURATION_INVALID", "La penalizacion de Vapor debe esperar un turno de su controlador.")
		var fusion_check: Dictionary = _validate_fusion_carrier(state, player_id, instance_id)
		if not fusion_check["ok"]:
			return fusion_check
	var contained_ids: Array = state["cards"]["zones"][_zone_id("fusion_materials", player_id)]["cards"]
	for contained_id in contained_ids:
		var contained_metadata: Dictionary = state["cards"]["instances"][contained_id]["metadata"]
		var carrier_id: Variant = contained_metadata.get("contained_by", null)
		if not carrier_id is String or carrier_id not in creature_ids:
			return _failure("JCP_FUSION_MATERIAL_ORPHANED", "Un material contenido no pertenece a una Fusion activa.")
		var carrier_entity: Variant = state["cards"]["instances"][carrier_id]["metadata"].get("fusion_entity", null)
		if not carrier_entity is Dictionary or contained_id not in carrier_entity.get("contained_physical_ids", []):
			return _failure("JCP_FUSION_MATERIAL_LINK_INVALID", "El material y su Fusion no se referencian mutuamente.")
	var support_ids: Array = state["cards"]["zones"][_zone_id("support", player_id)]["cards"]
	for instance_id in support_ids:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		var definition: Dictionary = _definition_for_instance(state, instance_id)
		if instance["metadata"].get("owner_id", -1) != player_id:
			return _failure("JCP_FIELD_OWNER_INVALID", "Un apoyo esta en el campo de otro propietario.")
		if definition["attributes"]["card_type"] not in ["spell", "trap", "item"]:
			return _failure("JCP_SUPPORT_ZONE_TYPE_INVALID", "La fila de apoyo contiene un tipo de carta imposible.")
		if not instance["metadata"].get("face_up", null) is bool or not instance["metadata"].get("active", null) is bool:
			return _failure("JCP_SUPPORT_FIELD_METADATA_INVALID", "Un apoyo en campo no tiene estado visible y activo valido.")
	var attachment_ids: Array = state["cards"]["zones"][_zone_id("attachments", player_id)]["cards"]
	for instance_id in attachment_ids:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		var definition: Dictionary = _definition_for_instance(state, instance_id)
		if instance["metadata"].get("owner_id", -1) != player_id or definition["attributes"]["card_type"] != "item":
			return _failure("JCP_ATTACHMENT_ZONE_TYPE_INVALID", "La zona de vinculos contiene una carta invalida.")
		if definition["id"] == "E04" or instance["metadata"].get("linked_to", "") not in creature_ids:
			return _failure("JCP_ATTACHMENT_LINK_INVALID", "Un equipo no conserva un portador valido.")
		if not _can_equip(state, definition["id"], instance["metadata"]["linked_to"], instance_id):
			return _failure("JCP_ATTACHMENT_COMPATIBILITY_INVALID", "Un equipo vinculado ya no es compatible con su portador.")
	var terrain_ids: Array = state["cards"]["zones"][_zone_id("terrain", player_id)]["cards"]
	for instance_id in terrain_ids:
		var instance: Dictionary = state["cards"]["instances"][instance_id]
		if instance["metadata"].get("owner_id", -1) != player_id:
			return _failure("JCP_FIELD_OWNER_INVALID", "Un Terreno esta en el campo de otro propietario.")
		if _definition_for_instance(state, instance_id)["attributes"]["card_type"] != "terrain":
			return _failure("JCP_TERRAIN_ZONE_TYPE_INVALID", "La zona de Terreno contiene otro tipo de carta.")
		if instance["metadata"].get("face_up", null) != true or instance["metadata"].get("active", null) != true:
			return _failure("JCP_TERRAIN_FIELD_METADATA_INVALID", "Un Terreno en campo debe estar visible y activo.")
		var terrain_metadata_check: Dictionary = _validate_terrain_form_metadata(state, instance_id)
		if not terrain_metadata_check["ok"]:
			return terrain_metadata_check
	return _success()


func _validate_fusion_carrier(state: Dictionary, player_id: int, carrier_id: String) -> Dictionary:
	var metadata: Dictionary = state["cards"]["instances"][carrier_id]["metadata"]
	if not metadata.has("fusion_entity"):
		return _success()
	var entity: Variant = metadata["fusion_entity"]
	var entity_check: Dictionary = FusionRecipeService.validate_generated_identity(entity, KNOWN_ANATOMIES, KNOWN_APTITUDES)
	if not entity_check["ok"]:
		return entity_check
	if entity["owner_id"] != player_id or carrier_id not in entity["contained_physical_ids"]:
		return _failure("JCP_FUSION_CARRIER_INVALID", "La entidad de Fusion no coincide con su portador fisico.")
	if entity["fusion_identity_id"] not in ["fusion.f001_nature_alpha", "fusion.f010_neutral_band", "fusion.f011_torch_band", "fusion.f012_thicket_company", "fusion.f018_two_headed_troll", "fusion.f067_water_major", "fusion.f068_steam_elemental", "fusion.f005_fire_dragon"] or entity["contained_physical_ids"].size() != 2:
		return _failure("JCP_FUSION_IDENTITY_NOT_ENABLED", "El duelo contiene una Fusion que aun no esta habilitada.")
	if metadata.has("troll_regeneration_turn"):
		if entity["fusion_identity_id"] != "fusion.f018_two_headed_troll" or not metadata["troll_regeneration_turn"] is int or metadata["troll_regeneration_turn"] < 1 or metadata["troll_regeneration_turn"] > state["turn"]["turn_number"]:
			return _failure("JCP_TROLL_REGENERATION_METADATA_INVALID", "El uso de regeneracion del Troll Bicéfalo no es valido.")
	for material_id in entity["contained_physical_ids"]:
		if material_id == carrier_id:
			continue
		if not _is_in_zone(state, material_id, _zone_id("fusion_materials", player_id)):
			return _failure("JCP_FUSION_MATERIAL_MISSING", "Falta un material fisico contenido en la Fusion.")
	return _success()


func _validate_pending_response_state(state: Dictionary) -> Dictionary:
	if not state["pending_response"] is Dictionary:
		return _failure("JCP_PENDING_RESPONSE_INVALID", "La respuesta pendiente debe ser un diccionario.")
	var pending: Dictionary = state["pending_response"]
	if pending.is_empty():
		return _success()
	var keys: Array = pending.keys()
	keys.sort()
	if keys != [
		"chain",
		"consecutive_passes",
		"context",
		"kind",
		"priority_player_id",
		"source_player_id",
	]:
		return _failure("JCP_PENDING_RESPONSE_KEYS_INVALID", "La respuesta pendiente tiene una estructura desconocida.")
	if pending["kind"] not in ["attack", "spell", "position_change", "equipment", "combat_destruction", "fusion_combat_choice", "creature_redirect_choice"] or not pending["context"] is Dictionary:
		return _failure("JCP_PENDING_RESPONSE_KIND_INVALID", "El tipo de respuesta pendiente no es valido.")
	if is_finished(state):
		return _failure("JCP_PENDING_RESPONSE_PHASE_INVALID", "Una partida terminada no puede conservar respuestas.")
	for player_key in ["source_player_id", "priority_player_id"]:
		if not pending[player_key] is int or pending[player_key] not in state["turn"]["order"]:
			return _failure("JCP_PENDING_RESPONSE_PLAYER_INVALID", "La respuesta pendiente referencia un jugador imposible.")
	if pending["source_player_id"] != TurnState.active_player(state["turn"]):
		return _failure("JCP_PENDING_RESPONSE_TURN_INVALID", "La fuente pendiente no coincide con el turno activo.")
	var context_check: Dictionary
	match pending["kind"]:
		"attack":
			context_check = _validate_pending_attack_context(state, pending)
		"spell":
			context_check = _validate_pending_spell_context(state, pending)
		"position_change":
			context_check = _validate_pending_position_context(state, pending)
		"equipment":
			context_check = _validate_pending_equipment_context(state, pending)
		"fusion_combat_choice":
			context_check = _validate_pending_fusion_combat_choice_context(state, pending)
		"creature_redirect_choice":
			context_check = _validate_pending_creature_redirect_context(state, pending)
		_:
			context_check = _validate_pending_combat_destruction_context(state, pending)
	if not context_check["ok"]:
		return context_check
	if not pending["consecutive_passes"] is int or pending["consecutive_passes"] < 0 or pending["consecutive_passes"] > 1:
		return _failure("JCP_PENDING_RESPONSE_PASSES_INVALID", "El contador de pases de respuesta no es valido.")
	if not pending["chain"] is Array:
		return _failure("JCP_REACTION_CHAIN_INVALID", "La cadena de respuestas no es una lista.")
	for link in pending["chain"]:
		if not link is Dictionary:
			return _failure("JCP_REACTION_CHAIN_INVALID", "Una respuesta encadenada no es valida.")
		var link_keys: Array = link.keys()
		link_keys.sort()
		if link_keys != ["controller_id", "definition_id", "support_id", "support_slot"]:
			return _failure("JCP_REACTION_CHAIN_INVALID", "Una respuesta encadenada tiene datos desconocidos.")
		if not link["controller_id"] is int or link["controller_id"] not in state["turn"]["order"]:
			return _failure("JCP_REACTION_CHAIN_INVALID", "Una respuesta pertenece a un jugador desconocido.")
		if not link["support_id"] is String or not link["definition_id"] is String or not link["support_slot"] is int:
			return _failure("JCP_REACTION_CHAIN_INVALID", "Una respuesta contiene identificadores invalidos.")
		if not _is_in_zone(state, link["support_id"], _zone_id("support", link["controller_id"])):
			return _failure("JCP_REACTION_CHAIN_SOURCE_MISSING", "Una respuesta ya no esta en la fila de apoyo.")
		if _definition_for_instance(state, link["support_id"])["id"] != link["definition_id"]:
			return _failure("JCP_REACTION_CHAIN_IDENTITY_INVALID", "La identidad revelada de una respuesta no coincide.")
		var metadata: Dictionary = state["cards"]["instances"][link["support_id"]]["metadata"]
		if not metadata.get("face_up", false) or not metadata.get("active", false):
			return _failure("JCP_REACTION_CHAIN_SOURCE_INACTIVE", "Una respuesta encadenada debe estar revelada y activa.")
	return _success()


func _validate_pending_attack_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] != PHASE_COMBAT:
		return _failure("JCP_PENDING_ATTACK_PHASE_INVALID", "Un ataque pendiente requiere la fase de combate.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["attacker_id", "modifiers", "target_id", "target_player_id", "target_slot"]:
		return _failure("JCP_PENDING_ATTACK_CONTEXT_INVALID", "El contexto del ataque pendiente no es valido.")
	var modifier_check: Dictionary = _validate_combat_modifiers(context["modifiers"])
	if not modifier_check["ok"]:
		return modifier_check
	if not context["target_player_id"] is int or context["target_player_id"] != _opponent_id(state, pending["source_player_id"]):
		return _failure("JCP_PENDING_ATTACK_OPPONENT_INVALID", "El defensor pendiente no es el rival del atacante.")
	if not context["attacker_id"] is String or not _is_in_zone(state, context["attacker_id"], _zone_id("creatures", pending["source_player_id"])):
		return _failure("JCP_PENDING_ATTACKER_INVALID", "El atacante pendiente ya no ocupa su fila.")
	if not context["target_slot"] is int or context["target_slot"] < -1 or not context["target_id"] is String:
		return _failure("JCP_PENDING_ATTACK_TARGET_INVALID", "El objetivo pendiente no es valido.")
	var enemy_cards: Array = state["cards"]["zones"][_zone_id("creatures", context["target_player_id"])]["cards"]
	if context["target_slot"] == -1:
		if context["target_id"] != "" or not enemy_cards.is_empty():
			return _failure("JCP_PENDING_ATTACK_TARGET_INVALID", "El ataque directo pendiente no es coherente.")
	elif context["target_slot"] >= enemy_cards.size() or enemy_cards[context["target_slot"]] != context["target_id"]:
		return _failure("JCP_PENDING_ATTACK_TARGET_INVALID", "La casilla objetivo cambio durante la respuesta.")
	return _success()


func _validate_pending_fusion_combat_choice_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] != PHASE_COMBAT:
		return _failure("JCP_FUSION_COMBAT_CHOICE_PHASE_INVALID", "La eleccion del Elemental Mayor requiere la fase de combate.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["attacker_id", "choice_queue", "modifiers", "target_id", "target_player_id", "target_slot"]:
		return _failure("JCP_FUSION_COMBAT_CHOICE_CONTEXT_INVALID", "El contexto de eleccion de combate no es valido.")
	var modifier_check: Dictionary = _validate_combat_modifiers(context["modifiers"])
	if not modifier_check["ok"]:
		return modifier_check
	if not context["choice_queue"] is Array or context["choice_queue"].is_empty():
		return _failure("JCP_FUSION_COMBAT_CHOICE_QUEUE_INVALID", "Falta el Elemental Mayor que debe elegir.")
	var attack_context := {
		"attacker_id": context["attacker_id"], "target_id": context["target_id"],
		"target_player_id": context["target_player_id"], "target_slot": context["target_slot"],
		"modifiers": context["modifiers"],
	}
	var attack_pending: Dictionary = pending.duplicate(true)
	attack_pending["context"] = attack_context
	var attack_check: Dictionary = _validate_pending_attack_context(state, attack_pending)
	if not attack_check["ok"]:
		return attack_check
	for entry in context["choice_queue"]:
		if not entry is Dictionary:
			return _failure("JCP_FUSION_COMBAT_CHOICE_QUEUE_INVALID", "Una eleccion pendiente no es valida.")
		var entry_keys: Array = entry.keys()
		entry_keys.sort()
		if entry_keys != ["creature_id", "player_id", "role"] or entry["role"] not in ["attacker", "target"]:
			return _failure("JCP_FUSION_COMBAT_CHOICE_QUEUE_INVALID", "Una eleccion pendiente tiene datos desconocidos.")
		if not entry["creature_id"] is String or not entry["player_id"] is int or entry["player_id"] not in state["turn"]["order"]:
			return _failure("JCP_FUSION_COMBAT_CHOICE_QUEUE_INVALID", "Una eleccion pendiente referencia una criatura o jugador invalidos.")
		if not _is_in_zone(state, entry["creature_id"], _zone_id("creatures", entry["player_id"])) or _fusion_identity_id(state, entry["creature_id"]) != "fusion.f067_water_major":
			return _failure("JCP_FUSION_COMBAT_CHOICE_SOURCE_INVALID", "La eleccion pendiente no pertenece a un Elemental Mayor activo.")
	if pending["priority_player_id"] != context["choice_queue"][0]["player_id"]:
		return _failure("JCP_FUSION_COMBAT_CHOICE_PRIORITY_INVALID", "La prioridad no coincide con la siguiente eleccion.")
	return _success()


func _validate_pending_creature_redirect_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] != PHASE_COMBAT or not pending["chain"].is_empty() or pending["consecutive_passes"] != 0:
		return _failure("JCP_CREATURE_REDIRECT_STATE_INVALID", "La eleccion de M13 requiere un combate sin cadena.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["attacker_id", "guardian_ids", "original_target_id", "original_target_slot"]:
		return _failure("JCP_CREATURE_REDIRECT_CONTEXT_INVALID", "El contexto de redireccion no es valido.")
	if pending["priority_player_id"] != _opponent_id(state, pending["source_player_id"]):
		return _failure("JCP_CREATURE_REDIRECT_PRIORITY_INVALID", "La eleccion debe pertenecer al defensor.")
	if not _is_in_zone(state, context["attacker_id"], _zone_id("creatures", pending["source_player_id"])):
		return _failure("JCP_CREATURE_REDIRECT_ATTACKER_INVALID", "El atacante de la redireccion ya no existe.")
	var defender_id: int = pending["priority_player_id"]
	var defenders: Array = state["cards"]["zones"][_zone_id("creatures", defender_id)]["cards"]
	if not context["original_target_slot"] is int or context["original_target_slot"] < 0 or context["original_target_slot"] >= defenders.size() or defenders[context["original_target_slot"]] != context["original_target_id"]:
		return _failure("JCP_CREATURE_REDIRECT_TARGET_INVALID", "El objetivo original ya no coincide.")
	if not context["guardian_ids"] is Array or context["guardian_ids"].is_empty():
		return _failure("JCP_CREATURE_REDIRECT_GUARDIANS_INVALID", "No existe un M13 capaz de redirigir.")
	for guardian_id in context["guardian_ids"]:
		if not guardian_id is String or guardian_id == context["original_target_id"] or guardian_id not in defenders or _active_base_definition_id(state, guardian_id) != "M13":
			return _failure("JCP_CREATURE_REDIRECT_GUARDIANS_INVALID", "Un protector pendiente no es M13 activo.")
		var metadata: Dictionary = state["cards"]["instances"][guardian_id]["metadata"]
		if not metadata.get("face_up", false) or metadata.get("redirect_turn", -1) == state["turn"]["turn_number"]:
			return _failure("JCP_CREATURE_REDIRECT_GUARDIANS_INVALID", "M13 no puede redirigir en este turno.")
	return _success()


func _validate_combat_modifiers(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _failure("JCP_COMBAT_MODIFIERS_INVALID", "Los modificadores de combate no son validos.")
	var keys: Array = value.keys()
	keys.sort()
	if keys != ["attacker_attack_delta", "attacker_defense_delta", "target_attack_delta", "target_defense_delta"]:
		return _failure("JCP_COMBAT_MODIFIERS_INVALID", "Los modificadores de combate estan incompletos.")
	for modifier in value.values():
		if not modifier is int:
			return _failure("JCP_COMBAT_MODIFIERS_INVALID", "Un modificador de combate no es entero.")
	if value["attacker_attack_delta"] < -5 or value["attacker_attack_delta"] > 5:
		return _failure("JCP_COMBAT_MODIFIERS_INVALID", "El modificador de ataque pendiente queda fuera del limite posible.")
	for bounded_key in ["attacker_defense_delta", "target_attack_delta", "target_defense_delta"]:
		if value[bounded_key] < 0 or value[bounded_key] > 1:
			return _failure("JCP_COMBAT_MODIFIERS_INVALID", "Un bono pendiente del Elemental Mayor queda fuera del limite posible.")
	return _success()


func _validate_pending_spell_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_PENDING_SPELL_PHASE_INVALID", "Una Magia pendiente requiere una fase principal.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["spell_definition_id", "spell_id", "target_id", "target_player_id", "target_slot"]:
		return _failure("JCP_PENDING_SPELL_CONTEXT_INVALID", "El contexto de la Magia pendiente no es valido.")
	if not context["spell_id"] is String or not context["spell_definition_id"] is String:
		return _failure("JCP_PENDING_SPELL_SOURCE_INVALID", "La fuente de la Magia pendiente no es valida.")
	if not _is_in_zone(state, context["spell_id"], _zone_id("hand", pending["source_player_id"])):
		return _failure("JCP_PENDING_SPELL_SOURCE_MISSING", "La Magia pendiente ya no esta en la mano de su jugador.")
	if _definition_for_instance(state, context["spell_id"])["id"] != context["spell_definition_id"] or context["spell_definition_id"] not in ["G01", "G02", "G03"]:
		return _failure("JCP_PENDING_SPELL_IDENTITY_INVALID", "La identidad de la Magia pendiente no coincide.")
	if not context["target_player_id"] is int or context["target_player_id"] not in state["turn"]["order"] or not context["target_slot"] is int or context["target_slot"] < 0 or not context["target_id"] is String:
		return _failure("JCP_PENDING_SPELL_TARGET_INVALID", "El objetivo de la Magia pendiente no es valido.")
	var targets: Array = state["cards"]["zones"][_zone_id("creatures", context["target_player_id"])]["cards"]
	if context["target_slot"] >= targets.size() or targets[context["target_slot"]] != context["target_id"]:
		return _failure("JCP_PENDING_SPELL_TARGET_INVALID", "La casilla objetivo de la Magia cambio durante la respuesta.")
	return _success()


func _validate_pending_position_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_PENDING_POSITION_PHASE_INVALID", "El cambio pendiente requiere una fase principal.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["creature_id", "previous_position"] or context["previous_position"] != "guard" or not context["creature_id"] is String:
		return _failure("JCP_PENDING_POSITION_CONTEXT_INVALID", "El contexto del cambio de postura no es valido.")
	if not _is_in_zone(state, context["creature_id"], _zone_id("creatures", pending["source_player_id"])):
		return _failure("JCP_PENDING_POSITION_SOURCE_MISSING", "La criatura cambiada ya no esta en su fila.")
	var metadata: Dictionary = state["cards"]["instances"][context["creature_id"]]["metadata"]
	if not metadata.get("face_up", false) or metadata.get("position", "") != "attack":
		return _failure("JCP_PENDING_POSITION_STATE_INVALID", "La criatura no conserva el cambio que disparo la respuesta.")
	return _success()


func _validate_pending_equipment_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_PENDING_EQUIPMENT_PHASE_INVALID", "El equipo pendiente requiere una fase principal.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["equipment_id", "target_creature_id"] or not context["equipment_id"] is String or not context["target_creature_id"] is String:
		return _failure("JCP_PENDING_EQUIPMENT_CONTEXT_INVALID", "El contexto del equipo no es valido.")
	if not _is_in_zone(state, context["equipment_id"], _zone_id("attachments", pending["source_player_id"])):
		return _failure("JCP_PENDING_EQUIPMENT_SOURCE_MISSING", "El equipo recien vinculado ya no esta en campo.")
	if not _is_in_zone(state, context["target_creature_id"], _zone_id("creatures", pending["source_player_id"])):
		return _failure("JCP_PENDING_EQUIPMENT_TARGET_MISSING", "El portador del equipo ya no esta en campo.")
	if state["cards"]["instances"][context["equipment_id"]]["metadata"].get("linked_to", "") != context["target_creature_id"]:
		return _failure("JCP_PENDING_EQUIPMENT_LINK_INVALID", "El vinculo que disparo la respuesta ya no coincide.")
	return _success()


func _validate_pending_combat_destruction_context(state: Dictionary, pending: Dictionary) -> Dictionary:
	if state["phase"]["current"] != PHASE_COMBAT:
		return _failure("JCP_PENDING_DESTRUCTION_PHASE_INVALID", "La represalia pendiente requiere la fase de combate.")
	var context: Dictionary = pending["context"]
	var keys: Array = context.keys()
	keys.sort()
	if keys != ["destroyed_creature_id", "destroyed_player_id", "surviving_creature_id", "surviving_player_id"]:
		return _failure("JCP_PENDING_DESTRUCTION_CONTEXT_INVALID", "El contexto de destruccion no es valido.")
	for player_key in ["destroyed_player_id", "surviving_player_id"]:
		if not context[player_key] is int or context[player_key] not in state["turn"]["order"]:
			return _failure("JCP_PENDING_DESTRUCTION_PLAYER_INVALID", "La destruccion referencia un jugador desconocido.")
	if context["destroyed_player_id"] == context["surviving_player_id"] or not context["destroyed_creature_id"] is String or not context["surviving_creature_id"] is String:
		return _failure("JCP_PENDING_DESTRUCTION_CONTEXT_INVALID", "Los combatientes de la represalia no son validos.")
	if not _is_in_zone(state, context["destroyed_creature_id"], _zone_id("graveyard", context["destroyed_player_id"])):
		return _failure("JCP_PENDING_DESTRUCTION_SOURCE_MISSING", "La criatura destruida no esta en el cementerio.")
	if not _is_in_zone(state, context["surviving_creature_id"], _zone_id("creatures", context["surviving_player_id"])):
		return _failure("JCP_PENDING_DESTRUCTION_SURVIVOR_MISSING", "El combatiente que sobrevivio ya no esta en campo.")
	return _success()


func validate_action(state: Dictionary, action: Object) -> Dictionary:
	var state_check: Dictionary = validate_state(state)
	if not state_check["ok"]:
		return state_check
	if action.type not in [
		ACTION_ADVANCE_PHASE,
		ACTION_ACTIVATE_FUSION_ABILITY,
		ACTION_ACTIVATE_CREATURE_ABILITY,
		ACTION_ACTIVATE_REACTION,
		ACTION_ATTACK,
		ACTION_CHANGE_POSITION,
		ACTION_CHOOSE_FUSION_COMBAT_BONUS,
		ACTION_REDIRECT_ATTACK,
		ACTION_DECLINE_REDIRECT,
		ACTION_CONCEDE,
		ACTION_EQUIP_ITEM,
		ACTION_FUSE_CREATURES,
		ACTION_PLAY_MAIN_SPELL,
		ACTION_PLAY_PERSISTENT,
		ACTION_PLAY_TERRAIN,
		ACTION_PASS_REACTION,
		ACTION_RELOCATE_EQUIPMENT,
		ACTION_SET_CREATURE,
		ACTION_SET_SUPPORT,
		ACTION_SUMMON_CREATURE,
	]:
		return _failure("JCP_ACTION_UNKNOWN", "La accion no pertenece al prototipo de fases.")
	if action.actor_id not in state["turn"]["order"]:
		return _failure("JCP_ACTOR_UNKNOWN", "El jugador no pertenece a la partida.")
	if not state["pending_response"].is_empty():
		if state["pending_response"]["kind"] == "fusion_combat_choice":
			if action.type != ACTION_CHOOSE_FUSION_COMBAT_BONUS:
				return _failure("JCP_FUSION_COMBAT_CHOICE_REQUIRED", "Debe elegirse el bono del Elemental Mayor antes de continuar.")
			if action.actor_id != state["pending_response"]["priority_player_id"]:
				return _failure("JCP_FUSION_COMBAT_CHOICE_WRONG_PLAYER", "La eleccion pertenece al controlador del Elemental Mayor.")
			return _validate_fusion_combat_choice(state, action.actor_id, action.payload)
		if state["pending_response"]["kind"] == "creature_redirect_choice":
			if action.type not in [ACTION_REDIRECT_ATTACK, ACTION_DECLINE_REDIRECT]:
				return _failure("JCP_CREATURE_REDIRECT_CHOICE_REQUIRED", "Debe resolverse la posible redireccion de M13.")
			if action.actor_id != state["pending_response"]["priority_player_id"]:
				return _failure("JCP_CREATURE_REDIRECT_WRONG_PLAYER", "La redireccion pertenece al defensor.")
			return _validate_creature_redirect(state, action.type, action.payload)
		if action.type not in [ACTION_ACTIVATE_REACTION, ACTION_PASS_REACTION]:
			return _failure("JCP_REACTION_WINDOW_ACTIVE", "Primero debe cerrarse la respuesta al ataque.")
		if action.actor_id != state["pending_response"]["priority_player_id"]:
			return _failure("JCP_REACTION_WRONG_PRIORITY", "La prioridad de respuesta pertenece al otro jugador.")
		if action.type == ACTION_ACTIVATE_REACTION:
			return _validate_reaction(state, action.actor_id, action.payload)
		if not action.payload.is_empty():
			return _failure("JCP_PAYLOAD_NOT_EMPTY", "Pasar prioridad no admite datos adicionales.")
		return _success()
	if action.type in [ACTION_ACTIVATE_REACTION, ACTION_PASS_REACTION]:
		return _failure("JCP_REACTION_WINDOW_INACTIVE", "No hay ningun ataque pendiente al que responder.")
	if action.type in [ACTION_REDIRECT_ATTACK, ACTION_DECLINE_REDIRECT]:
		return _failure("JCP_CREATURE_REDIRECT_WINDOW_INACTIVE", "No existe una redireccion de M13 pendiente.")
	if action.actor_id != TurnState.active_player(state["turn"]):
		return _failure("JCP_WRONG_ACTOR", "Solo el jugador activo puede actuar.")
	if action.type == ACTION_SUMMON_CREATURE:
		return _validate_creature_entry(state, action.actor_id, action.payload, true)
	if action.type == ACTION_SET_CREATURE:
		return _validate_creature_entry(state, action.actor_id, action.payload, false)
	if action.type == ACTION_ACTIVATE_FUSION_ABILITY:
		return _validate_fusion_ability(state, action.actor_id, action.payload)
	if action.type == ACTION_ACTIVATE_CREATURE_ABILITY:
		return _validate_creature_ability(state, action.actor_id, action.payload)
	if action.type == ACTION_ATTACK:
		return _validate_attack(state, action.actor_id, action.payload)
	if action.type == ACTION_CHANGE_POSITION:
		return _validate_position_change(state, action.actor_id, action.payload)
	if action.type == ACTION_SET_SUPPORT:
		return _validate_set_support(state, action.actor_id, action.payload)
	if action.type == ACTION_PLAY_PERSISTENT:
		return _validate_play_persistent(state, action.actor_id, action.payload)
	if action.type == ACTION_EQUIP_ITEM:
		return _validate_equip_item(state, action.actor_id, action.payload)
	if action.type == ACTION_FUSE_CREATURES:
		return _validate_fuse_creatures(state, action.actor_id, action.payload)
	if action.type == ACTION_PLAY_MAIN_SPELL:
		return _validate_play_main_spell(state, action.actor_id, action.payload)
	if action.type == ACTION_PLAY_TERRAIN:
		return _validate_play_terrain(state, action.actor_id, action.payload)
	if action.type == ACTION_RELOCATE_EQUIPMENT:
		return _validate_relocate_equipment(state, action.actor_id, action.payload)
	if not action.payload.is_empty():
		return _failure("JCP_PAYLOAD_NOT_EMPTY", "Esta accion no admite datos adicionales.")
	return _success()


func reduce(state: Dictionary, action: Object) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	if action.type == ACTION_CHOOSE_FUSION_COMBAT_BONUS:
		return _reduce_fusion_combat_choice(next_state, action.actor_id, action.payload["choice"])
	if action.type in [ACTION_REDIRECT_ATTACK, ACTION_DECLINE_REDIRECT]:
		return _reduce_creature_redirect(next_state, action.actor_id, action.payload.get("guardian_id", ""))
	if action.type == ACTION_ACTIVATE_REACTION:
		return _reduce_reaction(next_state, action.actor_id, action.payload["support_slot"])
	if action.type == ACTION_PASS_REACTION:
		return _reduce_pass_reaction(next_state, action.actor_id)
	if action.type == ACTION_CONCEDE:
		var winner_ids: Array = []
		for player_id in next_state["turn"]["order"]:
			if player_id != action.actor_id:
				winner_ids.append(player_id)
		next_state["winner_ids"] = winner_ids
		next_state["finished_reason"] = "concession"
		var finish_result: Dictionary = PhaseMachine.transition(next_state["phase"], PHASE_FINISHED)
		if not finish_result["ok"]:
			return _transition_failure(finish_result)
		next_state["phase"] = finish_result["value"]
		return _transition_success(next_state, [{
			"type": "player_conceded",
			"payload": {"player_id": action.actor_id, "winner_ids": winner_ids},
		}])
	if action.type == ACTION_ACTIVATE_FUSION_ABILITY:
		return _reduce_fusion_ability(
			next_state,
			action.actor_id,
			action.payload["source_instance_id"],
			action.payload["target_instance_id"]
		)
	if action.type == ACTION_ACTIVATE_CREATURE_ABILITY:
		return _reduce_creature_ability(next_state, action.actor_id, action.payload["source_instance_id"])
	if action.type == ACTION_SUMMON_CREATURE:
		return _reduce_creature_entry(next_state, action.actor_id, action.payload["instance_id"], true, action.payload)
	if action.type == ACTION_SET_CREATURE:
		return _reduce_creature_entry(next_state, action.actor_id, action.payload["instance_id"], false, action.payload)
	if action.type == ACTION_ATTACK:
		return _reduce_attack(
			next_state,
			action.actor_id,
			action.payload["attacker_id"],
			action.payload["target_slot"]
		)
	if action.type == ACTION_SET_SUPPORT:
		return _reduce_set_support(next_state, action.actor_id, action.payload["instance_id"])
	if action.type == ACTION_PLAY_PERSISTENT:
		return _reduce_play_persistent(next_state, action.actor_id, action.payload["instance_id"])
	if action.type == ACTION_EQUIP_ITEM:
		return _reduce_equip_item(
			next_state,
			action.actor_id,
			action.payload["instance_id"],
			action.payload["target_instance_id"]
		)
	if action.type == ACTION_FUSE_CREATURES:
		return _reduce_fuse_creatures(next_state, action.actor_id, action.payload["material_instance_ids"], action.payload["position"], action.payload.get("target_instance_id", ""))
	if action.type == ACTION_PLAY_MAIN_SPELL:
		return _reduce_play_main_spell(
			next_state,
			action.actor_id,
			action.payload["instance_id"],
			action.payload["target_player_id"],
			action.payload["target_slot"]
		)
	if action.type == ACTION_PLAY_TERRAIN:
		return _reduce_play_terrain(next_state, action.actor_id, action.payload["instance_id"])
	if action.type == ACTION_RELOCATE_EQUIPMENT:
		return _reduce_relocate_equipment(
			next_state,
			action.actor_id,
			action.payload["artifact_instance_id"],
			action.payload["equipment_instance_id"],
			action.payload["target_instance_id"]
		)
	if action.type == ACTION_CHANGE_POSITION:
		return _reduce_position_change(
			next_state,
			action.actor_id,
			action.payload["instance_id"],
			action.payload["target_position"]
		)

	var current_phase: String = next_state["phase"]["current"]
	var next_phase: String = _next_phase(current_phase)
	var events: Array = [{
		"type": "phase_completed",
		"payload": {"player_id": action.actor_id, "phase": current_phase},
	}]
	if current_phase == PHASE_END:
		var expiration: Dictionary = _expire_steam_penalties(next_state, action.actor_id)
		if not expiration["ok"]:
			return _transition_failure(expiration)
		next_state = expiration["state"]
		events.append_array(expiration["events"])
		var turn_result: Dictionary = TurnState.advance(next_state["turn"])
		if not turn_result["ok"]:
			return _transition_failure(turn_result)
		next_state["turn"] = turn_result["value"]
		next_state["turn_usage"] = {"fusion_sequence": 0, "normal_summon_used": false, "terrain_used": false}
		var fresh_phase: Dictionary = _new_phase_state()
		if not fresh_phase["ok"]:
			return _transition_failure(fresh_phase)
		next_state["phase"] = fresh_phase["value"]
		_begin_turn(next_state)
		events.append({
			"type": "turn_started",
			"payload": {
				"player_id": TurnState.active_player(next_state["turn"]),
				"turn_number": next_state["turn"]["turn_number"],
				"round_number": next_state["turn"]["round_number"],
				"energy": next_state["energy"][_player_key(TurnState.active_player(next_state["turn"]))].duplicate(true),
			},
		})
	else:
		var phase_result: Dictionary = PhaseMachine.transition(next_state["phase"], next_phase)
		if not phase_result["ok"]:
			return _transition_failure(phase_result)
		next_state["phase"] = phase_result["value"]
		if next_phase == PHASE_DRAW and _turn_requires_draw(next_state):
			var deck_zone: String = _zone_id("deck", action.actor_id)
			if next_state["cards"]["zones"][deck_zone]["cards"].is_empty():
				var winner_ids: Array = []
				for player_id in next_state["turn"]["order"]:
					if player_id != action.actor_id:
						winner_ids.append(player_id)
				next_state["winner_ids"] = winner_ids
				next_state["finished_reason"] = "deck_empty"
				var finish_result: Dictionary = PhaseMachine.transition(next_state["phase"], PHASE_FINISHED)
				if not finish_result["ok"]:
					return _transition_failure(finish_result)
				next_state["phase"] = finish_result["value"]
				events.append({
					"type": "player_deck_exhausted",
					"payload": {"player_id": action.actor_id, "winner_ids": winner_ids},
				})
				return _transition_success(next_state, events)
			var draw_result: Dictionary = _draw_one(next_state, action.actor_id)
			if not draw_result["ok"]:
				return _transition_failure(draw_result)
			next_state = draw_result["state"]
			events.append({
				"type": "card_drawn",
				"payload": {"player_id": action.actor_id, "count": 1},
			})
			events.append({
				"type": "private_card_drawn",
				"payload": {"player_id": action.actor_id, "instance_id": draw_result["instance_id"]},
				"visible_to": [action.actor_id],
			})
		events.append({
			"type": "phase_started",
			"payload": {"player_id": action.actor_id, "phase": next_phase},
		})
	return _transition_success(next_state, events)


func _expire_steam_penalties(state: Dictionary, player_id: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var events: Array = []
	for creature_id in next_state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]:
		var metadata: Dictionary = next_state["cards"]["instances"][creature_id]["metadata"].duplicate(true)
		if not metadata.has("steam_attack_penalty"):
			continue
		var expired_amount: int = metadata["steam_attack_penalty"]
		metadata.erase("steam_attack_penalty")
		metadata.erase("steam_penalty_owner_turns_remaining")
		var update: Dictionary = CardState.update_instance_metadata(next_state["cards"], creature_id, metadata)
		if not update["ok"]:
			return update
		next_state["cards"] = update["value"]
		events.append({"type": "timed_attack_penalty_expired", "payload": {"player_id": player_id, "target_instance_id": creature_id, "attack_penalty": expired_amount}})
	return {"ok": true, "state": next_state, "events": events}


func get_public_state(state: Dictionary) -> Dictionary:
	var cards_view: Dictionary = _card_view_for(state, -1)
	return {
		"active_player": TurnState.active_player(state["turn"]),
		"energy": state["energy"].duplicate(true),
		"finished_reason": state["finished_reason"],
		"life": state["life"].duplicate(true),
		"phase": state["phase"]["current"],
		"round_number": state["turn"]["round_number"],
		"turn_number": state["turn"]["turn_number"],
		"winner_ids": state["winner_ids"].duplicate(),
		"response_window": _public_response_window(state),
		"card_table": cards_view["value"],
	}


func get_player_state(state: Dictionary, viewer_id: int) -> Dictionary:
	var view: Dictionary = get_public_state(state)
	var cards_view: Dictionary = _card_view_for(state, viewer_id)
	view["card_table"] = cards_view["value"]
	view["viewer_id"] = viewer_id
	view["can_act"] = not is_finished(state) and (
		viewer_id == state["pending_response"].get("priority_player_id", TurnState.active_player(state["turn"]))
	)
	return view


func validate_viewer(state: Dictionary, viewer_id: int) -> Dictionary:
	if viewer_id not in state["turn"]["order"]:
		return _failure("JCP_VIEWER_UNKNOWN", "El observador no pertenece a la partida.")
	return _success()


func get_legal_actions(state: Dictionary, viewer_id: int) -> Array:
	if is_finished(state):
		return []
	if not state["pending_response"].is_empty():
		if state["pending_response"]["kind"] == "fusion_combat_choice":
			return _fusion_combat_choice_legal_actions(state, viewer_id)
		if state["pending_response"]["kind"] == "creature_redirect_choice":
			return _creature_redirect_legal_actions(state, viewer_id)
		return _reaction_legal_actions(state, viewer_id)
	if viewer_id != TurnState.active_player(state["turn"]):
		return []
	var result: Array = []
	var advance_result: Dictionary = LegalAction.create(
		ACTION_ADVANCE_PHASE,
		viewer_id,
		{},
		"Continuar a la fase siguiente"
	)
	var concede_result: Dictionary = LegalAction.create(ACTION_CONCEDE, viewer_id, {}, "Rendirse")
	result.append(advance_result["value"])
	result.append(concede_result["value"])
	if state["phase"]["current"] in [PHASE_MAIN_1, PHASE_MAIN_2] and not state["turn_usage"]["normal_summon_used"]:
		var hand_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("hand", viewer_id))
		var creature_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", viewer_id))
		if hand_result["ok"] and creature_result["ok"] and creature_result["value"].size() < 5:
			for instance_id in hand_result["value"]:
				var instance: Dictionary = state["cards"]["instances"][instance_id]
				var definition: Dictionary = state["cards"]["definitions"][instance["definition_id"]]
				if definition["attributes"]["card_type"] != "creature":
					continue
				var energy: int = state["energy"][_player_key(viewer_id)]["available"]
				if definition["attributes"]["cost"] > energy:
					continue
				var summon_payloads: Array = [{"instance_id": instance_id}]
				if instance["definition_id"] == "M12":
					var hidden_support_slots: Array = _hidden_enemy_support_slots(state, viewer_id)
					if not hidden_support_slots.is_empty():
						summon_payloads = []
						for support_slot in hidden_support_slots:
							summon_payloads.append({"instance_id": instance_id, "peek_support_slot": support_slot})
				elif instance["definition_id"] == "M15":
					var own_targets: Array = state["cards"]["zones"][_zone_id("creatures", viewer_id)]["cards"]
					if not own_targets.is_empty():
						summon_payloads = []
						for target_id in own_targets:
							summon_payloads.append({"instance_id": instance_id, "target_instance_id": target_id})
				for summon_payload in summon_payloads:
					var summon_result: Dictionary = LegalAction.create(
						ACTION_SUMMON_CREATURE,
						viewer_id,
						summon_payload,
						"Invocar %s" % definition["attributes"]["display_name"],
						{"cost": definition["attributes"]["cost"]}
					)
					result.append(summon_result["value"])
				var set_result: Dictionary = LegalAction.create(
					ACTION_SET_CREATURE,
					viewer_id,
					{"instance_id": instance_id},
					"Colocar %s boca abajo" % definition["attributes"]["display_name"],
					{"cost": definition["attributes"]["cost"]}
				)
				result.append(set_result["value"])
	if state["phase"]["current"] in [PHASE_MAIN_1, PHASE_MAIN_2]:
		result.append_array(_field_card_legal_actions(state, viewer_id))
		if true:
			var fusion_zone: Array = state["cards"]["zones"][_zone_id("creatures", viewer_id)]["cards"]
			for left_index in range(fusion_zone.size()):
				for right_index in range(left_index + 1, fusion_zone.size()):
					var material_ids: Array = [fusion_zone[left_index], fusion_zone[right_index]]
					var build: Dictionary = _build_enabled_fusion(state, material_ids, viewer_id)
					if not build["ok"]:
						continue
					var fusion_targets: Array = [""]
					if build["value"]["fusion_identity_id"] == "fusion.f068_steam_elemental":
						var visible_enemies: Array = _visible_enemy_creature_ids(state, viewer_id)
						if not visible_enemies.is_empty():
							fusion_targets = visible_enemies
					for target_id in fusion_targets:
						for position in ["attack", "guard"]:
							var fusion_payload: Dictionary = {"material_instance_ids": material_ids, "position": position}
							if not target_id.is_empty():
								fusion_payload["target_instance_id"] = target_id
							var fusion_action: Dictionary = LegalAction.create(
								ACTION_FUSE_CREATURES,
								viewer_id,
								fusion_payload,
								"Fusionar en %s: %s" % [position, build["value"]["display_name"]]
							)
							result.append(fusion_action["value"])
		if state["energy"][_player_key(viewer_id)]["available"] >= 1:
			var own_fusion_targets: Array = state["cards"]["zones"][_zone_id("creatures", viewer_id)]["cards"]
			for source_id in own_fusion_targets:
				var source_metadata: Dictionary = state["cards"]["instances"][source_id]["metadata"]
				if _active_base_definition_id(state, source_id) != "M09" or not source_metadata.get("face_up", false):
					continue
				if source_metadata.get("creature_ability_turn", -1) == state["turn"]["turn_number"]:
					continue
				var creature_ability: Dictionary = LegalAction.create(
					ACTION_ACTIVATE_CREATURE_ABILITY,
					viewer_id,
					{"source_instance_id": source_id},
					"Goblin Pendenciero: obtener +1 ATQ",
					{"cost": 1}
				)
				result.append(creature_ability["value"])
			for source_id in own_fusion_targets:
				var source_metadata: Dictionary = state["cards"]["instances"][source_id]["metadata"]
				var source_entity: Variant = source_metadata.get("fusion_entity", null)
				if not source_entity is Dictionary or source_entity.get("fusion_identity_id", "") != "fusion.f010_neutral_band":
					continue
				if source_metadata.get("fusion_ability_turn", -1) == state["turn"]["turn_number"]:
					continue
				for target_id in own_fusion_targets:
					if not state["cards"]["instances"][target_id]["metadata"].get("face_up", false):
						continue
					var ability_action: Dictionary = LegalAction.create(
						ACTION_ACTIVATE_FUSION_ABILITY,
						viewer_id,
						{"source_instance_id": source_id, "target_instance_id": target_id},
						"Banda Goblin: otorgar +1 ATQ",
						{"cost": 1}
					)
					result.append(ability_action["value"])
	if state["phase"]["current"] in [PHASE_MAIN_1, PHASE_MAIN_2]:
		var own_creatures: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", viewer_id))
		if own_creatures["ok"]:
			for instance_id in own_creatures["value"]:
				var instance: Dictionary = state["cards"]["instances"][instance_id]
				var metadata: Dictionary = instance["metadata"]
				if metadata.get("summoned_turn", -1) == state["turn"]["turn_number"]:
					continue
				if metadata.get("last_position_change_turn", -1) == state["turn"]["turn_number"]:
					continue
				if metadata.get("last_attack_turn", -1) == state["turn"]["turn_number"]:
					continue
				var target_position := "attack" if metadata.get("position", "guard") == "guard" else "guard"
				var position_result: Dictionary = LegalAction.create(
					ACTION_CHANGE_POSITION,
					viewer_id,
					{"instance_id": instance_id, "target_position": target_position},
					"Cambiar postura",
					{"target_position": target_position}
				)
				result.append(position_result["value"])
	if state["phase"]["current"] == PHASE_COMBAT:
		var own_creatures: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", viewer_id))
		var opponent_id: int = _opponent_id(state, viewer_id)
		var enemy_creatures: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", opponent_id))
		if own_creatures["ok"] and enemy_creatures["ok"]:
			for attacker_id in own_creatures["value"]:
				var metadata: Dictionary = state["cards"]["instances"][attacker_id]["metadata"]
				if not metadata.get("face_up", true) or metadata.get("position", "guard") != "attack":
					continue
				if _attack_entry_is_blocked(state, viewer_id, attacker_id):
					continue
				if metadata.get("last_attack_turn", -1) == state["turn"]["turn_number"] and not _has_dragon_extra_attack(state, attacker_id):
					continue
				if enemy_creatures["value"].is_empty():
					var direct_result: Dictionary = LegalAction.create(
						ACTION_ATTACK,
						viewer_id,
						{"attacker_id": attacker_id, "target_slot": -1},
						"Atacar directamente"
					)
					result.append(direct_result["value"])
				else:
					for target_slot in range(enemy_creatures["value"].size()):
						var attack_result: Dictionary = LegalAction.create(
							ACTION_ATTACK,
							viewer_id,
							{"attacker_id": attacker_id, "target_slot": target_slot},
							"Atacar criatura"
						)
						result.append(attack_result["value"])
	return result


func _public_response_window(state: Dictionary) -> Dictionary:
	if state["pending_response"].is_empty():
		return {"active": false}
	var pending: Dictionary = state["pending_response"]
	var public_chain: Array = []
	for link in pending["chain"]:
		public_chain.append({
			"controller_id": link["controller_id"],
			"definition_id": link["definition_id"],
			"support_slot": link["support_slot"],
		})
	var public_context: Dictionary = {}
	if pending["kind"] == "attack":
		public_context = {
			"attacker_id": pending["context"]["attacker_id"],
			"target_player_id": pending["context"]["target_player_id"],
			"target_slot": pending["context"]["target_slot"],
		}
	elif pending["kind"] == "spell":
		public_context = {
			"spell_definition_id": pending["context"]["spell_definition_id"],
			"target_player_id": pending["context"]["target_player_id"],
			"target_slot": pending["context"]["target_slot"],
		}
	elif pending["kind"] == "position_change":
		public_context = {"creature_id": pending["context"]["creature_id"]}
	elif pending["kind"] == "equipment":
		public_context = {
			"equipment_id": pending["context"]["equipment_id"],
			"target_creature_id": pending["context"]["target_creature_id"],
		}
	elif pending["kind"] == "fusion_combat_choice":
		public_context = {
			"attacker_id": pending["context"]["attacker_id"],
			"target_player_id": pending["context"]["target_player_id"],
			"target_slot": pending["context"]["target_slot"],
			"choice_creature_id": pending["context"]["choice_queue"][0]["creature_id"],
			"choice_role": pending["context"]["choice_queue"][0]["role"],
		}
	elif pending["kind"] == "creature_redirect_choice":
		public_context = {
			"attacker_id": pending["context"]["attacker_id"],
			"target_player_id": pending["priority_player_id"],
			"target_slot": pending["context"]["original_target_slot"],
			"guardian_ids": pending["context"]["guardian_ids"].duplicate(),
		}
	else:
		public_context = pending["context"].duplicate(true)
	return {
		"active": true,
		"kind": pending["kind"],
		"source_player_id": pending["source_player_id"],
		"priority_player_id": pending["priority_player_id"],
		"consecutive_passes": pending["consecutive_passes"],
		"chain": public_chain,
		"context": public_context,
	}


func _reaction_legal_actions(state: Dictionary, viewer_id: int) -> Array:
	var result: Array = []
	if viewer_id != state["pending_response"].get("priority_player_id", -1):
		return result
	var pass_result: Dictionary = LegalAction.create(
		ACTION_PASS_REACTION,
		viewer_id,
		{},
		"Pasar prioridad"
	)
	result.append(pass_result["value"])
	var support_cards: Array = state["cards"]["zones"][_zone_id("support", viewer_id)]["cards"]
	for support_slot in range(support_cards.size()):
		if not _reaction_is_eligible(state, viewer_id, support_slot):
			continue
		var support_id: String = support_cards[support_slot]
		var definition: Dictionary = _definition_for_instance(state, support_id)
		var activation_result: Dictionary = LegalAction.create(
			ACTION_ACTIVATE_REACTION,
			viewer_id,
			{"support_slot": support_slot},
			"Activar %s" % definition["attributes"]["display_name"]
		)
		result.append(activation_result["value"])
	return result


func _fusion_combat_choice_legal_actions(state: Dictionary, viewer_id: int) -> Array:
	if viewer_id != state["pending_response"].get("priority_player_id", -1):
		return []
	var result: Array = []
	for choice in ["attack", "defense"]:
		var action_result: Dictionary = LegalAction.create(
			ACTION_CHOOSE_FUSION_COMBAT_BONUS,
			viewer_id,
			{"choice": choice},
			"Elemental Mayor: +1 %s durante este combate" % ("ATQ" if choice == "attack" else "DEF")
		)
		result.append(action_result["value"])
	return result


func _creature_redirect_legal_actions(state: Dictionary, viewer_id: int) -> Array:
	if viewer_id != state["pending_response"].get("priority_player_id", -1):
		return []
	var result: Array = []
	result.append(LegalAction.create(ACTION_DECLINE_REDIRECT, viewer_id, {}, "Mantener el objetivo original")["value"])
	for guardian_id in state["pending_response"]["context"]["guardian_ids"]:
		result.append(LegalAction.create(ACTION_REDIRECT_ATTACK, viewer_id, {"guardian_id": guardian_id}, "M13 pasa a ser el objetivo")["value"])
	return result


func _validate_creature_redirect(state: Dictionary, action_type: String, payload: Dictionary) -> Dictionary:
	if action_type == ACTION_DECLINE_REDIRECT:
		return _success() if payload.is_empty() else _failure("JCP_CREATURE_REDIRECT_PAYLOAD_INVALID", "Rechazar la redireccion no admite datos.")
	if payload.keys() != ["guardian_id"] or not payload["guardian_id"] is String or payload["guardian_id"] not in state["pending_response"]["context"]["guardian_ids"]:
		return _failure("JCP_CREATURE_REDIRECT_PAYLOAD_INVALID", "Debe elegirse uno de los M13 disponibles.")
	return _success()


func _validate_fusion_combat_choice(state: Dictionary, _player_id: int, payload: Dictionary) -> Dictionary:
	if payload.keys() != ["choice"] or payload["choice"] not in ["attack", "defense"]:
		return _failure("JCP_FUSION_COMBAT_CHOICE_INVALID", "Debe elegirse ataque o defensa para el Elemental Mayor.")
	return _success()


func _reduce_fusion_combat_choice(state: Dictionary, player_id: int, choice: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state["pending_response"].duplicate(true)
	var context: Dictionary = pending["context"].duplicate(true)
	var queue: Array = context["choice_queue"].duplicate(true)
	var current: Dictionary = queue.pop_front()
	var creature_id: String = current["creature_id"]
	var metadata: Dictionary = next_state["cards"]["instances"][creature_id]["metadata"].duplicate(true)
	metadata["fusion_combat_choice_turn"] = next_state["turn"]["turn_number"]
	var update: Dictionary = CardState.update_instance_metadata(next_state["cards"], creature_id, metadata)
	if not update["ok"]:
		return _transition_failure(update)
	next_state["cards"] = update["value"]
	var modifier_key := "%s_%s_delta" % [current["role"], choice]
	context["modifiers"][modifier_key] += 1
	var events: Array = [{
		"type": "fusion_combat_bonus_chosen",
		"payload": {"player_id": player_id, "creature_id": creature_id, "choice": choice, "amount": 1},
	}]
	if not queue.is_empty():
		context["choice_queue"] = queue
		next_state["pending_response"]["context"] = context
		next_state["pending_response"]["priority_player_id"] = queue[0]["player_id"]
		return _transition_success(next_state, events)
	next_state["pending_response"] = {
		"kind": "attack",
		"source_player_id": pending["source_player_id"],
		"priority_player_id": context["target_player_id"],
		"consecutive_passes": 0,
		"chain": [],
		"context": {
			"attacker_id": context["attacker_id"],
			"target_player_id": context["target_player_id"],
			"target_slot": context["target_slot"],
			"target_id": context["target_id"],
			"modifiers": context["modifiers"],
		},
	}
	if _has_reaction(next_state):
		return _transition_success(next_state, events)
	next_state["pending_response"] = {}
	var combat: Dictionary = _resolve_attack(next_state, pending["source_player_id"], context["attacker_id"], context["target_slot"], context["modifiers"])
	if not combat["ok"]:
		return combat
	events.append_array(combat["events"])
	return _transition_success(combat["state"], events)


func _validate_reaction(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	if payload.keys() != ["support_slot"] or not payload["support_slot"] is int:
		return _failure("JCP_REACTION_PAYLOAD_INVALID", "Activar una respuesta requiere exactamente su casilla de apoyo.")
	var support_slot: int = payload["support_slot"]
	var support_cards: Array = state["cards"]["zones"][_zone_id("support", player_id)]["cards"]
	if support_slot < 0 or support_slot >= support_cards.size():
		return _failure("JCP_REACTION_SLOT_INVALID", "La casilla de respuesta no existe.")
	if not _reaction_is_eligible(state, player_id, support_slot):
		return _failure("JCP_REACTION_NOT_ELIGIBLE", "Esa carta no puede responder al efecto pendiente.")
	return _success()


func _reaction_is_eligible(state: Dictionary, player_id: int, support_slot: int) -> bool:
	if state["pending_response"].is_empty():
		return false
	var pending: Dictionary = state["pending_response"]
	var expected_player_id: int = (
		pending["context"]["destroyed_player_id"]
		if pending["kind"] == "combat_destruction"
		else _opponent_id(state, pending["source_player_id"])
	)
	if player_id != expected_player_id:
		return false
	var support_cards: Array = state["cards"]["zones"][_zone_id("support", player_id)]["cards"]
	if support_slot < 0 or support_slot >= support_cards.size():
		return false
	var support_id: String = support_cards[support_slot]
	var metadata: Dictionary = state["cards"]["instances"][support_id]["metadata"]
	if metadata.get("face_up", false) or metadata.get("active", false):
		return false
	if metadata.get("set_turn", state["turn"]["turn_number"]) >= state["turn"]["turn_number"]:
		return false
	var definition_id: String = _definition_for_instance(state, support_id)["id"]
	if pending["kind"] == "spell":
		return definition_id == "T03"
	if pending["kind"] == "position_change":
		return definition_id == "T04"
	if pending["kind"] == "equipment":
		return definition_id == "T05"
	if pending["kind"] == "combat_destruction":
		return definition_id == "T06"
	var context: Dictionary = pending["context"]
	if definition_id in ["G06", "G07", "T02"]:
		if context["target_slot"] < 0:
			return false
		if definition_id == "G07":
			var target_id: String = context.get("target_id", "")
			if target_id.is_empty() or state["cards"]["instances"][target_id]["metadata"].has("fusion_entity"):
				return false
		return true
	if definition_id == "T01":
		return _creature_cost(state, context["attacker_id"]) <= 2
	return false


func _has_reaction(state: Dictionary) -> bool:
	if state["pending_response"].is_empty():
		return false
	for player_id in state["turn"]["order"]:
		var support_cards: Array = state["cards"]["zones"][_zone_id("support", player_id)]["cards"]
		for support_slot in range(support_cards.size()):
			if _reaction_is_eligible(state, player_id, support_slot):
				return true
	return false


func _field_card_legal_actions(state: Dictionary, player_id: int) -> Array:
	var result: Array = []
	var hand_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("hand", player_id))
	var support_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("support", player_id))
	var terrain_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("terrain", player_id))
	var creature_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", player_id))
	var attachment_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("attachments", player_id))
	var opponent_id: int = _opponent_id(state, player_id)
	var enemy_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", opponent_id))
	if not hand_result["ok"] or not support_result["ok"] or not terrain_result["ok"] or not creature_result["ok"] or not attachment_result["ok"] or not enemy_result["ok"]:
		return result
	for instance_id in hand_result["value"]:
		var definition: Dictionary = _definition_for_instance(state, instance_id)
		var definition_id: String = definition["id"]
		var card_type: String = definition["attributes"]["card_type"]
		if definition_id in ["G01", "G02"]:
			for target_slot in range(creature_result["value"].size()):
				var main_spell_result: Dictionary = LegalAction.create(
					ACTION_PLAY_MAIN_SPELL,
					player_id,
					{
						"instance_id": instance_id,
						"target_player_id": player_id,
						"target_slot": target_slot,
					},
					"Jugar Magia sobre criatura propia"
				)
				result.append(main_spell_result["value"])
		if definition_id == "G03":
			for target_slot in range(enemy_result["value"].size()):
				var target_id: String = enemy_result["value"][target_slot]
				var target_metadata: Dictionary = state["cards"]["instances"][target_id]["metadata"]
				var target_definition: Dictionary = _definition_for_instance(state, target_id)
				if target_metadata.has("fusion_entity") or not target_metadata.get("face_up", true) or _creature_cost(state, target_id) > 2:
					continue
				var return_spell_result: Dictionary = LegalAction.create(
					ACTION_PLAY_MAIN_SPELL,
					player_id,
					{
						"instance_id": instance_id,
						"target_player_id": opponent_id,
						"target_slot": target_slot,
					},
					"Devolver criatura rival visible"
				)
				result.append(return_spell_result["value"])
		if support_result["value"].size() < 5 and (
			card_type == "trap" or definition_id in ["G06", "G07"]
		):
			var set_result: Dictionary = LegalAction.create(
				ACTION_SET_SUPPORT,
				player_id,
				{"instance_id": instance_id},
				"Preparar carta oculta"
			)
			result.append(set_result["value"])
		if support_result["value"].size() < 5 and definition_id in ["G04", "G05", "E04"]:
			var persistent_result: Dictionary = LegalAction.create(
				ACTION_PLAY_PERSISTENT,
				player_id,
				{"instance_id": instance_id},
				"Jugar carta persistente"
			)
			result.append(persistent_result["value"])
		if card_type == "item" and definition_id != "E04":
			for target_id in creature_result["value"]:
				if not _can_equip(state, definition_id, target_id, instance_id):
					continue
				var equip_result: Dictionary = LegalAction.create(
					ACTION_EQUIP_ITEM,
					player_id,
					{"instance_id": instance_id, "target_instance_id": target_id},
					"Equipar objeto"
				)
				result.append(equip_result["value"])
		if card_type == "terrain" and not state["turn_usage"]["terrain_used"]:
			var terrain_action: Dictionary = LegalAction.create(
				ACTION_PLAY_TERRAIN,
				player_id,
				{"instance_id": instance_id},
				"Jugar terreno"
			)
			result.append(terrain_action["value"])
	for artifact_id in support_result["value"]:
		var artifact_metadata: Dictionary = state["cards"]["instances"][artifact_id]["metadata"]
		if _definition_for_instance(state, artifact_id)["id"] != "E04":
			continue
		if not artifact_metadata.get("face_up", false) or not artifact_metadata.get("active", false):
			continue
		if artifact_metadata.get("last_activation_turn", -1) == state["turn"]["turn_number"]:
			continue
		for equipment_id in attachment_result["value"]:
			var current_target_id: String = state["cards"]["instances"][equipment_id]["metadata"].get("linked_to", "")
			var equipment_definition_id: String = _definition_for_instance(state, equipment_id)["id"]
			for target_id in creature_result["value"]:
				if target_id == current_target_id or not _can_equip(state, equipment_definition_id, target_id, equipment_id):
					continue
				var relocation_result: Dictionary = LegalAction.create(
					ACTION_RELOCATE_EQUIPMENT,
					player_id,
					{
						"artifact_instance_id": artifact_id,
						"equipment_instance_id": equipment_id,
						"target_instance_id": target_id,
					},
					"Trasladar equipo con E04"
				)
				result.append(relocation_result["value"])
	return result


func is_finished(state: Dictionary) -> bool:
	return not state.get("finished_reason", "").is_empty()


func _begin_turn(state: Dictionary) -> void:
	var player_id: int = TurnState.active_player(state["turn"])
	var resource: Dictionary = state["energy"][_player_key(player_id)]
	resource["maximum"] = min(resource["maximum"] + 1, state["config"]["energy_cap"])
	resource["available"] = resource["maximum"]


func _validate_creature_entry(state: Dictionary, player_id: int, payload: Dictionary, face_up: bool) -> Dictionary:
	if not payload.has("instance_id") or not payload["instance_id"] is String:
		return _failure("JCP_SUMMON_PAYLOAD_INVALID", "Invocar requiere exactamente un identificador de carta.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_SUMMON_PHASE_INVALID", "Solo se puede invocar durante una fase principal propia.")
	if state["turn_usage"]["normal_summon_used"]:
		return _failure("JCP_NORMAL_SUMMON_USED", "La invocacion normal de este turno ya se ha utilizado.")
	var instance_id: String = payload["instance_id"]
	var hand_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("hand", player_id))
	if not hand_result["ok"] or instance_id not in hand_result["value"]:
		return _failure("JCP_CARD_NOT_IN_HAND", "La carta no esta en la mano del jugador.")
	var creature_zone: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", player_id))
	if not creature_zone["ok"] or creature_zone["value"].size() >= 5:
		return _failure("JCP_CREATURE_ZONE_FULL", "No quedan espacios libres para criaturas.")
	var instance: Dictionary = state["cards"]["instances"][instance_id]
	if instance["metadata"].get("owner_id", -1) != player_id:
		return _failure("JCP_CARD_OWNER_INVALID", "La carta no pertenece al jugador.")
	var definition: Dictionary = state["cards"]["definitions"][instance["definition_id"]]
	if definition["attributes"]["card_type"] != "creature":
		return _failure("JCP_CARD_NOT_CREATURE", "Solo las criaturas pueden ocupar la fila de criaturas.")
	var cost: int = definition["attributes"]["cost"]
	if state["energy"][_player_key(player_id)]["available"] < cost:
		return _failure("JCP_ENERGY_INSUFFICIENT", "No hay energia suficiente para invocar esta criatura.")
	var expected_keys: Array = ["instance_id"]
	if face_up and definition["id"] == "M12" and not _hidden_enemy_support_slots(state, player_id).is_empty():
		expected_keys.append("peek_support_slot")
		if not payload.get("peek_support_slot", null) is int or payload["peek_support_slot"] not in _hidden_enemy_support_slots(state, player_id):
			return _failure("JCP_CREATURE_ENTRY_PEEK_INVALID", "M12 debe elegir un apoyo rival oculto valido.")
	elif face_up and definition["id"] == "M15" and not state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"].is_empty():
		expected_keys.append("target_instance_id")
		if not payload.get("target_instance_id", null) is String or payload["target_instance_id"] not in state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]:
			return _failure("JCP_CREATURE_ENTRY_TARGET_INVALID", "M15 debe elegir otra criatura propia en el campo.")
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	expected_keys.sort()
	if payload_keys != expected_keys:
		return _failure("JCP_SUMMON_PAYLOAD_INVALID", "La entrada contiene datos ausentes o no permitidos.")
	return _success()


func _reduce_creature_entry(state: Dictionary, player_id: int, instance_id: String, face_up: bool, payload: Dictionary = {}) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var instance: Dictionary = next_state["cards"]["instances"][instance_id]
	var definition: Dictionary = next_state["cards"]["definitions"][instance["definition_id"]]
	var metadata: Dictionary = instance["metadata"].duplicate(true)
	metadata["face_up"] = face_up
	metadata["position"] = "attack" if face_up else "guard"
	metadata["summoned_turn"] = next_state["turn"]["turn_number"]
	metadata["last_position_change_turn"] = -1
	metadata["last_attack_turn"] = -1
	var metadata_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not metadata_result["ok"]:
		return _transition_failure(metadata_result)
	var move_result: Dictionary = CardState.move_card(
		metadata_result["value"],
		instance_id,
		_zone_id("hand", player_id),
		_zone_id("creatures", player_id)
	)
	if not move_result["ok"]:
		return _transition_failure(move_result)
	next_state["cards"] = move_result["value"]
	next_state["energy"][_player_key(player_id)]["available"] -= definition["attributes"]["cost"]
	next_state["turn_usage"]["normal_summon_used"] = true
	if face_up:
		var events: Array = [{
			"type": "creature_summoned",
			"payload": {
				"player_id": player_id,
				"instance_id": instance_id,
				"definition_id": definition["id"],
				"cost": definition["attributes"]["cost"],
				"position": "attack",
			},
		}]
		if definition["id"] == "M12" and payload.has("peek_support_slot"):
			var opponent_id: int = _opponent_id(next_state, player_id)
			var support_slot: int = payload["peek_support_slot"]
			var support_id: String = next_state["cards"]["zones"][_zone_id("support", opponent_id)]["cards"][support_slot]
			var support_definition_id: String = next_state["cards"]["instances"][support_id]["definition_id"]
			events.append({"type": "creature_private_inspection", "payload": {"player_id": player_id, "source_instance_id": instance_id, "definition_id": "M12", "opponent_id": opponent_id, "support_slot": support_slot}})
			events.append({"type": "private_support_inspected", "payload": {"player_id": player_id, "source_instance_id": instance_id, "support_instance_id": support_id, "support_definition_id": support_definition_id, "support_slot": support_slot}, "visible_to": [player_id]})
		elif definition["id"] == "M15" and payload.has("target_instance_id"):
			var target_id: String = payload["target_instance_id"]
			var bonus: Dictionary = _add_temporary_bonus(next_state, target_id, 1, 1)
			if not bonus["ok"]:
				return _transition_failure(bonus)
			next_state = bonus["state"]
			if next_state["cards"]["instances"][target_id]["metadata"].get("face_up", false):
				events.append({"type": "creature_entry_bonus_applied", "payload": {"player_id": player_id, "source_instance_id": instance_id, "definition_id": "M15", "target_instance_id": target_id, "attack_bonus": 1, "defense_bonus": 1}})
			else:
				var target_slot: int = next_state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"].find(target_id)
				events.append({"type": "creature_entry_bonus_applied", "payload": {"player_id": player_id, "source_instance_id": instance_id, "definition_id": "M15", "target_slot": target_slot, "attack_bonus": 1, "defense_bonus": 1}})
				events.append({"type": "private_creature_entry_bonus_target", "payload": {"player_id": player_id, "target_instance_id": target_id, "target_slot": target_slot}, "visible_to": [player_id]})
		return _transition_success(next_state, events)
	return _transition_success(next_state, [
		{
			"type": "creature_set",
			"payload": {"player_id": player_id, "position": "guard"},
		},
		{
			"type": "private_creature_set",
			"payload": {
				"player_id": player_id,
				"instance_id": instance_id,
				"definition_id": definition["id"],
				"cost": definition["attributes"]["cost"],
			},
			"visible_to": [player_id],
		},
	])


func _validate_position_change(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["instance_id", "target_position"]:
		return _failure("JCP_POSITION_PAYLOAD_INVALID", "Cambiar postura requiere carta y postura de destino.")
	if not payload["instance_id"] is String or payload["target_position"] not in ["attack", "guard"]:
		return _failure("JCP_POSITION_PAYLOAD_INVALID", "La carta o la postura de destino no son validas.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_POSITION_PHASE_INVALID", "La postura solo puede cambiar durante una fase principal propia.")
	var instance_id: String = payload["instance_id"]
	var zone_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", player_id))
	if not zone_result["ok"] or instance_id not in zone_result["value"]:
		return _failure("JCP_CREATURE_NOT_CONTROLLED", "La criatura no esta en la fila del jugador.")
	var metadata: Dictionary = state["cards"]["instances"][instance_id]["metadata"]
	if metadata.get("summoned_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_POSITION_SUMMONED_THIS_TURN", "Una criatura no cambia de postura el turno en que entra.")
	if metadata.get("last_position_change_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_POSITION_ALREADY_CHANGED", "La criatura ya cambio de postura este turno.")
	if metadata.get("last_attack_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_POSITION_AFTER_ATTACK", "Una criatura que ya ataco no puede pasar a guardia este turno.")
	var current_position: String = metadata.get("position", "")
	if current_position == payload["target_position"]:
		return _failure("JCP_POSITION_UNCHANGED", "La criatura ya se encuentra en esa postura.")
	if not metadata.get("face_up", true) and payload["target_position"] != "attack":
		return _failure("JCP_HIDDEN_REVEAL_TARGET_INVALID", "Una criatura oculta solo puede revelarse pasando a ataque.")
	return _success()


func _reduce_position_change(state: Dictionary, player_id: int, instance_id: String, target_position: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var old_metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"]
	var was_hidden: bool = not old_metadata.get("face_up", true)
	var metadata: Dictionary = old_metadata.duplicate(true)
	metadata["face_up"] = true
	metadata["position"] = target_position
	metadata["last_position_change_turn"] = next_state["turn"]["turn_number"]
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	next_state["cards"] = update_result["value"]
	var definition_id: String = next_state["cards"]["instances"][instance_id]["definition_id"]
	var events: Array = [{
		"type": "creature_position_changed",
		"payload": {
			"player_id": player_id,
			"instance_id": instance_id,
			"definition_id": definition_id,
			"position": target_position,
			"revealed": was_hidden,
		},
	}]
	if old_metadata.get("position", "guard") == "guard" and target_position == "attack":
		for support_id in next_state["cards"]["zones"][_zone_id("support", player_id)]["cards"]:
			var support_definition_id: String = _definition_for_instance(next_state, support_id)["id"]
			var support_metadata: Dictionary = next_state["cards"]["instances"][support_id]["metadata"].duplicate(true)
			if support_definition_id != "G05" or not support_metadata.get("active", false):
				continue
			if support_metadata.get("last_trigger_turn", -1) == next_state["turn"]["turn_number"]:
				continue
			support_metadata["last_trigger_turn"] = next_state["turn"]["turn_number"]
			var support_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], support_id, support_metadata)
			if not support_update["ok"]:
				return _transition_failure(support_update)
			next_state["cards"] = support_update["value"]
			var bonus_result: Dictionary = _add_temporary_bonus(next_state, instance_id, 1, 0)
			if not bonus_result["ok"]:
				return _transition_failure(bonus_result)
			next_state = bonus_result["state"]
			events.append({
				"type": "persistent_effect_triggered",
				"payload": {
					"source_instance_id": support_id,
					"source_definition_id": "G05",
					"target_instance_id": instance_id,
					"attack_bonus": 1,
				},
			})
			break
		next_state["pending_response"] = {
			"kind": "position_change",
			"source_player_id": player_id,
			"priority_player_id": _opponent_id(next_state, player_id),
			"consecutive_passes": 0,
			"chain": [],
			"context": {
				"creature_id": instance_id,
				"previous_position": "guard",
			},
		}
		if not _has_reaction(next_state):
			next_state["pending_response"] = {}
	return _transition_success(next_state, events)


func _validate_set_support(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var common: Dictionary = _validate_single_hand_card_action(state, player_id, payload)
	if not common["ok"]:
		return common
	var instance_id: String = payload["instance_id"]
	var definition: Dictionary = _definition_for_instance(state, instance_id)
	if definition["attributes"]["card_type"] != "trap" and definition["id"] not in ["G06", "G07"]:
		return _failure("JCP_SUPPORT_NOT_REACTIVE", "Solo Trampas y Magias reactivas pueden prepararse ocultas.")
	return _validate_support_space(state, player_id)


func _reduce_set_support(state: Dictionary, player_id: int, instance_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var definition: Dictionary = _definition_for_instance(next_state, instance_id)
	var metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata["face_up"] = false
	metadata["active"] = false
	metadata["set_turn"] = next_state["turn"]["turn_number"]
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	var move_result: Dictionary = CardState.move_card(
		update_result["value"],
		instance_id,
		_zone_id("hand", player_id),
		_zone_id("support", player_id)
	)
	if not move_result["ok"]:
		return _transition_failure(move_result)
	next_state["cards"] = move_result["value"]
	return _transition_success(next_state, [
		{
			"type": "support_set",
			"payload": {"player_id": player_id},
		},
		{
			"type": "private_support_set",
			"payload": {
				"player_id": player_id,
				"instance_id": instance_id,
				"definition_id": definition["id"],
			},
			"visible_to": [player_id],
		},
	])


func _validate_play_persistent(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var common: Dictionary = _validate_single_hand_card_action(state, player_id, payload)
	if not common["ok"]:
		return common
	var definition_id: String = _definition_for_instance(state, payload["instance_id"])["id"]
	if definition_id not in ["G04", "G05", "E04"]:
		return _failure("JCP_CARD_NOT_PERSISTENT", "La carta no es una Magia persistente ni un artefacto independiente.")
	return _validate_support_space(state, player_id)


func _reduce_play_persistent(state: Dictionary, player_id: int, instance_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var definition: Dictionary = _definition_for_instance(next_state, instance_id)
	var metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata["face_up"] = true
	metadata["active"] = true
	metadata["played_turn"] = next_state["turn"]["turn_number"]
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	var move_result: Dictionary = CardState.move_card(
		update_result["value"],
		instance_id,
		_zone_id("hand", player_id),
		_zone_id("support", player_id)
	)
	if not move_result["ok"]:
		return _transition_failure(move_result)
	next_state["cards"] = move_result["value"]
	return _transition_success(next_state, [{
		"type": "persistent_played",
		"payload": {
			"player_id": player_id,
			"instance_id": instance_id,
			"definition_id": definition["id"],
		},
	}])


func _validate_play_main_spell(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["instance_id", "target_player_id", "target_slot"]:
		return _failure("JCP_MAIN_SPELL_PAYLOAD_INVALID", "La Magia requiere carta, jugador objetivo y casilla objetivo.")
	if not payload["instance_id"] is String or not payload["target_player_id"] is int or not payload["target_slot"] is int:
		return _failure("JCP_MAIN_SPELL_PAYLOAD_INVALID", "El objetivo de la Magia no es valido.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_FIELD_CARD_PHASE_INVALID", "Esta Magia solo puede jugarse durante una fase principal propia.")
	var spell_id: String = payload["instance_id"]
	if not _is_in_zone(state, spell_id, _zone_id("hand", player_id)):
		return _failure("JCP_CARD_NOT_IN_HAND", "La Magia no esta en la mano del jugador.")
	var spell_definition_id: String = _definition_for_instance(state, spell_id)["id"]
	if spell_definition_id not in ["G01", "G02", "G03"]:
		return _failure("JCP_CARD_NOT_MAIN_SPELL", "La carta no es una Magia de fase principal.")
	var expected_target_player: int = _opponent_id(state, player_id) if spell_definition_id == "G03" else player_id
	if payload["target_player_id"] != expected_target_player:
		return _failure("JCP_MAIN_SPELL_TARGET_PLAYER_INVALID", "La Magia no puede afectar a ese lado del campo.")
	var target_zone: Dictionary = CardState.zone_card_ids(
		state["cards"],
		_zone_id("creatures", expected_target_player)
	)
	if not target_zone["ok"]:
		return target_zone
	var target_slot: int = payload["target_slot"]
	if target_slot < 0 or target_slot >= target_zone["value"].size():
		return _failure("JCP_MAIN_SPELL_TARGET_INVALID", "La casilla objetivo no contiene una criatura.")
	if spell_definition_id == "G03":
		var target_id: String = target_zone["value"][target_slot]
		if state["cards"]["instances"][target_id]["metadata"].has("fusion_entity"):
			return _failure("JCP_GENERATED_ENTITY_RETURN_INVALID", "Una entidad generada no puede devolverse a la mano con un efecto generico.")
		if not state["cards"]["instances"][target_id]["metadata"].get("face_up", true):
			return _failure("JCP_G03_TARGET_HIDDEN", "G03 solo puede comprobar el coste de una criatura visible.")
		if _creature_cost(state, target_id) > 2:
			return _failure("JCP_G03_TARGET_COST", "G03 solo devuelve criaturas de coste impreso 2 o menos.")
	return _success()


func _reduce_play_main_spell(
	state: Dictionary,
	player_id: int,
	spell_id: String,
	target_player_id: int,
	target_slot: int
) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var spell_definition_id: String = _definition_for_instance(next_state, spell_id)["id"]
	var target_id: String = next_state["cards"]["zones"][_zone_id("creatures", target_player_id)]["cards"][target_slot]
	var opponent_id: int = _opponent_id(next_state, player_id)
	next_state["pending_response"] = {
		"kind": "spell",
		"source_player_id": player_id,
		"priority_player_id": opponent_id,
		"consecutive_passes": 0,
		"chain": [],
		"context": {
			"spell_id": spell_id,
			"spell_definition_id": spell_definition_id,
			"target_player_id": target_player_id,
			"target_slot": target_slot,
			"target_id": target_id,
		},
	}
	if _has_reaction(next_state):
		return _transition_success(next_state, [{
			"type": "main_spell_activated",
			"payload": {
				"player_id": player_id,
				"definition_id": spell_definition_id,
				"target_player_id": target_player_id,
				"target_slot": target_slot,
			},
		}])
	next_state["pending_response"] = {}
	return _resolve_main_spell(next_state, player_id, spell_id, target_player_id, target_slot)


func _resolve_main_spell(
	state: Dictionary,
	player_id: int,
	spell_id: String,
	target_player_id: int,
	target_slot: int
) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var spell_definition_id: String = _definition_for_instance(next_state, spell_id)["id"]
	var target_id: String = next_state["cards"]["zones"][_zone_id("creatures", target_player_id)]["cards"][target_slot]
	var extra_events: Array = []
	if spell_definition_id == "G01":
		var attack_bonus: Dictionary = _add_temporary_bonus(next_state, target_id, 2, 0)
		if not attack_bonus["ok"]:
			return _transition_failure(attack_bonus)
		next_state = attack_bonus["state"]
	elif spell_definition_id == "G02":
		var defense_bonus: Dictionary = _add_temporary_bonus(next_state, target_id, 0, 2)
		if not defense_bonus["ok"]:
			return _transition_failure(defense_bonus)
		next_state = defense_bonus["state"]
	else:
		var return_result: Dictionary = _return_creature_and_break_links(next_state, target_player_id, target_id)
		if not return_result["ok"]:
			return _transition_failure(return_result)
		next_state = return_result["state"]
		if not return_result["linked_ids"].is_empty():
			extra_events.append({
				"type": "linked_cards_destroyed",
				"payload": {"creature_id": target_id, "linked_ids": return_result["linked_ids"]},
			})
	var spell_move: Dictionary = CardState.move_card(
		next_state["cards"],
		spell_id,
		_zone_id("hand", player_id),
		_zone_id("graveyard", player_id)
	)
	if not spell_move["ok"]:
		return _transition_failure(spell_move)
	next_state["cards"] = spell_move["value"]
	var events: Array = [{
		"type": "main_spell_resolved",
		"payload": {
			"player_id": player_id,
			"instance_id": spell_id,
			"definition_id": spell_definition_id,
			"target_player_id": target_player_id,
			"target_slot": target_slot,
		},
	}]
	events.append_array(extra_events)
	return _transition_success(next_state, events)


func _add_temporary_bonus(state: Dictionary, target_id: String, attack_bonus: int, defense_bonus: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var metadata: Dictionary = next_state["cards"]["instances"][target_id]["metadata"].duplicate(true)
	var current_turn: int = next_state["turn"]["turn_number"]
	if metadata.get("temporary_bonus_turn", -1) != current_turn:
		metadata["temporary_attack_bonus"] = 0
		metadata["temporary_defense_bonus"] = 0
	metadata["temporary_bonus_turn"] = current_turn
	metadata["temporary_attack_bonus"] = metadata.get("temporary_attack_bonus", 0) + attack_bonus
	metadata["temporary_defense_bonus"] = metadata.get("temporary_defense_bonus", 0) + defense_bonus
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], target_id, metadata)
	if not update_result["ok"]:
		return update_result
	next_state["cards"] = update_result["value"]
	return {"ok": true, "code": "OK", "message": "", "state": next_state}


func _validate_equip_item(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["instance_id", "target_instance_id"]:
		return _failure("JCP_EQUIP_PAYLOAD_INVALID", "Equipar requiere objeto y criatura objetivo.")
	if not payload["instance_id"] is String or not payload["target_instance_id"] is String:
		return _failure("JCP_EQUIP_PAYLOAD_INVALID", "Los identificadores de equipo no son validos.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_FIELD_CARD_PHASE_INVALID", "Esta carta solo puede jugarse durante una fase principal propia.")
	var item_id: String = payload["instance_id"]
	if not _is_in_zone(state, item_id, _zone_id("hand", player_id)):
		return _failure("JCP_CARD_NOT_IN_HAND", "La carta no esta en la mano del jugador.")
	var definition: Dictionary = _definition_for_instance(state, item_id)
	if definition["attributes"]["card_type"] != "item" or definition["id"] == "E04":
		return _failure("JCP_CARD_NOT_EQUIPMENT", "La carta no es un equipo vinculable.")
	var target_id: String = payload["target_instance_id"]
	if not _is_in_zone(state, target_id, _zone_id("creatures", player_id)):
		return _failure("JCP_EQUIP_TARGET_INVALID", "El objetivo no es una criatura controlada.")
	if not _can_equip(state, definition["id"], target_id, item_id):
		return _failure("JCP_EQUIP_REQUIREMENT_FAILED", "La criatura no cumple los requisitos visibles del equipo.")
	return _success()


func _reduce_equip_item(state: Dictionary, player_id: int, instance_id: String, target_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var definition: Dictionary = _definition_for_instance(next_state, instance_id)
	var metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata["face_up"] = true
	metadata["active"] = true
	metadata["linked_to"] = target_id
	metadata["equipped_turn"] = next_state["turn"]["turn_number"]
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	var move_result: Dictionary = CardState.move_card(
		update_result["value"],
		instance_id,
		_zone_id("hand", player_id),
		_zone_id("attachments", player_id)
	)
	if not move_result["ok"]:
		return _transition_failure(move_result)
	next_state["cards"] = move_result["value"]
	var events: Array = [{
		"type": "item_equipped",
		"payload": {
			"player_id": player_id,
			"instance_id": instance_id,
			"definition_id": definition["id"],
			"target_instance_id": target_id,
		},
	}]
	next_state["pending_response"] = {
		"kind": "equipment",
		"source_player_id": player_id,
		"priority_player_id": _opponent_id(next_state, player_id),
		"consecutive_passes": 0,
		"chain": [],
		"context": {
			"equipment_id": instance_id,
			"target_creature_id": target_id,
		},
	}
	if not _has_reaction(next_state):
		next_state["pending_response"] = {}
	return _transition_success(next_state, events)


func _validate_relocate_equipment(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["artifact_instance_id", "equipment_instance_id", "target_instance_id"]:
		return _failure("JCP_RELOCATE_PAYLOAD_INVALID", "Trasladar equipo requiere artefacto, equipo y nueva criatura.")
	for key in payload_keys:
		if not payload[key] is String:
			return _failure("JCP_RELOCATE_PAYLOAD_INVALID", "Los identificadores del traslado no son validos.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_RELOCATE_PHASE_INVALID", "E04 solo puede activarse durante una fase principal propia.")
	var artifact_id: String = payload["artifact_instance_id"]
	if not _is_in_zone(state, artifact_id, _zone_id("support", player_id)):
		return _failure("JCP_RELOCATE_ARTIFACT_MISSING", "E04 no esta activo en la fila de apoyo del jugador.")
	if _definition_for_instance(state, artifact_id)["id"] != "E04":
		return _failure("JCP_RELOCATE_ARTIFACT_INVALID", "La carta elegida no permite trasladar equipos.")
	var artifact_metadata: Dictionary = state["cards"]["instances"][artifact_id]["metadata"]
	if not artifact_metadata.get("face_up", false) or not artifact_metadata.get("active", false):
		return _failure("JCP_RELOCATE_ARTIFACT_INACTIVE", "E04 debe estar visible y activo.")
	if artifact_metadata.get("last_activation_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_RELOCATE_ALREADY_USED", "Este E04 ya traslado un equipo durante el turno actual.")
	var equipment_id: String = payload["equipment_instance_id"]
	if not _is_in_zone(state, equipment_id, _zone_id("attachments", player_id)):
		return _failure("JCP_RELOCATE_EQUIPMENT_MISSING", "El equipo no esta vinculado a una criatura propia.")
	var equipment_definition: Dictionary = _definition_for_instance(state, equipment_id)
	if equipment_definition["attributes"]["card_type"] != "item" or equipment_definition["id"] == "E04":
		return _failure("JCP_RELOCATE_EQUIPMENT_INVALID", "La carta elegida no es un equipo trasladable.")
	var equipment_metadata: Dictionary = state["cards"]["instances"][equipment_id]["metadata"]
	if not equipment_metadata.get("face_up", false) or not equipment_metadata.get("active", false):
		return _failure("JCP_RELOCATE_EQUIPMENT_INACTIVE", "El equipo debe estar visible y activo.")
	var current_target_id: String = equipment_metadata.get("linked_to", "")
	if not _is_in_zone(state, current_target_id, _zone_id("creatures", player_id)):
		return _failure("JCP_RELOCATE_SOURCE_INVALID", "El portador actual del equipo no es valido.")
	var target_id: String = payload["target_instance_id"]
	if not _is_in_zone(state, target_id, _zone_id("creatures", player_id)):
		return _failure("JCP_RELOCATE_TARGET_INVALID", "La nueva portadora no es una criatura controlada.")
	if target_id == current_target_id:
		return _failure("JCP_RELOCATE_TARGET_UNCHANGED", "El equipo ya esta vinculado a esa criatura.")
	if not _can_equip(state, equipment_definition["id"], target_id, equipment_id):
		return _failure("JCP_RELOCATE_REQUIREMENT_FAILED", "La nueva portadora no cumple los requisitos del equipo.")
	return _success()


func _reduce_relocate_equipment(
	state: Dictionary,
	player_id: int,
	artifact_id: String,
	equipment_id: String,
	target_id: String
) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var equipment_metadata: Dictionary = next_state["cards"]["instances"][equipment_id]["metadata"].duplicate(true)
	var previous_target_id: String = equipment_metadata["linked_to"]
	equipment_metadata["linked_to"] = target_id
	equipment_metadata["equipped_turn"] = next_state["turn"]["turn_number"]
	var equipment_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], equipment_id, equipment_metadata)
	if not equipment_update["ok"]:
		return _transition_failure(equipment_update)
	next_state["cards"] = equipment_update["value"]
	var artifact_metadata: Dictionary = next_state["cards"]["instances"][artifact_id]["metadata"].duplicate(true)
	artifact_metadata["last_activation_turn"] = next_state["turn"]["turn_number"]
	var artifact_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], artifact_id, artifact_metadata)
	if not artifact_update["ok"]:
		return _transition_failure(artifact_update)
	next_state["cards"] = artifact_update["value"]
	var events: Array = [{
		"type": "equipment_relocated",
		"payload": {
			"player_id": player_id,
			"artifact_instance_id": artifact_id,
			"equipment_instance_id": equipment_id,
			"previous_target_instance_id": previous_target_id,
			"target_instance_id": target_id,
		},
	}]
	next_state["pending_response"] = {
		"kind": "equipment",
		"source_player_id": player_id,
		"priority_player_id": _opponent_id(next_state, player_id),
		"consecutive_passes": 0,
		"chain": [],
		"context": {
			"equipment_id": equipment_id,
			"target_creature_id": target_id,
		},
	}
	if not _has_reaction(next_state):
		next_state["pending_response"] = {}
	return _transition_success(next_state, events)


func _validate_play_terrain(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var common: Dictionary = _validate_single_hand_card_action(state, player_id, payload)
	if not common["ok"]:
		return common
	if _definition_for_instance(state, payload["instance_id"])["attributes"]["card_type"] != "terrain":
		return _failure("JCP_CARD_NOT_TERRAIN", "La carta elegida no es un Terreno.")
	if state["turn_usage"]["terrain_used"]:
		return _failure("JCP_TERRAIN_ALREADY_USED", "La jugada normal de Terreno de este turno ya se ha utilizado.")
	return _success()


func _reduce_play_terrain(state: Dictionary, player_id: int, instance_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var definition: Dictionary = _definition_for_instance(next_state, instance_id)
	var terrain_zone_id: String = _zone_id("terrain", player_id)
	var terrain_cards: Array = next_state["cards"]["zones"][terrain_zone_id]["cards"].duplicate()
	var previous_instance_id := ""
	var previous_definition_id := ""
	var previous_identity_id := ""
	var recipe: Dictionary = {}
	if not terrain_cards.is_empty():
		previous_instance_id = terrain_cards[0]
		previous_definition_id = _definition_for_instance(next_state, previous_instance_id)["id"]
		previous_identity_id = _terrain_identity(next_state, previous_instance_id)["id"]
		recipe = _terrain_recipe_for(previous_identity_id, definition["id"])
		var previous_metadata: Dictionary = next_state["cards"]["instances"][previous_instance_id]["metadata"].duplicate(true)
		previous_metadata["active"] = false
		previous_metadata.erase("terrain_form_id")
		previous_metadata.erase("terrain_form_name")
		previous_metadata.erase("terrain_components")
		var previous_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], previous_instance_id, previous_metadata)
		if not previous_update["ok"]:
			return _transition_failure(previous_update)
		var previous_move: Dictionary = CardState.move_card(
			previous_update["value"],
			previous_instance_id,
			terrain_zone_id,
			_zone_id("graveyard", player_id)
		)
		if not previous_move["ok"]:
			return _transition_failure(previous_move)
		next_state["cards"] = previous_move["value"]
	var metadata: Dictionary = next_state["cards"]["instances"][instance_id]["metadata"].duplicate(true)
	metadata["face_up"] = true
	metadata["active"] = true
	metadata["played_turn"] = next_state["turn"]["turn_number"]
	if recipe.is_empty():
		metadata.erase("terrain_form_id")
		metadata.erase("terrain_form_name")
		metadata.erase("terrain_components")
	else:
		metadata["terrain_form_id"] = recipe["id"]
		metadata["terrain_form_name"] = recipe["display_name"]
		metadata["terrain_components"] = recipe["components"].duplicate()
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], instance_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	var move_result: Dictionary = CardState.move_card(
		update_result["value"],
		instance_id,
		_zone_id("hand", player_id),
		terrain_zone_id
	)
	if not move_result["ok"]:
		return _transition_failure(move_result)
	next_state["cards"] = move_result["value"]
	next_state["turn_usage"]["terrain_used"] = true
	var event_type := "terrain_played"
	var event_payload := {
		"player_id": player_id,
		"instance_id": instance_id,
		"definition_id": definition["id"],
	}
	if not recipe.is_empty():
		event_type = "terrain_transformed"
		event_payload.merge({
			"previous_instance_id": previous_instance_id,
			"previous_definition_id": previous_definition_id,
			"components": recipe["components"].duplicate(),
			"result_id": recipe["id"],
			"result_name": recipe["display_name"],
		})
	elif not previous_instance_id.is_empty():
		event_type = "terrain_replaced"
		event_payload.merge({
			"previous_instance_id": previous_instance_id,
			"previous_definition_id": previous_definition_id,
			"previous_identity_id": previous_identity_id,
		})
	return _transition_success(next_state, [{"type": event_type, "payload": event_payload}])


func _validate_single_hand_card_action(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	if payload.keys() != ["instance_id"] or not payload["instance_id"] is String:
		return _failure("JCP_FIELD_CARD_PAYLOAD_INVALID", "La accion requiere exactamente una carta.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_FIELD_CARD_PHASE_INVALID", "Esta carta solo puede jugarse durante una fase principal propia.")
	if not _is_in_zone(state, payload["instance_id"], _zone_id("hand", player_id)):
		return _failure("JCP_CARD_NOT_IN_HAND", "La carta no esta en la mano del jugador.")
	return _success()


func _validate_support_space(state: Dictionary, player_id: int) -> Dictionary:
	var support_result: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("support", player_id))
	if not support_result["ok"]:
		return support_result
	if support_result["value"].size() >= 5:
		return _failure("JCP_SUPPORT_ZONE_FULL", "No quedan espacios libres en la fila de apoyo.")
	return _success()


func _is_in_zone(state: Dictionary, instance_id: String, zone_id: String) -> bool:
	var zone_result: Dictionary = CardState.zone_card_ids(state["cards"], zone_id)
	return zone_result["ok"] and instance_id in zone_result["value"]


func _visible_enemy_creature_ids(state: Dictionary, player_id: int) -> Array:
	var result: Array = []
	var opponent_id: int = _opponent_id(state, player_id)
	for instance_id in state["cards"]["zones"][_zone_id("creatures", opponent_id)]["cards"]:
		if state["cards"]["instances"][instance_id]["metadata"].get("face_up", false):
			result.append(instance_id)
	return result


func _hidden_enemy_support_slots(state: Dictionary, player_id: int) -> Array:
	var opponent_id: int = _opponent_id(state, player_id)
	var support_cards: Array = state["cards"]["zones"][_zone_id("support", opponent_id)]["cards"]
	var result: Array = []
	for slot in range(support_cards.size()):
		if not state["cards"]["instances"][support_cards[slot]]["metadata"].get("face_up", false):
			result.append(slot)
	return result


func _validate_fuse_creatures(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys not in [["material_instance_ids", "position"], ["material_instance_ids", "position", "target_instance_id"]] or not payload["material_instance_ids"] is Array:
		return _failure("JCP_FUSION_PAYLOAD_INVALID", "Fusionar requiere dos materiales, una postura y solo cuando proceda un objetivo.")
	if payload["position"] not in ["attack", "guard"]:
		return _failure("JCP_FUSION_POSITION_INVALID", "La Fusion debe aparecer en ataque o guardia.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_FUSION_PHASE_INVALID", "Una Fusion normal solo puede realizarse en una fase principal propia.")
	var material_ids: Array = payload["material_instance_ids"]
	if material_ids.size() != 2 or material_ids[0] == material_ids[1]:
		return _failure("JCP_FUSION_MATERIALS_INVALID", "La Fusion necesita dos criaturas fisicas distintas.")
	var own_creatures: Array = state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]
	for material_id in material_ids:
		if not material_id is String or material_id not in own_creatures:
			return _failure("JCP_FUSION_MATERIAL_NOT_CONTROLLED", "Los materiales deben ser criaturas propias en el campo.")
		var metadata: Dictionary = state["cards"]["instances"][material_id]["metadata"]
		if not metadata.get("face_up", false):
			return _failure("JCP_FUSION_MATERIAL_HIDDEN", "Los materiales basicos deben estar boca arriba.")
		if metadata.has("fusion_entity"):
			return _failure("JCP_FUSION_CHAIN_NOT_ENABLED", "Esta primera accion no admite una Fusion previa como material.")
	var build: Dictionary = _build_enabled_fusion(state, material_ids, player_id)
	if not build["ok"]:
		return build
	var is_steam: bool = build["value"]["fusion_identity_id"] == "fusion.f068_steam_elemental"
	var has_target: bool = payload.has("target_instance_id")
	if not is_steam and has_target:
		return _failure("JCP_FUSION_TARGET_NOT_ALLOWED", "Esta Fusion no admite una criatura objetivo.")
	if is_steam:
		var candidates: Array = _visible_enemy_creature_ids(state, player_id)
		if candidates.is_empty() and has_target:
			return _failure("JCP_FUSION_TARGET_NOT_ALLOWED", "Elemental de Vapor no tiene un objetivo visible disponible.")
		if not candidates.is_empty():
			if not has_target or not payload["target_instance_id"] is String or payload["target_instance_id"] not in candidates:
				return _failure("JCP_FUSION_TARGET_INVALID", "Elemental de Vapor debe elegir una criatura enemiga boca arriba.")
	return _success()


func _build_enabled_fusion(state: Dictionary, material_ids: Array, player_id: int) -> Dictionary:
	for material_id in material_ids:
		if state["cards"]["instances"].has(material_id) and state["cards"]["instances"][material_id]["metadata"].has("fusion_entity"):
			return _failure("JCP_FUSION_CHAIN_NOT_ENABLED", "Esta primera accion no admite una Fusion previa como material.")
	var generated_id := "fusion.p%d.t%d.n%d" % [player_id, state["turn"]["turn_number"], state["turn_usage"]["fusion_sequence"]]
	var built: Dictionary = FusionCatalog.build_for_cards(state["cards"], material_ids, generated_id, KNOWN_ANATOMIES, KNOWN_APTITUDES)
	if not built["ok"]:
		return built
	if built["value"]["fusion_identity_id"] not in ["fusion.f001_nature_alpha", "fusion.f010_neutral_band", "fusion.f011_torch_band", "fusion.f012_thicket_company", "fusion.f018_two_headed_troll", "fusion.f067_water_major", "fusion.f068_steam_elemental", "fusion.f005_fire_dragon"]:
		return _failure("JCP_FUSION_NOT_ENABLED", "La receta existe en el catalogo, pero todavia no esta habilitada en el duelo.")
	return built


func _validate_fusion_ability(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["source_instance_id", "target_instance_id"]:
		return _failure("JCP_FUSION_ABILITY_PAYLOAD_INVALID", "La habilidad requiere una Fusion fuente y una criatura objetivo.")
	if not payload["source_instance_id"] is String or not payload["target_instance_id"] is String:
		return _failure("JCP_FUSION_ABILITY_PAYLOAD_INVALID", "Los identificadores de la habilidad no son validos.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_FUSION_ABILITY_PHASE_INVALID", "La habilidad de Banda Goblin solo se usa en una fase principal propia.")
	var source_id: String = payload["source_instance_id"]
	var target_id: String = payload["target_instance_id"]
	if not _is_in_zone(state, source_id, _zone_id("creatures", player_id)):
		return _failure("JCP_FUSION_ABILITY_SOURCE_INVALID", "La Banda Goblin fuente no esta bajo control del jugador.")
	var source_metadata: Dictionary = state["cards"]["instances"][source_id]["metadata"]
	var source_entity: Variant = source_metadata.get("fusion_entity", null)
	if not source_entity is Dictionary or source_entity.get("fusion_identity_id", "") != "fusion.f010_neutral_band":
		return _failure("JCP_FUSION_ABILITY_SOURCE_INVALID", "La criatura fuente no es Banda Goblin.")
	if source_metadata.get("fusion_ability_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_FUSION_ABILITY_ALREADY_USED", "Banda Goblin ya uso su habilidad este turno.")
	if not _is_in_zone(state, target_id, _zone_id("creatures", player_id)):
		return _failure("JCP_FUSION_ABILITY_TARGET_INVALID", "El objetivo debe ser una criatura propia en el campo.")
	if not state["cards"]["instances"][target_id]["metadata"].get("face_up", false):
		return _failure("JCP_FUSION_ABILITY_TARGET_HIDDEN", "La criatura objetivo debe estar boca arriba.")
	if state["energy"][_player_key(player_id)]["available"] < 1:
		return _failure("JCP_ENERGY_INSUFFICIENT", "No hay energia suficiente para activar la habilidad.")
	return _success()


func _validate_creature_ability(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	if payload.keys() != ["source_instance_id"] or not payload["source_instance_id"] is String:
		return _failure("JCP_CREATURE_ABILITY_PAYLOAD_INVALID", "La habilidad requiere exactamente una criatura fuente.")
	if state["phase"]["current"] not in [PHASE_MAIN_1, PHASE_MAIN_2]:
		return _failure("JCP_CREATURE_ABILITY_PHASE_INVALID", "La habilidad solo puede usarse en una fase principal propia.")
	var source_id: String = payload["source_instance_id"]
	if not _is_in_zone(state, source_id, _zone_id("creatures", player_id)) or _active_base_definition_id(state, source_id) != "M09":
		return _failure("JCP_CREATURE_ABILITY_SOURCE_INVALID", "La fuente no es un M09 activo bajo control del jugador.")
	var metadata: Dictionary = state["cards"]["instances"][source_id]["metadata"]
	if not metadata.get("face_up", false):
		return _failure("JCP_CREATURE_ABILITY_SOURCE_HIDDEN", "M09 debe estar boca arriba para activar su habilidad.")
	if metadata.get("creature_ability_turn", -1) == state["turn"]["turn_number"]:
		return _failure("JCP_CREATURE_ABILITY_ALREADY_USED", "M09 ya uso su habilidad este turno.")
	if state["energy"][_player_key(player_id)]["available"] < 1:
		return _failure("JCP_ENERGY_INSUFFICIENT", "No hay energia suficiente para activar la habilidad.")
	return _success()


func _reduce_creature_ability(state: Dictionary, player_id: int, source_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	next_state["energy"][_player_key(player_id)]["available"] -= 1
	var metadata: Dictionary = next_state["cards"]["instances"][source_id]["metadata"].duplicate(true)
	metadata["creature_ability_turn"] = next_state["turn"]["turn_number"]
	var update: Dictionary = CardState.update_instance_metadata(next_state["cards"], source_id, metadata)
	if not update["ok"]:
		return _transition_failure(update)
	next_state["cards"] = update["value"]
	var bonus: Dictionary = _add_temporary_bonus(next_state, source_id, 1, 0)
	if not bonus["ok"]:
		return _transition_failure(bonus)
	next_state = bonus["state"]
	return _transition_success(next_state, [{"type": "creature_ability_activated", "payload": {"player_id": player_id, "source_instance_id": source_id, "definition_id": "M09", "energy_paid": 1, "attack_bonus": 1}}])


func _reduce_fusion_ability(state: Dictionary, player_id: int, source_id: String, target_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	next_state["energy"][_player_key(player_id)]["available"] -= 1
	var source_metadata: Dictionary = next_state["cards"]["instances"][source_id]["metadata"].duplicate(true)
	source_metadata["fusion_ability_turn"] = next_state["turn"]["turn_number"]
	var source_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], source_id, source_metadata)
	if not source_update["ok"]:
		return _transition_failure(source_update)
	next_state["cards"] = source_update["value"]
	var bonus_result: Dictionary = _add_temporary_bonus(next_state, target_id, 1, 0)
	if not bonus_result["ok"]:
		return _transition_failure(bonus_result)
	next_state = bonus_result["state"]
	return _transition_success(next_state, [{
		"type": "fusion_ability_activated",
		"payload": {
			"player_id": player_id,
			"source_instance_id": source_id,
			"fusion_identity_id": "fusion.f010_neutral_band",
			"target_instance_id": target_id,
			"energy_paid": 1,
			"attack_bonus": 1,
		},
	}])


func _reduce_fuse_creatures(state: Dictionary, player_id: int, material_ids: Array, position: String, target_id: String = "") -> Dictionary:
	var built: Dictionary = _build_enabled_fusion(state, material_ids, player_id)
	if not built["ok"]:
		return _transition_failure(built)
	var next_state: Dictionary = state.duplicate(true)
	var carrier_id: String = material_ids[0]
	var contained_id: String = material_ids[1]
	var entity: Dictionary = built["value"].duplicate(true)
	var carrier_metadata: Dictionary = next_state["cards"]["instances"][carrier_id]["metadata"].duplicate(true)
	for key in ["last_attack_turn", "last_position_change_turn", "temporary_attack_bonus", "temporary_bonus_turn", "temporary_defense_bonus", "alpha_leadership_turn", "fusion_ability_turn", "fusion_combat_choice_turn", "thicket_guard_turn", "troll_regeneration_turn", "steam_attack_penalty", "steam_penalty_owner_turns_remaining", "dragon_bonus_turn", "dragon_bonus_available", "energy_recovery_turn", "creature_ability_turn", "redirect_turn"]:
		carrier_metadata.erase(key)
	carrier_metadata["face_up"] = true
	carrier_metadata["position"] = position
	carrier_metadata["summoned_turn"] = next_state["turn"]["turn_number"]
	carrier_metadata["fusion_entity"] = entity
	var carrier_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], carrier_id, carrier_metadata)
	if not carrier_update["ok"]:
		return _transition_failure(carrier_update)
	next_state["cards"] = carrier_update["value"]
	var attachments: Array = next_state["cards"]["zones"][_zone_id("attachments", player_id)]["cards"]
	var inherited_ids: Array = []
	for attachment_id in attachments:
		var attachment_metadata: Dictionary = next_state["cards"]["instances"][attachment_id]["metadata"]
		if attachment_metadata.get("linked_to", "") not in material_ids:
			continue
		if not _can_equip(next_state, _definition_for_instance(next_state, attachment_id)["id"], carrier_id, attachment_id):
			var rejected_move: Dictionary = CardState.move_card(next_state["cards"], attachment_id, _zone_id("attachments", player_id), _zone_id("graveyard", player_id))
			if not rejected_move["ok"]:
				return _transition_failure(rejected_move)
			next_state["cards"] = rejected_move["value"]
			continue
		var inherited_metadata: Dictionary = attachment_metadata.duplicate(true)
		inherited_metadata["linked_to"] = carrier_id
		var inherited_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], attachment_id, inherited_metadata)
		if not inherited_update["ok"]:
			return _transition_failure(inherited_update)
		next_state["cards"] = inherited_update["value"]
		inherited_ids.append(attachment_id)
	var material_move: Dictionary = CardState.move_card(next_state["cards"], contained_id, _zone_id("creatures", player_id), _zone_id("fusion_materials", player_id))
	if not material_move["ok"]:
		return _transition_failure(material_move)
	next_state["cards"] = material_move["value"]
	var contained_metadata: Dictionary = next_state["cards"]["instances"][contained_id]["metadata"].duplicate(true)
	for key in ["last_attack_turn", "last_position_change_turn", "temporary_attack_bonus", "temporary_bonus_turn", "temporary_defense_bonus", "alpha_leadership_turn", "fusion_ability_turn", "fusion_combat_choice_turn", "thicket_guard_turn", "troll_regeneration_turn", "steam_attack_penalty", "steam_penalty_owner_turns_remaining", "dragon_bonus_turn", "dragon_bonus_available", "energy_recovery_turn", "creature_ability_turn", "redirect_turn"]:
		contained_metadata.erase(key)
	contained_metadata["contained_by"] = carrier_id
	var contained_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], contained_id, contained_metadata)
	if not contained_update["ok"]:
		return _transition_failure(contained_update)
	next_state["cards"] = contained_update["value"]
	next_state["turn_usage"]["fusion_sequence"] += 1
	var events: Array = [{
		"type": "creatures_fused",
		"payload": {
			"player_id": player_id,
			"carrier_instance_id": carrier_id,
			"material_instance_ids": material_ids.duplicate(),
			"fusion_identity_id": entity["fusion_identity_id"],
			"display_name": entity["display_name"],
			"position": position,
			"inherited_equipment_ids": inherited_ids,
		},
	}]
	if entity["fusion_identity_id"] == "fusion.f068_steam_elemental" and not target_id.is_empty():
		var target_metadata: Dictionary = next_state["cards"]["instances"][target_id]["metadata"].duplicate(true)
		target_metadata["steam_attack_penalty"] = min(5, target_metadata.get("steam_attack_penalty", 0) + 1)
		target_metadata["steam_penalty_owner_turns_remaining"] = 1
		var target_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], target_id, target_metadata)
		if not target_update["ok"]:
			return _transition_failure(target_update)
		next_state["cards"] = target_update["value"]
		events.append({
			"type": "fusion_entry_effect_applied",
			"payload": {
				"source_instance_id": carrier_id,
				"fusion_identity_id": entity["fusion_identity_id"],
				"target_instance_id": target_id,
				"attack_penalty": 1,
			},
		})
	return _transition_success(next_state, events)


func _can_equip(state: Dictionary, equipment_definition_id: String, target_id: String, equipment_instance_id: String = "") -> bool:
	var target_metadata: Dictionary = state["cards"]["instances"][target_id]["metadata"]
	var is_hidden: bool = not target_metadata.get("face_up", true)
	if is_hidden and equipment_definition_id not in ["E02", "E05"]:
		return false
	var equipment_definition: Dictionary = state["cards"]["definitions"][equipment_definition_id]
	var equipment_attributes: Dictionary = equipment_definition["attributes"]
	if not is_hidden:
		var target_attributes: Dictionary = _creature_attributes(state, target_id)
		var allowed_anatomies: Array = equipment_attributes.get("allowed_anatomies", [])
		if not allowed_anatomies.is_empty() and target_attributes.get("anatomy", "unassigned") not in allowed_anatomies:
			return false
		var aptitudes: Array = target_attributes.get("aptitudes", [])
		for required_aptitude in equipment_attributes.get("required_aptitudes", []):
			if required_aptitude not in aptitudes:
				return false
	if equipment_definition_id in ["E01", "E06"]:
		var owner_id: int = target_metadata.get("owner_id", -1)
		if owner_id >= 0:
			for attachment_id in state["cards"]["zones"][_zone_id("attachments", owner_id)]["cards"]:
				if attachment_id == equipment_instance_id:
					continue
				if state["cards"]["instances"][attachment_id]["metadata"].get("linked_to", "") != target_id:
					continue
				if _definition_for_instance(state, attachment_id)["id"] in ["E01", "E06"]:
					return false
	return true


func _validate_compatibility_catalog(state: Dictionary) -> Dictionary:
	for definition in state["cards"]["definitions"].values():
		var attributes: Dictionary = definition["attributes"]
		match attributes["card_type"]:
			"creature":
				if not attributes.get("anatomy", null) is String or attributes["anatomy"] not in KNOWN_ANATOMIES:
					return _failure("JCP_CREATURE_ANATOMY_INVALID", "Una criatura tiene un perfil anatomico desconocido.")
				if attributes["anatomy"] == "unassigned":
					return _failure("JCP_CREATURE_ANATOMY_UNASSIGNED", "Una criatura jugable necesita anatomia concreta.")
				var aptitudes_check: Dictionary = _validate_tag_list(attributes.get("aptitudes", null), KNOWN_APTITUDES)
				if not aptitudes_check["ok"]:
					return _failure("JCP_CREATURE_APTITUDES_INVALID", "Una criatura tiene aptitudes invalidas o repetidas.")
				var families_check: Dictionary = _validate_identity_list(attributes.get("families", null), true)
				if not families_check["ok"]:
					return _failure("JCP_CREATURE_FAMILIES_INVALID", "Una criatura necesita familias validas y no repetidas.")
				var superfamilies_check: Dictionary = _validate_identity_list(attributes.get("superfamilies", null), false)
				if not superfamilies_check["ok"]:
					return _failure("JCP_CREATURE_SUPERFAMILIES_INVALID", "Una criatura tiene superfamilias invalidas o repetidas.")
				var properties_check: Dictionary = _validate_identity_list(attributes.get("properties", null), false)
				if not properties_check["ok"]:
					return _failure("JCP_CREATURE_PROPERTIES_INVALID", "Una criatura tiene propiedades invalidas o repetidas.")
				if attributes.has("manipulator"):
					return _failure("JCP_COMPATIBILITY_LEGACY_FIELD", "La aptitud Manipulador no puede conservarse como booleano paralelo.")
			"item":
				var requirements_check: Dictionary = _validate_tag_list(attributes.get("required_aptitudes", null), KNOWN_APTITUDES)
				if not requirements_check["ok"]:
					return _failure("JCP_ITEM_APTITUDE_REQUIREMENTS_INVALID", "Un Objeto tiene requisitos de aptitud invalidos.")
				var anatomies_check: Dictionary = _validate_tag_list(attributes.get("allowed_anatomies", null), KNOWN_ANATOMIES)
				if not anatomies_check["ok"]:
					return _failure("JCP_ITEM_ANATOMY_REQUIREMENTS_INVALID", "Un Objeto tiene requisitos anatomicos invalidos.")
				if attributes.has("requires_manipulator"):
					return _failure("JCP_COMPATIBILITY_LEGACY_FIELD", "Los requisitos de Objeto no pueden conservar booleanos paralelos.")
	return _success()


func _validate_tag_list(value: Variant, allowed_values: Array) -> Dictionary:
	if not value is Array:
		return _failure("JCP_COMPATIBILITY_TAG_LIST_INVALID", "Las etiquetas de compatibilidad deben ser una lista.")
	var seen: Dictionary = {}
	for tag in value:
		if not tag is String or tag not in allowed_values or seen.has(tag):
			return _failure("JCP_COMPATIBILITY_TAG_INVALID", "Una etiqueta de compatibilidad es desconocida o esta repetida.")
		seen[tag] = true
	return _success()


func _validate_identity_list(value: Variant, require_nonempty: bool) -> Dictionary:
	if not value is Array or (require_nonempty and value.is_empty()):
		return _failure("JCP_IDENTITY_LIST_INVALID", "La identidad necesita una lista de etiquetas.")
	var seen: Dictionary = {}
	for tag in value:
		if not tag is String or tag.strip_edges().is_empty() or seen.has(tag):
			return _failure("JCP_IDENTITY_TAG_INVALID", "Una etiqueta de identidad esta vacia o repetida.")
		seen[tag] = true
	return _success()


func _validate_attack(state: Dictionary, player_id: int, payload: Dictionary) -> Dictionary:
	var payload_keys: Array = payload.keys()
	payload_keys.sort()
	if payload_keys != ["attacker_id", "target_slot"]:
		return _failure("JCP_ATTACK_PAYLOAD_INVALID", "Atacar requiere atacante y objetivo.")
	if not payload["attacker_id"] is String or not payload["target_slot"] is int or payload["target_slot"] < -1:
		return _failure("JCP_ATTACK_PAYLOAD_INVALID", "Los identificadores del combate no son validos.")
	if state["phase"]["current"] != PHASE_COMBAT:
		return _failure("JCP_ATTACK_PHASE_INVALID", "Solo se puede atacar durante la fase de combate propia.")
	var attacker_id: String = payload["attacker_id"]
	var own_zone: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", player_id))
	if not own_zone["ok"] or attacker_id not in own_zone["value"]:
		return _failure("JCP_ATTACKER_NOT_CONTROLLED", "El atacante no esta bajo el control del jugador.")
	var attacker_metadata: Dictionary = state["cards"]["instances"][attacker_id]["metadata"]
	if not attacker_metadata.get("face_up", true) or attacker_metadata.get("position", "guard") != "attack":
		return _failure("JCP_ATTACKER_NOT_READY", "Solo una criatura visible en postura de ataque puede atacar.")
	if state["turn"]["turn_number"] == 1 and player_id == state["config"]["starting_player"]:
		return _failure("JCP_ATTACK_INITIAL_TURN", "El jugador inicial no puede atacar durante el primer turno de la partida.")
	if attacker_metadata.get("last_attack_turn", -1) == state["turn"]["turn_number"] and not _has_dragon_extra_attack(state, attacker_id):
		return _failure("JCP_ATTACK_ALREADY_USED", "La criatura ya ha usado su ataque este turno.")
	var opponent_id: int = _opponent_id(state, player_id)
	var enemy_zone: Dictionary = CardState.zone_card_ids(state["cards"], _zone_id("creatures", opponent_id))
	if not enemy_zone["ok"]:
		return enemy_zone
	var target_slot: int = payload["target_slot"]
	if target_slot == -1:
		if not enemy_zone["value"].is_empty():
			return _failure("JCP_DIRECT_ATTACK_BLOCKED", "Las criaturas rivales protegen al jugador de ataques directos.")
		return _success()
	if target_slot >= enemy_zone["value"].size():
		return _failure("JCP_TARGET_NOT_ENEMY", "El objetivo no es una criatura rival valida.")
	return _success()


func _attack_entry_is_blocked(state: Dictionary, player_id: int, attacker_id: String) -> bool:
	if state["turn"]["turn_number"] == 1 and player_id == state["config"]["starting_player"]:
		return true
	var metadata: Dictionary = state["cards"]["instances"][attacker_id]["metadata"]
	return metadata.get("summoned_turn", -1) == state["turn"]["turn_number"] and metadata.has("fusion_entity")


func _active_base_definition_id(state: Dictionary, creature_id: String) -> String:
	if not _fusion_identity_id(state, creature_id).is_empty():
		return ""
	return state["cards"]["instances"][creature_id]["definition_id"]


func _can_gain_extra_attack(state: Dictionary, creature_id: String) -> bool:
	return _fusion_identity_id(state, creature_id) == "fusion.f005_fire_dragon" or _active_base_definition_id(state, creature_id) == "M18"


func _has_dragon_extra_attack(state: Dictionary, creature_id: String) -> bool:
	var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
	return _can_gain_extra_attack(state, creature_id) and metadata.get("dragon_bonus_turn", -1) == state["turn"]["turn_number"] and metadata.get("dragon_bonus_available", false)


func _redirect_guardians(state: Dictionary, defender_id: int, original_target_id: String) -> Array:
	var result: Array = []
	for creature_id in state["cards"]["zones"][_zone_id("creatures", defender_id)]["cards"]:
		if creature_id == original_target_id or _active_base_definition_id(state, creature_id) != "M13":
			continue
		var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
		if metadata.get("face_up", false) and metadata.get("redirect_turn", -1) != state["turn"]["turn_number"]:
			result.append(creature_id)
	return result


func _reduce_attack(state: Dictionary, player_id: int, attacker_id: String, target_slot: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var attacker_metadata: Dictionary = next_state["cards"]["instances"][attacker_id]["metadata"].duplicate(true)
	if attacker_metadata.get("last_attack_turn", -1) == next_state["turn"]["turn_number"] and _has_dragon_extra_attack(next_state, attacker_id):
		attacker_metadata["dragon_bonus_available"] = false
	attacker_metadata["last_attack_turn"] = next_state["turn"]["turn_number"]
	var attacker_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], attacker_id, attacker_metadata)
	if not attacker_update["ok"]:
		return _transition_failure(attacker_update)
	next_state["cards"] = attacker_update["value"]
	var opponent_id: int = _opponent_id(next_state, player_id)
	var target_id := ""
	if target_slot >= 0:
		target_id = next_state["cards"]["zones"][_zone_id("creatures", opponent_id)]["cards"][target_slot]
		var guardians: Array = _redirect_guardians(next_state, opponent_id, target_id)
		if not guardians.is_empty():
			next_state["pending_response"] = {
				"kind": "creature_redirect_choice", "source_player_id": player_id, "priority_player_id": opponent_id,
				"consecutive_passes": 0, "chain": [],
				"context": {"attacker_id": attacker_id, "original_target_id": target_id, "original_target_slot": target_slot, "guardian_ids": guardians},
			}
			return _transition_success(next_state, [{"type": "attack_declared", "payload": {"attacker_id": attacker_id, "attacker_player_id": player_id, "target_player_id": opponent_id, "target_slot": target_slot}}, {"type": "creature_redirect_offered", "payload": {"player_id": opponent_id, "original_target_slot": target_slot, "guardian_count": guardians.size()}}])
	var preparation: Dictionary = _prepare_fusion_combat(next_state, player_id, attacker_id, opponent_id, target_id)
	if not preparation["ok"]:
		return _transition_failure(preparation)
	next_state = preparation["state"]
	var modifiers: Dictionary = preparation["modifiers"]
	var preparation_events: Array = preparation["events"]
	if not preparation["choice_queue"].is_empty():
		next_state["pending_response"] = {
			"kind": "fusion_combat_choice",
			"source_player_id": player_id,
			"priority_player_id": preparation["choice_queue"][0]["player_id"],
			"consecutive_passes": 0,
			"chain": [],
			"context": {
				"attacker_id": attacker_id,
				"target_player_id": opponent_id,
				"target_slot": target_slot,
				"target_id": target_id,
				"modifiers": modifiers,
				"choice_queue": preparation["choice_queue"],
			},
		}
		var declared_events: Array = [{
			"type": "attack_declared",
			"payload": {"attacker_id": attacker_id, "attacker_player_id": player_id, "target_player_id": opponent_id, "target_slot": target_slot},
		}]
		declared_events.append_array(preparation_events)
		return _transition_success(next_state, declared_events)
	next_state["pending_response"] = {
		"kind": "attack",
		"source_player_id": player_id,
		"priority_player_id": opponent_id,
		"consecutive_passes": 0,
		"chain": [],
		"context": {
			"attacker_id": attacker_id,
			"target_player_id": opponent_id,
			"target_slot": target_slot,
			"target_id": target_id,
			"modifiers": modifiers,
		},
	}
	if _has_reaction(next_state):
		var pending_events: Array = [{
			"type": "attack_declared",
			"payload": {
				"attacker_id": attacker_id,
				"attacker_player_id": player_id,
				"target_player_id": opponent_id,
				"target_slot": target_slot,
			},
		}]
		pending_events.append_array(preparation_events)
		return _transition_success(next_state, pending_events)
	next_state["pending_response"] = {}
	var combat: Dictionary = _resolve_attack(next_state, player_id, attacker_id, target_slot, modifiers)
	if combat["ok"]:
		combat["events"] = preparation_events + combat["events"]
	return combat


func _reduce_creature_redirect(state: Dictionary, player_id: int, guardian_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state["pending_response"].duplicate(true)
	var context: Dictionary = pending["context"]
	var target_id: String = context["original_target_id"]
	var target_slot: int = context["original_target_slot"]
	var events: Array = []
	if not guardian_id.is_empty():
		target_id = guardian_id
		target_slot = next_state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"].find(guardian_id)
		var metadata: Dictionary = next_state["cards"]["instances"][guardian_id]["metadata"].duplicate(true)
		metadata["redirect_turn"] = next_state["turn"]["turn_number"]
		var update: Dictionary = CardState.update_instance_metadata(next_state["cards"], guardian_id, metadata)
		if not update["ok"]:
			return _transition_failure(update)
		next_state["cards"] = update["value"]
		events.append({"type": "creature_attack_redirected", "payload": {"player_id": player_id, "guardian_id": guardian_id, "definition_id": "M13", "original_target_slot": context["original_target_slot"], "target_slot": target_slot}})
	else:
		events.append({"type": "creature_redirect_declined", "payload": {"player_id": player_id, "original_target_slot": context["original_target_slot"]}})
	next_state["pending_response"] = {}
	var continued: Dictionary = _continue_attack_after_redirect(next_state, pending["source_player_id"], context["attacker_id"], target_slot, target_id)
	if continued["ok"]:
		continued["events"] = events + continued["events"]
	return continued


func _continue_attack_after_redirect(state: Dictionary, player_id: int, attacker_id: String, target_slot: int, target_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var opponent_id: int = _opponent_id(next_state, player_id)
	var preparation: Dictionary = _prepare_fusion_combat(next_state, player_id, attacker_id, opponent_id, target_id)
	if not preparation["ok"]:
		return _transition_failure(preparation)
	next_state = preparation["state"]
	var modifiers: Dictionary = preparation["modifiers"]
	var events: Array = preparation["events"]
	if not preparation["choice_queue"].is_empty():
		next_state["pending_response"] = {"kind": "fusion_combat_choice", "source_player_id": player_id, "priority_player_id": preparation["choice_queue"][0]["player_id"], "consecutive_passes": 0, "chain": [], "context": {"attacker_id": attacker_id, "target_player_id": opponent_id, "target_slot": target_slot, "target_id": target_id, "modifiers": modifiers, "choice_queue": preparation["choice_queue"]}}
		return _transition_success(next_state, events)
	next_state["pending_response"] = {"kind": "attack", "source_player_id": player_id, "priority_player_id": opponent_id, "consecutive_passes": 0, "chain": [], "context": {"attacker_id": attacker_id, "target_player_id": opponent_id, "target_slot": target_slot, "target_id": target_id, "modifiers": modifiers}}
	if _has_reaction(next_state):
		return _transition_success(next_state, events)
	next_state["pending_response"] = {}
	var combat: Dictionary = _resolve_attack(next_state, player_id, attacker_id, target_slot, modifiers)
	if combat["ok"]:
		combat["events"] = events + combat["events"]
	return combat


func _prepare_fusion_combat(state: Dictionary, player_id: int, attacker_id: String, opponent_id: int, target_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var modifiers: Dictionary = {"attacker_attack_delta": 0, "attacker_defense_delta": 0, "target_attack_delta": 0, "target_defense_delta": 0}
	var events: Array = []
	if _active_base_definition_id(next_state, attacker_id) == "M05":
		modifiers["attacker_attack_delta"] += 1
		events.append({"type": "creature_attack_bonus_triggered", "payload": {"player_id": player_id, "creature_id": attacker_id, "definition_id": "M05", "attack_bonus": 1}})
	for source_id in next_state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]:
		if source_id == attacker_id or _fusion_identity_id(next_state, source_id) != "fusion.f001_nature_alpha":
			continue
		var source_metadata: Dictionary = next_state["cards"]["instances"][source_id]["metadata"].duplicate(true)
		if source_metadata.get("alpha_leadership_turn", -1) == next_state["turn"]["turn_number"]:
			continue
		source_metadata["alpha_leadership_turn"] = next_state["turn"]["turn_number"]
		var source_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], source_id, source_metadata)
		if not source_update["ok"]:
			return source_update
		next_state["cards"] = source_update["value"]
		modifiers["attacker_attack_delta"] += 1
		events.append({"type": "fusion_leadership_triggered", "payload": {"source_instance_id": source_id, "target_instance_id": attacker_id, "attack_bonus": 1}})
	if _fusion_identity_id(next_state, attacker_id) == "fusion.f011_torch_band":
		var defense_bonus := 1 if _controls_other_visible_family(next_state, player_id, attacker_id, "goblin") else 0
		modifiers["attacker_attack_delta"] += 1
		modifiers["attacker_defense_delta"] += defense_bonus
		events.append({
			"type": "fusion_torch_band_triggered",
			"payload": {
				"source_instance_id": attacker_id,
				"attack_bonus": 1,
				"defense_bonus": defense_bonus,
			},
		})
	if not target_id.is_empty() and _fusion_identity_id(next_state, target_id) == "fusion.f012_thicket_company":
		var target_metadata: Dictionary = next_state["cards"]["instances"][target_id]["metadata"].duplicate(true)
		if target_metadata.get("thicket_guard_turn", -1) != next_state["turn"]["turn_number"]:
			target_metadata["thicket_guard_turn"] = next_state["turn"]["turn_number"]
			var target_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], target_id, target_metadata)
			if not target_update["ok"]:
				return target_update
			next_state["cards"] = target_update["value"]
			modifiers["attacker_attack_delta"] -= 1
			events.append({
				"type": "fusion_thicket_guard_triggered",
				"payload": {
					"source_instance_id": target_id,
					"target_instance_id": attacker_id,
					"attack_penalty": 1,
				},
			})
	var choice_queue: Array = []
	if _fusion_identity_id(next_state, attacker_id) == "fusion.f067_water_major" and next_state["cards"]["instances"][attacker_id]["metadata"].get("fusion_combat_choice_turn", -1) != next_state["turn"]["turn_number"]:
		choice_queue.append({"creature_id": attacker_id, "player_id": player_id, "role": "attacker"})
	if not target_id.is_empty() and _fusion_identity_id(next_state, target_id) == "fusion.f067_water_major" and next_state["cards"]["instances"][target_id]["metadata"].get("fusion_combat_choice_turn", -1) != next_state["turn"]["turn_number"]:
		choice_queue.append({"creature_id": target_id, "player_id": opponent_id, "role": "target"})
	return {"ok": true, "state": next_state, "modifiers": modifiers, "choice_queue": choice_queue, "events": events}


func _fusion_identity_id(state: Dictionary, creature_id: String) -> String:
	var entity: Variant = state["cards"]["instances"][creature_id]["metadata"].get("fusion_entity", null)
	return entity.get("fusion_identity_id", "") if entity is Dictionary else ""


func _controls_other_visible_family(state: Dictionary, player_id: int, excluded_id: String, family: String) -> bool:
	for creature_id in state["cards"]["zones"][_zone_id("creatures", player_id)]["cards"]:
		if creature_id == excluded_id:
			continue
		if not state["cards"]["instances"][creature_id]["metadata"].get("face_up", false):
			continue
		if family in _creature_attributes(state, creature_id)["families"]:
			return true
	return false


func _reduce_reaction(state: Dictionary, player_id: int, support_slot: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var support_cards: Array = next_state["cards"]["zones"][_zone_id("support", player_id)]["cards"]
	var support_id: String = support_cards[support_slot]
	var definition_id: String = _definition_for_instance(next_state, support_id)["id"]
	var metadata: Dictionary = next_state["cards"]["instances"][support_id]["metadata"].duplicate(true)
	metadata["face_up"] = true
	metadata["active"] = true
	var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], support_id, metadata)
	if not update_result["ok"]:
		return _transition_failure(update_result)
	next_state["cards"] = update_result["value"]
	var chain: Array = next_state["pending_response"]["chain"].duplicate(true)
	chain.append({
		"controller_id": player_id,
		"support_id": support_id,
		"definition_id": definition_id,
		"support_slot": support_slot,
	})
	next_state["pending_response"]["chain"] = chain
	next_state["pending_response"]["consecutive_passes"] = 0
	next_state["pending_response"]["priority_player_id"] = _opponent_id(next_state, player_id)
	return _transition_success(next_state, [{
		"type": "reaction_activated",
		"payload": {
			"player_id": player_id,
			"definition_id": definition_id,
			"support_slot": support_slot,
		},
	}])


func _reduce_pass_reaction(state: Dictionary, player_id: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var passes: int = next_state["pending_response"]["consecutive_passes"] + 1
	var events: Array = [{
		"type": "reaction_priority_passed",
		"payload": {"player_id": player_id, "consecutive_passes": passes},
	}]
	if passes < 2:
		next_state["pending_response"]["consecutive_passes"] = passes
		next_state["pending_response"]["priority_player_id"] = _opponent_id(next_state, player_id)
		return _transition_success(next_state, events)
	var resolution: Dictionary = _resolve_response_chain(next_state)
	if not resolution["ok"]:
		return resolution
	events.append_array(resolution["events"])
	return _transition_success(resolution["state"], events)


func _resolve_response_chain(state: Dictionary) -> Dictionary:
	if state["pending_response"]["kind"] == "spell":
		return _resolve_spell_response_chain(state)
	if state["pending_response"]["kind"] == "attack":
		return _resolve_attack_response_chain(state)
	return _resolve_trigger_response_chain(state)


func _resolve_attack_response_chain(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state["pending_response"].duplicate(true)
	var context: Dictionary = pending["context"]
	var base_modifiers: Dictionary = context["modifiers"]
	var attacker_attack_delta: int = base_modifiers["attacker_attack_delta"]
	var attacker_defense_delta: int = base_modifiers["attacker_defense_delta"]
	var target_attack_delta: int = base_modifiers["target_attack_delta"]
	var target_defense_delta: int = base_modifiers["target_defense_delta"]
	var canceled := false
	var events: Array = []
	var chain: Array = pending["chain"].duplicate(true)
	chain.reverse()
	for link in chain:
		var definition_id: String = link["definition_id"]
		match definition_id:
			"G06":
				target_defense_delta += 2
			"G07":
				if _is_in_zone(next_state, context["target_id"], _zone_id("creatures", context["target_player_id"])):
					var return_result: Dictionary = _return_creature_and_break_links(
						next_state,
						context["target_player_id"],
						context["target_id"]
					)
					if not return_result["ok"]:
						return _transition_failure(return_result)
					next_state = return_result["state"]
					if not return_result["linked_ids"].is_empty():
						events.append({
							"type": "linked_cards_destroyed",
							"payload": {"creature_id": context["target_id"], "linked_ids": return_result["linked_ids"]},
						})
				canceled = true
			"T01":
				if _is_in_zone(next_state, context["attacker_id"], _zone_id("creatures", pending["source_player_id"])):
					var destruction: Dictionary = _destroy_creature_and_links(
						next_state,
						pending["source_player_id"],
						context["attacker_id"]
					)
					if not destruction["ok"]:
						return _transition_failure(destruction)
					next_state = destruction["state"]
					events.append_array(destruction.get("events", []))
					if not destruction["linked_ids"].is_empty():
						events.append({
							"type": "linked_cards_destroyed",
							"payload": {"creature_id": context["attacker_id"], "linked_ids": destruction["linked_ids"]},
						})
				canceled = true
			"T02":
				attacker_attack_delta -= 2
		var consume_result: Dictionary = _consume_reaction_card(next_state, link)
		if not consume_result["ok"]:
			return _transition_failure(consume_result)
		next_state = consume_result["state"]
		events.append({
			"type": "reaction_resolved",
			"payload": {
				"player_id": link["controller_id"],
				"definition_id": definition_id,
				"support_slot": link["support_slot"],
			},
		})
	next_state["pending_response"] = {}
	if canceled:
		events.append({
			"type": "attack_canceled",
			"payload": {
				"attacker_player_id": pending["source_player_id"],
				"target_player_id": context["target_player_id"],
				"target_slot": context["target_slot"],
			},
		})
		return {"ok": true, "state": next_state, "events": events}
	var combat_result: Dictionary = _resolve_attack(
		next_state,
		pending["source_player_id"],
		context["attacker_id"],
		context["target_slot"],
		{
			"attacker_attack_delta": attacker_attack_delta,
			"attacker_defense_delta": attacker_defense_delta,
			"target_attack_delta": target_attack_delta,
			"target_defense_delta": target_defense_delta,
		}
	)
	if not combat_result["ok"]:
		return combat_result
	events.append_array(combat_result["events"])
	return {"ok": true, "state": combat_result["state"], "events": events}


func _resolve_spell_response_chain(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state["pending_response"].duplicate(true)
	var context: Dictionary = pending["context"]
	var negated := false
	var events: Array = []
	var chain: Array = pending["chain"].duplicate(true)
	chain.reverse()
	for link in chain:
		if link["definition_id"] == "T03":
			negated = true
		var consume_result: Dictionary = _consume_reaction_card(next_state, link)
		if not consume_result["ok"]:
			return _transition_failure(consume_result)
		next_state = consume_result["state"]
		events.append({
			"type": "reaction_resolved",
			"payload": {
				"player_id": link["controller_id"],
				"definition_id": link["definition_id"],
				"support_slot": link["support_slot"],
			},
		})
	next_state["pending_response"] = {}
	if negated:
		var spell_move: Dictionary = CardState.move_card(
			next_state["cards"],
			context["spell_id"],
			_zone_id("hand", pending["source_player_id"]),
			_zone_id("graveyard", pending["source_player_id"])
		)
		if not spell_move["ok"]:
			return _transition_failure(spell_move)
		next_state["cards"] = spell_move["value"]
		events.append({
			"type": "main_spell_negated",
			"payload": {
				"player_id": pending["source_player_id"],
				"instance_id": context["spell_id"],
				"definition_id": context["spell_definition_id"],
				"target_player_id": context["target_player_id"],
				"target_slot": context["target_slot"],
			},
		})
		return {"ok": true, "state": next_state, "events": events}
	var spell_result: Dictionary = _resolve_main_spell(
		next_state,
		pending["source_player_id"],
		context["spell_id"],
		context["target_player_id"],
		context["target_slot"]
	)
	if not spell_result["ok"]:
		return spell_result
	events.append_array(spell_result["events"])
	return {"ok": true, "state": spell_result["state"], "events": events}


func _consume_reaction_card(state: Dictionary, link: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var metadata: Dictionary = next_state["cards"]["instances"][link["support_id"]]["metadata"].duplicate(true)
	metadata["active"] = false
	var update_result: Dictionary = CardState.update_instance_metadata(
		next_state["cards"],
		link["support_id"],
		metadata
	)
	if not update_result["ok"]:
		return update_result
	var move_result: Dictionary = CardState.move_card(
		update_result["value"],
		link["support_id"],
		_zone_id("support", link["controller_id"]),
		_zone_id("graveyard", link["controller_id"])
	)
	if not move_result["ok"]:
		return move_result
	next_state["cards"] = move_result["value"]
	return {"ok": true, "code": "OK", "message": "", "state": next_state}


func _resolve_trigger_response_chain(state: Dictionary) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var pending: Dictionary = next_state["pending_response"].duplicate(true)
	var context: Dictionary = pending["context"]
	var triggered := false
	var events: Array = []
	var chain: Array = pending["chain"].duplicate(true)
	chain.reverse()
	for link in chain:
		var expected_definition: String = {
			"position_change": "T04",
			"equipment": "T05",
			"combat_destruction": "T06",
		}[pending["kind"]]
		if link["definition_id"] == expected_definition:
			triggered = true
		var consume_result: Dictionary = _consume_reaction_card(next_state, link)
		if not consume_result["ok"]:
			return _transition_failure(consume_result)
		next_state = consume_result["state"]
		events.append({
			"type": "reaction_resolved",
			"payload": {
				"player_id": link["controller_id"],
				"definition_id": link["definition_id"],
				"support_slot": link["support_slot"],
			},
		})
	next_state["pending_response"] = {}
	if not triggered:
		return {"ok": true, "state": next_state, "events": events}
	match pending["kind"]:
		"position_change":
			if _is_in_zone(next_state, context["creature_id"], _zone_id("creatures", pending["source_player_id"])):
				var metadata: Dictionary = next_state["cards"]["instances"][context["creature_id"]]["metadata"].duplicate(true)
				metadata["position"] = "guard"
				var update_result: Dictionary = CardState.update_instance_metadata(next_state["cards"], context["creature_id"], metadata)
				if not update_result["ok"]:
					return _transition_failure(update_result)
				next_state["cards"] = update_result["value"]
				events.append({
					"type": "position_change_reversed",
					"payload": {"player_id": pending["source_player_id"], "creature_id": context["creature_id"], "position": "guard"},
				})
		"equipment":
			if _is_in_zone(next_state, context["equipment_id"], _zone_id("attachments", pending["source_player_id"])):
				var equipment_metadata: Dictionary = next_state["cards"]["instances"][context["equipment_id"]]["metadata"].duplicate(true)
				equipment_metadata["active"] = false
				equipment_metadata["linked_to"] = ""
				var equipment_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], context["equipment_id"], equipment_metadata)
				if not equipment_update["ok"]:
					return _transition_failure(equipment_update)
				var equipment_move: Dictionary = CardState.move_card(
					equipment_update["value"],
					context["equipment_id"],
					_zone_id("attachments", pending["source_player_id"]),
					_zone_id("graveyard", pending["source_player_id"])
				)
				if not equipment_move["ok"]:
					return _transition_failure(equipment_move)
				next_state["cards"] = equipment_move["value"]
				events.append({
					"type": "newly_equipped_item_destroyed",
					"payload": {"player_id": pending["source_player_id"], "equipment_id": context["equipment_id"]},
				})
		"combat_destruction":
			if _is_in_zone(next_state, context["surviving_creature_id"], _zone_id("creatures", context["surviving_player_id"])):
				var destruction: Dictionary = _destroy_creature_and_links(next_state, context["surviving_player_id"], context["surviving_creature_id"])
				if not destruction["ok"]:
					return _transition_failure(destruction)
				next_state = destruction["state"]
				events.append_array(destruction.get("events", []))
				if not destruction["linked_ids"].is_empty():
					events.append({
						"type": "linked_cards_destroyed",
						"payload": {"creature_id": context["surviving_creature_id"], "linked_ids": destruction["linked_ids"]},
					})
				events.append({
					"type": "combat_survivor_destroyed",
					"payload": {"player_id": context["surviving_player_id"], "creature_id": context["surviving_creature_id"]},
				})
	return {"ok": true, "state": next_state, "events": events}


func _resolve_attack(
	state: Dictionary,
	player_id: int,
	attacker_id: String,
	target_slot: int,
	modifiers: Dictionary
) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var opponent_id: int = _opponent_id(next_state, player_id)
	var attacker_metadata: Dictionary = next_state["cards"]["instances"][attacker_id]["metadata"]
	var attacker_is_m16: bool = _active_base_definition_id(next_state, attacker_id) == "M16"
	var attacker_stats: Dictionary = _effective_stats(next_state, attacker_id)
	var attacker_attack: int = max(0, attacker_stats["attack"] + modifiers.get("attacker_attack_delta", 0))
	var events: Array = []
	if target_slot == -1:
		next_state["life"][_player_key(opponent_id)] = max(
			0,
			next_state["life"][_player_key(opponent_id)] - attacker_attack
		)
		events.append({
			"type": "direct_attack_resolved",
			"payload": {
				"attacker_id": attacker_id,
				"attacker_player_id": player_id,
				"defender_player_id": opponent_id,
				"damage": attacker_attack,
				"remaining_life": next_state["life"][_player_key(opponent_id)],
			},
		})
		_finish_if_life_depleted(next_state, events)
		return _transition_success(next_state, events)

	var target_id: String = next_state["cards"]["zones"][_zone_id("creatures", opponent_id)]["cards"][target_slot]
	var target_is_m16: bool = _active_base_definition_id(next_state, target_id) == "M16"
	var target_metadata: Dictionary = next_state["cards"]["instances"][target_id]["metadata"].duplicate(true)
	var target_was_hidden: bool = not target_metadata.get("face_up", true)
	if target_was_hidden:
		target_metadata["face_up"] = true
		var target_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], target_id, target_metadata)
		if not target_update["ok"]:
			return _transition_failure(target_update)
		next_state["cards"] = target_update["value"]
		events.append({
			"type": "creature_revealed",
			"payload": {
				"player_id": opponent_id,
				"instance_id": target_id,
				"definition_id": next_state["cards"]["instances"][target_id]["definition_id"],
				"position": target_metadata.get("position", "guard"),
			},
		})
	var target_stats: Dictionary = _effective_stats(next_state, target_id)
	var target_attack: int = max(0, target_stats["attack"] + modifiers.get("target_attack_delta", 0))
	var target_defense: int = max(0, target_stats["defense"] + modifiers.get("target_defense_delta", 0))
	if target_was_hidden and _active_base_definition_id(next_state, target_id) == "M06":
		target_defense += 1
		events.append({"type": "creature_reveal_bonus_triggered", "payload": {"player_id": opponent_id, "creature_id": target_id, "definition_id": "M06", "defense_bonus": 1}})
	var attacker_defense: int = max(0, attacker_stats["defense"] + modifiers.get("attacker_defense_delta", 0))
	var target_position: String = target_metadata.get("position", "guard")
	var target_destroyed: bool = attacker_attack > target_defense
	var attacker_destroyed: bool = target_attack > attacker_defense
	var damage_to_defender := 0
	var damage_to_attacker := 0
	if target_destroyed and target_position == "attack":
		damage_to_defender = attacker_attack - target_defense
	if attacker_destroyed and attacker_metadata.get("position", "attack") == "attack":
		damage_to_attacker = target_attack - attacker_defense
	if damage_to_defender > 0:
		next_state["life"][_player_key(opponent_id)] = max(0, next_state["life"][_player_key(opponent_id)] - damage_to_defender)
	if damage_to_attacker > 0:
		next_state["life"][_player_key(player_id)] = max(0, next_state["life"][_player_key(player_id)] - damage_to_attacker)
	if target_destroyed and _fusion_identity_id(next_state, target_id) == "fusion.f018_two_headed_troll" and target_metadata.get("troll_regeneration_turn", -1) != next_state["turn"]["turn_number"]:
		target_destroyed = false
		target_metadata = next_state["cards"]["instances"][target_id]["metadata"].duplicate(true)
		target_metadata["troll_regeneration_turn"] = next_state["turn"]["turn_number"]
		target_metadata["position"] = "guard"
		var target_regeneration: Dictionary = CardState.update_instance_metadata(next_state["cards"], target_id, target_metadata)
		if not target_regeneration["ok"]:
			return _transition_failure(target_regeneration)
		next_state["cards"] = target_regeneration["value"]
		events.append({"type": "fusion_combat_destruction_prevented", "payload": {"player_id": opponent_id, "creature_id": target_id, "fusion_identity_id": "fusion.f018_two_headed_troll", "position": "guard"}})
	if attacker_destroyed and _fusion_identity_id(next_state, attacker_id) == "fusion.f018_two_headed_troll" and attacker_metadata.get("troll_regeneration_turn", -1) != next_state["turn"]["turn_number"]:
		attacker_destroyed = false
		attacker_metadata = next_state["cards"]["instances"][attacker_id]["metadata"].duplicate(true)
		attacker_metadata["troll_regeneration_turn"] = next_state["turn"]["turn_number"]
		attacker_metadata["position"] = "guard"
		var attacker_regeneration: Dictionary = CardState.update_instance_metadata(next_state["cards"], attacker_id, attacker_metadata)
		if not attacker_regeneration["ok"]:
			return _transition_failure(attacker_regeneration)
		next_state["cards"] = attacker_regeneration["value"]
		events.append({"type": "fusion_combat_destruction_prevented", "payload": {"player_id": player_id, "creature_id": attacker_id, "fusion_identity_id": "fusion.f018_two_headed_troll", "position": "guard"}})
	if target_destroyed:
		var target_destruction: Dictionary = _destroy_creature_and_links(next_state, opponent_id, target_id)
		if not target_destruction["ok"]:
			return _transition_failure(target_destruction)
		next_state = target_destruction["state"]
		events.append_array(target_destruction.get("events", []))
		if not target_destruction["linked_ids"].is_empty():
			events.append({
				"type": "linked_cards_destroyed",
				"payload": {"creature_id": target_id, "linked_ids": target_destruction["linked_ids"]},
			})
	if attacker_destroyed:
		var attacker_destruction: Dictionary = _destroy_creature_and_links(next_state, player_id, attacker_id)
		if not attacker_destruction["ok"]:
			return _transition_failure(attacker_destruction)
		next_state = attacker_destruction["state"]
		events.append_array(attacker_destruction.get("events", []))
		if not attacker_destruction["linked_ids"].is_empty():
			events.append({
				"type": "linked_cards_destroyed",
				"payload": {"creature_id": attacker_id, "linked_ids": attacker_destruction["linked_ids"]},
			})
	events.append({
		"type": "creature_combat_resolved",
		"payload": {
			"attacker_id": attacker_id,
			"target_id": target_id,
			"attacker_attack": attacker_attack,
			"attacker_defense": attacker_defense,
			"target_attack": target_attack,
			"target_defense": target_defense,
			"attacker_destroyed": attacker_destroyed,
			"target_destroyed": target_destroyed,
			"damage_to_attacker": damage_to_attacker,
			"damage_to_defender": damage_to_defender,
		},
	})
	_finish_if_life_depleted(next_state, events)
	if target_destroyed and attacker_is_m16:
		var attacker_recovery: Dictionary = _recover_m16_energy(next_state, player_id, attacker_id)
		if not attacker_recovery["ok"]:
			return _transition_failure(attacker_recovery)
		next_state = attacker_recovery["state"]
		events.append_array(attacker_recovery["events"])
	if attacker_destroyed and target_is_m16:
		var target_recovery: Dictionary = _recover_m16_energy(next_state, opponent_id, target_id)
		if not target_recovery["ok"]:
			return _transition_failure(target_recovery)
		next_state = target_recovery["state"]
		events.append_array(target_recovery["events"])
	if not is_finished(next_state) and target_destroyed != attacker_destroyed:
		var destroyed_player_id: int = opponent_id if target_destroyed else player_id
		var destroyed_creature_id: String = target_id if target_destroyed else attacker_id
		var surviving_player_id: int = player_id if target_destroyed else opponent_id
		var surviving_creature_id: String = attacker_id if target_destroyed else target_id
		var survivor_metadata: Dictionary = next_state["cards"]["instances"][surviving_creature_id]["metadata"].duplicate(true)
		if _can_gain_extra_attack(next_state, surviving_creature_id) and survivor_metadata.get("dragon_bonus_turn", -1) != next_state["turn"]["turn_number"]:
			survivor_metadata["dragon_bonus_turn"] = next_state["turn"]["turn_number"]
			survivor_metadata["dragon_bonus_available"] = true
			var bonus_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], surviving_creature_id, survivor_metadata)
			if not bonus_update["ok"]:
				return _transition_failure(bonus_update)
			next_state["cards"] = bonus_update["value"]
			var source_definition_id: String = _active_base_definition_id(next_state, surviving_creature_id)
			events.append({"type": "extra_attack_granted", "payload": {"player_id": surviving_player_id, "creature_id": surviving_creature_id, "source_id": source_definition_id if not source_definition_id.is_empty() else "fusion.f005_fire_dragon", "turn_number": next_state["turn"]["turn_number"]}})
			if source_definition_id.is_empty():
				events.append({"type": "fusion_extra_attack_granted", "payload": {"player_id": surviving_player_id, "creature_id": surviving_creature_id, "fusion_identity_id": "fusion.f005_fire_dragon", "turn_number": next_state["turn"]["turn_number"]}})
		next_state["pending_response"] = {
			"kind": "combat_destruction",
			"source_player_id": player_id,
			"priority_player_id": destroyed_player_id,
			"consecutive_passes": 0,
			"chain": [],
			"context": {
				"destroyed_player_id": destroyed_player_id,
				"destroyed_creature_id": destroyed_creature_id,
				"surviving_player_id": surviving_player_id,
				"surviving_creature_id": surviving_creature_id,
			},
		}
		if not _has_reaction(next_state):
			next_state["pending_response"] = {}
	return _transition_success(next_state, events)


func _destroy_creature_and_links(state: Dictionary, player_id: int, creature_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var destroyed_definition_id: String = _active_base_definition_id(next_state, creature_id)
	var events: Array = []
	var attachments_result: Dictionary = CardState.zone_card_ids(next_state["cards"], _zone_id("attachments", player_id))
	if not attachments_result["ok"]:
		return attachments_result
	var linked_ids: Array = []
	for attachment_id in attachments_result["value"]:
		if next_state["cards"]["instances"][attachment_id]["metadata"].get("linked_to", "") == creature_id:
			linked_ids.append(attachment_id)
	for attachment_id in linked_ids:
		var link_move: Dictionary = CardState.move_card(
			next_state["cards"],
			attachment_id,
			_zone_id("attachments", player_id),
			_zone_id("graveyard", player_id)
		)
		if not link_move["ok"]:
			return link_move
		next_state["cards"] = link_move["value"]
	var material_ids: Array = _contained_material_ids(next_state, creature_id)
	for material_id in material_ids:
		if material_id == creature_id:
			continue
		var material_move: Dictionary = CardState.move_card(next_state["cards"], material_id, _zone_id("fusion_materials", player_id), _zone_id("graveyard", player_id))
		if not material_move["ok"]:
			return material_move
		next_state["cards"] = material_move["value"]
		var material_metadata: Dictionary = next_state["cards"]["instances"][material_id]["metadata"].duplicate(true)
		material_metadata.erase("contained_by")
		var material_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], material_id, material_metadata)
		if not material_update["ok"]:
			return material_update
		next_state["cards"] = material_update["value"]
	var creature_metadata: Dictionary = next_state["cards"]["instances"][creature_id]["metadata"].duplicate(true)
	creature_metadata.erase("fusion_entity")
	creature_metadata.erase("troll_regeneration_turn")
	creature_metadata.erase("dragon_bonus_turn")
	creature_metadata.erase("dragon_bonus_available")
	creature_metadata.erase("steam_attack_penalty")
	creature_metadata.erase("steam_penalty_owner_turns_remaining")
	var creature_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], creature_id, creature_metadata)
	if not creature_update["ok"]:
		return creature_update
	next_state["cards"] = creature_update["value"]
	var creature_move: Dictionary = CardState.move_card(
		next_state["cards"],
		creature_id,
		_zone_id("creatures", player_id),
		_zone_id("graveyard", player_id)
	)
	if not creature_move["ok"]:
		return creature_move
	next_state["cards"] = creature_move["value"]
	if destroyed_definition_id == "M07":
		var deck_cards: Array = next_state["cards"]["zones"][_zone_id("deck", player_id)]["cards"]
		if not deck_cards.is_empty():
			var draw_result: Dictionary = _draw_one(next_state, player_id)
			if not draw_result["ok"]:
				return draw_result
			next_state = draw_result["state"]
			events.append({"type": "creature_destruction_draw", "payload": {"player_id": player_id, "creature_id": creature_id, "definition_id": "M07", "count": 1}})
			events.append({"type": "private_card_drawn", "payload": {"player_id": player_id, "instance_id": draw_result["instance_id"]}, "visible_to": [player_id]})
		else:
			events.append({"type": "creature_destruction_draw_empty", "payload": {"player_id": player_id, "creature_id": creature_id, "definition_id": "M07"}})
	return {"ok": true, "code": "OK", "message": "", "state": next_state, "linked_ids": linked_ids, "events": events}


func _return_creature_and_break_links(state: Dictionary, player_id: int, creature_id: String) -> Dictionary:
	if state["cards"]["instances"][creature_id]["metadata"].has("fusion_entity"):
		return _failure("JCP_GENERATED_ENTITY_RETURN_INVALID", "Una entidad generada no puede ocupar la mano mediante un retorno generico.")
	var next_state: Dictionary = state.duplicate(true)
	var attachments_result: Dictionary = CardState.zone_card_ids(next_state["cards"], _zone_id("attachments", player_id))
	if not attachments_result["ok"]:
		return attachments_result
	var linked_ids: Array = []
	for attachment_id in attachments_result["value"]:
		if next_state["cards"]["instances"][attachment_id]["metadata"].get("linked_to", "") == creature_id:
			linked_ids.append(attachment_id)
	for attachment_id in linked_ids:
		var link_move: Dictionary = CardState.move_card(
			next_state["cards"],
			attachment_id,
			_zone_id("attachments", player_id),
			_zone_id("graveyard", player_id)
		)
		if not link_move["ok"]:
			return link_move
		next_state["cards"] = link_move["value"]
	var material_ids: Array = _contained_material_ids(next_state, creature_id)
	for material_id in material_ids:
		if material_id == creature_id:
			continue
		var material_move: Dictionary = CardState.move_card(next_state["cards"], material_id, _zone_id("fusion_materials", player_id), _zone_id("hand", player_id))
		if not material_move["ok"]:
			return material_move
		next_state["cards"] = material_move["value"]
		var material_metadata: Dictionary = next_state["cards"]["instances"][material_id]["metadata"].duplicate(true)
		material_metadata.erase("contained_by")
		var material_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], material_id, material_metadata)
		if not material_update["ok"]:
			return material_update
		next_state["cards"] = material_update["value"]
	var creature_metadata: Dictionary = next_state["cards"]["instances"][creature_id]["metadata"].duplicate(true)
	creature_metadata.erase("fusion_entity")
	creature_metadata.erase("troll_regeneration_turn")
	creature_metadata.erase("dragon_bonus_turn")
	creature_metadata.erase("dragon_bonus_available")
	creature_metadata.erase("steam_attack_penalty")
	creature_metadata.erase("steam_penalty_owner_turns_remaining")
	var creature_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], creature_id, creature_metadata)
	if not creature_update["ok"]:
		return creature_update
	next_state["cards"] = creature_update["value"]
	var creature_move: Dictionary = CardState.move_card(
		next_state["cards"],
		creature_id,
		_zone_id("creatures", player_id),
		_zone_id("hand", player_id)
	)
	if not creature_move["ok"]:
		return creature_move
	next_state["cards"] = creature_move["value"]
	return {"ok": true, "code": "OK", "message": "", "state": next_state, "linked_ids": linked_ids}


func _recover_m16_energy(state: Dictionary, player_id: int, creature_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var events: Array = []
	var collector_metadata: Dictionary = next_state["cards"]["instances"][creature_id]["metadata"].duplicate(true)
	if collector_metadata.get("energy_recovery_turn", -1) == next_state["turn"]["turn_number"]:
		return {"ok": true, "code": "OK", "message": "", "state": next_state, "events": events}
	collector_metadata["energy_recovery_turn"] = next_state["turn"]["turn_number"]
	var collector_update: Dictionary = CardState.update_instance_metadata(next_state["cards"], creature_id, collector_metadata)
	if not collector_update["ok"]:
		return collector_update
	next_state["cards"] = collector_update["value"]
	var resource: Dictionary = next_state["energy"][_player_key(player_id)]
	var before_energy: int = resource["available"]
	resource["available"] = min(resource["maximum"], resource["available"] + 1)
	events.append({"type": "creature_energy_recovered", "payload": {"player_id": player_id, "creature_id": creature_id, "definition_id": "M16", "amount": resource["available"] - before_energy}})
	return {"ok": true, "code": "OK", "message": "", "state": next_state, "events": events}


func _finish_if_life_depleted(state: Dictionary, events: Array) -> void:
	var defeated_ids: Array = []
	var winner_ids: Array = []
	for player_id in state["turn"]["order"]:
		if state["life"][_player_key(player_id)] <= 0:
			defeated_ids.append(player_id)
		else:
			winner_ids.append(player_id)
	if defeated_ids.is_empty():
		return
	state["winner_ids"] = winner_ids if defeated_ids.size() == 1 else []
	state["finished_reason"] = "life_zero"
	var finish_result: Dictionary = PhaseMachine.transition(state["phase"], PHASE_FINISHED)
	if finish_result["ok"]:
		state["phase"] = finish_result["value"]
	events.append({
		"type": "players_defeated",
		"payload": {"defeated_ids": defeated_ids, "winner_ids": state["winner_ids"].duplicate()},
	})


func _definition_for_instance(state: Dictionary, instance_id: String) -> Dictionary:
	var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
	return state["cards"]["definitions"][definition_id]


func _contained_material_ids(state: Dictionary, creature_id: String) -> Array:
	var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
	if not metadata.has("fusion_entity"):
		return [creature_id]
	return metadata["fusion_entity"]["contained_physical_ids"].duplicate()


func _creature_attributes(state: Dictionary, creature_id: String) -> Dictionary:
	var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
	if metadata.has("fusion_entity"):
		var entity: Dictionary = metadata["fusion_entity"]
		return {
			"display_name": entity["display_name"],
			"cost": entity["cost"],
			"attack": entity["attack"],
			"defense": entity["defense"],
			"families": entity["families"].duplicate(),
			"superfamilies": entity["superfamilies"].duplicate(),
			"element": entity["elements"][0],
			"anatomy": entity["anatomy"],
			"aptitudes": entity["aptitudes"].duplicate(),
			"properties": entity["properties"].duplicate(),
		}
	return _definition_for_instance(state, creature_id)["attributes"]


func _creature_cost(state: Dictionary, creature_id: String) -> int:
	return _creature_attributes(state, creature_id)["cost"]


func _terrain_recipe_for(current_identity_id: String, incoming_definition_id: String) -> Dictionary:
	var key := "%s>%s" % [current_identity_id, incoming_definition_id]
	if not TERRAIN_RECIPES.has(key):
		return {}
	return TERRAIN_RECIPES[key].duplicate(true)


func _terrain_recipe_by_id(form_id: String) -> Dictionary:
	for recipe in TERRAIN_RECIPES.values():
		if recipe["id"] == form_id:
			return recipe.duplicate(true)
	return {}


func _terrain_identity(state: Dictionary, terrain_id: String) -> Dictionary:
	var definition: Dictionary = _definition_for_instance(state, terrain_id)
	var metadata: Dictionary = state["cards"]["instances"][terrain_id]["metadata"]
	if metadata.has("terrain_form_id"):
		return {
			"id": metadata["terrain_form_id"],
			"display_name": metadata["terrain_form_name"],
			"transformed": true,
			"components": metadata["terrain_components"].duplicate(),
		}
	return {
		"id": definition["id"],
		"display_name": definition["attributes"]["display_name"],
		"transformed": false,
		"components": [definition["id"]],
	}


func _validate_terrain_form_metadata(state: Dictionary, terrain_id: String) -> Dictionary:
	var metadata: Dictionary = state["cards"]["instances"][terrain_id]["metadata"]
	var form_keys := ["terrain_form_id", "terrain_form_name", "terrain_components"]
	var present_count := 0
	for key in form_keys:
		if metadata.has(key):
			present_count += 1
	if present_count == 0:
		return _success()
	if present_count != form_keys.size():
		return _failure("JCP_TERRAIN_FORM_METADATA_INVALID", "La identidad transformada del Terreno esta incompleta.")
	if not metadata["terrain_form_id"] is String or not metadata["terrain_form_name"] is String or not metadata["terrain_components"] is Array:
		return _failure("JCP_TERRAIN_FORM_METADATA_INVALID", "La identidad transformada del Terreno tiene tipos invalidos.")
	var recipe: Dictionary = _terrain_recipe_by_id(metadata["terrain_form_id"])
	if recipe.is_empty():
		return _failure("JCP_TERRAIN_FORM_UNKNOWN", "La identidad transformada del Terreno no pertenece al reglamento.")
	if metadata["terrain_form_name"] != recipe["display_name"] or metadata["terrain_components"] != recipe["components"]:
		return _failure("JCP_TERRAIN_FORM_RECIPE_MISMATCH", "La identidad transformada no coincide con su receta ordenada.")
	if _definition_for_instance(state, terrain_id)["id"] != recipe["components"][1]:
		return _failure("JCP_TERRAIN_FORM_CARRIER_INVALID", "La carta fisica que conserva el Terreno no es el componente entrante.")
	return _success()


func _effective_stats(state: Dictionary, creature_id: String) -> Dictionary:
	var attributes: Dictionary = _creature_attributes(state, creature_id)
	var metadata: Dictionary = state["cards"]["instances"][creature_id]["metadata"]
	var attack: int = attributes["attack"]
	var defense: int = attributes["defense"]
	if metadata.get("temporary_bonus_turn", -1) == state["turn"]["turn_number"]:
		attack += metadata.get("temporary_attack_bonus", 0)
		defense += metadata.get("temporary_defense_bonus", 0)
	attack = max(0, attack - metadata.get("steam_attack_penalty", 0))
	var player_id: int = metadata.get("owner_id", -1)
	var position: String = metadata.get("position", "attack")
	if _active_base_definition_id(state, creature_id) == "M10" and position == "guard":
		attack += 1
	var attached_definitions: Array = []
	for attachment_id in state["cards"]["zones"][_zone_id("attachments", player_id)]["cards"]:
		if state["cards"]["instances"][attachment_id]["metadata"].get("linked_to", "") != creature_id:
			continue
		var attachment_definition_id: String = _definition_for_instance(state, attachment_id)["id"]
		attached_definitions.append(attachment_definition_id)
		match attachment_definition_id:
			"E01":
				attack += 1
			"E02":
				defense += 1
			"E03":
				if position == "guard":
					attack += 1
					defense += 1
			"E05":
				defense += 1
			"E06":
				attack += 1
	if "E05" in attached_definitions and "E06" in attached_definitions:
		attack += 1
		defense += 1
	for support_id in state["cards"]["zones"][_zone_id("support", player_id)]["cards"]:
		var support_metadata: Dictionary = state["cards"]["instances"][support_id]["metadata"]
		if not support_metadata.get("face_up", false) or not support_metadata.get("active", false):
			continue
		if _definition_for_instance(state, support_id)["id"] == "G04" and position == "guard":
			defense += 1
	for terrain_id in state["cards"]["zones"][_zone_id("terrain", player_id)]["cards"]:
		if state["cards"]["instances"][terrain_id]["metadata"].has("terrain_form_id"):
			continue
		var terrain_definition_id: String = _definition_for_instance(state, terrain_id)["id"]
		var element: String = attributes.get("element", "neutral")
		if terrain_definition_id == "R01" and element == "nature":
			defense += 1
		elif terrain_definition_id == "R02" and element == "water":
			defense += 1
		elif terrain_definition_id == "R03" and element == "fire":
			attack += 1
	return {
		"attack": attack,
		"defense": defense,
		"base_attack": attributes["attack"],
		"base_defense": attributes["defense"],
	}


func _card_view_for(state: Dictionary, viewer_id: int) -> Dictionary:
	var view_result: Dictionary = CardState.view_for(state["cards"], viewer_id)
	if not view_result["ok"]:
		return view_result
	var value: Dictionary = view_result["value"]
	for player_id in state["turn"]["order"]:
		for zone_kind in ["creatures", "support"]:
			var zone_id: String = _zone_id(zone_kind, player_id)
			var zone_view: Dictionary = value["zones"][zone_id]
			var visible_cards: Array = []
			var concealed_any := false
			for slot in zone_view["slots"]:
				if slot["card"] == null:
					continue
				var card: Dictionary = slot["card"]
				if zone_kind == "creatures":
					card["effective_stats"] = _effective_stats(state, card["instance"]["id"])
					if card["instance"]["metadata"].has("fusion_entity"):
						card["fusion_identity"] = card["instance"]["metadata"]["fusion_entity"].duplicate(true)
				if viewer_id != player_id and not card["instance"]["metadata"].get("face_up", true):
					slot["visible"] = false
					slot["card"] = null
					concealed_any = true
				else:
					visible_cards.append(card)
			zone_view["cards"] = visible_cards
			if concealed_any:
				zone_view["identities_visible"] = false
		var terrain_zone_id: String = _zone_id("terrain", player_id)
		var terrain_zone_view: Dictionary = value["zones"][terrain_zone_id]
		for card in terrain_zone_view["cards"]:
			card["terrain_identity"] = _terrain_identity(state, card["instance"]["id"])
		for slot in terrain_zone_view["slots"]:
			if slot["card"] != null:
				slot["card"]["terrain_identity"] = _terrain_identity(state, slot["card"]["instance"]["id"])
	return {"ok": true, "code": "OK", "message": "", "value": value}


func _turn_requires_draw(state: Dictionary) -> bool:
	return not (
		state["turn"]["turn_number"] == 1
		and TurnState.active_player(state["turn"]) == state["config"]["starting_player"]
	)


func _draw_one(state: Dictionary, player_id: int) -> Dictionary:
	var deck_id: String = _zone_id("deck", player_id)
	var hand_id: String = _zone_id("hand", player_id)
	var deck_result: Dictionary = CardState.zone_card_ids(state["cards"], deck_id)
	if not deck_result["ok"]:
		return deck_result
	if deck_result["value"].is_empty():
		return _failure("JCP_DECK_EMPTY", "El jugador debe robar, pero su baraja esta vacia.")
	var draw_result: Dictionary = CardOperations.draw(state["cards"], deck_id, hand_id, 1)
	if not draw_result["ok"]:
		return draw_result
	var next_state: Dictionary = state.duplicate(true)
	next_state["cards"] = draw_result["value"]
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"state": next_state,
		"instance_id": draw_result["drawn"][0],
	}


func _create_card_state(player_ids: Array, seed: int) -> Dictionary:
	var deck_result: Dictionary = DeckBuilder.build(_card_specs(), "jcp", 1)
	if not deck_result["ok"]:
		return deck_result
	var definitions: Array = deck_result["definitions"]
	var instances: Array = deck_result["instances"]
	var deck_cards: Dictionary = {"0": [], "1": []}
	for instance in instances:
		var owner_id: int = instance["metadata"]["copy_index"]
		instance["metadata"]["owner_id"] = owner_id
		deck_cards[_player_key(owner_id)].append(instance["id"])

	var zones: Array = []
	var placements: Dictionary = {}
	for player_id in player_ids:
		var zone_results: Array = [
			ZoneDefinition.create(_zone_id("deck", player_id), ZoneDefinition.VISIBILITY_HIDDEN, player_id),
			ZoneDefinition.create(_zone_id("hand", player_id), ZoneDefinition.VISIBILITY_OWNER, player_id),
			ZoneDefinition.create(_zone_id("creatures", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id, [], 5),
			ZoneDefinition.create(_zone_id("fusion_materials", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id),
			ZoneDefinition.create(_zone_id("support", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id, [], 5),
			ZoneDefinition.create(_zone_id("attachments", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id),
			ZoneDefinition.create(_zone_id("terrain", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id, [], 1),
			ZoneDefinition.create(_zone_id("graveyard", player_id), ZoneDefinition.VISIBILITY_PUBLIC, player_id),
		]
		for zone_result in zone_results:
			if not zone_result["ok"]:
				return zone_result
			zones.append(zone_result["value"])
			placements[zone_result["value"]["id"]] = []
		placements[_zone_id("deck", player_id)] = deck_cards[_player_key(player_id)]
	var cards_result: Dictionary = CardState.create(definitions, instances, zones, placements)
	if not cards_result["ok"]:
		return cards_result
	var rng_result: Dictionary = DeterministicRng.create(seed)
	if not rng_result["ok"]:
		return rng_result
	var shuffled_cards: Dictionary = cards_result["value"]
	var rng_state: Dictionary = rng_result["value"]
	for player_id in player_ids:
		var shuffle_result: Dictionary = CardRandomizer.shuffle_zone(
			shuffled_cards,
			_zone_id("deck", player_id),
			rng_state
		)
		if not shuffle_result["ok"]:
			return shuffle_result
		shuffled_cards = shuffle_result["value"]
		rng_state = shuffle_result["rng_state"]
	for player_id in player_ids:
		var deal_result: Dictionary = CardOperations.draw(
			shuffled_cards,
			_zone_id("deck", player_id),
			_zone_id("hand", player_id),
			5
		)
		if not deal_result["ok"]:
			return deal_result
		shuffled_cards = deal_result["value"]
	return {"ok": true, "code": "OK", "message": "", "value": shuffled_cards}


func _card_specs() -> Array:
	var specs: Array = []
	var creature_rows := [
		[1, 2, 0], [1, 1, 2], [1, 0, 3], [1, 1, 1], [1, 1, 1], [1, 0, 2],
		[1, 0, 1], [2, 3, 1], [2, 2, 2], [2, 1, 3], [3, 4, 2], [3, 3, 2],
		[3, 2, 2], [4, 4, 4], [4, 3, 3], [5, 4, 4], [6, 7, 4], [7, 5, 6],
	]
	var creature_elements := [
		"nature", "water", "fire", "neutral", "fire", "water",
		"nature", "water", "neutral", "nature", "neutral", "water",
		"neutral", "neutral", "nature", "neutral", "fire", "fire",
	]
	var creature_identities := [
		["Lobo de Zarza", ["wolf"], ["bestial"], "quadruped", ["bestial"]],
		["Ondina del Remanso", ["elemental"], [], "humanoid", ["sapient", "manipulator"]],
		["Núcleo de Escoria", ["elemental"], [], "amorphous", []],
		["Goblin Rebuscador", ["goblin"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Goblin Portaantorchas", ["goblin"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Muro de Marea", ["elemental"], [], "amorphous", []],
		["Cachorro de la Senda Verde", ["wolf"], ["bestial"], "quadruped", ["bestial"]],
		["Oleada Errante", ["elemental"], [], "amorphous", []],
		["Goblin Pendenciero", ["goblin"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Goblin Trampero del Matorral", ["goblin"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Troll Quebrapuertas", ["troll"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Oráculo del Espejo de Agua", ["elemental"], [], "humanoid", ["sapient", "manipulator", "channeler"]],
		["Troll Guarda del Puente", ["troll"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Lobo Gris del Páramo", ["wolf"], ["bestial"], "quadruped", ["bestial"]],
		["Troll Chamán del Musgo", ["troll"], ["humanoid"], "humanoid", ["sapient", "manipulator", "channeler"]],
		["Troll Cobrador del Paso", ["troll"], ["humanoid"], "humanoid", ["sapient", "manipulator"]],
		["Dragón de la Caldera", ["dragon"], ["draconic"], "winged", ["bestial"]],
		["Dragón Rojo de las Dos Coronas", ["dragon"], ["draconic"], "winged", ["sapient", "manipulator"]],
	]
	var creature_effects := [
		"Sin habilidad.",
		"Sin habilidad.",
		"Sin habilidad.",
		"Sin habilidad.",
		"Al declarar un ataque, obtiene +1 ATQ durante ese combate.",
		"Cuando sea revelada al recibir un ataque, obtiene +1 DEF durante ese combate.",
		"Cuando sea destruida, roba 1 carta.",
		"Sin habilidad.",
		"Una vez por turno, durante una fase principal propia, puede pagar 1 de Energia para obtener +1 ATQ hasta el final del turno.",
		"Mientras este en postura de guardia, obtiene +1 ATQ.",
		"Sin habilidad.",
		"Al entrar boca arriba, su controlador mira una carta de apoyo boca abajo del rival sin revelarla publicamente.",
		"Una vez por turno, cuando otra criatura propia sea atacada, puede pasar a ser el objetivo de ese ataque.",
		"Sin habilidad.",
		"Al entrar boca arriba, otra criatura propia obtiene +1 ATQ y +1 DEF hasta el final del turno.",
		"La primera vez en cada turno que destruya una criatura en combate, recuperas 1 de Energia.",
		"Sin habilidad.",
		"La primera vez en cada turno que destruya una criatura en combate y sobreviva, obtiene 1 ataque adicional ese turno. Solo una vez por turno.",
	]
	var spell_effects := [
		"Una criatura que controlas obtiene +2 ATQ hasta el final del turno.",
		"Una criatura que controlas obtiene +2 DEF hasta el final del turno.",
		"Devuelve a la mano una criatura enemiga visible de coste impreso 2 o menos.",
		"Tus criaturas en postura de guardia obtienen +1 DEF.",
		"La primera criatura que pase de guardia a ataque en tu turno obtiene +1 ATQ hasta el final del turno.",
		"Cuando una criatura que controlas sea atacada, obtiene +2 DEF durante ese combate.",
		"Cuando una criatura que controlas sea atacada, devuelvela a tu mano.",
	]
	var trap_effects := [
		"Cuando una criatura enemiga de coste 2 o menos ataque, destruyela.",
		"Cuando una criatura que controlas sea atacada, el atacante obtiene -2 ATQ durante ese combate.",
		"Cuando el rival active una Magia, anula su efecto; despues, ambas cartas van al Cementerio.",
		"Cuando una criatura enemiga pase voluntariamente de guardia a ataque, devuelvela a guardia.",
		"Cuando el rival vincule un equipo u objeto, destruye esa carta vinculada.",
		"Cuando una criatura que controlas sea destruida en combate, destruye a la criatura enemiga que combatio con ella si sigue en campo.",
	]
	var item_effects := [
		"Equipo. El portador obtiene +1 ATQ. Requiere Manipulador.",
		"Equipo. El portador obtiene +1 DEF.",
		"Equipo. En guardia, el portador obtiene +1 ATQ y +1 DEF. Requiere Manipulador.",
		"Artefacto. Una vez por turno, permite trasladar un equipo entre criaturas propias compatibles.",
		"Equipo del Bastion. El portador obtiene +1 DEF.",
		"Equipo del Bastion. El portador obtiene +1 ATQ. Requiere Manipulador.",
	]
	for index in range(creature_rows.size()):
		var row: Array = creature_rows[index]
		var identity: Array = creature_identities[index]
		var creature_spec: Dictionary = _card_spec(
			"M%02d" % (index + 1),
			identity[0],
			"creature",
			row[0],
			row[1],
			row[2],
			creature_effects[index]
		)
		creature_spec["attributes"]["element"] = creature_elements[index]
		creature_spec["attributes"]["families"] = identity[1].duplicate()
		creature_spec["attributes"]["superfamilies"] = identity[2].duplicate()
		creature_spec["attributes"]["anatomy"] = identity[3]
		creature_spec["attributes"]["aptitudes"] = identity[4].duplicate()
		creature_spec["attributes"]["properties"] = []
		specs.append(creature_spec)
	for index in range(7):
		var spell_spec: Dictionary = _card_spec("G%02d" % (index + 1), "Magia G%02d" % (index + 1), "spell", 0, 0, 0, spell_effects[index])
		spell_spec["attributes"]["spell_mode"] = "main" if index < 3 else ("persistent" if index < 5 else "reactive")
		specs.append(spell_spec)
	for index in range(6):
		var trap_spec: Dictionary = _card_spec("T%02d" % (index + 1), "Trampa T%02d" % (index + 1), "trap", 0, 0, 0, trap_effects[index])
		trap_spec["attributes"]["spell_mode"] = "reactive"
		specs.append(trap_spec)
	for index in range(6):
		var item_spec: Dictionary = _card_spec("E%02d" % (index + 1), "Objeto E%02d" % (index + 1), "item", 0, 0, 0, item_effects[index])
		item_spec["attributes"]["item_mode"] = "artifact" if index == 3 else "equipment"
		item_spec["attributes"]["required_aptitudes"] = ["manipulator"] if index in [0, 2, 5] else []
		item_spec["attributes"]["allowed_anatomies"] = []
		specs.append(item_spec)
	for terrain in [
		["R01", "Bosque", "nature", "Tus criaturas de Naturaleza obtienen +1 DEF."],
		["R02", "Lago", "water", "Tus criaturas de Agua obtienen +1 DEF."],
		["R03", "Volcan", "fire", "Tus criaturas de Fuego obtienen +1 ATQ."],
	]:
		var spec: Dictionary = _card_spec(terrain[0], terrain[1], "terrain", 0, 0, 0, terrain[3])
		spec["attributes"]["element"] = terrain[2]
		specs.append(spec)
	return specs


func _card_spec(
	definition_id: String,
	display_name: String,
	card_type: String,
	cost: int,
	attack: int,
	defense: int,
	effect_text: String
) -> Dictionary:
	return {
		"id": definition_id,
		"count": 2,
		"attributes": {
			"display_name": display_name,
			"card_type": card_type,
			"cost": cost,
			"attack": attack,
			"defense": defense,
			"effect_text": effect_text,
		},
		"tags": [card_type, "prototype"],
	}


func _zone_id(kind: String, player_id: int) -> String:
	return "%s:%d" % [kind, player_id]


func _opponent_id(state: Dictionary, player_id: int) -> int:
	for candidate_id in state["turn"]["order"]:
		if candidate_id != player_id:
			return candidate_id
	return -1


func _player_key(player_id: int) -> String:
	return str(player_id)


func _next_phase(current_phase: String) -> String:
	var index: int = PHASE_ORDER.find(current_phase)
	if index < 0 or index + 1 >= PHASE_ORDER.size():
		return PHASE_START
	return PHASE_ORDER[index + 1]


func _new_phase_state() -> Dictionary:
	return PhaseMachine.create({
		"initial": PHASE_START,
		"terminal": [PHASE_FINISHED],
		"transitions": {
			PHASE_START: [PHASE_DRAW, PHASE_FINISHED],
			PHASE_DRAW: [PHASE_MAIN_1, PHASE_FINISHED],
			PHASE_MAIN_1: [PHASE_COMBAT, PHASE_FINISHED],
			PHASE_COMBAT: [PHASE_MAIN_2, PHASE_FINISHED],
			PHASE_MAIN_2: [PHASE_END, PHASE_FINISHED],
			PHASE_END: [PHASE_FINISHED],
			PHASE_FINISHED: [],
		},
	})


func _normalize_config(config: Dictionary) -> Dictionary:
	var allowed_keys := ["energy_cap", "player_names", "starting_life", "starting_player"]
	for key in config.keys():
		if key not in allowed_keys:
			return _failure("JCP_CONFIG_KEY_UNKNOWN", "Opcion desconocida: %s" % key)
	var names: Variant = config.get("player_names", ["Jugador 1", "Jugador 2"])
	if not names is Array or names.size() != 2:
		return _failure("JCP_PLAYER_COUNT_INVALID", "El primer prototipo requiere exactamente dos jugadores.")
	var normalized_names: Array = []
	for name in names:
		if not name is String or name.strip_edges().is_empty() or name.length() > 32:
			return _failure("JCP_PLAYER_NAME_INVALID", "Los nombres deben contener entre 1 y 32 caracteres.")
		normalized_names.append(name.strip_edges())
	var starting_life: Variant = config.get("starting_life", 30)
	var energy_cap: Variant = config.get("energy_cap", 10)
	var starting_player: Variant = config.get("starting_player", 0)
	if not starting_life is int or starting_life < 1 or starting_life > 999:
		return _failure("JCP_STARTING_LIFE_INVALID", "La vida inicial debe estar entre 1 y 999.")
	if not energy_cap is int or energy_cap < 1 or energy_cap > 99:
		return _failure("JCP_ENERGY_CAP_INVALID", "El limite de energia debe estar entre 1 y 99.")
	if not starting_player is int or starting_player < 0 or starting_player >= normalized_names.size():
		return _failure("JCP_STARTING_PLAYER_INVALID", "El jugador inicial no existe.")
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": {
			"player_names": normalized_names,
			"starting_life": starting_life,
			"energy_cap": energy_cap,
			"starting_player": starting_player,
		},
	}


func _transition_success(state: Dictionary, events: Array) -> Dictionary:
	return {"ok": true, "state": state, "events": events}


func _transition_failure(result: Dictionary) -> Dictionary:
	return {"ok": false, "code": result["code"], "message": result["message"]}


func _success() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
