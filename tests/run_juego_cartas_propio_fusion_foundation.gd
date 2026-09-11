extends SceneTree
## Prueba el contrato puro de recetas y materiales contenidos sin activar recetas reales.

const FusionRecipeService = preload("res://games/juego_cartas_propio/fusion_recipe_service.gd")

const ANATOMIES := ["unassigned", "humanoid", "quadruped", "winged", "serpentine", "amorphous", "spectral", "colossal"]
const APTITUDES := ["bestial", "sapient", "reader", "channeler", "manipulator"]

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_expect(FusionRecipeService != null, "el servicio de Fusion se carga")
	_test_catalog_contract()
	_test_unordered_and_ordered_matching()
	_test_specificity_and_ambiguity()
	_test_visibility_ownership_and_physical_identity()
	_test_generated_identity_and_chained_materials()
	if _failures.is_empty() and _checks > 1:
		print("JCP-FUSION-FOUNDATION PASS: %d checks" % _checks)
		quit(0)
		return
	if _checks <= 1:
		_failures.append("la suite no ejecuto sus comprobaciones")
	printerr("JCP-FUSION-FOUNDATION FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_catalog_contract() -> void:
	_expect(FusionRecipeService.validate_catalog([], ANATOMIES, APTITUDES)["ok"], "un catalogo vacio es valido y no activa contenido")
	var recipe := _recipe("test.wolf_boreal", false, {"family": "wolf", "element": "nature"}, {"family": "wolf", "element": "ice"})
	_expect(FusionRecipeService.validate_recipe(recipe, ANATOMIES, APTITUDES)["ok"], "una receta completa de prueba valida")
	var one_material := recipe.duplicate(true)
	one_material["materials"] = [one_material["materials"][0]]
	_expect_code(FusionRecipeService.validate_recipe(one_material, ANATOMIES, APTITUDES), "JCP_FUSION_MATERIAL_COUNT_INVALID", "la V0.1 rechaza recetas de un material")
	var incomplete_result := recipe.duplicate(true)
	incomplete_result["result"].erase("effect_text")
	_expect_code(FusionRecipeService.validate_recipe(incomplete_result, ANATOMIES, APTITUDES), "JCP_FUSION_RESULT_KEYS_INVALID", "no se acepta una Fusion sin resultado completo")
	var undefined_anatomy := recipe.duplicate(true)
	undefined_anatomy["result"]["anatomy"] = "unassigned"
	_expect_code(FusionRecipeService.validate_recipe(undefined_anatomy, ANATOMIES, APTITUDES), "JCP_FUSION_RESULT_ANATOMY_INVALID", "una receta activa no puede ocultar la anatomia pendiente")
	var duplicated := recipe.duplicate(true)
	duplicated["result"]["identity_id"] = "fusion.boreal_copy"
	_expect_code(FusionRecipeService.validate_catalog([recipe, recipe.duplicate(true)], ANATOMIES, APTITUDES), "JCP_FUSION_RECIPE_ID_DUPLICATED", "los ids de receta son unicos")
	_expect_code(FusionRecipeService.validate_catalog([recipe, duplicated], ANATOMIES, APTITUDES), "JCP_FUSION_RECIPE_ID_DUPLICATED", "una receta duplicada no se disimula cambiando solo el resultado")
	duplicated["id"] = "test.wolf_boreal_copy"
	duplicated["result"]["identity_id"] = recipe["result"]["identity_id"]
	_expect_code(FusionRecipeService.validate_catalog([recipe, duplicated], ANATOMIES, APTITUDES), "JCP_FUSION_RESULT_ID_DUPLICATED", "las identidades resultantes tambien son unicas")


func _test_unordered_and_ordered_matching() -> void:
	var nature := _profile("card-nature", "M01", "", ["wolf"], ["bestial"], ["nature"], "quadruped", ["bestial"], [], 0, true)
	var ice := _profile("card-ice", "M02", "", ["wolf"], ["bestial"], ["ice"], "quadruped", ["bestial"], [], 0, true)
	var unordered := _recipe("test.unordered", false, {"family": "wolf", "element": "nature"}, {"family": "wolf", "element": "ice"})
	var direct := FusionRecipeService.find_recipe([unordered], [nature, ice], ANATOMIES, APTITUDES)
	_expect(not direct["value"].is_empty(), "una receta no ordenada coincide en orden directo")
	_expect_equal(direct["value"]["mapping"], [0, 1], "el orden directo conserva el mapeo")
	var reverse := FusionRecipeService.find_recipe([unordered], [ice, nature], ANATOMIES, APTITUDES)
	_expect(not reverse["value"].is_empty(), "una receta no ordenada coincide al invertir materiales")
	_expect_equal(reverse["value"]["mapping"], [1, 0], "el mapeo registra la inversion")
	var ordered := _recipe("test.ordered", true, {"family": "wolf", "element": "nature"}, {"family": "wolf", "element": "ice"})
	_expect(not FusionRecipeService.find_recipe([ordered], [nature, ice], ANATOMIES, APTITUDES)["value"].is_empty(), "una receta ordenada admite su orden escrito")
	_expect(FusionRecipeService.find_recipe([ordered], [ice, nature], ANATOMIES, APTITUDES)["value"].is_empty(), "una receta ordenada rechaza el orden inverso")


func _test_specificity_and_ambiguity() -> void:
	var first := _profile("physical-a", "M01", "", ["wolf"], ["bestial"], ["nature"], "quadruped", ["bestial"], [], 0, true)
	var second := _profile("physical-b", "M02", "", ["wolf"], ["bestial"], ["ice"], "quadruped", ["bestial"], [], 0, true)
	var broad := _recipe("test.broad", false, {"family": "wolf"}, {"family": "wolf"})
	broad["result"]["identity_id"] = "fusion.wolf_pack"
	var specific := _recipe("test.specific", false, {"family": "wolf", "element": "nature"}, {"family": "wolf", "element": "ice"})
	var match_result := FusionRecipeService.find_recipe([broad, specific], [first, second], ANATOMIES, APTITUDES)
	_expect(match_result["ok"], "la busqueda con recetas amplias y especificas es valida")
	_expect_equal(match_result["value"]["recipe"]["id"], "test.specific", "gana la receta mas especifica")
	var tied := specific.duplicate(true)
	tied["id"] = "test.specific_tied"
	tied["result"]["identity_id"] = "fusion.boreal_tied"
	_expect_code(FusionRecipeService.find_recipe([specific, tied], [first, second], ANATOMIES, APTITUDES), "JCP_FUSION_RECIPE_AMBIGUOUS", "un empate de especificidad se rechaza en vez de elegir al azar")


func _test_visibility_ownership_and_physical_identity() -> void:
	var recipe := _recipe("test.visibility", false, {"family": "wolf"}, {"family": "wolf"})
	var first := _profile("physical-a", "M01", "", ["wolf"], ["bestial"], ["nature"], "quadruped", ["bestial"], [], 0, true)
	var second := _profile("physical-b", "M02", "", ["wolf"], ["bestial"], ["ice"], "quadruped", ["bestial"], [], 0, false)
	_expect(FusionRecipeService.find_recipe([recipe], [first, second], ANATOMIES, APTITUDES)["value"].is_empty(), "una criatura oculta no aporta requisitos de Fusion")
	second["face_up"] = true
	second["owner_id"] = 1
	_expect_code(FusionRecipeService.find_recipe([recipe], [first, second], ANATOMIES, APTITUDES), "JCP_FUSION_OWNER_MISMATCH", "no se fusionan materiales de controladores distintos")
	second["owner_id"] = 0
	second["physical_instance_ids"] = ["physical-a"]
	_expect_code(FusionRecipeService.find_recipe([recipe], [first, second], ANATOMIES, APTITUDES), "JCP_FUSION_PHYSICAL_MATERIAL_REUSED", "una carta fisica no cuenta dos veces")


func _test_generated_identity_and_chained_materials() -> void:
	var base := _profile("physical-a", "M01", "", ["wolf"], ["bestial"], ["nature"], "quadruped", ["bestial"], [], 0, true)
	var previous := _profile("physical-b", "", "fusion.wolf_pack", ["wolf"], ["bestial"], ["ice"], "quadruped", ["bestial"], [], 0, true)
	previous["physical_instance_ids"] = ["physical-b", "physical-c"]
	var recipe := _recipe("test.chain", false, {"definition_id": "M01"}, {"fusion_identity_id": "fusion.wolf_pack"})
	var found := FusionRecipeService.find_recipe([recipe], [base, previous], ANATOMIES, APTITUDES)
	_expect(found["ok"] and not found["value"].is_empty(), "una receta puede admitir una Fusion previa como material")
	var built := FusionRecipeService.build_generated_identity(found["value"], "generated-1", [base, previous], ANATOMIES, APTITUDES)
	_expect(built["ok"], "se construye una identidad generada canonica")
	if not built["ok"]:
		return
	var entity: Dictionary = built["value"]
	_expect_equal(entity["contained_physical_ids"], ["physical-a", "physical-b", "physical-c"], "una Fusion encadenada conserva solo las cartas fisicas originales")
	_expect_equal(entity["source_fusion_ids"], ["fusion.wolf_pack"], "la procedencia registra la entidad intermedia sin convertirla en carta")
	_expect_equal(entity["fusion_identity_id"], "fusion.boreal", "el resultado usa la identidad escrita por la receta")
	_expect(FusionRecipeService.validate_generated_identity(entity, ANATOMIES, APTITUDES)["ok"], "la entidad generada valida con su contrato exacto")
	var released := FusionRecipeService.release_physical_materials(entity, ANATOMIES, APTITUDES)
	_expect_equal(released["value"], ["physical-a", "physical-b", "physical-c"], "la destruccion futura puede liberar todas las cartas fisicas contenidas")
	var tampered := entity.duplicate(true)
	tampered["contained_physical_ids"].append("physical-a")
	_expect(not FusionRecipeService.validate_generated_identity(tampered, ANATOMIES, APTITUDES)["ok"], "una entidad manipulada no puede duplicar materiales fisicos")
	var forged_match: Dictionary = found["value"].duplicate(true)
	forged_match["recipe"]["materials"][0] = {"definition_id": "M99"}
	_expect_code(FusionRecipeService.build_generated_identity(forged_match, "generated-2", [base, previous], ANATOMIES, APTITUDES), "JCP_FUSION_MATCH_INVALID", "una coincidencia manipulada no puede generar una entidad")
	var forged_specificity: Dictionary = found["value"].duplicate(true)
	forged_specificity["specificity"] += 1
	_expect_code(FusionRecipeService.build_generated_identity(forged_specificity, "generated-2", [base, previous], ANATOMIES, APTITUDES), "JCP_FUSION_MATCH_INVALID", "la especificidad manipulada no se acepta como coincidencia valida")
	var forged_order: Dictionary = found["value"].duplicate(true)
	forged_order["recipe"]["ordered"] = true
	forged_order["recipe"]["materials"] = [{"family": "wolf"}, {"family": "wolf"}]
	forged_order["mapping"] = [1, 0]
	forged_order["specificity"] = 2
	_expect_code(FusionRecipeService.build_generated_identity(forged_order, "generated-2", [base, previous], ANATOMIES, APTITUDES), "JCP_FUSION_MAPPING_INVALID", "una receta ordenada no acepta un mapeo inverso fabricado")
	var same_identity_source := previous.duplicate(true)
	same_identity_source["physical_instance_ids"] = ["physical-d", "physical-e"]
	var two_previous_recipe := _recipe("test.two_previous", false, {"fusion_identity_id": "fusion.wolf_pack"}, {"fusion_identity_id": "fusion.wolf_pack"})
	var two_previous_match := FusionRecipeService.find_recipe([two_previous_recipe], [previous, same_identity_source], ANATOMIES, APTITUDES)
	var two_previous_built := FusionRecipeService.build_generated_identity(two_previous_match["value"], "generated-3", [previous, same_identity_source], ANATOMIES, APTITUDES)
	_expect(two_previous_built["ok"], "dos entidades intermedias del mismo tipo pueden formar una Fusion superior")
	_expect_equal(two_previous_built["value"]["source_fusion_ids"], ["fusion.wolf_pack", "fusion.wolf_pack"], "la procedencia conserva la multiplicidad de identidades intermedias")


func _recipe(id: String, ordered: bool, first: Dictionary, second: Dictionary) -> Dictionary:
	return {
		"id": id,
		"ordered": ordered,
		"materials": [first, second],
		"result": {
			"identity_id": "fusion.boreal",
			"display_name": "Fusion de prueba",
			"cost": 3,
			"attack": 4,
			"defense": 4,
			"families": ["wolf"],
			"superfamilies": ["bestial"],
			"elements": ["nature", "ice"],
			"anatomy": "quadruped",
			"aptitudes": ["bestial"],
			"properties": [],
			"fusion_mode": "integration",
			"effect_text": "Texto funcional sintetico para probar el contrato.",
		},
	}


func _profile(physical_id: String, definition_id: String, fusion_id: String, families: Array, superfamilies: Array, elements: Array, anatomy: String, aptitudes: Array, properties: Array, owner_id: int, face_up: bool) -> Dictionary:
	return {
		"definition_id": definition_id,
		"fusion_identity_id": fusion_id,
		"families": families,
		"superfamilies": superfamilies,
		"elements": elements,
		"anatomy": anatomy,
		"aptitudes": aptitudes,
		"properties": properties,
		"owner_id": owner_id,
		"face_up": face_up,
		"physical_instance_ids": [physical_id],
	}


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])


func _expect_code(result: Dictionary, expected_code: String, description: String) -> void:
	_expect(not result["ok"], description)
	if not result["ok"]:
		_expect_equal(result["code"], expected_code, "%s usa un codigo especifico" % description)
