extends SceneTree
## UX-06: las acciones comunes deben vivir en tablero/contexto y respetar el presupuesto de clics.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false

	var snapshot: Dictionary = table.debug_snapshot()
	var common_direct := [
		"summon_creature", "set_creature", "set_support", "play_persistent", "play_terrain",
		"play_main_spell", "equip_item", "attack", "activate_creature_ability", "activate_fusion_ability",
	]
	for action_type in common_direct:
		_check(action_type in snapshot["direct_board_action_types"], "%s está absorbida por tablero/contexto" % action_type)

	# Colocar una criatura real permite probar el menú contextual sin depender de encontrar M09 en una semilla concreta.
	var summon := _first_action(snapshot["legal_actions"], "summon_creature")
	_check(not summon.is_empty(), "existe una criatura invocable para probar el menú contextual")
	if summon.is_empty() or not table.call("_perform_action", summon):
		_failures.append("no se pudo preparar una criatura de campo")
		_finish(table)
		return
	await process_frame
	var source_id: String = summon["payload"]["instance_id"]
	table.call("_select_card", source_id)
	await process_frame

	var visible_cards: Dictionary = table.call("_visible_cards_by_id", table.get("_engine").get_player_state(0)["game"]["card_table"])
	var single_ability := {
		"type": "activate_creature_ability",
		"actor_id": 0,
		"payload": {"source_instance_id": source_id},
		"label": "Habilidad contextual de prueba",
		"metadata": {"cost": 1},
	}
	table.call("_clear_children", table.get("_creature_action_buttons"))
	table.call("_render_creature_action_popup", [single_ability], visible_cards)
	var ability_button: Button = table.find_child("CreatureAbilityAction", true, false)
	_check(ability_button != null, "una habilidad activada aparece junto a la criatura")
	if ability_button != null:
		var carried: Array = ability_button.get_meta("jcp_ability_actions", [])
		_check_equal(carried.size(), 1, "el botón contextual conserva una única acción exacta")
		if carried.size() == 1:
			_check_equal(carried[0], single_ability, "el botón contextual conserva payload/actor/tipo sin reinterpretarlo")

	# Una habilidad con varios objetivos conserva el mismo botón y delega la elección posterior.
	var multi_ability := [
		{
			"type": "activate_fusion_ability",
			"actor_id": 0,
			"payload": {"source_instance_id": source_id, "target_instance_id": source_id},
			"label": "Habilidad objetivo A",
			"metadata": {"cost": 1},
		},
		{
			"type": "activate_fusion_ability",
			"actor_id": 0,
			"payload": {"source_instance_id": source_id, "target_instance_id": "TARGET-B"},
			"label": "Habilidad objetivo B",
			"metadata": {"cost": 1},
		},
	]
	table.call("_clear_children", table.get("_creature_action_buttons"))
	table.call("_render_creature_action_popup", multi_ability, visible_cards)
	ability_button = table.find_child("CreatureAbilityAction", true, false)
	_check(ability_button != null, "habilidad con varios objetivos sigue naciendo junto a la criatura")
	if ability_button != null:
		var carried_multi: Array = ability_button.get_meta("jcp_ability_actions", [])
		_check_equal(carried_multi.size(), 2, "el botón contextual conserva las dos opciones de objetivo")
		_check(ability_button.tooltip_text.contains("objetivo"), "la UI comunica que todavía falta elegir objetivo")

	# La vieja confirmación territorial añadía un clic sin decisión estratégica: debe haber desaparecido.
	_check(not _has_dialog_title(table, "Cambiar el Territorio"), "Terreno no conserva confirmación redundante de sustitución")

	_finish(table)


func _first_action(actions: Array, action_type: String) -> Dictionary:
	for action in actions:
		if action["type"] == action_type:
			return action
	return {}


func _has_dialog_title(node: Node, title: String) -> bool:
	if node is ConfirmationDialog and node.title == title:
		return true
	for child in node.get_children():
		if _has_dialog_title(child, title):
			return true
	return false


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


func _check_equal(actual, expected, label: String) -> void:
	_check(actual == expected, "%s (esperado=%s actual=%s)" % [label, str(expected), str(actual)])


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("CLICK_BUDGET PASS: %d checks — acciones comunes contextuales y Terreno sin confirmación extra" % _checks)
		quit(0)
		return
	printerr("CLICK_BUDGET FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
