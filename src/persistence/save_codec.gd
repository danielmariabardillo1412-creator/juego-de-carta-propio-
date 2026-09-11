extends RefCounted
## Deterministic save package with canonical SHA-256 integrity.
##
## Disk encoding uses an explicit typed JSON tree. Ordinary JSON cannot preserve
## the distinction between Godot int and float values, so checksums and module
## validation would otherwise change after a write/read round trip.

const StateDigest = preload("res://src/state/state_digest.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const RuntimeSnapshot = preload("res://src/core/runtime_snapshot.gd")

const SCHEMA := "zapiti-universal-engine-save"
const VERSION := 4
const PACKAGE_KEYS := [
	"checksum",
	"engine_version",
	"module_id",
	"module_version",
	"payload",
	"schema",
	"version",
]
const TYPE_KEY := "t"
const VALUE_KEY := "v"
const MAX_BYTES := 4 * 1024 * 1024


static func build(engine: Object, module_version: String = "") -> Dictionary:
	if engine == null or not engine.has_method("export_runtime_snapshot"):
		return _error("SAVE_ENGINE_INVALID", "A compatible engine instance is required.")
	var payload: Variant = engine.call("export_runtime_snapshot")
	if not payload is Dictionary:
		return _error("SAVE_PAYLOAD_INVALID", "Engine snapshot must be a Dictionary.")
	var runtime_check: Dictionary = RuntimeSnapshot.validate(payload, false)
	if not runtime_check["ok"]:
		return runtime_check
	var snapshot_module_version: Variant = payload.get("module_version", "")
	if not snapshot_module_version is String or snapshot_module_version.is_empty():
		return _error("SAVE_MODULE_VERSION_INVALID", "Engine snapshot has no valid module version.")
	if module_version.is_empty():
		module_version = snapshot_module_version
	elif module_version != snapshot_module_version:
		return _error("SAVE_MODULE_VERSION_MISMATCH", "Package module version differs from engine snapshot.")
	if payload.get("lifecycle", "") not in ["RUNNING", "FINISHED", "CLOSED"]:
		return _error("SAVE_LIFECYCLE_INVALID", "Only started engine snapshots can be saved.")
	var payload_check: Dictionary = PureDataValidator.validate(payload, "$.payload")
	if not payload_check["ok"]:
		return payload_check
	var checksum: Dictionary = StateDigest.sha256(payload)
	if not checksum["ok"]:
		return checksum
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": {
			"schema": SCHEMA,
			"version": VERSION,
			"engine_version": payload["engine_version"],
			"module_id": payload["module_id"],
			"module_version": module_version,
			"payload": payload.duplicate(true),
			"checksum": checksum["value"],
		},
	}


static func encode(package: Dictionary, pretty: bool = false) -> Dictionary:
	var check: Dictionary = validate(package)
	if not check["ok"]:
		return check
	var typed_tree: Dictionary = _to_typed(package)
	var indent: String = "\t" if pretty else ""
	var text: String = JSON.stringify(typed_tree, indent, true, true)
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return _error("SAVE_TEXT_TOO_LARGE", "Encoded save exceeds maximum byte size.")
	return {"ok": true, "code": "OK", "message": "", "value": text}


