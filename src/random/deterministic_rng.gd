extends RefCounted
## Pure-data deterministic random number generator.
##
## The algorithm is deliberately simple and fully specified so the same state
## can be reproduced in Godot, Python or another runtime. Every operation takes
## a snapshot Dictionary and returns a new snapshot; supplied state is never
## mutated.

const ALGORITHM := "lcg31-v1"
const MODULUS := 2147483648
const MULTIPLIER := 1103515245
const INCREMENT := 12345
const STATE_KEYS := ["algorithm", "draws", "state"]


static func create(seed: int) -> Dictionary:
	if seed < 0:
		return _error("RNG_SEED_INVALID", "Seed must be a non-negative integer.")
	var normalized_seed: int = seed % MODULUS
	var value := {
		"algorithm": ALGORITHM,
		"state": normalized_seed,
		"draws": 0,
	}
	return _success(value)


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("RNG_STATE_INVALID", "RNG state must be a Dictionary.")
	var state: Dictionary = value
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _error("RNG_STATE_KEYS_INVALID", "RNG state requires exactly algorithm, draws and state.")
	if state["algorithm"] != ALGORITHM:
		return _error("RNG_ALGORITHM_UNSUPPORTED", "RNG algorithm is not supported.")
	if not (state["state"] is int) or state["state"] < 0 or state["state"] >= MODULUS:
		return _error("RNG_VALUE_INVALID", "RNG state value is outside the lcg31 range.")
	if not (state["draws"] is int) or state["draws"] < 0:
		return _error("RNG_DRAWS_INVALID", "RNG draw count must be a non-negative integer.")
	return _ok()


static func next_raw(state: Dictionary) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var current: int = state["state"]
	var next_value: int = (MULTIPLIER * current + INCREMENT) % MODULUS
	var next_state: Dictionary = state.duplicate(true)
	next_state["state"] = next_value
	next_state["draws"] += 1
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": next_value,
		"state": next_state,
	}


static func next_int(state: Dictionary, max_exclusive: int) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if max_exclusive <= 0 or max_exclusive > MODULUS:
		return _error(
			"RNG_BOUND_INVALID",
			"max_exclusive must be between 1 and %d." % MODULUS
		)

	# Rejection sampling avoids modulo bias while preserving deterministic state.
	var limit: int = MODULUS - (MODULUS % max_exclusive)
	var working_state: Dictionary = state.duplicate(true)
	while true:
		var raw := next_raw(working_state)
		if not raw["ok"]:
			return raw
		working_state = raw["state"]
		var raw_value: int = raw["value"]
		if raw_value < limit:
			return {
				"ok": true,
				"code": "OK",
				"message": "",
				"value": raw_value % max_exclusive,
				"state": working_state,
			}
	return _error("RNG_INTERNAL", "Rejection sampling loop exited without producing a value.")


static func shuffle_values(state: Dictionary, values: Array) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var shuffled: Array = values.duplicate(true)
	var working_state: Dictionary = state.duplicate(true)
	var swaps: Array = []

	for index in range(shuffled.size() - 1, 0, -1):
		var picked := next_int(working_state, index + 1)
		if not picked["ok"]:
			return picked
		working_state = picked["state"]
		var target_index: int = picked["value"]
		if target_index != index:
			var temporary: Variant = shuffled[index]
			shuffled[index] = shuffled[target_index]
			shuffled[target_index] = temporary
		swaps.append({"from": index, "to": target_index})

	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": shuffled,
		"state": working_state,
		"swaps": swaps,
		"draws_used": working_state["draws"] - state["draws"],
	}


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
