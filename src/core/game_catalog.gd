extends RefCounted
## Runtime registry for interchangeable game modules.
##
## Registration instantiates and validates the complete module contract. Creation
## repeats identity/version checks so a changed script cannot silently replace a
## catalogued ruleset under the same id.

const ModuleContract = preload("res://src/core/module_contract.gd")
const IdentifierRules = preload("res://src/core/identifier_rules.gd")

var _entries: Dictionary = {}


func register(module_id: String, script_path: String, display_name: String = "") -> Dictionary:
	var id_check: Dictionary = IdentifierRules.validate_symbol(
		module_id,
		"catalog module_id",
		IdentifierRules.MAX_MODULE_ID_LENGTH
	)
	if not id_check["ok"]:
		return id_check
	if script_path.is_empty() or not script_path.begins_with("res://"):
		return _error("CATALOG_PATH_INVALID", "Module script path must be a non-empty res:// path.")
	if _entries.has(module_id):
		return _error("CATALOG_ENTRY_DUPLICATE", "Module id is already registered.")
	if not ResourceLoader.exists(script_path):
		return _error("CATALOG_SCRIPT_MISSING", "Module script does not exist: %s" % script_path)
	var script: Variant = load(script_path)
	if script == null or not script is Script or not script.can_instantiate():
		return _error("CATALOG_SCRIPT_INVALID", "Module script cannot be instantiated.")
	var instance: Object = script.new()
	var contract: Dictionary = ModuleContract.validate_module(instance)
	if not contract["ok"]:
		return contract
	if contract["module_id"] != module_id:
		return _error("CATALOG_ID_MISMATCH", "Registered id does not match module_id().")
	var resolved_name: String = display_name if not display_name.strip_edges().is_empty() else module_id
	_entries[module_id] = {
		"module_id": module_id,
		"module_version": contract["module_version"],
		"script_path": script_path,
		"display_name": resolved_name,
	}
	return _ok()


func create_module(module_id: String) -> Dictionary:
	if not _entries.has(module_id):
		return _error("CATALOG_ENTRY_UNKNOWN", "Unknown module id.")
	var entry: Dictionary = _entries[module_id]
	var script: Variant = load(entry["script_path"])
	if script == null or not script is Script or not script.can_instantiate():
		return _error("CATALOG_LOAD_FAILED", "Could not load or instantiate module script.")
	var instance: Object = script.new()
	var contract: Dictionary = ModuleContract.validate_module(instance)
	if not contract["ok"]:
		return contract
	if contract["module_id"] != entry["module_id"]:
		return _error("CATALOG_ID_DRIFT", "Loaded module id differs from the registered id.")
	if contract["module_version"] != entry["module_version"]:
		return _error("CATALOG_VERSION_DRIFT", "Loaded module version differs from the registered version.")
	return {"ok": true, "code": "OK", "message": "", "value": instance}


func list_entries() -> Array:
	var ids: Array = _entries.keys()
	ids.sort()
	var result: Array = []
	for module_id in ids:
		result.append(_entries[module_id].duplicate(true))
	return result


func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
