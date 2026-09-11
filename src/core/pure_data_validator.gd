extends RefCounted
## Validates the portable data subset accepted by the universal engine.
##
## Supported values: null, bool, int, finite float, String, Array and Dictionary
## with String keys. Bounded depth, node count, collection size and string size
## prevent malformed modules from exhausting the engine during validation.

const MAX_DEPTH := 64
const MAX_NODES := 200000
const MAX_COLLECTION_ITEMS := 100000
const MAX_STRING_LENGTH := 1048576


static func validate(value: Variant, path: String = "$") -> Dictionary:
	var budget: Dictionary = {"nodes": 0}
	return _validate(value, path, 0, budget)


static func _validate(value: Variant, path: String, depth: int, budget: Dictionary) -> Dictionary:
	if depth > MAX_DEPTH:
		return _error("DATA_DEPTH_EXCEEDED", "%s exceeds maximum nesting depth." % path)
	budget["nodes"] = int(budget["nodes"]) + 1
	if budget["nodes"] > MAX_NODES:
		return _error("DATA_NODE_LIMIT_EXCEEDED", "%s exceeds the maximum pure-data node count." % path)

	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_INT:
			return _ok()
		TYPE_FLOAT:
			if is_nan(value) or is_inf(value):
				return _error("DATA_FLOAT_INVALID", "%s contains NaN or infinity." % path)
			return _ok()
		TYPE_STRING:
			if String(value).length() > MAX_STRING_LENGTH:
				return _error("DATA_STRING_TOO_LONG", "%s exceeds maximum String length." % path)
			return _ok()
		TYPE_ARRAY:
			var array_value: Array = value
			if array_value.size() > MAX_COLLECTION_ITEMS:
				return _error("DATA_COLLECTION_TOO_LARGE", "%s exceeds maximum Array size." % path)
			for index in range(array_value.size()):
				var child: Dictionary = _validate(array_value[index], "%s[%d]" % [path, index], depth + 1, budget)
				if not child["ok"]:
					return child
			return _ok()
		TYPE_DICTIONARY:
			var dict_value: Dictionary = value
			if dict_value.size() > MAX_COLLECTION_ITEMS:
				return _error("DATA_COLLECTION_TOO_LARGE", "%s exceeds maximum Dictionary size." % path)
			for key in dict_value.keys():
				if not key is String:
					return _error("DATA_KEY_INVALID", "%s contains a non-String dictionary key." % path)
				if String(key).length() > MAX_STRING_LENGTH:
					return _error("DATA_KEY_TOO_LONG", "%s contains an oversized dictionary key." % path)
				var child: Dictionary = _validate(dict_value[key], "%s.%s" % [path, key], depth + 1, budget)
				if not child["ok"]:
					return child
			return _ok()
		_:
			return _error(
				"DATA_TYPE_UNSUPPORTED",
				"%s contains unsupported type %s." % [path, type_string(typeof(value))]
			)


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
