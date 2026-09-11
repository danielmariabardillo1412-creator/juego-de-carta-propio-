extends RefCounted
## Minimal pure-data condition language for reusable game rules.
## Supported operators: always, all, any, not, equals, not_equals, gt, gte,
## lt, lte, in, contains, exists. Operands can be literals or {"path": "a.b"}.

const DataPath = preload("res://src/state/data_path.gd")


static func evaluate(condition: Variant, state: Dictionary) -> Dictionary:
	if not condition is Dictionary:
		return _error("CONDITION_INVALID", "Condition must be a Dictionary.")
	var operator: Variant = condition.get("op", "")
	if not operator is String:
		return _error("CONDITION_OPERATOR_INVALID", "Condition op must be a String.")
	match operator:
		"always":
			return _success(bool(condition.get("value", true)))
		"all", "any":
			var children: Variant = condition.get("conditions", [])
			if not children is Array:
				return _error("CONDITION_CHILDREN_INVALID", "conditions must be an Array.")
			if operator == "all":
				for child in children:
					var result = evaluate(child, state)
					if not result["ok"] or not result["value"]:
						return result
				return _success(true)
			for child in children:
				var result = evaluate(child, state)
				if not result["ok"]:
					return result
				if result["value"]:
					return _success(true)
			return _success(false)
		"not":
			var child_result = evaluate(condition.get("condition", {}), state)
			if not child_result["ok"]:
				return child_result
			return _success(not child_result["value"])
		"exists":
			var path_value: Variant = condition.get("path", "")
			if not path_value is String:
				return _error("CONDITION_PATH_INVALID", "exists requires a String path.")
			return _success(DataPath.has_path(state, path_value))
		"equals", "not_equals", "gt", "gte", "lt", "lte", "in", "contains":
			var left = _operand(condition.get("left", null), state)
			var right = _operand(condition.get("right", null), state)
			if not left["ok"]:
				return left
			if not right["ok"]:
				return right
			return _compare(operator, left["value"], right["value"])
		_:
			return _error("CONDITION_OPERATOR_UNKNOWN", "Unknown condition operator: %s" % operator)


static func _operand(spec: Variant, state: Dictionary) -> Dictionary:
	if spec is Dictionary and spec.size() == 1 and spec.has("path"):
		if not spec["path"] is String or not DataPath.has_path(state, spec["path"]):
			return _error("CONDITION_PATH_MISSING", "Condition operand path does not exist.")
		return {"ok": true, "code": "OK", "message": "", "value": DataPath.get_value(state, spec["path"])}
	return {"ok": true, "code": "OK", "message": "", "value": spec}


static func _compare(operator: String, left: Variant, right: Variant) -> Dictionary:
	match operator:
		"equals": return _success(left == right)
		"not_equals": return _success(left != right)
		"gt", "gte", "lt", "lte":
			if not ((left is int or left is float) and (right is int or right is float)):
				return _error("CONDITION_NUMERIC_REQUIRED", "Ordered comparison requires numeric operands.")
			if operator == "gt": return _success(left > right)
			if operator == "gte": return _success(left >= right)
			if operator == "lt": return _success(left < right)
			return _success(left <= right)
		"in":
			if not right is Array:
				return _error("CONDITION_CONTAINER_INVALID", "in requires an Array right operand.")
			return _success(left in right)
		"contains":
			if left is Dictionary:
				return _success(left.has(right))
			if left is Array:
				return _success(right in left)
			if left is String and right is String:
				return _success(left.contains(right))
			return _error("CONDITION_CONTAINER_INVALID", "contains requires compatible Array, String or Dictionary operands.")
	return _error("CONDITION_OPERATOR_UNKNOWN", "Unknown comparison operator.")


static func _success(value: bool) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