static func decode(text: String) -> Dictionary:
	if text.is_empty():
		return _error("SAVE_TEXT_EMPTY", "Save text cannot be empty.")
	if text.to_utf8_buffer().size() > MAX_BYTES:
		return _error("SAVE_TEXT_TOO_LARGE", "Save text exceeds maximum allowed byte size.")
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		return _error("SAVE_JSON_INVALID", "Save text is not a valid typed JSON object.")
	var restored: Dictionary = _from_typed(parsed, "$")
	if not restored["ok"]:
		return restored
	var package_value: Variant = restored.get("value", null)
	if not package_value is Dictionary:
		return _error("SAVE_PACKAGE_INVALID", "Decoded save root must be a Dictionary.")
	var check: Dictionary = validate(package_value)
	if not check["ok"]:
		return check
	return {"ok": true, "code": "OK", "message": "", "value": package_value.duplicate(true)}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("SAVE_PACKAGE_INVALID", "Save package must be a Dictionary.")
	var package: Dictionary = value
	var keys: Array = package.keys()
	keys.sort()
	if keys != PACKAGE_KEYS:
		return _error("SAVE_PACKAGE_KEYS_INVALID", "Save package keys are invalid.")
	if package["schema"] != SCHEMA or package["version"] != VERSION:
		return _error("SAVE_SCHEMA_UNSUPPORTED", "Save schema/version is unsupported.")
	if not package["engine_version"] is int or package["engine_version"] != RuntimeSnapshot.VERSION:
		return _error("SAVE_ENGINE_VERSION_MISMATCH", "Save engine version is unsupported.")
	if not package["module_id"] is String or package["module_id"].is_empty():
		return _error("SAVE_MODULE_ID_INVALID", "module_id must be non-empty.")
	if not package["module_version"] is String or package["module_version"].is_empty():
		return _error("SAVE_MODULE_VERSION_INVALID", "module_version must be non-empty.")
	if not package["payload"] is Dictionary or not package["checksum"] is String or package["checksum"].length() != 64:
		return _error("SAVE_CONTENT_INVALID", "Save payload/checksum fields are invalid.")
	if package["payload"].get("module_id", "") != package["module_id"]:
		return _error("SAVE_MODULE_ID_MISMATCH", "Package and payload module ids differ.")
	if package["payload"].get("module_version", "") != package["module_version"]:
		return _error("SAVE_MODULE_VERSION_MISMATCH", "Package and payload module versions differ.")
	if package["payload"].get("engine_version", -1) != package["engine_version"]:
		return _error("SAVE_ENGINE_VERSION_MISMATCH", "Package and payload engine versions differ.")
	if package["payload"].get("lifecycle", "") not in ["RUNNING", "FINISHED", "CLOSED"]:
		return _error("SAVE_LIFECYCLE_INVALID", "Save payload lifecycle is not supported.")
	var payload_check: Dictionary = RuntimeSnapshot.validate(package["payload"], false)
	if not payload_check["ok"]:
		return payload_check
	var checksum: Dictionary = StateDigest.sha256(package["payload"])
	if not checksum["ok"]:
		return checksum
	if checksum["value"] != package["checksum"]:
		return _error("SAVE_CHECKSUM_MISMATCH", "Save payload integrity check failed.")
	return {"ok": true, "code": "OK", "message": ""}


static func _to_typed(value: Variant) -> Dictionary:
	match typeof(value):
		TYPE_NIL:
			return {TYPE_KEY: "nil"}
		TYPE_BOOL:
			return {TYPE_KEY: "bool", VALUE_KEY: value}
		TYPE_INT:
			return {TYPE_KEY: "int", VALUE_KEY: str(value)}
		TYPE_FLOAT:
			return {TYPE_KEY: "float", VALUE_KEY: JSON.stringify(value, "", true, true)}
		TYPE_STRING:
			return {TYPE_KEY: "string", VALUE_KEY: value}
		TYPE_ARRAY:
			var items: Array = []
			for item in value:
				items.append(_to_typed(item))
			return {TYPE_KEY: "array", VALUE_KEY: items}
		TYPE_DICTIONARY:
			var keys: Array = value.keys()
			keys.sort()
			var pairs: Array = []
			for key in keys:
				pairs.append([key, _to_typed(value[key])])
			return {TYPE_KEY: "dictionary", VALUE_KEY: pairs}
		_:
			return {TYPE_KEY: "unsupported", VALUE_KEY: str(typeof(value))}


