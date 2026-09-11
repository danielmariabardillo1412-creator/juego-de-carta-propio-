extends RefCounted
## Generic deterministic turn cursor.
##
## Round counting is anchored to the player/index where the cycle began. This
## avoids the old error where a game starting at seat 2 counted the first wrap at
## seat 0 as a complete round after only part of the table had acted.

const DIRECTION_FORWARD := 1
const DIRECTION_REVERSE := -1
const STATE_KEYS := [
	"active_index",
	"direction",
	"order",
	"round_anchor_index",
	"round_number",
	"turn_number",
]


static func create(order: Array, starting_index: int = 0, direction: int = DIRECTION_FORWARD) -> Dictionary:
	if order.is_empty():
		return _error("TURN_ORDER_EMPTY", "Turn order cannot be empty.")
	if starting_index < 0 or starting_index >= order.size():
		return _error("TURN_START_INVALID", "Starting index is outside turn order.")
	if direction != DIRECTION_FORWARD and direction != DIRECTION_REVERSE:
		return _error("TURN_DIRECTION_INVALID", "Turn direction must be 1 or -1.")
	var seen: Dictionary = {}
	for player_id in order:
		if not player_id is int or player_id < 0:
			return _error("TURN_PLAYER_INVALID", "Turn order contains an invalid player id.")
		if seen.has(player_id):
			return _error("TURN_PLAYER_DUPLICATE", "Turn order contains duplicate player ids.")
		seen[player_id] = true
	return _success({
		"order": order.duplicate(),
		"active_index": starting_index,
		"round_anchor_index": starting_index,
		"direction": direction,
		"turn_number": 1,
		"round_number": 1,
	})


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("TURN_STATE_INVALID", "Turn state must be a Dictionary.")
	var state: Dictionary = value
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _error("TURN_KEYS_INVALID", "Turn state keys are invalid.")
	if not state["order"] is Array or state["order"].is_empty():
		return _error("TURN_ORDER_INVALID", "Turn order must be non-empty.")
	var seen: Dictionary = {}
	for player_id in state["order"]:
		if not player_id is int or player_id < 0 or seen.has(player_id):
			return _error("TURN_ORDER_INVALID", "Turn order player ids must be unique non-negative integers.")
		seen[player_id] = true
	if not state["active_index"] is int or state["active_index"] < 0 or state["active_index"] >= state["order"].size():
		return _error("TURN_ACTIVE_INVALID", "Active turn index is invalid.")
	if not state["round_anchor_index"] is int or state["round_anchor_index"] < 0 or state["round_anchor_index"] >= state["order"].size():
		return _error("TURN_ROUND_ANCHOR_INVALID", "Round anchor index is invalid.")
	if state["direction"] != DIRECTION_FORWARD and state["direction"] != DIRECTION_REVERSE:
		return _error("TURN_DIRECTION_INVALID", "Turn direction must be 1 or -1.")
	if not state["turn_number"] is int or state["turn_number"] < 1:
		return _error("TURN_NUMBER_INVALID", "Turn number must be positive.")
	if not state["round_number"] is int or state["round_number"] < 1:
		return _error("TURN_ROUND_INVALID", "Round number must be positive.")
	return _ok()


static func active_player(state: Dictionary) -> int:
	if not validate(state)["ok"]:
		return -1
	return state["order"][state["active_index"]]


static func round_anchor_player(state: Dictionary) -> int:
	if not validate(state)["ok"]:
		return -1
	return state["order"][state["round_anchor_index"]]


static func advance(state: Dictionary, steps: int = 1) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if steps <= 0:
		return _error("TURN_STEPS_INVALID", "Advance steps must be greater than zero.")
	var next_state: Dictionary = state.duplicate(true)
	for _step in range(steps):
		next_state["active_index"] = posmod(
			next_state["active_index"] + next_state["direction"],
			next_state["order"].size()
		)
		next_state["turn_number"] += 1
		if next_state["active_index"] == next_state["round_anchor_index"]:
			next_state["round_number"] += 1
	return _success(next_state)


static func set_active_player(
	state: Dictionary,
	player_id: int,
	counts_as_turn: bool = false,
	starts_new_round: bool = false
) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var index: int = state["order"].find(player_id)
	if index < 0:
		return _error("TURN_PLAYER_UNKNOWN", "Player is not in turn order.")
	var next_state: Dictionary = state.duplicate(true)
	next_state["active_index"] = index
	if counts_as_turn:
		next_state["turn_number"] += 1
	if starts_new_round:
		next_state["round_number"] += 1
		next_state["round_anchor_index"] = index
	return _success(next_state)


static func set_round_anchor(state: Dictionary, player_id: int, increment_round: bool = false) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var index: int = state["order"].find(player_id)
	if index < 0:
		return _error("TURN_PLAYER_UNKNOWN", "Player is not in turn order.")
	var next_state: Dictionary = state.duplicate(true)
	next_state["round_anchor_index"] = index
	if increment_round:
		next_state["round_number"] += 1
	return _success(next_state)


static func reverse(state: Dictionary) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var next_state: Dictionary = state.duplicate(true)
	next_state["direction"] *= -1
	return _success(next_state)


static func remove_player(state: Dictionary, player_id: int) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if state["order"].size() <= 1:
		return _error("TURN_LAST_PLAYER", "Turn order cannot remove its final player.")
	var remove_index: int = state["order"].find(player_id)
	if remove_index < 0:
		return _error("TURN_PLAYER_UNKNOWN", "Player is not in turn order.")
	var active_id: int = active_player(state)
	var anchor_id: int = round_anchor_player(state)
	var next_state: Dictionary = state.duplicate(true)
	next_state["order"].remove_at(remove_index)
	if player_id == active_id:
		if state["direction"] == DIRECTION_FORWARD:
			next_state["active_index"] = remove_index % next_state["order"].size()
		else:
			next_state["active_index"] = posmod(remove_index - 1, next_state["order"].size())
	else:
		next_state["active_index"] = next_state["order"].find(active_id)
	if player_id == anchor_id:
		next_state["round_anchor_index"] = next_state["active_index"]
	else:
		next_state["round_anchor_index"] = next_state["order"].find(anchor_id)
	var next_check := validate(next_state)
	if not next_check["ok"]:
		return next_check
	return _success(next_state)


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
