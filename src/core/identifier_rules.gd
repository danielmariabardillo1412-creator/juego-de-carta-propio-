extends RefCounted
## Shared validation for engine/module/action/event identifiers.

const MAX_MODULE_ID_LENGTH := 128
const MAX_MODULE_VERSION_LENGTH := 64
const MAX_ACTION_TYPE_LENGTH := 96
const MAX_EVENT_TYPE_LENGTH := 96
const MAX_REQUEST_ID_LENGTH := 128


static func validate_symbol(value: Variant, field_name: String, max_length: int) -> Dictionary:
	if not value is String:
		return _error("IDENTIFIER_TYPE_INVALID", "%s must be a String." % field_name)
	var text: String = value
	if text.is_empty() or text.strip_edges().is_empty():
		return _error("IDENTIFIER_EMPTY", "%s cannot be empty or whitespace-only." % field_name)
	if text.length() > max_length:
		return _error("IDENTIFIER_TOO_LONG", "%s exceeds %d characters." % [field_name, max_length])
	for index in range(text.length()):
		var codepoint: int = text.unicode_at(index)
		if codepoint <= 32 or codepoint == 127:
			return _error("IDENTIFIER_CONTROL_CHARACTER", "%s contains a control character." % field_name)
	return _ok()


static func validate_optional_request_id(value: Variant) -> Dictionary:
	if not value is String:
		return _error("REQUEST_ID_INVALID", "request_id must be a String.")
	var text: String = value
	if text.is_empty():
		return _ok()
	return validate_symbol(text, "request_id", MAX_REQUEST_ID_LENGTH)


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
