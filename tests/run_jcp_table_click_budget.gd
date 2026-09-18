extends SceneTree
## UX-06: las acciones comunes deben cumplir presupuesto de clics y no depender del rail técnico.

const GameAction = preload("res://src/core/game_action.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false

	var found := _find_seed_with_m09(table)
	_check(found.get("ok", false), "se encuentra una apertura reproducible con M09 jugable")
	if not found.get("ok", false):
		_finish(table)
		return
	var m09_id: String = found["instance_id"]
	var summon: Dictionary = _action_for_source(table.debug_snapshot()["legal_actions"], "summon_creature", m09_id)
	_check(not summon.is_empty(), "M09 dispone de invocación normal")
	if summon.is_empty() or not table.call("_perform_action", summon):
		_failures.append("no se pudo invocar M09 para probar su habilidad")
		_finish(table)
		return
	await process_frame

	if not _has_source_action(table.call("_legal_actions"), "activate_creature_ability", m09_id):
		_check(_advance_to_next_own_main(table, 0), "se alcanza el siguiente Principal propio para recuperar Energía")
		await process_frame
	_check(_has_source_action(table.call("_legal_actions"), "activate_creature_ability", m09_id), "la habilidad real de M09 está legal")
	if not _has_source_action(table.call("_legal_actions"), "activate_creature_ability", m09_id):
		_finish(table)
		return

	table.call("_select_card", m09_id)
	await process_frame
	var ability_button: Button = table.find_child("CreatureAbilityAction", true, false)
	_check(ability_button != null and not ability_button.disabled, "M09 expone Habilidad junto a la propia criatura")
	_check(not _rail_contains(table, "Goblin Pendenciero"), "la habilidad de M09 no se duplica en el rail")
	var before: int = table.debug_snapshot()["state_version"]
	if ability_button != null:
		ability_button.emit_signal("pressed")
		await process_frame
	var after: Dictionary = table.debug_snapshot()
	_check_equal(after["state_version"], before + 1, "seleccionar criatura + Habilidad produce un único COMMIT")
	_check_equal(after["last_committed_action"].get("type", ""), "activate_creature_ability", "el botón contextual usa la acción UCE real")
	_check_equal(after["last_committed_action"].get("payload", {}).get("source_instance_id", ""), m09_id, "la habilidad conserva la fuente correcta")

	# Una habilidad con varios objetivos también debe nacer junto a la criatura, no en el rail.
	table.call("_select_card", m09_id)
	await process_frame
	table.call("_clear_children", table.get("_creature_action_buttons"))
	var synthetic_actions := [
		{"type": "activate_fusion_ability", "actor_id": 0, "payload": {"source_instance_id": m09_id, "target_instance_id": m09_id}, "label": "Habilidad objetivo A", "metadata": {}},
		{"type": "activate_fusion_ability", "actor_id": 0, "payload": {"source_instance_id": m09_id, "target_instance_id": "TARGET-B"}, "label": "Habilidad objetivo B", "metadata": {}},
	]
	var visible_cards: Dictionary = table.call("_visible_cards_by_id", table.get("_engine").get_player_state(0)["game"]["card_table"])
	table.call("_render_creature_action_popup", synthetic_actions, visible_cards)
	ability_button = table.find_child("CreatureAbilityAction", true, false)
	_check(ability_button != null, "una habilidad con varios objetivos conserva botón contextual Habilidad")
	if ability_button != null:
		_check(ability_button.tooltip_text.contains("objetivo"), "el botón contextual avisa que falta elegir objetivo")

	# El diálogo de confirmación territorial antiguo ya no debe existir: Terreno normal = selección + zona.
	_check(not _has_dialog_title(table, "Cambiar el Territorio"), "no existe confirmación extra de sustitución de Terreno")

	_finish(table)


func _find_seed_with_m09(table: Node) -> Dictionary:
	for seed in range(1, 121):
		table.start_match(seed)
		var snapshot: Dictionary = table.debug_snapshot()
		for card in snapshot["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]:
			if card["definition"].get("id", "") != "M09":
				continue
			var instance_id: String = card["instance"]["id"]
			if not _action_for_source(snapshot["legal_actions"], "summon_creature", instance_id).is_empty():
				return {"ok": true, "seed": seed, "instance_id": instance_id}
	return {"ok": false}


func _action_for_source(actions: Array, action_type: String, instance_id: String) -> Dictionary:
	for action in actions:
		if action["type"] == action_type and action["payload"].get("instance_id", "") == instance_id:
			return action
	return {}


func _has_source_action(actions: Array, action_type: String, instance_id: String) -> bool:
	for action in actions:
		if action["type"] == action_type and action["payload"].get("source_instance_id", "") == instance_id:
			return true
	return false


func _advance_to_next_own_main(table: Node, player_id: int) -> bool:
	var engine = table.get("_engine")
	var initial_turn: int = engine.get_public_state()["game"]["turn_number"]
	for step in range(30):
		var game: Dictionary = engine.get_public_state()["game"]
		if game["turn_number"] > initial_turn and game["active_player"] == player_id and game["phase"] == "MAIN_1":
			table.call("_refresh")
			return true
		var actor: int = game["response_window"].get("priority_player_id", game["active_player"]) if game["response_window"].get("active", false) else game["active_player"]
		var action: Dictionary = {}
		for legal in engine.get_legal_actions(actor):
			if legal.type in ["pass_reaction", "advance_phase"]:
				action = legal.to_dict()
				break
		if action.is_empty():
			return false
		var result = engine.perform_action(GameAction.new(action["type"], actor, action["payload"], "click-budget-%02d" % step))
		if not result.success:
			return false
	table.call("_refresh")
	return false


func _rail_contains(table: Node, fragment: String) -> bool:
	for child in table.get("_action_list").get_children():
		if child is Button and child.text.contains(fragment):
			return true
	return false


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
		print("CLICK_BUDGET PASS: %d checks — habilidades contextuales y Terreno sin confirmación extra" % _checks)
		quit(0)
		return
	printerr("CLICK_BUDGET FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
