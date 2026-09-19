extends SceneTree
## Preflight de la vertical slice visual/onboarding previa a la prueba humana.
## Verifica que la capa de presentación exista sin alterar el comportamiento headless.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1600, 900)
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame

	var snapshot: Dictionary = table.debug_snapshot()
	_check(int(snapshot.get("onboarding_page_count", 0)) == 6, "onboarding conserva 6 páginas de reglas")
	_check(not bool(snapshot.get("onboarding_visible", true)), "onboarding no bloquea ejecución headless")

	var guide_button: Node = table.find_child("GuideButton", true, false)
	_check(guide_button != null, "mesa ofrece botón GUÍA para reabrir onboarding")

	var onboarding: Node = table.find_child("PrehumanOnboarding", true, false)
	_check(onboarding != null, "overlay de onboarding existe")
	if onboarding != null:
		_check(onboarding.page_count() == 6, "overlay expone seis páginas")
		onboarding.open()
		_check(onboarding.visible, "GUÍA puede abrirse programáticamente")
		onboarding.close()
		_check(not onboarding.visible, "onboarding puede cerrarse sin tocar UCE")

	var tiles: Array[Node] = get_nodes_in_group("jcp_card_tiles")
	_check(not tiles.is_empty(), "mesa renderiza cartas")
	var readable_hand := false
	var graphical_face := false
	for tile in tiles:
		var card_name: Node = tile.find_child("CardName", true, false)
		if card_name != null:
			var element: Node = tile.find_child("CardElement", true, false)
			var art: Node = tile.find_child("ArtPlaceholder", true, false)
			if element != null and art != null:
				readable_hand = true
			if art != null and art.get_child_count() > 0:
				var art_child: Node = art.get_child(0)
				var script: Script = art_child.get_script()
				if script != null and script.resource_path == "res://demo/card_art_placeholder.gd":
					graphical_face = true
	_check(readable_hand, "cartas de mano muestran nombre, elemento y área de arte")
	_check(graphical_face, "cartas usan identidad gráfica provisional en lugar de sigilo de texto")

	var before_version := int(snapshot.get("state_version", -1))
	if onboarding != null:
		onboarding.open()
		onboarding.close()
	var after_version := int(table.debug_snapshot().get("state_version", -2))
	_check(before_version == after_version, "abrir/cerrar guía no muta estado UCE")

	_finish(table)


func _check(ok: bool, label: String) -> void:
	_checks += 1
	if not ok:
		_failures.append(label)


func _finish(table: Node) -> void:
	table.queue_free()
	if _failures.is_empty():
		print("PRESENTATION_PREFLIGHT PASS: %d checks — cartas legibles y onboarding aislado de UCE" % _checks)
		quit(0)
		return
	printerr("PRESENTATION_PREFLIGHT FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)
