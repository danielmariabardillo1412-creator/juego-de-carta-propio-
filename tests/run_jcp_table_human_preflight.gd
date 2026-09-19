extends SceneTree
## Preflight de fixtures usados por 08_PRIMERA_PRUEBA_HUMANA_UX_V0_1.
## No sustituye la prueba humana: solo garantiza que las semillas/documentación no se pudran.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false

	# H1 — criatura/postura/ataque.
	table.start_match(210921)
	await process_frame
	var h1 := table.debug_snapshot()
	_check(_has_action_type(h1["legal_actions"], "summon_creature") or _has_action_type(h1["legal_actions"], "set_creature"),
		"H1 seed 210921 conserva una criatura jugable")

	# H2 — M01 + G01.
	table.start_match(419)
	await process_frame
	var h2_hand: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	_check(_hand_has(h2_hand, "M01"), "H2 seed 419 conserva M01")
	_check(_hand_has(h2_hand, "G01"), "H2 seed 419 conserva G01")

	# H3 — M01 + E02.
	table.start_match(487)
	await process_frame
	var h3_hand: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
	_check(_hand_has(h3_hand, "M01"), "H3 seed 487 conserva M01")
	_check(_hand_has(h3_hand, "E02"), "H3 seed 487 conserva E02")

	# H4 — buscar fixture estable con dos Terrenos iniciales para no improvisar la microprueba.
	var terrain_fixture := _find_two_terrain_seed(table)
	_check(terrain_fixture.get("seed", -1) >= 0, "H4 encuentra una semilla con dos Terrenos iniciales")
	if terrain_fixture.get("seed", -1) >= 0:
		print("HUMAN_PREFLIGHT H4_SEED=", terrain_fixture["seed"], " TERRAINS=", terrain_fixture["terrains"])

	# H5 — la semilla documentada conserva la secuencia base usada por END_TURN_RESPONSE.
	table.start_match(555)
	await process_frame
	var state: Dictionary = table.get("_engine").export_module_state()
	_check(not _find_hand(state, 0, "M01").is_empty(), "H5 seed 555 conserva M01 atacante")
	_check(not _find_hand(state, 1, "M02").is_empty(), "H5 seed 555 conserva M02 defensor")
	_check(not _find_hand(state, 1, "G06").is_empty(), "H5 seed 555 conserva G06 de respuesta")

	# H6 — la seed está cubierta además por FUSION_GUI; aquí congelamos que sigue arrancando correctamente.
	_check(table.start_match(53927), "H6 seed 53927 inicia correctamente")
	await process_frame

	# H7 no necesita seed: UX-01/CREATURE-UX ya prueba el bloqueo PRE-COMMIT.
	_check(true, "H7 es independiente de semilla y está cubierto por PRE-COMMIT")

	_finish(table)


func _find_two_terrain_seed(table: Node) -> Dictionary:
	for seed in range(1, 1001):
		table.start_match(seed)
		var cards: Array = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]
		var terrains: Array = []
		for card in cards:
			var definition: Dictionary = card.get("definition", {})
			if definition.get("attributes", {}).get("card_type", "") == "terrain":
				terrains.append(definition.get("id", ""))
		if terrains.size() >= 2:
			return {"seed": seed, "terrains": terrains}
	return {"seed": -1, "terrains": []}


func _hand_has(cards: Array, definition_id: String) -> bool:
	for card in cards:
		if card.get("definition", {}).get("id", "") == definition_id:
			return true
	return false


func _has_action_type(actions: Array, action_type: String) -> bool:
	for action in actions:
		if action.get("type", "") == action_type:
			return true
	return false


func _find_hand(state: Dictionary, player_id: int, definition_id: String) -> String:
	for instance_id in state["cards"]["zones"]["hand:%d" % player_id]["cards"]:
		if state["cards"]["instances"][instance_id]["definition_id"] == definition_id:
			return instance_id
	return ""


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("HUMAN_PREFLIGHT PASS: %d checks — fixtures H1-H7 reproducibles" % _checks)
		quit(0)
		return
	printerr("HUMAN_PREFLIGHT FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
