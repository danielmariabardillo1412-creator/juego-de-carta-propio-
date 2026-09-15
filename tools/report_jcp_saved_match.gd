extends SceneTree
## Resume una partida guardada sin modificarla ni publicar manos o barajas.

const SaveCodec = preload("res://src/persistence/save_codec.gd")

const DEFAULT_PATH := "user://juego_cartas_propio/partida_manual.json"
const CARD_ACTIONS := [
	"summon_creature", "set_creature", "set_support", "play_persistent",
	"equip_item", "play_main_spell", "play_terrain",
]


func _init() -> void:
	var path := DEFAULT_PATH
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--file="):
			path = argument.trim_prefix("--file=")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("JCP-SAVED-REPORT: no se pudo leer el guardado: %s" % path)
		quit(1)
		return
	var decoded: Dictionary = SaveCodec.decode(file.get_as_text())
	if not decoded["ok"]:
		printerr("JCP-SAVED-REPORT: guardado inválido: %s" % decoded["code"])
		quit(1)
		return
	var snapshot: Dictionary = decoded["value"]["payload"]
	if snapshot["module_id"] != "zapiti.juego_cartas_propio":
		printerr("JCP-SAVED-REPORT: el guardado no es del juego de cartas propio")
		quit(1)
		return
	var state: Dictionary = snapshot["module_state"]
	var instances: Dictionary = state["cards"]["instances"]
	var action_counts: Dictionary = {}
	var cards_played := {"0": {}, "1": {}}
	for action in snapshot["actions"]:
		var action_type: String = action["type"]
		action_counts[action_type] = action_counts.get(action_type, 0) + 1
		if action_type not in CARD_ACTIONS:
			continue
		var instance_id: String = action["payload"].get("instance_id", "")
		if not instances.has(instance_id):
			continue
		var definition_id: String = instances[instance_id]["definition_id"]
		var actor_key := str(action["actor_id"])
		var player_cards: Dictionary = cards_played[actor_key]
		player_cards[definition_id] = player_cards.get(definition_id, 0) + 1
	var fusion_counts: Dictionary = {}
	for event in snapshot["events"]:
		var identity: String = event["payload"].get("fusion_identity_id", "")
		if event["type"] == "creatures_fused" and not identity.is_empty():
			fusion_counts[identity] = fusion_counts.get(identity, 0) + 1
	var report := {
		"source": "local_saved_match",
		"lifecycle": snapshot["lifecycle"],
		"seed": snapshot["seed"],
		"starting_player": snapshot["config"].get("starting_player", -1),
		"turn_number": state["turn"].get("turn_number", -1),
		"winner_ids": state.get("winner_ids", []),
		"finished_reason": state.get("finished_reason", ""),
		"life": state.get("life", {}),
		"action_counts": action_counts,
		"cards_played": cards_played,
		"fusions": fusion_counts,
		"note": "Solo el guardado FINISHED sirve para evaluar una partida completa; uso de carta no mide su valor causal.",
	}
	print(JSON.stringify(report, "\t"))
	quit(0)
