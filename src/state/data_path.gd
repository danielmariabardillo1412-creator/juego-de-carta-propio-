extends RefCounted
## Immutable-style access to nested pure-data values using dot-separated paths.
## Dictionary keys are literal segments; Array segments must be non-negative integers.


static func get_value(root_value: Variant, path: String, default_value: Variant = null) -> Variant:
	if path.is_empty():
		return root_value
	var current: Variant = root_value
	for segment in path.split(".", false):
		if current is Dictionary:
			if not current.has(segment):
				return default_value
			current = current[segment]
		elif current is Array:
			if not segment.is_valid_int():
				return default_value
			var index: int = int(segment)
			if index < 0 or index >= current.size():
				return default_value
			current = current[index]
		else:
			return default_value
	return current


static func has_path(root_value: Variant, path: String) -> bool:
	var sentinel = RefCounted.new()
	return not is_same(get_value(root_value, path, sentinel), sentinel)


static func set_value(root_value: Variant, path: String, value: Variant) -> Dictionary:
	if path.is_empty():
		return _success(value)
	if not (root_value is Dictionary or root_value is Array):
		return _error("PATH_ROOT_INVALID", "Path root must be a Dictionary or Array.")
	var next_root: Variant = root_value.duplicate(true)
	var segments: PackedStringArray = path.split(".", false)
	var current: Variant = next_root
	for index in range(segments.size() - 1):
		var segment: String = segments[index]
		if current is Dictionary:
			if not current.has(segment):
				return _error("PATH_SEGMENT_MISSING", "Missing path segment: %s" % segment)
			current = current[segment]
		elif current is Array:
			if not segment.is_valid_int():
				return _error("PATH_INDEX_INVALID", "Array path segment is not an integer.")
			var array_index: int = int(segment)
			if array_index < 0 or array_index >= current.size():
				return _error("PATH_INDEX_OUT_OF_RANGE", "Array path index is outside bounds.")
			current = current[array_index]
		else:
			return _error("PATH_SEGMENT_INVALID", "A path segment traverses a scalar value.")
	var final_segment: String = segments[segments.size() - 1]
	if current is Dictionary:
		current[final_segment] = value
	elif current is Array:
		if not final_segment.is_valid_int():
			return _error("PATH_INDEX_INVALID", "Final Array path segment is not an integer.")
		var final_index: int = int(final_segment)
		if final_index < 0 or final_index >= current.size():
			return _error("PATH_INDEX_OUT_OF_RANGE", "Final Array path index is outside bounds.")
		current[final_index] = value
	else:
		return _error("PATH_TARGET_INVALID", "Path target parent is a scalar value.")
	return _success(next_root)


static func increment(root_value: Variant, path: String, amount: Variant = 1) -> Dictionary:
	var current: Variant = get_value(root_value, path, null)
	if not (current is int or current is float):
		return _error("PATH_VALUE_NOT_NUMERIC", "Increment target must be numeric.")
	if not (amount is int or amount is float):
		return _error("PATH_AMOUNT_NOT_NUMERIC", "Increment amount must be numeric.")
	return set_value(root_value, path, current + amount)


static func _success(value: Variant) -> Dictionary:
	var copied: Variant = value
	if value is Dictionary or value is Array:
		copied = value.duplicate(true)
	return {"ok": true, "code": "OK", "message": "", "value": copied}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
