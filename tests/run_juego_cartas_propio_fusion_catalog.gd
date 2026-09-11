extends SceneTree
## Verifica el primer catalogo de Fusion conectado a identidades reales M01-M18.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const FusionCatalog = preload("res://games/juego_cartas_propio/fusion_catalog.gd")
const FusionRecipeService = preload("res://games/juego_cartas_propio/fusion_recipe_service.gd")

const ANATOMIES := ["unassigned", "humanoid", "quadruped", "winged", "serpentine", "amorphous", "spectral", "colossal"]
const APTITUDES := ["bestial", "sapient", "reader", "channeler", "manipulator"]

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_test_catalog_contract()
	_test_fire_dragon()
	_test_neutral_goblins_match_in_both_orders()
	_test_generated_band_identity()
	_test_alpha_and_water_major()
	_test_two_headed_troll_requires_distinct_materials()
	_test_visibility_owner_and_physical_guards()
	_test_goblin_mixed_bands()
	_test_profile_rejects_non_creatures()
	if _failures.is_empty():
		print("JCP-FUSION-CATALOG PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-FUSION-CATALOG FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_catalog_contract() -> void:
	var recipes: Array = FusionCatalog.recipes()
	_expect_equal(recipes.size(), 8, "las ocho Fusiones iniciales forman el catalogo controlado")
	_expect(FusionRecipeService.validate_catalog(recipes, ANATOMIES, APTITUDES)["ok"], "las ocho recetas cumplen el contrato generico")
	_expect_equal(recipes[1]["result"]["display_name"], "Banda Goblin", "se conserva el nombre aprobado")
	_expect_equal(recipes[1]["result"]["fusion_mode"], "formation", "la Banda es una Formacion y no una integracion corporal")
	var modified: Array = FusionCatalog.recipes()
	modified[1]["result"]["attack"] = 99
	_expect_equal(FusionCatalog.recipes()[1]["result"]["attack"], 3, "cada lectura devuelve un catalogo independiente")


func _test_fire_dragon() -> void:
	var cards: Dictionary = _visible_cards()
	var first: String = _instance_for(cards, "M17", 0)
	var second: String = _instance_for(cards, "M18", 0)
	for pair in [[first, second], [second, first]]:
		var built: Dictionary = FusionCatalog.build_for_cards(cards, pair, "generated.dragon", ANATOMIES, APTITUDES)
		_expect(built["ok"], "F005 acepta los dos ordenes")
		if built["ok"]:
			_expect_equal(built["value"]["fusion_identity_id"], "fusion.f005_fire_dragon", "la pareja produce F005")
			_expect_equal([built["value"]["cost"], built["value"]["attack"], built["value"]["defense"]], [8, 8, 8], "F005 conserva las cifras aprobadas")
			_expect_equal(built["value"]["aptitudes"], ["bestial"], "F005 no hereda Manipulador por union")
	var wrong: Dictionary = FusionCatalog.find_for_cards(cards, [first, _instance_for(cards, "M03", 0)], ANATOMIES, APTITUDES)
	_expect(wrong["ok"] and wrong["value"].is_empty(), "compartir Fuego sin familia Dragon no basta")


func _test_neutral_goblins_match_in_both_orders() -> void:
	var cards: Dictionary = _visible_cards()
	var m04: String = _instance_for(cards, "M04", 0)
	var m09: String = _instance_for(cards, "M09", 0)
	var direct: Dictionary = FusionCatalog.find_for_cards(cards, [m04, m09], ANATOMIES, APTITUDES)
	_expect(direct["ok"] and not direct["value"].is_empty(), "M04 + M09 encuentra F010-NEU")
	_expect_equal(direct["value"].get("mapping", []), [0, 1], "el orden directo conserva su mapeo")
	var inverse: Dictionary = FusionCatalog.find_for_cards(cards, [m09, m04], ANATOMIES, APTITUDES)
	_expect(inverse["ok"] and not inverse["value"].is_empty(), "M09 + M04 tambien encuentra la receta no ordenada")
	_expect_equal(inverse["value"].get("recipe", {}).get("id", ""), "recipe.f010_neutral_band", "el orden inverso produce la misma receta")


func _test_generated_band_identity() -> void:
	var cards: Dictionary = _visible_cards()
	var m04: String = _instance_for(cards, "M04", 0)
	var m09: String = _instance_for(cards, "M09", 0)
	var built: Dictionary = FusionCatalog.build_for_cards(cards, [m04, m09], "generated.band.1", ANATOMIES, APTITUDES)
	_expect(built["ok"], "la Banda se construye desde cartas reales del catalogo")
	if not built["ok"]:
		return
	var entity: Dictionary = built["value"]
	_expect_equal(entity["fusion_identity_id"], "fusion.f010_neutral_band", "la entidad usa la identidad F010-NEU")
	_expect_equal([entity["cost"], entity["attack"], entity["defense"]], [3, 3, 3], "la Banda conserva coste y estadisticas aprobados")
	_expect_equal(entity["families"], ["goblin"], "la Formacion sigue contando como Goblin")
	_expect_equal(entity["aptitudes"], ["sapient", "manipulator"], "la Formacion puede conservar equipo compatible")
	_expect_equal(entity["contained_physical_ids"], [m04, m09], "la entidad contiene exactamente las dos cartas fisicas")
	_expect_equal(FusionRecipeService.release_physical_materials(entity, ANATOMIES, APTITUDES)["value"], [m04, m09], "la destruccion futura puede recuperar ambos materiales")


func _test_alpha_and_water_major() -> void:
	var cards: Dictionary = _visible_cards()
	var m01: String = _instance_for(cards, "M01", 0)
	var m07: String = _instance_for(cards, "M07", 0)
	var alpha: Dictionary = FusionCatalog.build_for_cards(cards, [m07, m01], "generated.alpha.1", ANATOMIES, APTITUDES)
	_expect(alpha["ok"], "los dos Lobos de Naturaleza construyen F001 en orden inverso")
	if alpha["ok"]:
		_expect_equal(alpha["value"]["display_name"], "Alfa de la Manada de Naturaleza", "F001 conserva su nombre completo")
		_expect_equal([alpha["value"]["attack"], alpha["value"]["defense"]], [3, 2], "F001 conserva sus cifras aprobadas")
		_expect_equal(alpha["value"]["anatomy"], "quadruped", "F001 sigue siendo un Lobo cuadrupedo")
	var m06: String = _instance_for(cards, "M06", 0)
	var m08: String = _instance_for(cards, "M08", 0)
	var water_major: Dictionary = FusionCatalog.build_for_cards(cards, [m06, m08], "generated.water.1", ANATOMIES, APTITUDES)
	_expect(water_major["ok"], "dos Elementales de Agua construyen F067")
	if water_major["ok"]:
		_expect_equal(water_major["value"]["display_name"], "Elemental Mayor de Agua", "F067 conserva su nombre")
		_expect_equal([water_major["value"]["cost"], water_major["value"]["attack"], water_major["value"]["defense"]], [4, 4, 4], "F067 conserva coste y cifras aprobados")
		_expect_equal(water_major["value"]["aptitudes"], [], "la Integracion amorfa no inventa Manipulador")
	var m03: String = _instance_for(cards, "M03", 0)
	var steam: Dictionary = FusionCatalog.build_for_cards(cards, [m03, m06], "generated.steam.1", ANATOMIES, APTITUDES)
	_expect(steam["ok"], "Fuego + Agua construye F068")
	if steam["ok"]:
		_expect_equal(steam["value"]["fusion_identity_id"], "fusion.f068_steam_elemental", "F068 conserva su identidad")
		_expect_equal([steam["value"]["cost"], steam["value"]["attack"], steam["value"]["defense"]], [3, 2, 4], "F068 conserva coste y cifras aprobados")
	var m14: String = _instance_for(cards, "M14", 0)
	var mixed_wolves: Dictionary = FusionCatalog.find_for_cards(cards, [m01, m14], ANATOMIES, APTITUDES)
	_expect(mixed_wolves["ok"] and mixed_wolves["value"].is_empty(), "un Lobo Neutral no satisface F001-NAT")


func _test_two_headed_troll_requires_distinct_materials() -> void:
	var cards: Dictionary = _visible_cards()
	var m11: String = _instance_for(cards, "M11", 0)
	var m13: String = _instance_for(cards, "M13", 0)
	var troll: Dictionary = FusionCatalog.build_for_cards(cards, [m13, m11], "generated.troll.1", ANATOMIES, APTITUDES)
	_expect(troll["ok"], "dos Trolls neutrales distintos construyen F018 en cualquier orden")
	if troll["ok"]:
		_expect_equal(troll["value"]["fusion_identity_id"], "fusion.f018_two_headed_troll", "F018 conserva su identidad estable")
		_expect_equal([troll["value"]["cost"], troll["value"]["attack"], troll["value"]["defense"]], [6, 6, 6], "F018 conserva coste y cifras aprobados")
	var repeated_cards: Dictionary = cards.duplicate(true)
	repeated_cards["instances"][m13]["definition_id"] = "M11"
	var repeated: Dictionary = FusionCatalog.find_for_cards(repeated_cards, [m11, m13], ANATOMIES, APTITUDES)
	_expect(repeated["ok"] and repeated["value"].is_empty(), "dos copias del mismo Troll no satisfacen la receta distinta")
	var m15: String = _instance_for(cards, "M15", 0)
	var mixed_element: Dictionary = FusionCatalog.find_for_cards(cards, [m11, m15], ANATOMIES, APTITUDES)
	_expect(mixed_element["ok"] and mixed_element["value"].is_empty(), "un Troll de Naturaleza no satisface F018-NEU")


func _test_visibility_owner_and_physical_guards() -> void:
	var cards: Dictionary = _visible_cards()
	var m04: String = _instance_for(cards, "M04", 0)
	var m09: String = _instance_for(cards, "M09", 0)
	cards["instances"][m09]["metadata"]["face_up"] = false
	var hidden: Dictionary = FusionCatalog.find_for_cards(cards, [m04, m09], ANATOMIES, APTITUDES)
	_expect(hidden["ok"] and hidden["value"].is_empty(), "un Goblin oculto no habilita la receta")
	cards["instances"][m09]["metadata"]["face_up"] = true
	var enemy_m09: String = _instance_for(cards, "M09", 1)
	var mixed: Dictionary = FusionCatalog.find_for_cards(cards, [m04, enemy_m09], ANATOMIES, APTITUDES)
	_expect(not mixed["ok"], "no se mezclan Goblins de controladores distintos")
	_expect_equal(mixed["code"], "JCP_FUSION_OWNER_MISMATCH", "el rechazo identifica propietarios distintos")
	var reused: Dictionary = FusionCatalog.find_for_cards(cards, [m04, m04], ANATOMIES, APTITUDES)
	_expect(not reused["ok"], "una misma carta fisica no ocupa ambos materiales")
	_expect_equal(reused["code"], "JCP_FUSION_PHYSICAL_MATERIAL_REUSED", "el rechazo identifica material repetido")


func _test_goblin_mixed_bands() -> void:
	var cards: Dictionary = _visible_cards()
	var m05: String = _instance_for(cards, "M05", 0)
	var m09: String = _instance_for(cards, "M09", 0)
	var match_result: Dictionary = FusionCatalog.find_for_cards(cards, [m05, m09], ANATOMIES, APTITUDES)
	_expect(match_result["ok"] and not match_result["value"].is_empty(), "Fuego + Neutral encuentra F011")
	_expect_equal(match_result["value"]["recipe"]["id"], "recipe.f011_torch_band", "la pareja selecciona Banda de Antorchas")
	var build_result: Dictionary = FusionCatalog.build_for_cards(cards, [m05, m09], "generated.torch.1", ANATOMIES, APTITUDES)
	_expect(build_result["ok"], "F011 se construye desde cartas fisicas reales")
	if build_result["ok"]:
		_expect_equal(build_result["value"]["fusion_identity_id"], "fusion.f011_torch_band", "F011 conserva su identidad estable")
		_expect_equal([build_result["value"]["cost"], build_result["value"]["attack"], build_result["value"]["defense"]], [3, 3, 2], "F011 conserva coste y cifras aprobados")
	var m10: String = _instance_for(cards, "M10", 0)
	var thicket: Dictionary = FusionCatalog.build_for_cards(cards, [m10, m09], "generated.thicket.1", ANATOMIES, APTITUDES)
	_expect(thicket["ok"], "Naturaleza + Neutral construye F012 en orden inverso")
	if thicket["ok"]:
		_expect_equal(thicket["value"]["fusion_identity_id"], "fusion.f012_thicket_company", "F012 conserva su identidad estable")
		_expect_equal([thicket["value"]["cost"], thicket["value"]["attack"], thicket["value"]["defense"]], [3, 2, 4], "F012 conserva coste y cifras aprobados")


func _test_profile_rejects_non_creatures() -> void:
	var cards: Dictionary = _visible_cards()
	var spell_id: String = _instance_for(cards, "G01", 0)
	var profile_result: Dictionary = FusionCatalog.profile_for_card(cards, spell_id)
	_expect(not profile_result["ok"], "una Magia no se convierte en material de criatura")
	_expect_equal(profile_result["code"], "JCP_FUSION_CARD_NOT_CREATURE", "el rechazo distingue tipos de carta")
	var missing: Dictionary = FusionCatalog.profile_for_card(cards, "missing-card")
	_expect(not missing["ok"], "una carta inexistente se rechaza")
	_expect_equal(missing["code"], "JCP_FUSION_CARD_INSTANCE_UNKNOWN", "la instancia inexistente tiene error especifico")


func _visible_cards() -> Dictionary:
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	if not engine.start(10770).success:
		return {}
	var state: Dictionary = engine.export_module_state()
	var cards: Dictionary = state["cards"]
	for instance in cards["instances"].values():
		instance["metadata"]["face_up"] = true
	return cards


func _instance_for(cards: Dictionary, definition_id: String, owner_id: int) -> String:
	for instance_id in cards["instances"]:
		var instance: Dictionary = cards["instances"][instance_id]
		if instance["definition_id"] == definition_id and instance["metadata"]["owner_id"] == owner_id:
			return instance_id
	return ""


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
