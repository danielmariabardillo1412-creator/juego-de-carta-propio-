extends RefCounted
## Canonical command envelope sent to a game module through the engine.
##
## Instances remain mutable because GDScript has no readonly fields. The engine
## therefore snapshots and reconstructs every incoming action before validation,
## reduction and logging; a caller or module never owns the committed envelope.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const IdentifierRules = preload("res://src/core/identifier_rules.gd")

var type: String
var actor_id: int
var payload: Dictionary
var request_id: String


func _init(
	p_type: String,
	p_actor_id: int,
	p_payload: Dictionary = {},
	p_request_id: String = ""
) -> void:
	type = p_type
	actor_id = p_actor_id
	payload = p_payload.duplicate(true)
	request_id = p_request_id


func validate_shape() -> Dictionary:
	var type_check: Dictionary = IdentifierRules.validate_symbol(
		type,
		"action type",
		IdentifierRules.MAX_ACTION_TYPE_LENGTH
	)
	if not type_check["ok"]:
		return type_check
	if actor_id < 0:
		return _error("ACTOR_ID_INVALID", "Actor id must be zero or greater.")
	var request_check: Dictionary = IdentifierRules.validate_optional_request_id(request_id)
	if not request_check["ok"]:
		return request_check
	var payload_check: Dictionary = PureDataValidator.validate(payload, "$.payload")
	if not payload_check["ok"]:
		return payload_check
	return _ok()


func to_dict() -> Dictionary:
	return {
		"type": type,
		"actor_id": actor_id,
		"payload": payload.duplicate(true),
		"request_id": request_id,
	}


static func from_dict(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("ACTION_NOT_DICTIONARY", "Serialized action must be a Dictionary.")
	var data: Dictionary = value
	var expected_keys: Array = ["actor_id", "payload", "request_id", "type"]
	var actual_keys: Array = data.keys()
	actual_keys.sort()
	if actual_keys != expected_keys:
		return _error("ACTION_KEYS_INVALID", "Serialized action has missing or unknown keys.")
	if not data["type"] is String:
		return _error("ACTION_TYPE_INVALID", "Action type must be a String.")
	if not data["actor_id"] is int:
		return _error("ACTOR_ID_INVALID", "Actor id must be an integer.")
	if not data["payload"] is Dictionary:
		return _error("ACTION_PAYLOAD_INVALID", "Action payload must be a Dictionary.")
	if not data["request_id"] is String:
		return _error("REQUEST_ID_INVALID", "Request id must be a String.")
	var action = new(data["type"], data["actor_id"], data["payload"], data["request_id"])
	var validation: Dictionary = action.validate_shape()
	if not validation["ok"]:
		return validation
	return {"ok": true, "code": "OK", "message": "", "value": action}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
