extends SceneTree
## Verifica perfiles anatomicos, aptitudes discretas y requisitos de equipo.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

var _checks := 0
var _failures: Array = []
var _request_sequence := 0


func _init() -> void:
	_test_catalog_uses_discrete_aptitudes()
	_test_generic_aptitude_and_anatomy_requirements()
	_test_linked_equipment_is_revalidated()
	_test_malformed_profiles_are_rejected()
	if _failures.is_empty():
		print("JCP-COMPATIBILITY-PROFILES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-COMPATIBILITY-PROFILES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _test_catalog_uses_discrete_aptitudes() -> void:
	var engine = _start(10770)
	_expect(engine != null, "el catalogo con perfiles se inicia")
	if engine == null:
		return
	var state: Dictionary = engine.export_module_state()
	var manipulator_count := 0
	var family_counts := {"wolf": 0, "goblin": 0, "elemental": 0, "troll": 0, "dragon": 0}
	var expected_names := [
		"Lobo de Zarza", "Ondina del Remanso", "Núcleo de Escoria", "Goblin Rebuscador",
		"Goblin Portaantorchas", "Muro de Marea", "Cachorro de la Senda Verde", "Oleada Errante",
		"Goblin Pendenciero", "Goblin Trampero del Matorral", "Troll Quebrapuertas", "Oráculo del Espejo de Agua",
		"Troll Guarda del Puente", "Lobo Gris del Páramo", "Troll Chamán del Musgo", "Troll Cobrador del Paso",
		"Dragón de la Caldera", "Dragón Rojo de las Dos Coronas",
	]
	for index in range(1, 19):
		var definition: Dictionary = state["cards"]["definitions"]["M%02d" % index]
		_expect_equal(definition["attributes"]["display_name"], expected_names[index - 1], "M%02d conserva su identidad fantastica" % index)
		_expect(definition["attributes"]["anatomy"] != "unassigned", "M%02d recibe anatomia concreta" % index)
		_expect(definition["attributes"]["families"] is Array and definition["attributes"]["families"].size() == 1, "M%02d registra una familia concreta" % index)
		var family: String = definition["attributes"]["families"][0]
		_expect(family_counts.has(family), "M%02d pertenece a una familia de la baraja" % index)
		if family_counts.has(family):
			family_counts[family] += 1
		_expect(definition["attributes"]["aptitudes"] is Array, "M%02d registra aptitudes como lista" % index)
		_expect(not definition["attributes"].has("intelligence"), "M%02d no usa una escala numerica de inteligencia" % index)
		_expect(not definition["attributes"].has("manipulator"), "M%02d no conserva el booleano antiguo" % index)
		if "manipulator" in definition["attributes"]["aptitudes"]:
			manipulator_count += 1
	_expect_equal(manipulator_count, 11, "se conserva el reparto aprobado de once Manipuladores")
	_expect_equal(family_counts, {"wolf": 3, "goblin": 4, "elemental": 5, "troll": 4, "dragon": 2}, "el catalogo conserva el reparto de cinco familias")
	_expect_equal(state["cards"]["definitions"]["M17"]["attributes"]["aptitudes"], ["bestial"], "el primer Dragon no puede usar equipo de Manipulador")
	_expect("manipulator" in state["cards"]["definitions"]["M18"]["attributes"]["aptitudes"], "el segundo Dragon conserva sus garras prensiles")
	for definition_id in ["E01", "E03", "E06"]:
		_expect_equal(state["cards"]["definitions"][definition_id]["attributes"]["required_aptitudes"], ["manipulator"], "%s exige Manipulador mediante el contrato generico" % definition_id)
	for definition_id in ["E02", "E04", "E05"]:
		_expect_equal(state["cards"]["definitions"][definition_id]["attributes"]["required_aptitudes"], [], "%s no recibe requisitos no escritos" % definition_id)
	_expect(engine.validate_internal_consistency()["ok"], "el catalogo migrado conserva la consistencia")


func _test_generic_aptitude_and_anatomy_requirements() -> void:
	var engine = _start(10770)
	_expect(engine != null, "se prepara una criatura para consultar compatibilidad")
	if engine == null:
		return
	var state: Dictionary = engine.export_module_state()
	var target_id: String = _find_in_hand(state, "M02")
	var module = GameModule.new()
	state["cards"]["definitions"]["M02"]["attributes"]["anatomy"] = "humanoid"
	state["cards"]["definitions"]["E01"]["attributes"]["allowed_anatomies"] = ["humanoid"]
	_expect(module.call("_can_equip", state, "E01", target_id), "una anatomia admitida y Manipulador pueden usar el arma")
	state["cards"]["definitions"]["M02"]["attributes"]["anatomy"] = "quadruped"
	_expect(not module.call("_can_equip", state, "E01", target_id), "la misma aptitud no ignora una anatomia incompatible")
	state["cards"]["definitions"]["E01"]["attributes"]["allowed_anatomies"] = []
	state["cards"]["definitions"]["E01"]["attributes"]["required_aptitudes"] = ["reader", "channeler"]
	_expect(not module.call("_can_equip", state, "E01", target_id), "Manipulador no equivale a saber leer y canalizar")
	state["cards"]["definitions"]["M02"]["attributes"]["aptitudes"] = ["manipulator", "sapient", "reader", "channeler"]
	_expect(module.call("_can_equip", state, "E01", target_id), "una criatura con todas las aptitudes escritas cumple el requisito complejo")


func _test_linked_equipment_is_revalidated() -> void:
	var engine = _start(10770)
	_expect(engine != null and _reach_main(engine), "se prepara el vinculo que debe seguir siendo legal")
	if engine == null:
		return
	var state: Dictionary = engine.export_module_state()
	var creature_id: String = _find_in_hand(state, "M02")
	var item_id: String = _find_in_hand(state, "E01")
	_expect(_perform(engine, "summon_creature", {"instance_id": creature_id}, "summon"), "se invoca una criatura Manipuladora")
	_expect(_perform(engine, "equip_item", {"instance_id": item_id, "target_instance_id": creature_id}, "equip"), "E01 se vincula legalmente")
	var tampered: Dictionary = engine.export_module_state()
	tampered["cards"]["definitions"]["M02"]["attributes"]["aptitudes"] = []
	var validation: Dictionary = GameModule.new().validate_state(tampered)
	_expect(not validation["ok"], "un cambio que deja un equipo ilegal invalida el estado")
	_expect_equal(validation["code"], "JCP_ATTACHMENT_COMPATIBILITY_INVALID", "el rechazo identifica el vinculo incompatible")


func _test_malformed_profiles_are_rejected() -> void:
	var engine = _start(10770)
	_expect(engine != null, "se prepara la validacion hostil de perfiles")
	if engine == null:
		return
	var duplicated: Dictionary = engine.export_module_state()
	duplicated["cards"]["definitions"]["M01"]["attributes"]["aptitudes"] = ["bestial", "bestial"]
	var duplicated_check: Dictionary = GameModule.new().validate_state(duplicated)
	_expect(not duplicated_check["ok"], "una aptitud repetida se rechaza")
	_expect_equal(duplicated_check["code"], "JCP_CREATURE_APTITUDES_INVALID", "el rechazo de aptitudes repetidas es especifico")
	var unknown_anatomy: Dictionary = engine.export_module_state()
	unknown_anatomy["cards"]["definitions"]["M01"]["attributes"]["anatomy"] = "cualquier_cosa"
	var anatomy_check: Dictionary = GameModule.new().validate_state(unknown_anatomy)
	_expect(not anatomy_check["ok"], "una anatomia desconocida se rechaza")
	_expect_equal(anatomy_check["code"], "JCP_CREATURE_ANATOMY_INVALID", "el rechazo anatomico es especifico")
	var unassigned_anatomy: Dictionary = engine.export_module_state()
	unassigned_anatomy["cards"]["definitions"]["M01"]["attributes"]["anatomy"] = "unassigned"
	var unassigned_check: Dictionary = GameModule.new().validate_state(unassigned_anatomy)
	_expect(not unassigned_check["ok"], "una criatura jugable no vuelve a anatomia pendiente")
	_expect_equal(unassigned_check["code"], "JCP_CREATURE_ANATOMY_UNASSIGNED", "el rechazo distingue anatomia conocida pero pendiente")
	var duplicated_family: Dictionary = engine.export_module_state()
	duplicated_family["cards"]["definitions"]["M01"]["attributes"]["families"] = ["wolf", "wolf"]
	var family_check: Dictionary = GameModule.new().validate_state(duplicated_family)
	_expect(not family_check["ok"], "una familia repetida se rechaza")
	_expect_equal(family_check["code"], "JCP_CREATURE_FAMILIES_INVALID", "el rechazo de familia repetida es especifico")


func _start(seed: int):
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	return engine if engine.start(seed).success else null


func _reach_main(engine) -> bool:
	return _perform(engine, "advance_phase", {}, "advance") and _perform(engine, "advance_phase", {}, "advance")


func _perform(engine, type: String, payload: Dictionary, prefix: String) -> bool:
	return engine.perform_action(GameAction.new(type, 0, payload, _next_request(prefix))).success


func _find_in_hand(state: Dictionary, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:0"]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


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
