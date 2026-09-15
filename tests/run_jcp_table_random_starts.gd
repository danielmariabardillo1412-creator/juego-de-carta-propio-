extends SceneTree
## Partidas humanas variadas y repetición exacta de una semilla de diagnóstico.

var _checks := 0
var _failures: Array = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	root.add_child(table)
	await process_frame
	var first: Dictionary = table.debug_snapshot()
	var first_seed: int = first["seed"]
	_check(first_seed >= 0 and first_seed <= 2147483646, "el inicio normal recibe una semilla válida")
	_check(int(table.get("_seed_input").value) == first_seed, "Herramientas recuerda la semilla visible")
	var first_hand := _hand_ids(first)
	var seen := {first_seed: true}
	var hand_changed := false
	var previous_seed := first_seed
	for attempt in range(3):
		table.call("_restart_pressed")
		var next: Dictionary = table.debug_snapshot()
		var next_seed: int = next["seed"]
		_check(next_seed != previous_seed, "Nueva partida no repite la semilla anterior")
		_check(next["view"]["game"]["card_table"]["zones"]["hand:0"]["count"] == 5, "cada partida entrega cinco cartas propias")
		_check(next["view"]["game"]["card_table"]["zones"]["hand:1"]["count"] == 5, "cada partida entrega cinco cartas rivales")
		_check(next["view"]["game"]["card_table"]["zones"]["deck:0"]["count"] == 35, "el mazo propio conserva 40 cartas")
		_check(next["view"]["game"]["card_table"]["zones"]["deck:1"]["count"] == 35, "el mazo rival conserva 40 cartas")
		seen[next_seed] = true
		if _hand_ids(next) != first_hand:
			hand_changed = true
		previous_seed = next_seed
	_check(seen.size() >= 3, "varias partidas ofrecen repartos con semillas distintas")
	_check(hand_changed, "las nuevas partidas cambian efectivamente la mano inicial")
	var seed_box: SpinBox = table.get("_seed_input")
	seed_box.value = first_seed
	var replay_buttons: Array = table.find_children("ReplaySeedButton", "Button", true, false)
	_check(replay_buttons.size() == 1, "Herramientas ofrece jugar una semilla concreta")
	if replay_buttons.size() == 1:
		replay_buttons[0].pressed.emit()
		var replay: Dictionary = table.debug_snapshot()
		_check(replay["seed"] == first_seed, "el botón repite la semilla solicitada")
		_check(_hand_ids(replay) == first_hand, "repetir la semilla reproduce la mano inicial exacta")
	table.queue_free()
	if _failures.is_empty():
		print("JCP-TABLE-RANDOM-STARTS PASS: %d checks" % _checks)
		quit(0)
	else:
		printerr("JCP-TABLE-RANDOM-STARTS FAIL: %s" % ", ".join(_failures))
		quit(1)


func _hand_ids(snapshot: Dictionary) -> Array:
	var ids: Array = []
	for card in snapshot["view"]["game"]["card_table"]["zones"]["hand:0"]["cards"]:
		ids.append(card["instance"]["id"])
	return ids


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
