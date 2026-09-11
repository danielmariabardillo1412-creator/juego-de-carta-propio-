extends RefCounted
## Canonical sequenced event emitted after a committed state transition.
##
## An empty visible_to Array means public. Otherwise only the listed player ids
## may receive the event through get_events().

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const IdentifierRules = preload("res://src/core/identifier_rules.gd")

const SERIALIZED_KEYS := ["payload", "sequence", "type", "visible_to"]

var sequence: int
var type: String
var payload: Dictionary
var visible_to: Array


func _init(
	p_sequence: int,
	p_type: String,
	p_payload: Dictionary = {},
	p_visible_to: Array = []
) -> void:
	sequence = p_sequence
	type = p_type
	payload = p_payload.duplicate(true)
	visible_to = p_visible_to.duplicate()


func validate_shape() -> Dictionary:
	if sequence < 1:
		return _error("EVENT_SEQUENCE_INVALID", "Event sequence must be one or greater.")
	var type_check: Dictionary = IdentifierRules.validate_symbol(
		type,
		"event type",
		IdentifierRules.MAX_EVENT_TYPE_LENGTH
	)
	if not type_check["ok"]:
		return type_check
	var payload_check: Dictionary = PureDataValidator.validate(payload, "$.payload")
	if not payload_check["ok"]:
		return payload_check
	var seen: Dictionary = {}
	for player_id in visible_to:
		if not player_id is int or player_id < 0:
			return _error("EVENT_VISIBILITY_INVALID", "Event visibility contains an invalid player id.")
		if seen.has(player_id):
			return _error("EVENT_VISIBILITY_DUPLICATE", "Event visibility contains a duplicate player id.")
		seen[player_id] = true
	return _ok()


func is_visible_to(viewer_id: int) -> bool:
	if visible_to.is_empty():
		return true
	return viewer_id >= 0 and viewer_id in visible_to


func to_dict() -> Dictionary:
	return {
		"sequence": sequence,
		"type": type,
		"payload": payload.duplicate(true),
		"visible_to": visible_to.duplicate(),
	}


static func from_dict(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("EVENT_NOT_DICTIONARY", "Serialized event must be a Dictionary.")
	var data: Dictionary = value
	var keys: Array = data.keys()
	keys.sort()
	if keys != SERIALIZED_KEYS:
		return _error("EVENT_KEYS_INVALID", "Serialized event has missing or unknown keys.")
	if not data["sequence"] is int or not data["type"] is String:
		return _error("EVENT_FIELDS_INVALID", "Serialized event sequence/type fields are invalid.")
	if not data["payload"] is Dictionary or not data["visible_to"] is Array:
		return _error("EVENT_FIELDS_INVALID", "Serialized event payload/visible_to fields are invalid.")
	var event = new(data["sequence"], data["type"], data["payload"], data["visible_to"])
	var validation: Dictionary = event.validate_shape()
	if not validation["ok"]:
		return validation
	return {"ok": true, "code": "OK", "message": "", "value": event}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
