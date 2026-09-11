extends RefCounted
## Reconstructs a session from seed and accepted action log.
##
## Replay validates the canonical runtime snapshot before execution and compares
## the complete rebuilt snapshot after execution. A mismatch includes the first
## structural difference to make deterministic drift diagnosable.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const RuntimeSnapshot = preload("res://src/core/runtime_snapshot.gd")
const StateDigest = preload("res://src/state/state_digest.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")


static func replay(module: Object, config: Dictionary, runtime_snapshot: Dictionary) -> Dictionary:
	var snapshot_check: Dictionary = RuntimeSnapshot.validate(runtime_snapshot, false)
	if not snapshot_check["ok"]:
		return snapshot_check
	var config_check: Dictionary = PureDataValidator.validate(config, "$.config")
	if not config_check["ok"]:
		return config_check
	if runtime_snapshot["config"] != config:
		return _error("REPLAY_CONFIG_MISMATCH", "Replay config must exactly match the snapshot config.")
	if module == null:
		return _error("REPLAY_MODULE_INVALID", "Replay requires a fresh compatible module instance.")
	var engine = UniversalCardEngine.new(module, config)
	if not engine.is_ready():
		var construction: Dictionary = engine.construction_error()
		return _error(
			construction.get("code", "REPLAY_ENGINE_INVALID"),
			construction.get("message", "Replay engine could not be constructed.")
		)
	if runtime_snapshot["module_id"] != engine.module_id():
		return _error("REPLAY_MODULE_MISMATCH", "Snapshot module_id does not match replay module.")
	if runtime_snapshot["module_version"] != engine.module_version():
		return _error("REPLAY_MODULE_VERSION_MISMATCH", "Snapshot module version does not match replay module.")
	var started = engine.start(runtime_snapshot["seed"])
	if not started.success:
		return _error(started.code, started.message)
	for action_index in range(runtime_snapshot["actions"].size()):
		var action_result: Dictionary = GameAction.from_dict(runtime_snapshot["actions"][action_index])
		if not action_result["ok"]:
			return _error(
				"REPLAY_ACTION_INVALID",
				"Action %d is invalid: %s — %s" % [action_index, action_result["code"], action_result["message"]]
			)
		var applied = engine.perform_action(action_result["value"])
		if not applied.success:
			return _error(
				"REPLAY_ACTION_FAILED",
				"Action %d failed: %s — %s" % [action_index, applied.code, applied.message]
			)
	if runtime_snapshot["lifecycle"] == "CLOSED":
		var closed = engine.close()
		if not closed.success:
			return _error("REPLAY_CLOSE_FAILED", "%s: %s" % [closed.code, closed.message])
	var rebuilt: Dictionary = engine.export_runtime_snapshot()
	var rebuilt_check: Dictionary = RuntimeSnapshot.validate(rebuilt, false)
	if not rebuilt_check["ok"]:
		return _error(rebuilt_check["code"], rebuilt_check["message"])
	var rebuilt_digest: Dictionary = StateDigest.sha256(rebuilt)
	var expected_digest: Dictionary = StateDigest.sha256(runtime_snapshot)
	if not rebuilt_digest["ok"] or not expected_digest["ok"]:
		return _error("REPLAY_DIGEST_FAILED", "Could not digest complete replay snapshots.")
	var matches: bool = rebuilt_digest["value"] == expected_digest["value"]
	var difference: Dictionary = {}
	if not matches:
		difference = first_difference(runtime_snapshot, rebuilt)
	return {
		"ok": matches,
		"code": "OK" if matches else "REPLAY_SNAPSHOT_MISMATCH",
		"message": "" if matches else "Replayed runtime snapshot does not match the source snapshot.",
		"engine": engine,
		"snapshot": rebuilt,
		"expected_digest": expected_digest["value"],
		"actual_digest": rebuilt_digest["value"],
		"first_difference": difference,
	}


static func replay_from_snapshot(module: Object, runtime_snapshot: Dictionary) -> Dictionary:
	if not runtime_snapshot is Dictionary or not runtime_snapshot.get("config", null) is Dictionary:
		return _error("REPLAY_SNAPSHOT_INVALID", "Snapshot has no usable config.")
	return replay(module, runtime_snapshot["config"], runtime_snapshot)


static func replay_script(module_script: Variant, runtime_snapshot: Dictionary) -> Dictionary:
	if not module_script is Script or not module_script.can_instantiate():
		return _error("REPLAY_SCRIPT_INVALID", "Replay script must be an instantiable Script resource.")
	var module: Variant = module_script.new()
	if module == null:
		return _error("REPLAY_MODULE_INVALID", "Replay script could not create a module instance.")
	return replay_from_snapshot(module, runtime_snapshot)


static func first_difference(expected: Variant, actual: Variant, path: String = "$") -> Dictionary:
	if typeof(expected) != typeof(actual):
		return {
			"path": path,
			"reason": "TYPE_MISMATCH",
			"expected_type": type_string(typeof(expected)),
			"actual_type": type_string(typeof(actual)),
			"expected": expected,
			"actual": actual,
		}
	match typeof(expected):
		TYPE_ARRAY:
			if expected.size() != actual.size():
				return {
					"path": path,
					"reason": "ARRAY_SIZE_MISMATCH",
					"expected": expected.size(),
					"actual": actual.size(),
				}
			for index in range(expected.size()):
				var child: Dictionary = first_difference(expected[index], actual[index], "%s[%d]" % [path, index])
				if not child.is_empty():
					return child
		TYPE_DICTIONARY:
			var expected_keys: Array = expected.keys()
			var actual_keys: Array = actual.keys()
			expected_keys.sort()
			actual_keys.sort()
			if expected_keys != actual_keys:
				return {
					"path": path,
					"reason": "DICTIONARY_KEYS_MISMATCH",
					"expected": expected_keys,
					"actual": actual_keys,
				}
			for key in expected_keys:
				var child: Dictionary = first_difference(expected[key], actual[key], "%s.%s" % [path, key])
				if not child.is_empty():
					return child
		_:
			if expected != actual:
				return {"path": path, "reason": "VALUE_MISMATCH", "expected": expected, "actual": actual}
	return {}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
