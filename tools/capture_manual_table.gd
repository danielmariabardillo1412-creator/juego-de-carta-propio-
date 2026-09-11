extends SceneTree
## Captura reproducible de la mesa a la resolución de escritorio del prototipo.

const OUTPUT_PATH := "res://artifacts/manual_table_preview.png"
const INTERACTION_PATH := "res://artifacts/manual_table_interaction_preview.png"
const CHOICE_PATH := "res://artifacts/manual_table_choice_preview.png"


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
	root.add_child(table)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var error := _save_viewport(OUTPUT_PATH)
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
	print("JCP-TABLE-CAPTURE PASS: 3 capturas (1600x900)")
	quit(0)


func _save_viewport(path: String) -> Error:
	var image := root.get_texture().get_image()
	var output_absolute := ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(output_absolute.get_base_dir())
	return image.save_png(output_absolute)
