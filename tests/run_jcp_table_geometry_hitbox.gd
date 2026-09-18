extends SceneTree
## UX-05: geometría e hitbox deben permanecer estables y compartir el mismo polígono proyectado.

const CardTile = preload("res://demo/card_tile.gd")
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")

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

	var source_id := _first_creature_id(table.debug_snapshot()["legal_actions"])
	var hand_tile: CardTile = _find_tile(table, source_id)
	_check(hand_tile != null, "existe una criatura jugable en mano")
	if hand_tile == null:
		_finish(table)
		return

	var hand_rect := hand_tile.get_global_rect()
	var slot_rects := _own_creature_slot_rects(table)
	_check_equal(slot_rects.size(), 5, "existen cinco casillas propias medibles")
	_check(_projected_hit_matches_visual(table.call("_field_slot", "creatures", 2)), "casilla vacía comparte polígono visual/hitbox")
	_check(_projected_hit_matches_visual(_terrain_lane(table)), "Terreno comparte polígono visual/hitbox")

	# Seleccionar solo cambia estado visual, nunca geometría.
	table.call("_select_card", source_id)
	await process_frame
	hand_tile = _find_tile(table, source_id)
	_check(_same_rect(hand_rect, hand_tile.get_global_rect()), "seleccionar no mueve ni redimensiona la carta en mano")
	_check(_same_rect_list(slot_rects, _own_creature_slot_rects(table)), "seleccionar no mueve las casillas del campo")
	_check(_projected_hit_matches_visual(table.call("_field_slot", "creatures", 2)), "resaltado de selección conserva hitbox proyectada")

	# Cancelar tampoco debe desplazar nada.
	table.call("_cancel_pending_interaction", "cancel test")
	await process_frame
	hand_tile = _find_tile(table, source_id)
	_check(_same_rect(hand_rect, hand_tile.get_global_rect()), "cancelar no mueve la carta en mano")
	_check(_same_rect_list(slot_rects, _own_creature_slot_rects(table)), "cancelar no mueve las casillas")

	# Iniciar drag lógico ilumina destinos pero no puede recolocar la mesa.
	table.call("_on_creature_drag_started", source_id)
	await process_frame
	hand_tile = _find_tile(table, source_id)
	_check(_same_rect(hand_rect, hand_tile.get_global_rect()), "iniciar drag no mueve la carta origen")
	_check(_same_rect_list(slot_rects, _own_creature_slot_rects(table)), "iniciar drag no mueve destinos")
	_check(_projected_hit_matches_visual(table.call("_field_slot", "creatures", 2)), "drag conserva igualdad visual/hitbox")
	table.call("_on_creature_drag_failed", source_id)
	await process_frame

	# Colocar una criatura en Ataque mediante el mismo estado contextual ya probado por CREATURE-UX.
	table.call("_select_card", source_id)
	table.call("_on_empty_slot_pressed", 0, "creatures", 2)
	var summon := _candidate_action(table, "summon_creature")
	_check(not summon.is_empty(), "C3 ofrece invocación en Ataque")
	if not summon.is_empty():
		table.call("_commit_creature_mode", summon)
		await process_frame
		var field_tile: CardTile = _find_tile(table, source_id)
		_check(field_tile != null, "la criatura colocada sigue siendo una superficie interactiva")
		if field_tile != null:
			var holder: Control = field_tile.get_parent()
			var visual := _first_projected_piece(holder)
			var polygon: PackedVector2Array = field_tile.projected_hit_polygon()
			_check(visual != null and polygon.size() == 4, "la criatura ocupada recibe polígono proyectado")
			if visual != null and polygon.size() == 4:
				_check(_same_polygon(polygon, visual.template_corners), "carta ocupada y dibujo comparten exactamente el mismo polígono")
				_check(field_tile._has_point(_polygon_center(polygon)), "centro visible de la carta ocupada es clicable")
				_check(not field_tile._has_point(Vector2.ZERO), "esquina exterior al trapecio de la carta ocupada no es clicable")

	_finish(table)


func _projected_hit_matches_visual(control: Control) -> bool:
	if control == null or not control.has_method("projected_hit_polygon"):
		return false
	var visual := _first_projected_piece(control)
	if visual == null:
		return false
	var polygon: PackedVector2Array = control.call("projected_hit_polygon")
	if polygon.size() != 4 or not _same_polygon(polygon, visual.template_corners):
		return false
	if not control._has_point(_polygon_center(polygon)):
		return false
	return not control._has_point(Vector2.ZERO)


func _first_projected_piece(node: Node) -> ProjectedFieldPiece:
	for child in node.get_children():
		if child is ProjectedFieldPiece:
			return child
	return null


func _terrain_lane(node: Node) -> Control:
	if node is Control and node.get_meta("board_role", "") == "terrain_lane":
		return node
	for child in node.get_children():
		var found := _terrain_lane(child)
		if found != null:
			return found
	return null


func _own_creature_slot_rects(table: Node) -> Array:
	var rects: Array = []
	for slot in range(5):
		var control: Control = table.call("_field_slot", "creatures", slot)
		rects.append(control.get_global_rect())
	return rects


func _same_rect_list(a: Array, b: Array) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if not _same_rect(a[index], b[index]):
			return false
	return true


func _same_rect(a: Rect2, b: Rect2) -> bool:
	return a.position.distance_to(b.position) < 0.1 and a.size.distance_to(b.size) < 0.1


func _same_polygon(a: PackedVector2Array, b: PackedVector2Array) -> bool:
	if a.size() != b.size():
		return false
	for index in range(a.size()):
		if a[index].distance_to(b[index]) >= 0.1:
			return false
	return true


func _polygon_center(polygon: PackedVector2Array) -> Vector2:
	var center := Vector2.ZERO
	for point in polygon:
		center += point
	return center / float(polygon.size())


func _first_creature_id(actions: Array) -> String:
	for action in actions:
		if action["type"] == "summon_creature":
			return action["payload"].get("instance_id", "")
	return ""


func _candidate_action(table: Node, action_type: String) -> Dictionary:
	for action in table.get("_creature_interaction").candidate_actions:
		if action["type"] == action_type:
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


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


func _check_equal(actual, expected, label: String) -> void:
	_check(actual == expected, "%s (esperado=%s actual=%s)" % [label, str(expected), str(actual)])


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("GEOMETRY_HITBOX PASS: %d checks — geometría estable y hitbox proyectada compartida" % _checks)
		quit(0)
		return
	printerr("GEOMETRY_HITBOX FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
