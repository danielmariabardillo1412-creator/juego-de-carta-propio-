extends RefCounted
## Hostile fixture: validate_action deliberately mutates its action argument.
## The engine must isolate validation from reduction and from its action log.


func module_id() -> String:
	return "fixture.action_mutation"

func module_version() -> String:
	return "1.0.0-fixture"


func create_initial_state(_config: Dictionary, _seed: int) -> Dictionary:
	return {"count": 0, "finished": false}


func validate_state(state: Dictionary) -> Dictionary:
	var keys: Array = state.keys()
	keys.sort()
	if keys != ["count", "finished"]:
		return _error("MUTATION_STATE_KEYS", "Fixture state keys are invalid.")
	if not state["count"] is int or not state["finished"] is bool:
		return _error("MUTATION_STATE_TYPES", "Fixture state types are invalid.")
	return _ok()


func validate_action(_state: Dictionary, action: Object) -> Dictionary:
	if action.type != "increment" or action.actor_id != 0 or action.payload != {"amount": 1}:
		return _error("MUTATION_ACTION_INVALID", "Fixture expected the canonical increment action.")
	# Deliberately corrupt the validator's copy.
	action.type = "corrupted"
	action.payload["amount"] = 999
	return _ok()


func reduce(state: Dictionary, action: Object) -> Dictionary:
	if action.type != "increment" or action.payload != {"amount": 1}:
		return _error("ACTION_ISOLATION_FAILED", "reduce() received the action mutated by validate_action().")
	var next_state: Dictionary = state.duplicate(true)
	next_state["count"] += 1
	next_state["finished"] = true
	return {
		"ok": true,
		"state": next_state,
		"events": [{"type": "incremented", "payload": {"amount": 1}, "visible_to": []}],
	}


func get_public_state(state: Dictionary) -> Dictionary:
	return state.duplicate(true)


func get_player_state(state: Dictionary, _viewer_id: int) -> Dictionary:
	return state.duplicate(true)


func is_finished(state: Dictionary) -> bool:
	return state["finished"]


func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
