extends RefCounted
## Generic finite phase/state machine with explicit, reachable transition graph.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const STATE_KEYS := ["current", "definition", "entry_count", "history"]
const DEFINITION_KEYS := ["initial", "terminal", "transitions"]
const MAX_PHASES := 4096
const MAX_PHASE_NAME_LENGTH := 128


static func create(definition: Dictionary) -> Dictionary:
	var definition_check := validate_definition(definition)
	if not definition_check["ok"]:
		return definition_check
	return _success({
		"definition": definition.duplicate(true),
		"current": definition["initial"],
		"history": [definition["initial"]],
		"entry_count": {definition["initial"]: 1},
	})


static func validate_definition(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("PHASE_DEFINITION_INVALID", "Phase definition must be a Dictionary.")
	var definition: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(definition, "$.phase_definition")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = definition.keys()
	keys.sort()
	if keys != DEFINITION_KEYS:
		return _error("PHASE_DEFINITION_KEYS_INVALID", "Definition requires initial, terminal and transitions.")
	var initial_check: Dictionary = _validate_phase_name(definition["initial"])
	if not initial_check["ok"]:
		return _error("PHASE_INITIAL_INVALID", initial_check["message"])
	if not definition["terminal"] is Array or not definition["transitions"] is Dictionary:
		return _error("PHASE_GRAPH_INVALID", "terminal/transitions fields are invalid.")
	if definition["transitions"].is_empty() or definition["transitions"].size() > MAX_PHASES:
		return _error("PHASE_GRAPH_SIZE_INVALID", "Transition graph must contain 1..%d phases." % MAX_PHASES)

	var phases: Dictionary = {}
	for source in definition["transitions"].keys():
		var source_check: Dictionary = _validate_phase_name(source)
		if not source_check["ok"] or not definition["transitions"][source] is Array:
			return _error("PHASE_TRANSITION_INVALID", "Transition graph entries are invalid.")
		phases[source] = true
		var seen_destinations: Dictionary = {}
		for destination in definition["transitions"][source]:
			var destination_check: Dictionary = _validate_phase_name(destination)
			if not destination_check["ok"] or seen_destinations.has(destination):
				return _error("PHASE_DESTINATION_INVALID", "Transition destinations must be unique valid phase names.")
			seen_destinations[destination] = true
			phases[destination] = true
	if phases.size() > MAX_PHASES:
		return _error("PHASE_GRAPH_SIZE_INVALID", "Transition graph exceeds maximum phase count.")
	if not phases.has(definition["initial"]):
		return _error("PHASE_INITIAL_UNKNOWN", "Initial phase is absent from transition graph.")
	for phase_name in phases.keys():
		if not definition["transitions"].has(phase_name):
			return _error("PHASE_NODE_INCOMPLETE", "Every destination phase must have its own transition entry: %s" % phase_name)

	var seen_terminal: Dictionary = {}
	for terminal in definition["terminal"]:
		if not terminal is String or not phases.has(terminal) or seen_terminal.has(terminal):
			return _error("PHASE_TERMINAL_UNKNOWN", "Terminal phases must be unique known phase names.")
		if not definition["transitions"][terminal].is_empty():
			return _error("PHASE_TERMINAL_HAS_TRANSITIONS", "Terminal phase cannot have outgoing transitions: %s" % terminal)
		seen_terminal[terminal] = true

	var reachable: Dictionary = {definition["initial"]: true}
	var queue: Array = [definition["initial"]]
	while not queue.is_empty():
		var source_phase: String = queue.pop_front()
		for destination in definition["transitions"][source_phase]:
			if not reachable.has(destination):
				reachable[destination] = true
				queue.append(destination)
	if reachable.size() != phases.size():
		return _error("PHASE_UNREACHABLE", "Every declared phase must be reachable from the initial phase.")
	return _ok()


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("PHASE_STATE_INVALID", "Phase state must be a Dictionary.")
	var state: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(state, "$.phase_state")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _error("PHASE_STATE_KEYS_INVALID", "Phase state keys are invalid.")
	var definition_check: Dictionary = validate_definition(state["definition"])
	if not definition_check["ok"]:
		return definition_check
	if not state["current"] is String or not state["definition"]["transitions"].has(state["current"]):
		return _error("PHASE_CURRENT_INVALID", "Current phase is invalid.")
	if not state["history"] is Array or state["history"].is_empty():
		return _error("PHASE_HISTORY_INVALID", "Phase history must be a non-empty Array.")
	if state["history"][0] != state["definition"]["initial"] or state["history"].back() != state["current"]:
		return _error("PHASE_HISTORY_INVALID", "Phase history must begin at initial and end at current.")
	var calculated_counts: Dictionary = {}
	for index in range(state["history"].size()):
		var phase_value: Variant = state["history"][index]
		if not phase_value is String or not state["definition"]["transitions"].has(phase_value):
			return _error("PHASE_HISTORY_INVALID", "Phase history contains an unknown phase.")
		calculated_counts[phase_value] = int(calculated_counts.get(phase_value, 0)) + 1
		if index > 0:
			var previous: Variant = state["history"][index - 1]
			if phase_value not in state["definition"]["transitions"][previous]:
				return _error("PHASE_HISTORY_TRANSITION_INVALID", "Phase history contains a forbidden transition.")
	if not state["entry_count"] is Dictionary:
		return _error("PHASE_ENTRY_COUNT_INVALID", "entry_count must be a Dictionary.")
	if state["entry_count"] != calculated_counts:
		return _error("PHASE_ENTRY_COUNT_MISMATCH", "entry_count must exactly match phase history.")
	return _ok()


static func can_transition(state: Dictionary, destination: String) -> bool:
	if not validate(state)["ok"]:
		return false
	return destination in state["definition"]["transitions"].get(state["current"], [])


static func transition(state: Dictionary, destination: String) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	if not can_transition(state, destination):
		return _error("PHASE_TRANSITION_FORBIDDEN", "Transition is not allowed: %s -> %s" % [state["current"], destination])
	var next_state: Dictionary = state.duplicate(true)
	next_state["current"] = destination
	next_state["history"].append(destination)
	next_state["entry_count"][destination] = int(next_state["entry_count"].get(destination, 0)) + 1
	var next_check: Dictionary = validate(next_state)
	if not next_check["ok"]:
		return next_check
	return _success(next_state)


static func is_terminal(state: Dictionary) -> bool:
	if not validate(state)["ok"]:
		return false
	return state["current"] in state["definition"]["terminal"]


static func _validate_phase_name(value: Variant) -> Dictionary:
	if not value is String:
		return _error("PHASE_NAME_INVALID", "Phase name must be a String.")
	var name: String = value
	if name.is_empty() or name.strip_edges() != name or name.length() > MAX_PHASE_NAME_LENGTH:
		return _error("PHASE_NAME_INVALID", "Phase name must be trimmed, non-empty and bounded.")
	for index in range(name.length()):
		if name.unicode_at(index) <= 32 or name.unicode_at(index) == 127:
			return _error("PHASE_NAME_INVALID", "Phase name cannot contain whitespace/control characters.")
	return _ok()


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
