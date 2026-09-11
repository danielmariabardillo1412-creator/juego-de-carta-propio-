extends RefCounted
## Contrato puro para validar y resolver recetas de Fusion sin activar contenido jugable.
##
## No modifica el estado del duelo. Las recetas concretas se conectaran al modulo
## cuando sus materiales y resultados tengan identidad y valores aprobados.

const FUSION_MODES := ["integration", "formation", "assembly", "convergence", "colony"]
const RECIPE_KEYS := ["id", "materials", "ordered", "result"]
const MATERIAL_KEYS := [
	"anatomy",
	"aptitudes",
	"definition_id",
	"element",
	"family",
	"fusion_identity_id",
	"properties",
	"superfamily",
]
const RESULT_KEYS := [
	"anatomy",
	"aptitudes",
	"attack",
	"cost",
	"defense",
	"display_name",
	"effect_text",
	"elements",
	"families",
	"fusion_mode",
	"identity_id",
	"properties",
	"superfamilies",
]
const PROFILE_KEYS := [
	"anatomy",
	"aptitudes",
	"definition_id",
	"elements",
	"face_up",
	"families",
	"fusion_identity_id",
	"owner_id",
	"physical_instance_ids",
	"properties",
	"superfamilies",
]
const GENERATED_KEYS := [
	"anatomy",
	"aptitudes",
	"attack",
	"contained_physical_ids",
	"cost",
	"defense",
	"display_name",
	"effect_text",
	"elements",
	"families",
	"fusion_identity_id",
	"fusion_mode",
	"id",
	"owner_id",
	"properties",
	"source_fusion_ids",
	"superfamilies",
]


