extends SceneTree
## Verifica clics gráficos reales en atacante y objetivo, no solo señales invocadas directamente.

const CardTile = preload("res://demo/card_tile.gd")

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	table.start_match(210921)
	await process_frame
	var summon: Dictionary = _first_action(table.debug_snapshot()["legal_actions"], "summon_creature")
	if summon.is_empty():
		_fail("no hay invocación inicial")
		return
	var attacker_id: String = summon["payload"]["instance_id"]
	table.call("_perform_action", summon)
	table.call("_confirm_end_turn")
	table.set_viewer(1, false)
	var defender: Dictionary = _first_action(table.debug_snapshot()["legal_actions"], "summon_creature")
	if defender.is_empty():
		defender = _first_action(table.debug_snapshot()["legal_actions"], "set_creature")
	if defender.is_empty():
		_fail("no hay defensor")
		return
	var defender_id: String = defender["payload"]["instance_id"]
	table.call("_perform_action", defender)
	table.call("_confirm_end_turn")
	table.set_viewer(0, false)
	await process_frame
	var attacker: CardTile = _find_tile(table, attacker_id)
	if attacker == null:
		_fail("no aparece atacante")
		return
	await _click(attacker.get_global_rect().get_center())
	await process_frame
	var selected: Dictionary = table.debug_snapshot()
	var attack_menu: Button = table.find_child("CreatureAttackAction", true, false)
	if selected["phase"] != "MAIN_1" or selected["selected_card_id"] != attacker_id or not selected["creature_action_popup_visible"] or attack_menu == null or attack_menu.disabled:
		_fail("seleccionar atacante no abre su menú local: fase=%s selección=%s popup=%s botón=%s" % [selected["phase"], selected["selected_card_id"], selected["creature_action_popup_visible"], "ausente" if attack_menu == null else str(attack_menu.disabled)])
		return
	var popup: Control = table.get("_creature_action_popup")
	var selected_tile: CardTile = _find_tile(table, attacker_id)
	if selected_tile == null or absf(popup.get_global_rect().get_center().x - selected_tile.get_global_rect().get_center().x) > 240.0:
		_fail("el menú de criatura debe aparecer junto a la carta")
		return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://artifacts/manual_table_creature_actions.png"))
	await _click(attack_menu.get_global_rect().get_center())
	if not table.debug_snapshot()["attack_targeting"] or _count_targeted(table) < 1:
		_fail("Atacar no ilumina objetivos legales")
		return
	var defender_tile: CardTile = _find_tile(table, defender_id)
	if defender_tile == null:
		defender_tile = _find_hidden_tile(table)
	if defender_tile == null:
		_fail("no aparece objetivo rival")
		return
	var before: int = selected["state_version"]
	await _click(defender_tile.get_global_rect().get_center())
	var after: Dictionary = table.debug_snapshot()
	if after["state_version"] != before + 2 or after["phase"] != "COMBAT" or table.get("_last_committed_action").get("type", "") != "attack":
		_fail("el clic en criatura rival no abrió Combate y ejecutó el ataque")
		return
	table.start_match(210921)
	await process_frame
	var first_turn_summon: Dictionary = _first_action(table.debug_snapshot()["legal_actions"], "summon_creature")
	if first_turn_summon.is_empty() or not table.call("_perform_action", first_turn_summon):
		_fail("no se pudo preparar el primer turno")
		return
	var first_turn_attacker: CardTile = _find_tile(table, first_turn_summon["payload"]["instance_id"])
	await _click(first_turn_attacker.get_global_rect().get_center())
	var first_turn_attack: Button = table.find_child("CreatureAttackAction", true, false)
	if first_turn_attack == null or not first_turn_attack.disabled:
		_fail("el menú debe explicar que el primer turno no permite atacar")
		return
	var enemy_empty: Control = _find_opponent_empty_slot(table)
	if enemy_empty == null:
		_fail("no aparece casilla rival vacía")
		return
	var unchanged: int = table.debug_snapshot()["state_version"]
	await _click(enemy_empty.get_global_rect().get_center())
	if table.debug_snapshot()["state_version"] != unchanged or table.debug_snapshot()["phase"] != "MAIN_1" or not table.get("_summary_label").text.contains("primer turno"):
		_fail("el primer turno debe impedir ataque directo sin cambiar fase")
		return
	table.call("_confirm_end_turn")
	table.set_viewer(1, false)
	table.call("_confirm_end_turn")
	table.set_viewer(0, false)
	await process_frame
	var direct_attacker: CardTile = _find_tile(table, first_turn_summon["payload"]["instance_id"])
	await _click(direct_attacker.get_global_rect().get_center())
	var direct_attack_button: Button = table.find_child("CreatureAttackAction", true, false)
	if direct_attack_button == null or direct_attack_button.disabled:
		_fail("no aparece Atacar al seleccionar criatura apta")
		return
	await _click(direct_attack_button.get_global_rect().get_center())
	var direct_heading: BaseButton = _find_direct_heading(table)
	if direct_heading == null:
		_fail("sin criaturas rivales no aparece Vida rival como objetivo directo")
		return
	var before_direct: Dictionary = table.debug_snapshot()
	await _click(direct_heading.get_global_rect().get_center())
	var after_direct: Dictionary = table.debug_snapshot()
	if after_direct["state_version"] != before_direct["state_version"] + 2 or table.get("_last_committed_action").get("type", "") != "attack":
		_fail("clic en Vida rival no ejecutó ataque directo automático")
		return
	if not table.get("_summary_label").text.contains("0 de daño"):
		_fail("el ataque del Cachorro con ATQ 0 debe explicar que no quitó Vida")
		return
	print("ATTACK_GUI PASS: atacante y objetivo por clic desde Principal 1, Combate automático")
	table.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("ATTACK_GUI FAIL: ", message)
	quit(1)


func _first_action(actions: Array, kind: String) -> Dictionary:
	for action in actions:
		if action["type"] == kind:
			return action
	return {}


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
		if found != null:
			return found
	return null


func _find_hidden_tile(node: Node) -> CardTile:
	if node is CardTile and node.instance_id.begins_with("hidden-slot-1-"):
		return node
	for child in node.get_children():
		var found := _find_hidden_tile(child)
		if found != null:
			return found
	return null


func _count_targeted(node: Node) -> int:
	var count := 1 if node is CardTile and node.get("_targeted") else 0
	for child in node.get_children():
		count += _count_targeted(child)
	return count


func _find_opponent_empty_slot(node: Node) -> Control:
	if node is Control and node.get_meta("board_role", "") == "creature_slot" and node is BaseButton:
		var ancestor := node.get_parent()
		while ancestor != null:
			if ancestor.name == "OpponentCreatureRow":
				return node
			ancestor = ancestor.get_parent()
	for child in node.get_children():
		var found := _find_opponent_empty_slot(child)
		if found != null:
			return found
	return null


func _find_direct_heading(node: Node) -> BaseButton:
	if node is BaseButton and node.text.contains("ATAQUE DIRECTO"):
		return node
	for child in node.get_children():
		var found := _find_direct_heading(child)
		if found != null:
			return found
	return null


func _click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	await process_frame
	var down := InputEventMouseButton.new()
	down.position = point
	down.global_position = point
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	var up := InputEventMouseButton.new()
	up.position = point
	up.global_position = point
	up.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(up)
	await process_frame
