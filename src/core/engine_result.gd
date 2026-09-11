extends RefCounted
## Result returned by lifecycle operations and action dispatch.

var success: bool
var code: String
var message: String
var state_version: int
var event_sequence: int


func _init(
	p_success: bool,
	p_code: String,
	p_message: String,
	p_state_version: int,
	p_event_sequence: int = -1
) -> void:
	success = p_success
	code = p_code
	message = p_message
	state_version = p_state_version
	event_sequence = p_event_sequence


func to_dict() -> Dictionary:
	return {
		"success": success,
		"code": code,
		"message": message,
		"state_version": state_version,
		"event_sequence": event_sequence,
	}
