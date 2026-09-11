extends RefCounted
## Tiny rule module used only to verify the UCE-01 engine contract.
## It is intentionally not a card game.


func module_id() -> String:
	return "fixture.minimal_turn.v1"

func module_version() -> String:
	return "1.0.0-fixture"


func create_initial_state(config: Dictionary, seed: int) -> Dictionary:
	var player_count: int = config.get("player_count", 2)
	var max_passes: int = config.get("max_passes", 2)
	return {
		"seed": seed,
		"player_count": player_count,
		"max_passes": max_passes,
		"current_actor": 0,
		"pass_count": 0,
		"finished": max_passes <= 0,
	}


func validate_action(state: Dictionary, action: Object) -> Dictionary:
	if action.type != "pass":
		return _reject("UNKNOWN_ACTION", "Only the fixture 'pass' action is supported.")
	if action.actor_id != state["current_actor"]:
		return _reject("WRONG_ACTOR", "The action actor does not own the current turn.")
	if not action.payload.is_empty():
		return _reject("PAYLOAD_NOT_EMPTY", "The fixture pass action requires an empty payload.")
	return {"ok": true, "code": "OK", "message": ""}


func reduce(state: Dictionary, action: Object) -> Dictionary:
	var next_state := state.duplicate(true)
	next_state["pass_count"] += 1
	var next_actor: int = (action.actor_id + 1) % next_state["player_count"]
	next_state["current_actor"] = next_actor
	next_state["finished"] = next_state["pass_count"] >= next_state["max_passes"]

	return {
		"ok": true,
		"state": next_state,
		"events": [
			{
				"type": "turn_passed",
				"payload": {
					"actor_id": action.actor_id,
					"next_actor": next_actor,
					"pass_count": next_state["pass_count"],
				},
			},
			{
				"type": "action_receipt",
				"payload": {"request_id": action.request_id},
				"visible_to": [action.actor_id],
			},
		],
	}


func get_public_state(state: Dictionary) -> Dictionary:
	return {
		"current_actor": state["current_actor"],
		"pass_count": state["pass_count"],
		"finished": state["finished"],
	}


func get_player_state(state: Dictionary, viewer_id: int) -> Dictionary:
	var view := get_public_state(state)
	view["viewer_id"] = viewer_id
	view["can_act"] = not state["finished"] and viewer_id == state["current_actor"]
	return view


func validate_viewer(state: Dictionary, viewer_id: int) -> Dictionary:
	if viewer_id < 0 or viewer_id >= state.get("player_count", 0):
		return _reject("VIEWER_UNKNOWN", "Viewer is outside the fixture player range.")
	return {"ok": true, "code": "OK", "message": ""}


func is_finished(state: Dictionary) -> bool:
	return state.get("finished", false)


func _reject(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
