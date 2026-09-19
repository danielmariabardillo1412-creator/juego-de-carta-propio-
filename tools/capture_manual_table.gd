extends SceneTree
## Captura reproducible de la mesa a la resolución de escritorio del prototipo.

const ONBOARDING_PATH := "res://artifacts/manual_table_onboarding.png"
const OUTPUT_PATH := "res://artifacts/manual_table_preview.png"
const INTERACTION_PATH := "res://artifacts/manual_table_interaction_preview.png"
const CHOICE_PATH := "res://artifacts/manual_table_choice_preview.png"
const ATTACK_PATH := "res://artifacts/manual_table_attack_projected.png"
const GUARD_PATH := "res://artifacts/manual_table_guard_projected.png"
const ProjectedFieldPiece = preload("res://demo/projected_field_piece.gd")


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	root.size = Vector2i(1600, 900)
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	if scene == null:
		printerr("No se pudo cargar la mesa.")
		quit(1)
		return
	var table := scene.instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := _save_viewport(ONBOARDING_PATH)
	if error != OK:
		printerr("No se pudo guardar la captura de onboarding: %s" % error_string(error))
		quit(1)
		return
	var onboarding: Node = table.find_child("PrehumanOnboarding", true, false)
	if onboarding != null:
		onboarding.close()
	await process_frame
	await RenderingServer.frame_post_draw
	error = _save_viewport(OUTPUT_PATH)
	if error != OK:
		printerr("No se pudo guardar la captura inicial: %s" % error_string(error))
		quit(1)
		return
	for action in table.debug_snapshot()["legal_actions"]:
		if action["type"] == "summon_creature":
			table.call("_select_card", action["payload"]["instance_id"])
			break
	await process_frame
	await RenderingServer.frame_post_draw
	error = _save_viewport(INTERACTION_PATH)
	if error != OK:
		printerr("No se pudo guardar la captura interactiva: %s" % error_string(error))
		quit(1)
		return
	table.call("_on_empty_slot_pressed", 0, "creatures", 2)
	await process_frame
	await RenderingServer.frame_post_draw
	error = _save_viewport(CHOICE_PATH)
	if error != OK:
		printerr("No se pudo guardar la captura de elección: %s" % error_string(error))
		quit(1)
		return
	table.queue_free()
	await process_frame
	if not await _capture_placed_creature("summon_creature", "attack", ATTACK_PATH):
		quit(1)
		return
	if not await _capture_placed_creature("set_creature", "guard", GUARD_PATH):
		quit(1)
		return
	print("JCP-TABLE-CAPTURE PASS: 6 capturas (1600x900), onboarding + mesa + Ataque y Guardia reales")
	quit(0)


func _capture_placed_creature(action_type: String, posture: String, path: String) -> bool:
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	var table := scene.instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	var chosen: Dictionary = {}
	for action in table.debug_snapshot()["legal_actions"]:
		if action["type"] == action_type:
			chosen = action
			break
	if chosen.is_empty():
		printerr("No se pudo colocar una criatura real en %s" % posture)
		table.queue_free()
		return false
	table.call("_select_card", chosen["payload"]["instance_id"])
	table.call("_on_empty_slot_pressed", 0, "creatures", 2)
	if table.debug_snapshot()["creature_interaction"]["phase"] == "MODE_SELECTION":
		table.call("_commit_creature_mode", chosen)
	if table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["creatures:0"]["count"] != 1:
		printerr("La interacción no confirmó la criatura en %s" % posture)
		table.queue_free()
		return false
	await process_frame
	await RenderingServer.frame_post_draw
	var zone: Dictionary = table.debug_snapshot()["view"]["game"]["card_table"]["zones"]["creatures:0"]
	if zone["count"] != 1 or zone["slots"].all(func(slot: Dictionary) -> bool: return slot["card"] == null or slot["card"]["instance"]["metadata"].get("position", "") != posture):
		printerr("La criatura capturada no está en %s" % posture)
		table.queue_free()
		return false
	var projected_cards: Array = []
	_find_projected_cards(table, projected_cards)
	if not projected_cards.any(func(piece) -> bool: return piece.guard == (posture == "guard") and piece.face_down == (posture == "guard")):
		printerr("La criatura %s no utiliza la proyección de campo esperada" % posture)
		table.queue_free()
		return false
	var error := _save_viewport(path)
	table.queue_free()
	if error != OK:
		printerr("No se pudo guardar la captura de %s: %s" % [posture, error_string(error)])
		return false
	return true


func _find_projected_cards(node: Node, result: Array) -> void:
	if node is ProjectedFieldPiece and node.occupied and not node.auxiliary:
		result.append(node)
	for child in node.get_children():
		_find_projected_cards(child, result)


func _save_viewport(path: String) -> Error:
	var image := root.get_texture().get_image()
	var output_absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	return image.save_png(output_absolute)
