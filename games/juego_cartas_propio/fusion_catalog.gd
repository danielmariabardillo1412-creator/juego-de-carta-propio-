extends RefCounted
## Catalogo especifico de Fusiones aprobadas para el juego de cartas propio.
##
## No modifica el duelo. Traduce cartas fisicas del catalogo del juego al perfil
## canonico que consume FusionRecipeService y delega alli toda coincidencia.

const FusionRecipeService = preload("res://games/juego_cartas_propio/fusion_recipe_service.gd")


static func recipes() -> Array:
	return [
		{
			"id": "recipe.f001_nature_alpha",
			"materials": [
				{"family": "wolf", "element": "nature"},
				{"family": "wolf", "element": "nature"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f001_nature_alpha",
				"display_name": "Alfa de la Manada de Naturaleza",
				"cost": 3,
				"attack": 3,
				"defense": 2,
				"families": ["wolf"],
				"superfamilies": ["bestial"],
				"elements": ["nature"],
				"anatomy": "quadruped",
				"aptitudes": ["bestial"],
				"properties": [],
				"fusion_mode": "integration",
				"effect_text": "La primera vez en cada uno de tus turnos que otra criatura propia declare un ataque, esa criatura obtiene +1 ATQ durante ese combate.",
			},
		},
		{
			"id": "recipe.f010_neutral_band",
			"materials": [
				{"family": "goblin", "element": "neutral"},
				{"family": "goblin", "element": "neutral"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f010_neutral_band",
				"display_name": "Banda Goblin",
				"cost": 3,
				"attack": 3,
				"defense": 3,
				"families": ["goblin"],
				"superfamilies": ["humanoid"],
				"elements": ["neutral"],
				"anatomy": "humanoid",
				"aptitudes": ["sapient", "manipulator"],
				"properties": [],
				"fusion_mode": "formation",
				"effect_text": "Una vez por turno, durante una fase principal propia, puedes pagar 1 de Energia: una criatura propia obtiene +1 ATQ hasta el final del turno.",
			},
		},
		{
			"id": "recipe.f011_torch_band",
			"materials": [
				{"family": "goblin", "element": "neutral"},
				{"family": "goblin", "element": "fire"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f011_torch_band",
				"display_name": "Banda de Antorchas",
				"cost": 3,
				"attack": 3,
				"defense": 2,
				"families": ["goblin"],
				"superfamilies": ["humanoid"],
				"elements": ["neutral", "fire"],
				"anatomy": "humanoid",
				"aptitudes": ["sapient", "manipulator"],
				"properties": [],
				"fusion_mode": "formation",
				"effect_text": "Al atacar, obtiene +1 ATQ durante ese combate. Si controlas otro Goblin boca arriba, obtiene ademas +1 DEF durante ese combate.",
			},
		},
		{
			"id": "recipe.f012_thicket_company",
			"materials": [
				{"family": "goblin", "element": "neutral"},
				{"family": "goblin", "element": "nature"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f012_thicket_company",
				"display_name": "Cuadrilla del Matorral",
				"cost": 3,
				"attack": 2,
				"defense": 4,
				"families": ["goblin"],
				"superfamilies": ["humanoid"],
				"elements": ["neutral", "nature"],
				"anatomy": "humanoid",
				"aptitudes": ["sapient", "manipulator"],
				"properties": [],
				"fusion_mode": "formation",
				"effect_text": "Una vez por turno, cuando sea atacada, la criatura atacante obtiene -1 ATQ durante ese combate.",
			},
		},
		{
			"id": "recipe.f018_two_headed_troll",
			"materials": [
				{"family": "troll", "element": "neutral"},
				{"family": "troll", "element": "neutral"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f018_two_headed_troll",
				"display_name": "Troll Bicéfalo",
				"cost": 6,
				"attack": 6,
				"defense": 6,
				"families": ["troll"],
				"superfamilies": ["humanoid"],
				"elements": ["neutral"],
				"anatomy": "humanoid",
				"aptitudes": ["sapient", "manipulator"],
				"properties": [],
				"fusion_mode": "integration",
				"effect_text": "Una vez por turno, si fuera a ser destruido en combate, no es destruido y pasa a guardia.",
			},
		},
		{
			"id": "recipe.f067_water_major",
			"materials": [
				{"family": "elemental", "element": "water"},
				{"family": "elemental", "element": "water"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f067_water_major",
				"display_name": "Elemental Mayor de Agua",
				"cost": 4,
				"attack": 4,
				"defense": 4,
				"families": ["elemental"],
				"superfamilies": [],
				"elements": ["water"],
				"anatomy": "amorphous",
				"aptitudes": [],
				"properties": [],
				"fusion_mode": "integration",
				"effect_text": "Al comenzar el primer combate en el que participe cada turno, su controlador elige: obtiene +1 ATQ o +1 DEF durante ese combate.",
			},
		},
		{
			"id": "recipe.f068_steam_elemental",
			"materials": [
				{"family": "elemental", "element": "fire"},
				{"family": "elemental", "element": "water"},
			],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f068_steam_elemental",
				"display_name": "Elemental de Vapor",
				"cost": 3,
				"attack": 2,
				"defense": 4,
				"families": ["elemental"],
				"superfamilies": [],
				"elements": ["fire", "water"],
				"anatomy": "amorphous",
				"aptitudes": [],
				"properties": [],
				"fusion_mode": "integration",
				"effect_text": "Al entrar, una criatura enemiga boca arriba obtiene -1 ATQ hasta el final del siguiente turno de su controlador.",
			},
		},
		{
			"id": "recipe.f005_fire_dragon",
			"materials": [{"family": "dragon", "element": "fire"}, {"family": "dragon", "element": "fire"}],
			"ordered": false,
			"result": {
				"identity_id": "fusion.f005_fire_dragon",
				"display_name": "Dragón Bicéfalo Elemental",
				"cost": 8,
				"attack": 8,
				"defense": 8,
				"families": ["dragon"],
				"superfamilies": ["draconic"],
				"elements": ["fire"],
				"anatomy": "winged",
				"aptitudes": ["bestial"],
				"properties": [],
				"fusion_mode": "integration",
				"effect_text": "La primera vez en cada turno que destruya una criatura en combate y sobreviva, obtiene 1 ataque adicional ese turno. Solo una vez por turno.",
			},
		},
	]


static func profile_for_card(cards: Dictionary, instance_id: String) -> Dictionary:
	if instance_id.is_empty() or not cards.has("instances") or not cards.has("definitions"):
		return _failure("JCP_FUSION_CARD_STATE_INVALID", "Falta el estado de cartas necesario para construir el material.")
	if not cards["instances"] is Dictionary or not cards["instances"].has(instance_id):
		return _failure("JCP_FUSION_CARD_INSTANCE_UNKNOWN", "La carta fisica indicada no existe.")
	var instance: Dictionary = cards["instances"][instance_id]
	var definition_id: Variant = instance.get("definition_id", null)
	if not definition_id is String or not cards["definitions"] is Dictionary or not cards["definitions"].has(definition_id):
		return _failure("JCP_FUSION_CARD_DEFINITION_UNKNOWN", "La carta fisica no tiene una definicion conocida.")
	var definition: Dictionary = cards["definitions"][definition_id]
	var attributes: Variant = definition.get("attributes", null)
	if not attributes is Dictionary or attributes.get("card_type", "") != "creature":
		return _failure("JCP_FUSION_CARD_NOT_CREATURE", "Solo una criatura puede convertirse en material de criatura.")
	var metadata: Variant = instance.get("metadata", null)
	if not metadata is Dictionary or not metadata.get("owner_id", null) is int:
		return _failure("JCP_FUSION_CARD_OWNER_INVALID", "La carta fisica necesita un controlador valido.")
	for list_key in ["families", "superfamilies", "aptitudes", "properties"]:
		if not attributes.get(list_key, null) is Array:
			return _failure("JCP_FUSION_CARD_PROFILE_INVALID", "La criatura no contiene un perfil de identidad completo.")
	if not attributes.get("element", null) is String or not attributes.get("anatomy", null) is String:
		return _failure("JCP_FUSION_CARD_PROFILE_INVALID", "La criatura no contiene elemento o anatomia validos.")
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": {
			"definition_id": definition_id,
			"fusion_identity_id": "",
			"families": attributes["families"].duplicate(),
			"superfamilies": attributes["superfamilies"].duplicate(),
			"elements": [attributes["element"]],
			"anatomy": attributes["anatomy"],
			"aptitudes": attributes["aptitudes"].duplicate(),
			"properties": attributes["properties"].duplicate(),
			"owner_id": metadata["owner_id"],
			"face_up": metadata.get("face_up", false),
			"physical_instance_ids": [instance_id],
		},
	}


static func find_for_cards(cards: Dictionary, instance_ids: Array, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	var profiles_result: Dictionary = _profiles_for_cards(cards, instance_ids)
	if not profiles_result["ok"]:
		return profiles_result
	var match_result: Dictionary = FusionRecipeService.find_recipe(recipes(), profiles_result["value"], known_anatomies, known_aptitudes)
	if not match_result["ok"]:
		return match_result
	if not match_result["value"].is_empty() and not _specific_pair_is_valid(match_result["value"], profiles_result["value"]):
		return {"ok": true, "code": "OK", "message": "", "value": {}}
	return match_result


static func build_for_cards(cards: Dictionary, instance_ids: Array, generated_id: String, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	var profiles_result: Dictionary = _profiles_for_cards(cards, instance_ids)
	if not profiles_result["ok"]:
		return profiles_result
	var profiles: Array = profiles_result["value"]
	var match_result: Dictionary = FusionRecipeService.find_recipe(recipes(), profiles, known_anatomies, known_aptitudes)
	if not match_result["ok"]:
		return match_result
	if match_result["value"].is_empty() or not _specific_pair_is_valid(match_result["value"], profiles):
		return _failure("JCP_FUSION_RECIPE_NOT_FOUND", "Las criaturas no satisfacen una receta registrada.")
	return FusionRecipeService.build_generated_identity(match_result["value"], generated_id, profiles, known_anatomies, known_aptitudes)


static func _specific_pair_is_valid(match_value: Dictionary, profiles: Array) -> bool:
	var identity_id: String = match_value["recipe"]["result"]["identity_id"]
	if identity_id == "fusion.f018_two_headed_troll":
		return profiles[0]["definition_id"] != profiles[1]["definition_id"]
	return true


static func _profiles_for_cards(cards: Dictionary, instance_ids: Array) -> Dictionary:
	if instance_ids.size() != 2:
		return _failure("JCP_FUSION_CARD_COUNT_INVALID", "Se necesitan exactamente dos cartas fisicas.")
	var profiles: Array = []
	for instance_id in instance_ids:
		if not instance_id is String:
			return _failure("JCP_FUSION_CARD_INSTANCE_UNKNOWN", "El identificador de material no es textual.")
		var profile_result: Dictionary = profile_for_card(cards, instance_id)
		if not profile_result["ok"]:
			return profile_result
		profiles.append(profile_result["value"])
	return {"ok": true, "code": "OK", "message": "", "value": profiles}


static func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