static func _from_typed(node_value: Variant, path: String) -> Dictionary:
	if not node_value is Dictionary:
		return _error("SAVE_TYPED_NODE_INVALID", "%s is not a typed node Dictionary." % path)
	var node: Dictionary = node_value
	var type_value: Variant = node.get(TYPE_KEY, "")
	if not type_value is String:
		return _error("SAVE_TYPED_TAG_INVALID", "%s has an invalid type tag." % path)
	var expected_keys: Array = [TYPE_KEY] if type_value == "nil" else [TYPE_KEY, VALUE_KEY]
	var node_keys: Array = node.keys()
	node_keys.sort()
	expected_keys.sort()
	if node_keys != expected_keys:
		return _error("SAVE_TYPED_KEYS_INVALID", "%s has missing or unknown typed-node keys." % path)
	match type_value:
		"nil":
			return _decoded(null)
		"bool":
			if not node[VALUE_KEY] is bool:
				return _error("SAVE_TYPED_BOOL_INVALID", "%s has an invalid bool value." % path)
			return _decoded(node[VALUE_KEY])
		"int":
			if not node[VALUE_KEY] is String or not String(node[VALUE_KEY]).is_valid_int():
				return _error("SAVE_TYPED_INT_INVALID", "%s has an invalid int value." % path)
			var int_value: int = int(node[VALUE_KEY])
			if str(int_value) != node[VALUE_KEY]:
				return _error("SAVE_TYPED_INT_NONCANONICAL", "%s contains a noncanonical int value." % path)
			return _decoded(int_value)
		"float":
			if not node[VALUE_KEY] is String or not String(node[VALUE_KEY]).is_valid_float():
				return _error("SAVE_TYPED_FLOAT_INVALID", "%s has an invalid float value." % path)
			var float_value: float = float(node[VALUE_KEY])
			if is_nan(float_value) or is_inf(float_value):
				return _error("SAVE_TYPED_FLOAT_INVALID", "%s contains NaN or infinity." % path)
			var canonical_float: String = JSON.stringify(float_value, "", true, true)
			if canonical_float != node[VALUE_KEY]:
				return _error("SAVE_TYPED_FLOAT_NONCANONICAL", "%s contains a noncanonical float value." % path)
			return _decoded(float_value)
		"string":
			if not node[VALUE_KEY] is String:
				return _error("SAVE_TYPED_STRING_INVALID", "%s has an invalid String value." % path)
			return _decoded(node[VALUE_KEY])
		"array":
			if not node[VALUE_KEY] is Array:
				return _error("SAVE_TYPED_ARRAY_INVALID", "%s has an invalid Array payload." % path)
			var items: Array = []
			for index in range(node[VALUE_KEY].size()):
				var child: Dictionary = _from_typed(node[VALUE_KEY][index], "%s[%d]" % [path, index])
				if not child["ok"]:
					return child
				items.append(child.get("value", null))
			return _decoded(items)
		"dictionary":
			if not node[VALUE_KEY] is Array:
				return _error("SAVE_TYPED_DICTIONARY_INVALID", "%s has an invalid Dictionary payload." % path)
			var result: Dictionary = {}
			var previous_key: String = ""
			for index in range(node[VALUE_KEY].size()):
				var raw_pair: Variant = node[VALUE_KEY][index]
				if not raw_pair is Array or raw_pair.size() != 2 or not raw_pair[0] is String:
					return _error("SAVE_TYPED_PAIR_INVALID", "%s contains an invalid key/value pair." % path)
				var key: String = raw_pair[0]
				if result.has(key):
					return _error("SAVE_TYPED_KEY_DUPLICATE", "%s contains duplicate key %s." % [path, key])
				if index > 0 and key <= previous_key:
					return _error("SAVE_TYPED_KEY_ORDER_INVALID", "%s dictionary keys are not in canonical order." % path)
				previous_key = key
				var child: Dictionary = _from_typed(raw_pair[1], "%s.%s" % [path, key])
				if not child["ok"]:
					return child
				result[key] = child.get("value", null)
			return _decoded(result)
		_:
			return _error("SAVE_TYPED_TAG_UNKNOWN", "%s contains unknown type tag: %s" % [path, type_value])


static func _decoded(value: Variant) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
