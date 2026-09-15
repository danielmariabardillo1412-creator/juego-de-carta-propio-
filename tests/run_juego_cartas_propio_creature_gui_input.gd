extends SceneTree
## Prueba gráfica de eventos GUI reales, además de la suite de estado/acciones.

const CardTile = preload("res://demo/card_tile.gd")

var _failures: Array = []
var _checks := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	var table = scene.instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	var id := _first_creature_id(table.debug_snapshot()["legal_actions"])
	var tile := _find_tile(table, id)
	if tile == null:
		_failures.append("No existe carta jugable")
		_finish(table)
		return
	var hand_center: Vector2 = tile.get_global_rect().get_center()
	var before: int = table.debug_snapshot()["state_version"]
	await _click(hand_center)
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "TARGET_SELECTION", "clic GUI selecciona criatura")
	_check(table.debug_snapshot()["state_version"] == before, "clic GUI no muta")
	await _key_escape()
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "IDLE", "Escape GUI cancela")
	_check(table.debug_snapshot()["state_version"] == before, "Escape GUI no muta")
	tile = _find_tile(table, id)
	await _click(tile.get_global_rect().get_center())
	await _click(Vector2(1130, 710))
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "IDLE", "clic GUI en mesa vacía cancela")
	_check(table.debug_snapshot()["state_version"] == before, "clic GUI vacío no muta")
	# La escena reconstruye controles tras cancelar: obtener posiciones recientes.
	tile = _find_tile(table, id)
	hand_center = tile.get_global_rect().get_center()
	await _click(hand_center)
	var slot: Control = table.call("_field_slot", "creatures", 2)
	await _click(slot.get_global_rect().get_center())
	await process_frame
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "MODE_SELECTION", "clic GUI en C3 abre los modos")
	_check(table.debug_snapshot()["state_version"] == before, "C3 GUI no muta con dos modos")
	if table.get("_creature_mode_buttons").get_child_count() == 0:
		_failures.append("Menú GUI no apareció")
		_finish(table)
		return
	var mode_button: Button = table.get("_creature_mode_buttons").get_child(0)
	await _click(mode_button.get_global_rect().get_center())
	_check(table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"] == 1, "clic GUI en Ataque coloca criatura")
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "IDLE", "clic GUI vuelve a IDLE")
	table.start_match(210921)
	await process_frame
	id = _first_creature_id(table.debug_snapshot()["legal_actions"])
	tile = _find_tile(table, id)
	before = table.debug_snapshot()["state_version"]
	var outside := Vector2(1150, 710)
	await _drag(tile.get_global_rect().get_center(), outside)
	_check(table.debug_snapshot()["state_version"] == before, "drag GUI inválido no muta")
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "IDLE", "drag GUI inválido cancela")
	tile = _find_tile(table, id)
	slot = table.call("_field_slot", "creatures", 2)
	await _drag(tile.get_global_rect().get_center(), slot.get_global_rect().get_center())
	_check(table.debug_snapshot()["creature_interaction"]["phase"] == "MODE_SELECTION", "drag GUI legal abre los mismos modos")
	_check(table.debug_snapshot()["state_version"] == before, "drag GUI legal no confirma antes del modo")
	mode_button = table.get("_creature_mode_buttons").get_child(1)
	await _click(mode_button.get_global_rect().get_center())
	_check(table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"] == 1, "drag GUI + Guardia coloca criatura")
	_finish(table)


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
	up.pressed = false
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
	up.pressed = false
	Input.parse_input_event(up)
	await process_frame
	await process_frame


func _key_escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame


func _first_creature_id(actions: Array) -> String:
	for action in actions:
		if action["type"] == "summon_creature":
			return action["payload"]["instance_id"]
	return ""


func _find_tile(node: Node, id: String) -> CardTile:
	if node is CardTile and node.instance_id == id:
		return node
	for child in node.get_children():
		var found := _find_tile(child, id)
		if found != null:
			return found
	return null


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("JCP-CREATURE-GUI-INPUT PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-CREATURE-GUI-INPUT FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
