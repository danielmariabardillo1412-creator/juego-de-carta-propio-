extends SceneTree
## Recorre dos invocaciones normales y dos clics de materiales propios para una Fusión real.

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
						_fail("no se pudo invocar material")
						return
					break
		var advanced := false
		for legal in engine.get_legal_actions(actor):
			if legal.type == "advance_phase":
				advanced = engine.perform_action(GameAction.new(legal.type, actor, legal.payload, "fusion-gui-advance-%d" % step)).success
				break
		if not advanced:
			_fail("no avanzó la fase hasta reunir materiales")
			return
	if not fusion_found:
		_fail("no aparecieron dos materiales compatibles en Principal")
		return
	table.call("_refresh")
	await process_frame
	var first: CardTile = _find_tile(table, materials[0])
	if first == null:
		_fail("no aparece el primer material en la mesa")
		return
	var second: CardTile = _find_tile(table, materials[1])
	if second == null or not first.get("_fusion_drag_enabled") or materials[0] not in second.get("_fusion_drop_sources"):
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
		_fail("el segundo material no se ilumina al iniciar el arrastre")
		return
	table.call("_on_fusion_drag_failed", materials[0])
	first = _find_tile(table, materials[0])
	second = _find_tile(table, materials[1])
	var before_drag: int = table.debug_snapshot()["state_version"]
	await _drag(first.get_global_rect().get_center(), second.get_global_rect().get_center())
	if table.get("_choice_actions").is_empty() or not table.get("_choice_overlay").visible or table.debug_snapshot()["state_version"] != before_drag:
		_fail("arrastrar material no abre confirmación sin mutar")
		return
	if not table.get("_choice_overlay_title").text.contains("0 ENERGÍA"):
		_fail("la confirmación no muestra el pago real de Fusión normal")
		return
	await RenderingServer.frame_post_draw
	var capture_path := ProjectSettings.globalize_path("res://artifacts/manual_table_fusion_preview.png")
	if root.get_texture().get_image().save_png(capture_path) != OK:
		_fail("no se pudo capturar la confirmación de Fusión")
		return
	table.call("_cancel_choices")
	if table.debug_snapshot()["state_version"] != before_drag:
		_fail("cancelar Fusión arrastrada cambió el motor")
		return
	first = _find_tile(table, materials[0])
	await _click(first.get_global_rect().get_center())
	if table.debug_snapshot()["selected_card_id"] != materials[0] or not table.get("_selection_label").text.contains("FUSIÓN"):
		_fail("primer clic no explica la Fusión")
		return
	second = _find_tile(table, materials[1])
	if second == null:
		_fail("no aparece el segundo material en la mesa")
		return
	var before: int = table.debug_snapshot()["state_version"]
	await _click(second.get_global_rect().get_center())
	var choices: Array = table.get("_choice_actions")
	if choices.is_empty() or not table.get("_choice_overlay").visible or table.debug_snapshot()["state_version"] != before:
		_fail("segundo clic no abrió las opciones sin mutar")
		return
	var button: Button = table.get("_choice_overlay_list").get_child(0)
	await _click(button.get_global_rect().get_center())
	if table.get("_last_committed_action").get("type", "") != "fuse_creatures":
		_fail("la elección no confirmó Fusión en UCE")
		return
	print("FUSION_GUI PASS: arrastre y dos clics, cancelación, coste 0 y Fusión confirmada")
	table.queue_free()
	quit(0)


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


func _find_tile(node: Node, instance_id: String) -> CardTile:
	if node is CardTile and node.instance_id == instance_id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, instance_id)
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


func _drag(origin: Vector2, target: Vector2) -> void:
	var down := InputEventMouseButton.new()
	down.position = origin
	down.global_position = origin
	down.button_index = MOUSE_BUTTON_LEFT
	down.button_mask = MOUSE_BUTTON_MASK_LEFT
	down.pressed = true
	Input.parse_input_event(down)
	await process_frame
	for fraction in [0.12, 0.45, 0.72, 1.0]:
		var motion := InputEventMouseMotion.new()
		motion.position = origin.lerp(target, fraction)
		motion.global_position = motion.position
		motion.relative = (target - origin) * 0.25
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(motion)
		await process_frame
	var up := InputEventMouseButton.new()
	up.position = target
	up.global_position = target
	up.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _fail(message: String) -> void:
	printerr("FUSION_GUI FAIL: ", message)
	quit(1)
