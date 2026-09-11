extends SceneTree
## Recorrido visible: selección conservada en Principal 1 y ataque directo sobre objetivo en Combate.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	var table = scene.instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false
	var snapshot: Dictionary = table.debug_snapshot()
	var first_summon := _first_action(snapshot["legal_actions"], "summon_creature")
	_expect(not first_summon.is_empty(), "J1 dispone de una criatura invocable")
	if first_summon.is_empty():
		_finish(table)
		return
	var attacker_id: String = first_summon["payload"]["instance_id"]
	_expect(table.call("_perform_action", first_summon), "J1 invoca su atacante")
	table.call("_confirm_end_turn")
	table.set_viewer(1, false)
	snapshot = table.debug_snapshot()
	var rival_summon := _first_action(snapshot["legal_actions"], "set_creature")
	if rival_summon.is_empty():
		rival_summon = _first_action(snapshot["legal_actions"], "summon_creature")
	_expect(not rival_summon.is_empty(), "J2 dispone de una criatura para defender")
	if rival_summon.is_empty():
		_finish(table)
		return
	var defender_id: String = rival_summon["payload"]["instance_id"]
	var defender_hidden: bool = rival_summon["type"] == "set_creature"
	_expect(table.call("_perform_action", rival_summon), "J2 ocupa su campo")
	table.call("_confirm_end_turn")
	table.set_viewer(0, false)
	snapshot = table.debug_snapshot()
	_expect_equal(snapshot["phase"], "MAIN_1", "J1 recupera control en Principal 1")
	var attacker_visual: int = table.call("_visual_slot_for", "creatures", 0, attacker_id)
	table.call("_on_board_card_selected", attacker_id, 0, "creatures", attacker_visual)
	var defender_visual: int = table.call("_visual_slot_for", "creatures", 1, defender_id)
	table.call("_on_board_card_selected", defender_id, 1, "creatures", defender_visual)
	snapshot = table.debug_snapshot()
	_expect_equal(snapshot["selected_card_id"], attacker_id, "pulsar al rival antes de Combate conserva el atacante")
	_expect(snapshot["status_message"].contains("IR A COMBATE"), "la mesa explica el paso que falta")
	table.call("_advance_phase_pressed")
	snapshot = table.debug_snapshot()
	_expect_equal(snapshot["phase"], "COMBAT", "el control superior entra en Combate")
	table.call("_select_card", attacker_id)
	var before_attack: int = table.debug_snapshot()["state_version"]
	if defender_hidden:
		var hidden_slot := _first_target_slot(table.debug_snapshot()["legal_actions"], attacker_id)
		_expect(hidden_slot >= 0, "la criatura oculta tiene una casilla pública atacable")
		table.call("_on_hidden_board_card_selected", "hidden", 1, "creatures", hidden_slot)
	else:
		table.call("_on_board_card_selected", defender_id, 1, "creatures", defender_visual)
	snapshot = table.debug_snapshot()
	_expect(snapshot["state_version"] > before_attack, "pulsar el objetivo declara el ataque")
	_expect_equal(snapshot["selected_card_id"], "", "el ataque aplicado limpia la selección")
	_finish(table)


func _first_action(actions: Array, action_type: String) -> Dictionary:
	for action in actions:
		if action["type"] == action_type:
			return action
	return {}


func _first_target_slot(actions: Array, attacker_id: String) -> int:
	for action in actions:
		if action["type"] == "attack" and action["payload"].get("attacker_id", "") == attacker_id:
			return int(action["payload"].get("target_slot", -1))
	return -1


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_expect(actual == expected, "%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("JCP-TABLE-ATTACK-FLOW PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-TABLE-ATTACK-FLOW FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
