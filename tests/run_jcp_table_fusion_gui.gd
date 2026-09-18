extends SceneTree
## Demuestra que drag y click-click de una Fusión real desembocan en el mismo comando UCE.

const GameAction = preload("res://src/core/game_action.gd")
const CardTile = preload("res://demo/card_tile.gd")
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	table.get("_ai_enabled").button_pressed = false
	table.get("_auto_follow").button_pressed = false

	var prepared: Dictionary = await _prepare_fusion(table)
	if not prepared.get("ok", false):
		_fail(prepared.get("error", "no se pudo preparar Fusión"))
		return
	var materials: Array = prepared["materials"]
	var first: CardTile = _find_tile(table, materials[0])
	var second: CardTile = _find_tile(table, materials[1])
	if first == null or second == null:
		_fail("no aparecen ambos materiales en la mesa")
		return
	if not first.get("_fusion_drag_enabled") or materials[0] not in second.get("_fusion_drop_sources"):
		_fail("los materiales compatibles no permiten arrastre dirigido")
		return
	if second._can_drop_data(Vector2.ZERO, {"kind": "fusion_material", "instance_id": "INVALIDO"}) or first._can_drop_data(Vector2.ZERO, {"kind": "fusion_material", "instance_id": materials[0]}):
		_fail("una carta ajena o la misma carta se aceptó como material")
		return

	table.call("_on_fusion_drag_started", materials[0])
	var lit := false
	for child in second.get_parent().get_children():
		if child is ProjectedFieldPiece and child.highlighted:
			lit = true
	if not lit:
		_fail("el segundo material no se ilumina al iniciar la ruta de drag")
		return
	table.call("_on_fusion_drag_failed", materials[0])

	# Ruta lógica de drag: el drop debe desembocar en el mismo conjunto de acciones UCE sin mutar.
	var before_drag: int = table.debug_snapshot()["state_version"]
	table.call("_on_fusion_dropped", materials[0], materials[1])
	var drag_choices: Array = table.get("_choice_actions")
	if drag_choices.is_empty() or not table.get("_choice_overlay").visible or table.debug_snapshot()["state_version"] != before_drag:
		_fail("la ruta drag no abre confirmación sin mutar")
		return
	if not table.get("_choice_overlay_title").text.contains("0 ENERGÍA"):
		_fail("la confirmación no muestra el pago real de Fusión normal")
		return
	var drag_choice: Dictionary = drag_choices[0].duplicate(true)
	var drag_command := _command_signature(drag_choice)

	# Antes del COMMIT, el segundo material puede deseleccionarse sin perder el primero.
	var change_second: Button = _find_named_button(table, "FusionChangeSecondMaterial")
	if change_second == null:
		_fail("la confirmación de Fusión no ofrece cambiar el segundo material")
		return
	change_second.emit_signal("pressed")
	await process_frame
	var back_to_one: Dictionary = table.debug_snapshot()
	if back_to_one["state_version"] != before_drag:
		_fail("cambiar el segundo material mutó UCE antes del COMMIT")
		return
	if back_to_one["selected_card_id"] != materials[0] or not back_to_one["status_message"].contains("FUSIÓN 1/2"):
		_fail("cambiar segundo material no conserva claramente el primero")
		return
	if not table.get("_choice_actions").is_empty() or table.get("_choice_overlay").visible:
		_fail("volver a FUSIÓN 1/2 dejó abierta la confirmación anterior")
		return
	second = _find_tile(table, materials[1])
	var second_reenabled := false
	if second != null:
		for child in second.get_parent().get_children():
			if child is ProjectedFieldPiece and child.highlighted:
				second_reenabled = true
	if not second_reenabled:
		_fail("al deseleccionar el segundo material no se vuelven a iluminar socios compatibles")
		return

	# Volver a elegir el segundo material restaura una sola confirmación final.
	var target_slot_back: int = table.call("_visual_slot_for", "creatures", 0, materials[1])
	table.call("_on_board_card_selected", materials[1], 0, "creatures", target_slot_back)
	if table.get("_choice_actions").is_empty() or not table.get("_choice_overlay").visible:
		_fail("reelegir el segundo material no restaura la confirmación de Fusión")
		return
	table.call("_cancel_choices")
	var canceled_all: Dictionary = table.debug_snapshot()
	if canceled_all["state_version"] != before_drag or canceled_all["selected_card_id"] != "":
		_fail("Cancelar Fusión no limpia toda la selección sin mutar UCE")
		return

	# Ruta lógica click-click sobre exactamente el mismo estado del motor.
	table.call("_select_card", materials[0])
	if table.debug_snapshot()["selected_card_id"] != materials[0] or not table.get("_selection_label").text.contains("FUSIÓN"):
		_fail("el primer clic lógico no explica la Fusión")
		return
	var before_click: int = table.debug_snapshot()["state_version"]
	var target_slot: int = table.call("_visual_slot_for", "creatures", 0, materials[1])
	table.call("_on_board_card_selected", materials[1], 0, "creatures", target_slot)
	var click_choices: Array = table.get("_choice_actions")
	if click_choices.is_empty() or not table.get("_choice_overlay").visible or table.debug_snapshot()["state_version"] != before_click:
		_fail("la ruta click-click no abre confirmación sin mutar")
		return
	var click_choice: Dictionary = click_choices[0].duplicate(true)
	var click_command := _command_signature(click_choice)
	if click_command != drag_command:
		_fail("drag y click-click no ofrecen exactamente el mismo comando UCE de Fusión")
		return

	# La confirmación usa la misma acción ya comparada.
	table.call("_perform_choice", click_choice)
	var committed: Dictionary = table.get("_last_committed_action").duplicate(true)
	if committed.get("type", "") != "fuse_creatures":
		_fail("la confirmación no ejecutó Fusión en UCE")
		return
	if table.debug_snapshot()["state_version"] != before_click + 1:
		_fail("confirmar Fusión debe producir exactamente una mutación")
		return
	if committed != drag_command or committed != click_command:
		_fail("el COMMIT final no coincide con el comando común de drag y click-click")
		return

	print("FUSION_GUI PASS: drag/click equivalentes; segundo material reversible, cancelación total y COMMIT único verificados")
	table.queue_free()
	quit(0)


