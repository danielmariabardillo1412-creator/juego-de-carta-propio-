extends SceneTree
## Sonda local no mutante para distinguir latencia de selección y reconstrucción.

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var table = load("res://demo/juego_cartas_table.tscn").instantiate()
	table.startup_seed = 210921
	root.add_child(table)
	await process_frame
	await process_frame
	var view: Dictionary = table.debug_snapshot()["view"]["game"]["card_table"]
	var ids: Array = []
	for card in view["zones"]["hand:0"]["cards"]:
		ids.append(card["instance"]["id"])
	var engine = table.get("_engine")
	for label in ["actions", "view"]:
		var measure_start := Time.get_ticks_usec()
		for probe_index in range(20):
			if label == "actions":
				engine.get_legal_actions(0)
			else:
				engine.get_player_state(0)
		print("SELECTION_PROFILE %s avg_ms=%.1f" % [label, float(Time.get_ticks_usec() - measure_start) / 20000.0])
	for round_index in range(2):
		for id in ids:
			var start_us := Time.get_ticks_usec()
			table.call("_select_card", id)
			print("SELECTION_PROFILE round=%d id=%s ms=%.1f" % [round_index, id, float(Time.get_ticks_usec() - start_us) / 1000.0])
	quit(0)
