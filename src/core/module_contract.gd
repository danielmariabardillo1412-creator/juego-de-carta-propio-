extends RefCounted
## Runtime contract checker for interchangeable rule modules.
##
## GDScript has no interface construct. The engine therefore validates a small
## duck-typed contract and freezes module identity/version at construction time.

const IdentifierRules = preload("res://src/core/identifier_rules.gd")

const REQUIRED_METHODS := [
	"module_id",
	"module_version",
	"create_initial_state",
	"validate_action",
	"reduce",
	"get_public_state",
	"get_player_state",
	"is_finished",
]


static func validate_module(module: Object) -> Dictionary:
	if module == null:
		return _error("MODULE_MISSING", "A game module is required.")
	for method_name in REQUIRED_METHODS:
		if not module.has_method(method_name):
			return _error(
				"MODULE_METHOD_MISSING",
				"Game module is missing required method: %s" % method_name
			)
	var id_value: Variant = module.call("module_id")
	var id_check: Dictionary = IdentifierRules.validate_symbol(
		id_value,
		"module_id",
		IdentifierRules.MAX_MODULE_ID_LENGTH
	)
	if not id_check["ok"]:
		return _error("MODULE_ID_INVALID", id_check["message"])
	var version_value: Variant = module.call("module_version")
	var version_check: Dictionary = IdentifierRules.validate_symbol(
		version_value,
		"module_version",
		IdentifierRules.MAX_MODULE_VERSION_LENGTH
	)
	if not version_check["ok"]:
		return _error("MODULE_VERSION_INVALID", version_check["message"])
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"module_id": String(id_value),
		"module_version": String(version_value),
	}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
