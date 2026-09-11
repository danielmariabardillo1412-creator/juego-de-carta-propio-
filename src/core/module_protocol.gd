extends RefCounted
## Strict validators for every value returned by a rule module.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const IdentifierRules = preload("res://src/core/identifier_rules.gd")
const LegalAction = preload("res://src/core/legal_action.gd")

const DECISION_KEYS := ["code", "message", "ok"]
const TRANSITION_SUCCESS_KEYS := ["events", "ok", "state"]
const EVENT_KEYS_MINIMAL := ["payload", "type"]
const EVENT_KEYS_WITH_VISIBILITY := ["payload", "type", "visible_to"]


static func validate_decision(value: Variant, method_name: String) -> Dictionary:
	if not value is Dictionary:
		return _error("MODULE_DECISION_INVALID", "%s() must return a Dictionary." % method_name)
	var decision: Dictionary = value
	var keys: Array = decision.keys()
	keys.sort()
	if keys != DECISION_KEYS:
		return _error("MODULE_DECISION_KEYS_INVALID", "%s() must return exactly ok, code and message." % method_name)
	if not decision["ok"] is bool or not decision["code"] is String or not decision["message"] is String:
		return _error("MODULE_DECISION_TYPES_INVALID", "%s() returned invalid decision field types." % method_name)
	if decision["ok"]:
		if decision["code"] != "OK":
			return _error("MODULE_DECISION_SUCCESS_CODE_INVALID", "%s() success must use code OK." % method_name)
	else:
		if decision["code"].is_empty() or decision["code"] == "OK":
			return _error("MODULE_DECISION_FAILURE_CODE_INVALID", "%s() failure requires a non-OK code." % method_name)
		if decision["message"].strip_edges().is_empty():
			return _error("MODULE_DECISION_FAILURE_MESSAGE_INVALID", "%s() failure requires a non-empty message." % method_name)
	return _ok()


static func validate_transition(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("TRANSITION_INVALID", "reduce() must return a Dictionary.")
	var transition: Dictionary = value
	if not transition.has("ok") or not transition["ok"] is bool:
		return _error("TRANSITION_INVALID", "reduce() result requires a boolean ok field.")
	var keys: Array = transition.keys()
	keys.sort()
	if not transition["ok"]:
		var failure_check: Dictionary = validate_decision(transition, "reduce")
		if not failure_check["ok"]:
			return failure_check
		return {
			"ok": false,
			"code": transition["code"],
			"message": transition["message"],
		}
	if keys != TRANSITION_SUCCESS_KEYS:
		return _error("TRANSITION_KEYS_INVALID", "Successful reduce() must return exactly ok, state and events.")
	if not transition["state"] is Dictionary or not transition["events"] is Array:
		return _error("TRANSITION_CONTENT_INVALID", "Successful reduce() requires Dictionary state and Array events.")
	for index in range(transition["events"].size()):
		var event_check: Dictionary = validate_event_spec(transition["events"][index], index)
		if not event_check["ok"]:
			return event_check
	return _ok()


static func validate_event_spec(value: Variant, index: int = -1) -> Dictionary:
	var label: String = "event" if index < 0 else "event %d" % index
	if not value is Dictionary:
		return _error("EVENT_SPEC_INVALID", "%s specification must be a Dictionary." % label)
	var spec: Dictionary = value
	var keys: Array = spec.keys()
	keys.sort()
	if keys != EVENT_KEYS_MINIMAL and keys != EVENT_KEYS_WITH_VISIBILITY:
		return _error("EVENT_SPEC_KEYS_INVALID", "%s has missing or unknown keys." % label)
	var type_check: Dictionary = IdentifierRules.validate_symbol(
		spec["type"],
		"event type",
		IdentifierRules.MAX_EVENT_TYPE_LENGTH
	)
	if not type_check["ok"]:
		return type_check
	if String(spec["type"]).begins_with("engine_"):
		return _error("EVENT_TYPE_RESERVED", "%s uses the reserved engine_ event namespace." % label)
	if not spec["payload"] is Dictionary:
		return _error("EVENT_PAYLOAD_INVALID", "%s payload must be a Dictionary." % label)
	var path_index: int = index if index >= 0 else 0
	var payload_check: Dictionary = PureDataValidator.validate(spec["payload"], "$.events[%d].payload" % path_index)
	if not payload_check["ok"]:
		return payload_check
	if spec.has("visible_to"):
		if not spec["visible_to"] is Array:
			return _error("EVENT_VISIBILITY_INVALID", "%s visible_to must be an Array." % label)
		var seen_viewers: Dictionary = {}
		for viewer_id in spec["visible_to"]:
			if not viewer_id is int or viewer_id < 0:
				return _error("EVENT_VISIBILITY_INVALID", "%s visible_to requires non-negative integer viewer ids." % label)
			if seen_viewers.has(viewer_id):
				return _error("EVENT_VISIBILITY_DUPLICATE", "%s visible_to contains a duplicate viewer id." % label)
			seen_viewers[viewer_id] = true
	return _ok()


static func validate_view(value: Variant, path: String) -> Dictionary:
	if not value is Dictionary:
		return _error("MODULE_VIEW_INVALID", "%s must be a Dictionary." % path)
	return PureDataValidator.validate(value, path)


static func validate_legal_actions(value: Variant, viewer_id: int) -> Dictionary:
	if viewer_id < 0:
		return _error("LEGAL_ACTION_VIEWER_INVALID", "Legal-action viewer id must be non-negative.")
	if not value is Array:
		return _error("LEGAL_ACTIONS_INVALID", "get_legal_actions() must return an Array.")
	var pure_check: Dictionary = PureDataValidator.validate(value, "$.legal_actions")
	if not pure_check["ok"]:
		return pure_check
	for index in range(value.size()):
		var action_check: Dictionary = LegalAction.validate(value[index], viewer_id)
		if not action_check["ok"]:
			return _error(action_check["code"], "Legal action %d: %s" % [index, action_check["message"]])
		for previous_index in range(index):
			if value[previous_index] == value[index]:
				return _error("LEGAL_ACTION_DUPLICATE", "Legal action %d duplicates an earlier action." % index)
	return _ok()


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