func _prepare_fusion(table: Node) -> Dictionary:
	table.start_match(53927)
	await process_frame
	var engine = table.get("_engine")
	var materials: Array = []
	var fusion_found := false
	for step in range(120):
		var game: Dictionary = engine.get_player_state(0)["game"]
		var actor: int = game["active_player"]
		if actor == 0 and game["phase"] == "MAIN_1":
			materials = _material_ids(game["card_table"])
			if materials.size() == 2:
				for legal in engine.get_legal_actions(0):
					if legal.type == "fuse_creatures" and materials[0] in legal.payload.get("material_instance_ids", []) and materials[1] in legal.payload.get("material_instance_ids", []):
						fusion_found = true
						break
				if fusion_found:
					break
			var next_id := "M01" if materials.is_empty() else "M07"
			var instance_id := _definition_in_zone(game["card_table"], "hand:0", next_id)
			for legal in engine.get_legal_actions(0):
				if legal.type == "summon_creature" and legal.payload.get("instance_id", "") == instance_id:
					if not engine.perform_action(GameAction.new(legal.type, actor, legal.payload, "fusion-gui-summon-%d" % step)).success:
						return {"ok": false, "error": "no se pudo invocar material"}
					break
		var advanced := false
		for legal in engine.get_legal_actions(actor):
			if legal.type == "advance_phase":
				advanced = engine.perform_action(GameAction.new(legal.type, actor, legal.payload, "fusion-gui-advance-%d" % step)).success
				break
		if not advanced:
			return {"ok": false, "error": "no avanzó la fase hasta reunir materiales"}
	if not fusion_found:
		return {"ok": false, "error": "no aparecieron dos materiales compatibles en Principal"}
	table.call("_refresh")
	await process_frame
	return {"ok": true, "materials": materials}


func _command_signature(action: Dictionary) -> Dictionary:
	return {
		"type": action.get("type", ""),
		"actor_id": action.get("actor_id", -1),
		"payload": action.get("payload", {}).duplicate(true),
	}


func _material_ids(card_table: Dictionary) -> Array:
	var ids: Array = []
	for card in card_table["zones"]["creatures:0"]["cards"]:
		if card["definition"].get("id", "") in ["M01", "M07"]:
			ids.append(card["instance"]["id"])
	return ids


func _definition_in_zone(card_table: Dictionary, zone: String, definition_id: String) -> String:
	for card in card_table["zones"][zone]["cards"]:
		if card["definition"].get("id", "") == definition_id:
			return card["instance"]["id"]
	return ""


func _find_named_button(node: Node, button_name: String) -> Button:
	if node is Button and node.name == button_name:
		return node
	for child in node.get_children():
		var found := _find_named_button(child, button_name)
		if found != null:
			return found
	return null


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	printerr("FUSION_GUI FAIL: ", message)
	quit(1)
