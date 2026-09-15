extends SceneTree
## Un resultado con varias posturas/objetivos no se presenta como varios resultados.


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	var fusion_actions: Array = []
	for position in ["attack", "guard"]:
		for target in ["T1", "T2"]:
			fusion_actions.append({"type": "fuse_creatures", "label": "Fusionar: Elemental de Vapor", "payload": {"position": position, "target_instance_id": target}})
	table.set("_choice_actions", fusion_actions)
	table.call("_render_choice_buttons", {"T1": "Banda Goblin", "T2": "Ordina"})
	var list: VBoxContainer = table.get("_choice_overlay_list")
	if list.get_child_count() != 2 or not table.get("_choice_overlay_title").text.contains("Elemental de Vapor"):
		_fail("la Fusión se repite en lugar de ofrecer dos posturas")
		return
	if not list.get_child(0).text.begins_with("ATAQUE") or not list.get_child(1).text.begins_with("GUARDIA"):
		_fail("las dos decisiones de postura no son claras")
		return
	table.set("_choice_actions", [fusion_actions[0], fusion_actions[1]])
	table.set("_choice_stage", "targets")
	table.call("_clear_children", list)
	table.call("_render_choice_buttons", {"T1": "Banda Goblin", "T2": "Ordina"})
	if list.get_child_count() != 2 or not list.get_child(0).text.contains("Banda Goblin") or not list.get_child(1).text.contains("Ordina"):
		_fail("elegir Ataque no muestra los dos objetivos reales")
		return
	var summon_actions: Array = [
		{"type": "summon_creature", "label": "Invocar Troll Chamán", "payload": {"instance_id": "M15", "target_instance_id": "T1"}},
		{"type": "summon_creature", "label": "Invocar Troll Chamán", "payload": {"instance_id": "M15", "target_instance_id": "T2"}},
		{"type": "set_creature", "label": "Colocar Troll Chamán", "payload": {"instance_id": "M15"}},
	]
	table.set("_choice_actions", summon_actions)
	table.set("_choice_stage", "")
	table.call("_clear_children", list)
	table.call("_render_choice_buttons", {"T1": "Banda Goblin", "T2": "Ordina"})
	if list.get_child_count() != 2 or not list.get_child(0).text.begins_with("ATAQUE") or not list.get_child(1).text.begins_with("GUARDIA"):
		_fail("una criatura con habilidad de entrada debe ofrecer solo Ataque o Guardia inicialmente")
		return
	print("CHOICE_DIALOGS PASS: una Fusión/un monstruo, dos posturas y objetivos separados")
	table.queue_free()
	quit(0)


func _fail(message: String) -> void:
	printerr("CHOICE_DIALOGS FAIL: ", message)
	quit(1)
