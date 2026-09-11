extends RefCounted
## Small immutable effect language for generic state changes.
## Supported effects: set, increment, append, erase_value.

const DataPath = preload("res://src/state/data_path.gd")


static func apply_all(state: Dictionary, effects: Array) -> Dictionary:
	var working: Dictionary = state.duplicate(true)
	for raw_effect in effects:
		var result = apply(working, raw_effect)
		if not result["ok"]:
			return result
		working = result["value"]
	return {"ok": true, "code": "OK", "message": "", "value": working}


static func apply(state: Dictionary, effect: Variant) -> Dictionary:
	if not effect is Dictionary:
		return _error("EFFECT_INVALID", "Effect must be a Dictionary.")
	var effect_type: Variant = effect.get("type", "")
	var path: Variant = effect.get("path", "")
	if not effect_type is String or not path is String or path.is_empty():
		return _error("EFFECT_SHAPE_INVALID", "Effect requires String type and path.")
	match effect_type:
		"set":
			return DataPath.set_value(state, path, effect.get("value", null))
		"increment":
			return DataPath.increment(state, path, effect.get("amount", 1))
		"append":
			var current: Variant = DataPath.get_value(state, path, null)
			if not current is Array:
				return _error("EFFECT_TARGET_NOT_ARRAY", "append target must be an Array.")
			var next_array: Array = current.duplicate(true)
			next_array.append(effect.get("value", null))
			return DataPath.set_value(state, path, next_array)
		"erase_value":
			var current: Variant = DataPath.get_value(state, path, null)
			if not current is Array:
				return _error("EFFECT_TARGET_NOT_ARRAY", "erase_value target must be an Array.")
			var next_array: Array = current.duplicate(true)
			next_array.erase(effect.get("value", null))
			return DataPath.set_value(state, path, next_array)
		_:
			return _error("EFFECT_TYPE_UNKNOWN", "Unknown effect type: %s" % effect_type)


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