static func validate_catalog(recipes: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not recipes is Array:
		return _failure("JCP_FUSION_CATALOG_TYPE_INVALID", "El catalogo de Fusiones debe ser una lista.")
	var recipe_ids: Dictionary = {}
	var result_ids: Dictionary = {}
	for index in range(recipes.size()):
		var check := validate_recipe(recipes[index], known_anatomies, known_aptitudes)
		if not check["ok"]:
			return _failure(check["code"], "Receta %d: %s" % [index, check["message"]])
		var recipe: Dictionary = recipes[index]
		if recipe_ids.has(recipe["id"]):
			return _failure("JCP_FUSION_RECIPE_ID_DUPLICATED", "Dos recetas comparten identificador.")
		if result_ids.has(recipe["result"]["identity_id"]):
			return _failure("JCP_FUSION_RESULT_ID_DUPLICATED", "Dos recetas generan la misma identidad.")
		recipe_ids[recipe["id"]] = true
		result_ids[recipe["result"]["identity_id"]] = true
	return _success()


static func validate_recipe(recipe: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not recipe is Dictionary:
		return _failure("JCP_FUSION_RECIPE_TYPE_INVALID", "Una receta debe ser un diccionario.")
	if _sorted_keys(recipe) != RECIPE_KEYS:
		return _failure("JCP_FUSION_RECIPE_KEYS_INVALID", "La receta contiene claves ausentes o desconocidas.")
	if not _valid_identifier(recipe["id"]):
		return _failure("JCP_FUSION_RECIPE_ID_INVALID", "El identificador de receta no es valido.")
	if not recipe["ordered"] is bool:
		return _failure("JCP_FUSION_ORDER_FLAG_INVALID", "ordered debe ser booleano.")
	if not recipe["materials"] is Array or recipe["materials"].size() != 2:
		return _failure("JCP_FUSION_MATERIAL_COUNT_INVALID", "La V0.1 exige exactamente dos materiales.")
	for requirement in recipe["materials"]:
		var requirement_check := _validate_requirement(requirement, known_anatomies, known_aptitudes)
		if not requirement_check["ok"]:
			return requirement_check
	return _validate_result(recipe["result"], known_anatomies, known_aptitudes)


static func find_recipe(recipes: Array, material_profiles: Array, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	var catalog_check := validate_catalog(recipes, known_anatomies, known_aptitudes)
	if not catalog_check["ok"]:
		return catalog_check
	if material_profiles.size() != 2:
		return _failure("JCP_FUSION_PROFILE_COUNT_INVALID", "Se requieren dos perfiles de material.")
	for profile in material_profiles:
		var profile_check := validate_material_profile(profile, known_anatomies, known_aptitudes)
		if not profile_check["ok"]:
			return profile_check
	if material_profiles[0]["owner_id"] != material_profiles[1]["owner_id"]:
		return _failure("JCP_FUSION_OWNER_MISMATCH", "Los materiales deben pertenecer al mismo controlador.")
	if not material_profiles[0]["face_up"] or not material_profiles[1]["face_up"]:
		return {"ok": true, "code": "OK", "message": "", "value": {}}
	var all_physical_ids: Array = material_profiles[0]["physical_instance_ids"] + material_profiles[1]["physical_instance_ids"]
	if _has_duplicates(all_physical_ids):
		return _failure("JCP_FUSION_PHYSICAL_MATERIAL_REUSED", "Una carta fisica no puede ocupar dos materiales.")

	var candidates: Array = []
	for recipe in recipes:
		var direct := _match_pair(recipe, material_profiles, [0, 1])
		if direct:
			candidates.append({"recipe": recipe, "mapping": [0, 1], "specificity": _recipe_specificity(recipe)})
		elif not recipe["ordered"] and _match_pair(recipe, material_profiles, [1, 0]):
			candidates.append({"recipe": recipe, "mapping": [1, 0], "specificity": _recipe_specificity(recipe)})
	if candidates.is_empty():
		return {"ok": true, "code": "OK", "message": "", "value": {}}
	candidates.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return left["specificity"] > right["specificity"])
	var best: Dictionary = candidates[0]
	if candidates.size() > 1 and candidates[1]["specificity"] == best["specificity"]:
		return _failure("JCP_FUSION_RECIPE_AMBIGUOUS", "Varias recetas igualmente especificas coinciden.")
	return {"ok": true, "code": "OK", "message": "", "value": best.duplicate(true)}


static func validate_material_profile(profile: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not profile is Dictionary or _sorted_keys(profile) != PROFILE_KEYS:
		return _failure("JCP_FUSION_PROFILE_INVALID", "El perfil de material no tiene el contrato canonico.")
	if not profile["owner_id"] is int or profile["owner_id"] < 0 or not profile["face_up"] is bool:
		return _failure("JCP_FUSION_PROFILE_OWNER_INVALID", "Propietario o visibilidad del material no son validos.")
	if not profile["definition_id"] is String or not profile["fusion_identity_id"] is String:
		return _failure("JCP_FUSION_PROFILE_IDENTITY_INVALID", "Las identidades del material deben ser cadenas.")
	if profile["definition_id"].is_empty() == profile["fusion_identity_id"].is_empty():
		return _failure("JCP_FUSION_PROFILE_IDENTITY_INVALID", "Un material debe ser carta fisica o Fusion, pero no ambas.")
	if profile["anatomy"] not in known_anatomies:
		return _failure("JCP_FUSION_PROFILE_ANATOMY_INVALID", "La anatomia del material no es conocida.")
	for key in ["families", "superfamilies", "elements", "properties", "physical_instance_ids"]:
		var list_check := _validate_unique_strings(profile[key], false)
		if not list_check["ok"]:
			return _failure("JCP_FUSION_PROFILE_LIST_INVALID", "%s no es una lista valida." % key)
	if profile["physical_instance_ids"].is_empty():
		return _failure("JCP_FUSION_PROFILE_PHYSICAL_EMPTY", "Todo material debe contener al menos una carta fisica.")
	var aptitude_check := _validate_known_tags(profile["aptitudes"], known_aptitudes, false)
	if not aptitude_check["ok"]:
		return _failure("JCP_FUSION_PROFILE_APTITUDES_INVALID", aptitude_check["message"])
	return _success()


static func build_generated_identity(match_value: Dictionary, generated_id: String, material_profiles: Array, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if _sorted_keys(match_value) != ["mapping", "recipe", "specificity"]:
		return _failure("JCP_FUSION_MATCH_INVALID", "Falta una coincidencia de receta valida.")
	var recipe_check := validate_recipe(match_value["recipe"], known_anatomies, known_aptitudes)
	if not recipe_check["ok"]:
		return _failure("JCP_FUSION_MATCH_INVALID", "La coincidencia contiene una receta invalida.")
	if not _valid_identifier(generated_id):
		return _failure("JCP_FUSION_GENERATED_ID_INVALID", "La entidad generada necesita un identificador valido.")
	if material_profiles.size() != 2:
		return _failure("JCP_FUSION_PROFILE_COUNT_INVALID", "Se requieren dos perfiles de material.")
	for profile in material_profiles:
		var profile_check := validate_material_profile(profile, known_anatomies, known_aptitudes)
		if not profile_check["ok"]:
			return profile_check
	if material_profiles[0]["owner_id"] != material_profiles[1]["owner_id"] or not material_profiles[0]["face_up"] or not material_profiles[1]["face_up"]:
		return _failure("JCP_FUSION_MATCH_INVALID", "Los materiales ya no cumplen control y visibilidad.")
	var mapping: Array = match_value["mapping"]
	if mapping not in [[0, 1], [1, 0]]:
		return _failure("JCP_FUSION_MAPPING_INVALID", "El orden de materiales no es valido.")
	if match_value["recipe"]["ordered"] and mapping != [0, 1]:
		return _failure("JCP_FUSION_MAPPING_INVALID", "Una receta ordenada no admite el mapeo inverso.")
	if not match_value["specificity"] is int or match_value["specificity"] != _recipe_specificity(match_value["recipe"]):
		return _failure("JCP_FUSION_MATCH_INVALID", "La especificidad de la coincidencia no es valida.")
	if not _match_pair(match_value["recipe"], material_profiles, mapping):
		return _failure("JCP_FUSION_MATCH_INVALID", "Los materiales ya no satisfacen la receta.")
	var contained: Array = []
	var source_fusions: Array = []
	for profile in material_profiles:
		contained.append_array(profile["physical_instance_ids"])
		if not profile["fusion_identity_id"].is_empty():
			source_fusions.append(profile["fusion_identity_id"])
	if contained.is_empty() or _has_duplicates(contained):
		return _failure("JCP_FUSION_PHYSICAL_MATERIAL_REUSED", "Los materiales fisicos contenidos no son validos.")
	var result: Dictionary = match_value["recipe"]["result"]
	var entity := {
		"id": generated_id,
		"fusion_identity_id": result["identity_id"],
		"display_name": result["display_name"],
		"owner_id": material_profiles[0]["owner_id"],
		"cost": result["cost"],
		"attack": result["attack"],
		"defense": result["defense"],
		"families": result["families"].duplicate(),
		"superfamilies": result["superfamilies"].duplicate(),
		"elements": result["elements"].duplicate(),
		"anatomy": result["anatomy"],
		"aptitudes": result["aptitudes"].duplicate(),
		"properties": result["properties"].duplicate(),
		"fusion_mode": result["fusion_mode"],
		"effect_text": result["effect_text"],
		"contained_physical_ids": contained,
		"source_fusion_ids": source_fusions,
	}
	var entity_check := validate_generated_identity(entity, known_anatomies, known_aptitudes)
	if not entity_check["ok"]:
		return entity_check
	return {"ok": true, "code": "OK", "message": "", "value": entity}


static func validate_generated_identity(entity: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not entity is Dictionary or _sorted_keys(entity) != GENERATED_KEYS:
		return _failure("JCP_FUSION_GENERATED_INVALID", "La entidad generada no tiene el contrato canonico.")
	if not _valid_identifier(entity["id"]) or not _valid_identifier(entity["fusion_identity_id"]):
		return _failure("JCP_FUSION_GENERATED_ID_INVALID", "La identidad generada no es valida.")
	if not entity["owner_id"] is int or entity["owner_id"] < 0:
		return _failure("JCP_FUSION_GENERATED_OWNER_INVALID", "El controlador de la Fusion no es valido.")
	if not entity["display_name"] is String or entity["display_name"].strip_edges().is_empty() or not entity["effect_text"] is String or entity["effect_text"].strip_edges().is_empty():
		return _failure("JCP_FUSION_GENERATED_TEXT_INVALID", "Nombre y texto funcional deben estar definidos.")
	for key in ["cost", "attack", "defense"]:
		if not entity[key] is int or entity[key] < 0:
			return _failure("JCP_FUSION_GENERATED_STATS_INVALID", "Las cifras de la Fusion no son validas.")
	if entity["anatomy"] not in known_anatomies or entity["anatomy"] == "unassigned":
		return _failure("JCP_FUSION_GENERATED_ANATOMY_INVALID", "La Fusion necesita anatomia concreta.")
	if entity["fusion_mode"] not in FUSION_MODES:
		return _failure("JCP_FUSION_GENERATED_MODE_INVALID", "El modo narrativo de Fusion no es valido.")
	for key in ["families", "superfamilies", "elements", "properties", "contained_physical_ids"]:
		var list_check := _validate_unique_strings(entity[key], false)
		if not list_check["ok"]:
			return _failure("JCP_FUSION_GENERATED_LIST_INVALID", "%s no es una lista valida." % key)
	if entity["contained_physical_ids"].is_empty():
		return _failure("JCP_FUSION_GENERATED_MATERIALS_EMPTY", "La Fusion debe contener cartas fisicas.")
	var source_check := _validate_string_list(entity["source_fusion_ids"], false)
	if not source_check["ok"]:
		return _failure("JCP_FUSION_GENERATED_LIST_INVALID", "source_fusion_ids no es una lista valida.")
	var aptitude_check := _validate_known_tags(entity["aptitudes"], known_aptitudes, false)
	if not aptitude_check["ok"]:
		return _failure("JCP_FUSION_GENERATED_APTITUDES_INVALID", aptitude_check["message"])
	return _success()


static func release_physical_materials(entity: Dictionary, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	var check := validate_generated_identity(entity, known_anatomies, known_aptitudes)
	if not check["ok"]:
		return check
	return {"ok": true, "code": "OK", "message": "", "value": entity["contained_physical_ids"].duplicate()}


static func _validate_requirement(requirement: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not requirement is Dictionary or requirement.is_empty():
		return _failure("JCP_FUSION_MATERIAL_REQUIREMENT_INVALID", "Cada material necesita al menos un requisito.")
	for key in requirement.keys():
		if key not in MATERIAL_KEYS:
			return _failure("JCP_FUSION_MATERIAL_REQUIREMENT_INVALID", "Un requisito contiene una clave desconocida.")
	for key in ["definition_id", "fusion_identity_id", "family", "superfamily", "element"]:
		if requirement.has(key) and (not requirement[key] is String or requirement[key].strip_edges().is_empty()):
			return _failure("JCP_FUSION_MATERIAL_REQUIREMENT_INVALID", "%s debe ser una cadena no vacia." % key)
	if requirement.has("definition_id") and requirement.has("fusion_identity_id"):
		return _failure("JCP_FUSION_MATERIAL_REQUIREMENT_INVALID", "Un requisito no puede exigir carta fisica y Fusion a la vez.")
	if requirement.has("anatomy") and requirement["anatomy"] not in known_anatomies:
		return _failure("JCP_FUSION_MATERIAL_ANATOMY_INVALID", "La receta exige una anatomia desconocida.")
	if requirement.has("aptitudes"):
		var aptitude_check := _validate_known_tags(requirement["aptitudes"], known_aptitudes, true)
		if not aptitude_check["ok"]:
			return _failure("JCP_FUSION_MATERIAL_APTITUDES_INVALID", aptitude_check["message"])
	if requirement.has("properties"):
		var properties_check := _validate_unique_strings(requirement["properties"], true)
		if not properties_check["ok"]:
			return _failure("JCP_FUSION_MATERIAL_PROPERTIES_INVALID", "Las propiedades exigidas no son validas.")
	return _success()


static func _validate_result(result: Variant, known_anatomies: Array, known_aptitudes: Array) -> Dictionary:
	if not result is Dictionary or _sorted_keys(result) != RESULT_KEYS:
		return _failure("JCP_FUSION_RESULT_KEYS_INVALID", "El resultado no tiene el contrato completo.")
	if not _valid_identifier(result["identity_id"]) or not result["display_name"] is String or result["display_name"].strip_edges().is_empty():
		return _failure("JCP_FUSION_RESULT_IDENTITY_INVALID", "Identificador o nombre del resultado no son validos.")
	if not result["effect_text"] is String or result["effect_text"].strip_edges().is_empty():
		return _failure("JCP_FUSION_RESULT_EFFECT_INVALID", "El resultado necesita texto funcional.")
	for key in ["cost", "attack", "defense"]:
		if not result[key] is int or result[key] < 0:
			return _failure("JCP_FUSION_RESULT_STATS_INVALID", "Coste, ATQ y DEF deben ser enteros no negativos.")
	if result["fusion_mode"] not in FUSION_MODES:
		return _failure("JCP_FUSION_RESULT_MODE_INVALID", "El modo de Fusion no es conocido.")
	if result["anatomy"] not in known_anatomies or result["anatomy"] == "unassigned":
		return _failure("JCP_FUSION_RESULT_ANATOMY_INVALID", "El resultado necesita una anatomia concreta.")
	for key in ["families", "superfamilies", "elements", "properties"]:
		var list_check := _validate_unique_strings(result[key], key in ["families", "elements"])
		if not list_check["ok"]:
			return _failure("JCP_FUSION_RESULT_LIST_INVALID", "%s no es una lista valida." % key)
	var aptitude_check := _validate_known_tags(result["aptitudes"], known_aptitudes, false)
	if not aptitude_check["ok"]:
		return _failure("JCP_FUSION_RESULT_APTITUDES_INVALID", aptitude_check["message"])
	return _success()


static func _match_pair(recipe: Dictionary, profiles: Array, mapping: Array) -> bool:
	return _requirement_matches(recipe["materials"][0], profiles[mapping[0]]) and _requirement_matches(recipe["materials"][1], profiles[mapping[1]])


static func _requirement_matches(requirement: Dictionary, profile: Dictionary) -> bool:
	if requirement.has("definition_id") and requirement["definition_id"] != profile["definition_id"]:
		return false
	if requirement.has("fusion_identity_id") and requirement["fusion_identity_id"] != profile["fusion_identity_id"]:
		return false
	if requirement.has("family") and requirement["family"] not in profile["families"]:
		return false
	if requirement.has("superfamily") and requirement["superfamily"] not in profile["superfamilies"]:
		return false
	if requirement.has("element") and requirement["element"] not in profile["elements"]:
		return false
	if requirement.has("anatomy") and requirement["anatomy"] != profile["anatomy"]:
		return false
	for aptitude in requirement.get("aptitudes", []):
		if aptitude not in profile["aptitudes"]:
			return false
	for property in requirement.get("properties", []):
		if property not in profile["properties"]:
			return false
	return true


static func _recipe_specificity(recipe: Dictionary) -> int:
	var score := 0
	for requirement in recipe["materials"]:
		for key in requirement.keys():
			if requirement[key] is Array:
				score += requirement[key].size()
			else:
				score += 1
	return score


static func _validate_known_tags(value: Variant, known: Array, require_nonempty: bool) -> Dictionary:
	var list_check := _validate_unique_strings(value, require_nonempty)
	if not list_check["ok"]:
		return list_check
	for tag in value:
		if tag not in known:
			return _failure("JCP_FUSION_TAG_UNKNOWN", "La etiqueta %s no pertenece al catalogo." % tag)
	return _success()


static func _validate_unique_strings(value: Variant, require_nonempty: bool) -> Dictionary:
	var list_check := _validate_string_list(value, require_nonempty)
	if not list_check["ok"]:
		return list_check
	var seen: Dictionary = {}
	for entry in value:
		if seen.has(entry):
			return _failure("JCP_FUSION_LIST_INVALID", "La lista contiene valores repetidos.")
		seen[entry] = true
	return _success()


static func _validate_string_list(value: Variant, require_nonempty: bool) -> Dictionary:
	if not value is Array or (require_nonempty and value.is_empty()):
		return _failure("JCP_FUSION_LIST_INVALID", "Se esperaba una lista de cadenas.")
	for entry in value:
		if not entry is String or entry.strip_edges().is_empty():
			return _failure("JCP_FUSION_LIST_INVALID", "La lista contiene valores vacios o no textuales.")
	return _success()


static func _valid_identifier(value: Variant) -> bool:
	if not value is String or value.is_empty() or value.length() > 96:
		return false
	for index in range(value.length()):
		var code: int = value.unicode_at(index)
		var allowed: bool = code >= 48 and code <= 57 or code >= 65 and code <= 90 or code >= 97 and code <= 122 or code in [45, 46, 95]
		if not allowed:
			return false
	return true


static func _has_duplicates(values: Array) -> bool:
	var seen: Dictionary = {}
	for value in values:
		if seen.has(value):
			return true
		seen[value] = true
	return false


static func _sorted_keys(value: Dictionary) -> Array:
	var keys := value.keys()
	keys.sort()
	return keys


static func _success() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
