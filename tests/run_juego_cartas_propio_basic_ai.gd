extends SceneTree
## Recorrido de integración del rival automático local y devolución del control al humano.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://demo/juego_cartas_table.tscn")
	_expect(scene != null, "la escena con rival automático carga")
	if scene == null:
		_finish()
		return
	var table = scene.instantiate()
	root.add_child(table)
	await process_frame
	_expect(not table.debug_snapshot()["ai_enabled"], "headless no activa la IA sin pedirlo")
	var ai_toggle: CheckButton = table.get("_ai_enabled")
	ai_toggle.button_pressed = true
	_expect(table.debug_snapshot()["ai_enabled"], "la IA puede activarse en una partida local")
	for _step in range(6):
		table.call("_advance_phase_pressed")
	var snapshot: Dictionary = table.debug_snapshot()
	_expect_equal(snapshot["active_player"], 1, "terminar Final entrega el turno al rival")
	var safety := 400
	while safety > 0:
		safety -= 1
		snapshot = table.debug_snapshot()
		var game: Dictionary = snapshot["view"]["game"]
		if game["active_player"] == 0 and not snapshot["ai_running"]:
			break
		if game["active_player"] == 1 and game["response_window"].get("active", false) and game["response_window"].get("priority_player_id", -1) == 0:
			var actions: Array = snapshot["legal_actions"]
			for index in range(actions.size()):
				if actions[index]["type"] in ["pass_reaction", "decline_redirect"]:
					table.perform_legal_action(index)
					break
		await create_timer(0.01).timeout
	snapshot = table.debug_snapshot()
	_expect(safety > 0, "la IA no entra en bucle")
	_expect_equal(snapshot["active_player"], 0, "la IA completa su turno y devuelve el control")
	_expect_equal(snapshot["viewer_id"], 0, "el humano conserva siempre su punto de vista")
	_expect(not snapshot["privacy_hidden"], "la IA no activa la cortina de relevo")
	_expect(snapshot["state_version"] > 6, "el rival ejecuta acciones reales del motor")
	table.queue_free()
	_finish()


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])


func _finish() -> void:
	if _failures.is_empty():
		print("JCP-BASIC-AI PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-BASIC-AI FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
