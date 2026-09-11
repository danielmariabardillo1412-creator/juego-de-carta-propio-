extends RefCounted
## Generic finite numeric score table with configurable target/leader semantics.

const TARGET_AT_LEAST := "AT_LEAST"
const TARGET_AT_MOST := "AT_MOST"
const TARGET_EXACT := "EXACT"
const TARGET_RULES := [TARGET_AT_LEAST, TARGET_AT_MOST, TARGET_EXACT]
const LEADER_HIGH := "HIGH"
const LEADER_LOW := "LOW"
const LEADER_RULES := [LEADER_HIGH, LEADER_LOW]
const STATE_KEYS := ["leader_rule", "scores", "target", "target_rule"]


static func create(
	participant_ids: Array,
	initial_score: Variant = 0,
	target: Variant = null,
	target_rule: String = TARGET_AT_LEAST,
	leader_rule: String = LEADER_HIGH
) -> Dictionary:
	if participant_ids.is_empty():
		return _error("SCORE_PARTICIPANTS_EMPTY", "At least one score participant is required.")
	if not _is_finite_number(initial_score):
		return _error("SCORE_INITIAL_INVALID", "Initial score must be a finite number.")
	if target != null and not _is_finite_number(target):
		return _error("SCORE_TARGET_INVALID", "Target must be a finite number or null.")
	if target_rule not in TARGET_RULES:
		return _error("SCORE_TARGET_RULE_INVALID", "Target rule is unsupported.")
	if leader_rule not in LEADER_RULES:
		return _error("SCORE_LEADER_RULE_INVALID", "Leader rule is unsupported.")
	var scores: Dictionary = {}
	for participant_id in participant_ids:
		if not participant_id is int or participant_id < 0:
			return _error("SCORE_PARTICIPANT_INVALID", "Participant ids must be non-negative integers.")
		var key: String = str(participant_id)
		if scores.has(key):
			return _error("SCORE_PARTICIPANT_DUPLICATE", "Participant ids must be unique.")
		scores[key] = initial_score
	return _success({
		"scores": scores,
		"target": target,
		"target_rule": target_rule,
		"leader_rule": leader_rule,
	})


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("SCORE_STATE_INVALID", "Score state must be a Dictionary.")
	var state: Dictionary = value
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS or not state["scores"] is Dictionary or state["scores"].is_empty():
		return _error("SCORE_STATE_KEYS_INVALID", "Score state keys are invalid.")
	if state["target"] != null and not _is_finite_number(state["target"]):
		return _error("SCORE_TARGET_INVALID", "Score target must be finite or null.")
	if not state["target_rule"] is String or state["target_rule"] not in TARGET_RULES:
		return _error("SCORE_TARGET_RULE_INVALID", "Score target rule is unsupported.")
	if not state["leader_rule"] is String or state["leader_rule"] not in LEADER_RULES:
		return _error("SCORE_LEADER_RULE_INVALID", "Score leader rule is unsupported.")
	for participant_key in state["scores"].keys():
		if not participant_key is String or not participant_key.is_valid_int() or int(participant_key) < 0:
			return _error("SCORE_KEY_INVALID", "Score keys must be non-negative integer Strings.")
		if str(int(participant_key)) != participant_key:
			return _error("SCORE_KEY_NONCANONICAL", "Score keys must use canonical integer Strings.")
		if not _is_finite_number(state["scores"][participant_key]):
			return _error("SCORE_VALUE_INVALID", "Scores must be finite numbers.")
	return _ok()


static func add(state: Dictionary, participant_id: int, amount: Variant) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if not _is_finite_number(amount):
		return _error("SCORE_AMOUNT_INVALID", "Score amount must be a finite number.")
	var key: String = str(participant_id)
	if not state["scores"].has(key):
		return _error("SCORE_PARTICIPANT_UNKNOWN", "Unknown score participant.")
	var next_value: Variant = state["scores"][key] + amount
	if not _is_finite_number(next_value):
		return _error("SCORE_RESULT_INVALID", "Score operation produced a non-finite value.")
	var next_state: Dictionary = state.duplicate(true)
	next_state["scores"][key] = next_value
	return _success(next_state)


static func set_score(state: Dictionary, participant_id: int, score: Variant) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if not _is_finite_number(score):
		return _error("SCORE_VALUE_INVALID", "Score must be a finite number.")
	var key: String = str(participant_id)
	if not state["scores"].has(key):
		return _error("SCORE_PARTICIPANT_UNKNOWN", "Unknown score participant.")
	var next_state: Dictionary = state.duplicate(true)
	next_state["scores"][key] = score
	return _success(next_state)


static func leader_ids(state: Dictionary) -> Array:
	if not validate(state)["ok"]:
		return []
	var best: Variant = null
	var result: Array = []
	for key in state["scores"].keys():
		var value: Variant = state["scores"][key]
		var is_better: bool = best == null
		if best != null and state["leader_rule"] == LEADER_HIGH:
			is_better = value > best
		elif best != null and state["leader_rule"] == LEADER_LOW:
			is_better = value < best
		if is_better:
			best = value
			result = [int(key)]
		elif value == best:
			result.append(int(key))
	result.sort()
	return result


static func target_reached(state: Dictionary) -> bool:
	if not validate(state)["ok"] or state["target"] == null:
		return false
	for value in state["scores"].values():
		match state["target_rule"]:
			TARGET_AT_LEAST:
				if value >= state["target"]:
					return true
			TARGET_AT_MOST:
				if value <= state["target"]:
					return true
			TARGET_EXACT:
				if value == state["target"]:
					return true
	return false


static func participant_target_reached(state: Dictionary, participant_id: int) -> bool:
	if not validate(state)["ok"] or state["target"] == null:
		return false
	var key: String = str(participant_id)
	if not state["scores"].has(key):
		return false
	var isolated: Dictionary = state.duplicate(true)
	for other_key in isolated["scores"].keys():
		if other_key != key:
			isolated["scores"].erase(other_key)
	return target_reached(isolated)


static func _is_finite_number(value: Variant) -> bool:
	if value is int:
		return true
	if value is float:
		return not is_nan(value) and not is_inf(value)
	return false


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
