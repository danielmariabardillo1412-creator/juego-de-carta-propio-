extends RefCounted
## Serializable legal-action description for UI, bots and network clients.
##
## Legal actions are data contracts, not suggestions. Every value is validated
## as portable pure data so a UI or policy cannot smuggle Objects, callables or
## malformed actor identities into the action-selection boundary.

const IdentifierRules = preload("res://src/core/identifier_rules.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const KEYS := ["actor_id", "label", "metadata", "payload", "type"]
const MAX_LABEL_LENGTH := 512


static func create(
	action_type: String,
	actor_id: int,
	payload: Dictionary = {},
	label: String = "",
	metadata: Dictionary = {}
) -> Dictionary:
	var value: Dictionary = {
		"type": action_type,
		"actor_id": actor_id,
		"payload": payload.duplicate(true),
		"label": label,
		"metadata": metadata.duplicate(true),
	}
	var check: Dictionary = validate(value, actor_id)
	if not check["ok"]:
		return check
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": value,
	}


static func validate(value: Variant, expected_actor_id: int = -1) -> Dictionary:
	if not value is Dictionary:
		return _error("LEGAL_ACTION_INVALID", "Legal action must be a Dictionary.")
	var action: Dictionary = value
	var keys: Array = action.keys()
	keys.sort()
	if keys != KEYS:
		return _error("LEGAL_ACTION_KEYS_INVALID", "Legal action has missing or unknown keys.")
	var type_check: Dictionary = IdentifierRules.validate_symbol(
		action["type"],
		"legal action type",
		IdentifierRules.MAX_ACTION_TYPE_LENGTH
	)
	if not type_check["ok"]:
		return type_check
	if not action["actor_id"] is int or action["actor_id"] < 0:
		return _error("LEGAL_ACTION_ACTOR_INVALID", "Legal action actor_id must be a non-negative integer.")
	if expected_actor_id >= 0 and action["actor_id"] != expected_actor_id:
		return _error("LEGAL_ACTION_ACTOR_MISMATCH", "Legal action does not belong to the expected actor.")
	if not action["payload"] is Dictionary or not action["metadata"] is Dictionary:
		return _error("LEGAL_ACTION_DATA_INVALID", "Legal action payload and metadata must be Dictionaries.")
	if not action["label"] is String:
		return _error("LEGAL_ACTION_LABEL_INVALID", "Legal action label must be a String.")
	var label: String = action["label"]
	if label.length() > MAX_LABEL_LENGTH:
		return _error("LEGAL_ACTION_LABEL_TOO_LONG", "Legal action label exceeds the maximum length.")
	for character_index in range(label.length()):
		var codepoint: int = label.unicode_at(character_index)
		if codepoint < 32 and codepoint not in [9, 10, 13]:
			return _error("LEGAL_ACTION_LABEL_INVALID", "Legal action label contains a control character.")
	var pure_check: Dictionary = PureDataValidator.validate(action, "$.legal_action")
	if not pure_check["ok"]:
		return pure_check
	return _ok()


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
