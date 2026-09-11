extends RefCounted
## Canonical pure-data serializer and SHA-256 digest.
##
## Every supported Variant type receives an explicit type tag, so values such as
## int 1, float 1.0 and String "1" can never share a canonical representation.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const CANONICAL_SCHEMA := "uce-canonical-v1"


static func canonical_string(value: Variant) -> Dictionary:
	var check: Dictionary = PureDataValidator.validate(value)
	if not check["ok"]:
		return check
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": CANONICAL_SCHEMA + "|" + _encode(value),
	}


static func sha256(value: Variant) -> Dictionary:
	var encoded: Dictionary = canonical_string(value)
	if not encoded["ok"]:
		return encoded
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": String(encoded["value"]).sha256_text(),
	}


static func _encode(value: Variant) -> String:
	match typeof(value):
		TYPE_NIL:
			return "n"
		TYPE_BOOL:
			return "b:1" if value else "b:0"
		TYPE_INT:
			return "i:" + str(value)
		TYPE_FLOAT:
			return "f:" + JSON.stringify(value)
		TYPE_STRING:
			return "s:" + JSON.stringify(value)
		TYPE_ARRAY:
			var parts: Array = []
			for item in value:
				parts.append(_encode(item))
			return "a:[" + ",".join(parts) + "]"
		TYPE_DICTIONARY:
			var keys: Array = value.keys()
			keys.sort()
			var pairs: Array = []
			for key in keys:
				pairs.append(JSON.stringify(key) + ":" + _encode(value[key]))
			return "d:{" + ",".join(pairs) + "}"
		_:
			return "unsupported"
