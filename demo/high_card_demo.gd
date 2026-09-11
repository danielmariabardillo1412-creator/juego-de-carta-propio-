extends Node
## Runs one deterministic High Card Arena match and exits.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const HighCardArena = preload("res://games/high_card_arena/high_card_arena_module.gd")
const SaveCodec = preload("res://src/persistence/save_codec.gd")


func _ready() -> void:
	var config = {
		"player_names": ["Ana", "Bruno"],
		"hand_size": 5,
		"target_score": 3,
		"starting_player": 0,
	}
	var engine = UniversalCardEngine.new(HighCardArena.new(), config)
	if not engine.is_ready():
		printerr("ENGINE CONSTRUCTION FAILED: " + str(engine.construction_error()))
		get_tree().quit(1)
		return
	var started = engine.start(123456)
	if not started.success:
		printerr("ENGINE START FAILED: %s %s" % [started.code, started.message])
		get_tree().quit(1)
		return
	var request_number = 1
	while engine.lifecycle_name() == "RUNNING" and request_number < 100:
		var state: Dictionary = engine.get_public_state()
		var actor_id: int = state["game"]["active_player"]
		var actions: Array = engine.get_legal_actions(actor_id)
		if actions.is_empty():
			printerr("NO LEGAL ACTIONS FOR ACTIVE PLAYER")
			get_tree().quit(1)
			return
		var selected: Dictionary = actions[0]
		var action = GameAction.new(
			selected["type"],
			actor_id,
			selected["payload"],
			"demo-%03d" % request_number
		)
		var result = engine.perform_action(action)
		if not result.success:
			printerr("ACTION FAILED: %s %s" % [result.code, result.message])
			get_tree().quit(1)
			return
		request_number += 1
	if engine.lifecycle_name() == "RUNNING":
		printerr("DEMO ACTION LIMIT REACHED BEFORE FINISH")
		get_tree().quit(1)
		return
	var final_state: Dictionary = engine.get_public_state()
	var save_result = SaveCodec.build(engine, engine.module_version())
	if not save_result["ok"]:
		printerr("DEMO SAVE BUILD FAILED: %s %s" % [save_result.get("code", ""), save_result.get("message", "")])
		get_tree().quit(1)
		return
	print("ZAPITI UNIVERSAL ENGINE DEMO FINISHED")
	print(JSON.stringify({
		"lifecycle": engine.lifecycle_name(),
		"winner_ids": final_state["game"]["winner_ids"],
		"reason": final_state["game"]["finished_reason"],
		"scores": final_state["game"]["scores"]["scores"],
		"state_version": final_state["engine"]["state_version"],
		"event_sequence": final_state["engine"]["event_sequence"],
		"save_checksum": save_result["value"]["checksum"],
	}, "\t"))
	get_tree().quit(0)
