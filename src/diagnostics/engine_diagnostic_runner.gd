extends RefCounted
## Staged runtime diagnostic for the complete universal card engine experiment.
##
## Design goals:
## - Load subsystems dynamically so one broken script can be reported without
##   preloading the entire engine at boot.
## - Continue through independent stages after failures.
## - Write machine-readable and human-readable reports both beside the project
##   (when writable) and under user:// as a fallback.
## - Never claim runtime health when a required stage was skipped.

const REPORT_SCHEMA = "zapiti-universal-engine-diagnostic-v1"
const BUILD_ID = "systems-hardening-f05"
const DEFAULT_SEED = 123456
const MAX_ACTIONS = 128

const REQUIRED_RESOURCES = [
	"res://src/core/engine_result.gd",
	"res://src/core/game_action.gd",
	"res://src/core/game_event.gd",
	"res://src/core/legal_action.gd",
	"res://src/core/identifier_rules.gd",
	"res://src/core/module_contract.gd",
	"res://src/core/module_protocol.gd",
	"res://src/core/pure_data_validator.gd",
	"res://src/core/runtime_snapshot.gd",
	"res://src/core/universal_card_engine.gd",
	"res://src/cards/card_definition.gd",
	"res://src/cards/card_instance.gd",
	"res://src/cards/card_state.gd",
	"res://src/cards/card_randomizer.gd",
	"res://src/cards/deal_service.gd",
	"res://src/random/deterministic_rng.gd",
	"res://src/session/player_registry.gd",
	"res://src/turns/turn_state.gd",
	"res://src/turns/phase_machine.gd",
	"res://src/scoring/score_state.gd",
	"res://src/persistence/save_codec.gd",
	"res://src/persistence/save_file_store.gd",
	"res://src/persistence/replay_service.gd",
	"res://src/network/sync_packet.gd",
	"res://src/ai/bot_adapter.gd",
	"res://src/ai/first_legal_policy.gd",
	"res://games/high_card_arena/high_card_arena_module.gd",
	"res://tests/fixtures/action_mutation_module.gd",
]

var _report: Dictionary = {}
var _loaded: Dictionary = {}
var _engine: Object = null
var _module: Object = null
var _config: Dictionary = {
	"player_names": ["Diagnostic A", "Diagnostic B"],
	"hand_size": 5,
	"target_score": 3,
	"starting_player": 0,
}


func run(options: Dictionary = {}) -> Dictionary:
	_config = options.get("config", _config).duplicate(true)
	var seed_value: Variant = options.get("seed", DEFAULT_SEED)
	var seed: int = DEFAULT_SEED
	if seed_value is int and seed_value >= 0:
		seed = seed_value

	_report = {
		"schema": REPORT_SCHEMA,
		"build_id": BUILD_ID,
		"started_unix": int(Time.get_unix_time_from_system()),
		"finished_unix": 0,
		"environment": _environment_info(),
		"config": _config.duplicate(true),
		"seed": seed,
		"current_stage": "boot",
		"stages": [],
		"summary": {},
		"report_paths": [],
	}

	_write_boot_marker()
	_enter_stage("environment")
	_stage_environment()
	_enter_stage("resource_scan")
	_stage_resource_scan()
	_enter_stage("action_envelope_isolation")
	_stage_action_envelope_isolation()
	_enter_stage("module_construction")
	_stage_module_construction()
	_enter_stage("engine_construction")
	_stage_engine_construction()
	_enter_stage("engine_start")
	_stage_engine_start(seed)
	_enter_stage("initial_views")
	_stage_initial_views()
	_enter_stage("external_interfaces")
	_stage_external_interfaces()
	_enter_stage("rejected_action_atomicity")
	_stage_rejected_action_atomicity()
	_enter_stage("complete_match")
	_stage_complete_match()
	_enter_stage("state_integrity")
	_stage_state_integrity()
	_enter_stage("persistence")
	_stage_persistence()
	_enter_stage("replay")
	_stage_replay()
	_enter_stage("sync")
	_stage_sync()
	_enter_stage("determinism")
	_stage_determinism(seed)

	_report["current_stage"] = "finalize"
	_finalize_report()
	var write_result: Dictionary = _write_reports()
	_report["report_paths"] = write_result.get("paths", []).duplicate()
	# Rewrite once so the report itself contains the final paths.
	_write_reports()
	_print_summary()
	return _report.duplicate(true)


func _stage_environment() -> void:
	_add_pass("environment", "ENVIRONMENT_CAPTURED", "Godot and operating-system metadata captured.", _report["environment"])


func _stage_resource_scan() -> void:
	var missing: Array = []
	var unloadable: Array = []
	for path_value in REQUIRED_RESOURCES:
		var path: String = path_value
		if not ResourceLoader.exists(path):
			missing.append(path)
			continue
		var script: Variant = load(path)
		if script == null or not script is Script:
			unloadable.append(path)
			continue
		_loaded[path] = script
	if missing.is_empty() and unloadable.is_empty():
		_add_pass("resource_scan", "RESOURCES_LOADABLE", "All required scripts exist and load through ResourceLoader.", {
			"required_count": REQUIRED_RESOURCES.size(),
			"loaded_count": _loaded.size(),
		})
	else:
		_add_fail("resource_scan", "RESOURCE_LOAD_FAILURE", "One or more required scripts are missing or cannot be parsed/loaded.", {
			"missing": missing,
			"unloadable": unloadable,
			"loaded_count": _loaded.size(),
		})


func _stage_action_envelope_isolation() -> void:
	var engine_script: Variant = _loaded.get("res://src/core/universal_card_engine.gd", null)
	var action_script: Variant = _loaded.get("res://src/core/game_action.gd", null)
	var fixture_script: Variant = _loaded.get("res://tests/fixtures/action_mutation_module.gd", null)
	if engine_script == null or action_script == null or fixture_script == null:
		_add_skip("action_envelope_isolation", "ISOLATION_RESOURCES_UNAVAILABLE", "Action-isolation resources could not be loaded.")
		return
	var isolation_engine: Object = engine_script.new(fixture_script.new(), {})
	if isolation_engine == null or not bool(isolation_engine.call("is_ready")):
		_add_fail("action_envelope_isolation", "ISOLATION_ENGINE_INVALID", "Action-isolation fixture engine could not be constructed.")
		return
	var start_result: Variant = isolation_engine.call("start", 1)
	if start_result == null or not start_result is Object or not bool(start_result.get("success")):
		_add_fail("action_envelope_isolation", "ISOLATION_START_FAILED", "Action-isolation fixture engine did not start.")
		return
	var action: Object = action_script.new("increment", 0, {"amount": 1}, "diagnostic-action-isolation")
	var applied: Variant = isolation_engine.call("perform_action", action)
	if applied == null or not applied is Object or not bool(applied.get("success")):
		_add_fail("action_envelope_isolation", "ACTION_ISOLATION_FAILED", "Validator mutation contaminated reduction or rejected the action.", _object_result_details(applied))
		return
	var snapshot: Variant = isolation_engine.call("export_runtime_snapshot")
	if not snapshot is Dictionary or not snapshot.get("actions", []) is Array or snapshot["actions"].size() != 1:
		_add_fail("action_envelope_isolation", "ACTION_LOG_INVALID", "Isolation fixture produced an invalid action log.")
		return
	var logged_action: Variant = snapshot["actions"][0]
	if not logged_action is Dictionary or logged_action.get("type", "") != "increment" or logged_action.get("payload", {}) != {"amount": 1}:
		_add_fail("action_envelope_isolation", "ACTION_LOG_MUTATED", "Committed action log contains validator mutations.", _safe_dictionary(logged_action))
		return
	_add_pass("action_envelope_isolation", "ACTION_ENVELOPE_ISOLATED", "Validation, reduction and action logging use isolated canonical action snapshots.")


func _stage_module_construction() -> void:
	var module_script: Variant = _loaded.get("res://games/high_card_arena/high_card_arena_module.gd", null)
	if module_script == null:
		_add_skip("module_construction", "MODULE_SCRIPT_UNAVAILABLE", "The example game module could not be loaded.")
		return
	_module = module_script.new()
	if _module == null:
		_add_fail("module_construction", "MODULE_INSTANTIATION_FAILED", "The example game module script did not instantiate.")
		return
	if not _module.has_method("module_id") or not _module.has_method("validate_config"):
		_add_fail("module_construction", "MODULE_SURFACE_INCOMPLETE", "The example module lacks required identification/configuration methods.")
		return
	var module_id_value: Variant = _module.call("module_id")
	var config_result: Variant = _module.call("validate_config", _config.duplicate(true))
	if not module_id_value is String or String(module_id_value).is_empty():
		_add_fail("module_construction", "MODULE_ID_INVALID", "module_id() did not return a non-empty String.")
		return
	if not config_result is Dictionary or not config_result.get("ok", false):
		_add_fail("module_construction", "MODULE_CONFIG_REJECTED", "The diagnostic configuration was rejected.", _safe_dictionary(config_result))
		return
	_add_pass("module_construction", "MODULE_READY", "The example game module instantiated and accepted its configuration.", {
		"module_id": module_id_value,
	})


func _stage_engine_construction() -> void:
	if _module == null:
		_add_skip("engine_construction", "MODULE_UNAVAILABLE", "Engine construction requires a valid module.")
		return
	var engine_script: Variant = _loaded.get("res://src/core/universal_card_engine.gd", null)
	if engine_script == null:
		_add_skip("engine_construction", "ENGINE_SCRIPT_UNAVAILABLE", "The universal engine script could not be loaded.")
		return
	_engine = engine_script.new(_module, _config.duplicate(true))
	if _engine == null:
		_add_fail("engine_construction", "ENGINE_INSTANTIATION_FAILED", "The universal engine did not instantiate.")
		return
	if not _engine.has_method("is_ready") or not _engine.has_method("construction_error"):
		_add_fail("engine_construction", "ENGINE_SURFACE_INCOMPLETE", "The engine lacks construction diagnostic methods.")
		return
	if not bool(_engine.call("is_ready")):
		_add_fail("engine_construction", "ENGINE_NOT_READY", "The engine rejected its module or configuration.", _safe_dictionary(_engine.call("construction_error")))
		return
	_add_pass("engine_construction", "ENGINE_READY", "The universal engine accepted the module and configuration.")


func _stage_engine_start(seed: int) -> void:
	if _engine == null or not _engine.has_method("start"):
		_add_skip("engine_start", "ENGINE_UNAVAILABLE", "Engine start requires a constructed engine.")
		return
	var result: Variant = _engine.call("start", seed)
	if result == null or not result is Object:
		_add_fail("engine_start", "START_RESULT_INVALID", "Engine start returned an invalid result object.")
		return
	var success_value: Variant = result.get("success")
	if not success_value is bool or not success_value:
		_add_fail("engine_start", str(result.get("code")), str(result.get("message")), _object_result_details(result))
		return
	var lifecycle: String = str(_engine.call("lifecycle_name"))
	if lifecycle != "RUNNING" and lifecycle != "FINISHED":
		_add_fail("engine_start", "LIFECYCLE_INVALID", "Engine entered an unexpected lifecycle after start.", {"lifecycle": lifecycle})
		return
	_add_pass("engine_start", "ENGINE_STARTED", "Engine created its initial deterministic state.", {
		"lifecycle": lifecycle,
		"state_version": int(_engine.call("state_version")),
		"event_sequence": int(_engine.call("event_sequence")),
	})


func _stage_initial_views() -> void:
	if not _engine_running_or_finished():
		_add_skip("initial_views", "ENGINE_NOT_STARTED", "State-view checks require a started engine.")
		return
	var public_state: Variant = _engine.call("get_public_state")
	var player_zero: Variant = _engine.call("get_player_state", 0)
	var player_one: Variant = _engine.call("get_player_state", 1)
	if not public_state is Dictionary or not player_zero is Dictionary or not player_one is Dictionary:
		_add_fail("initial_views", "STATE_VIEW_INVALID", "One or more engine views are not Dictionaries.")
		return
	var public_game: Variant = public_state.get("game", {})
	var player_zero_game: Variant = player_zero.get("game", {})
	if not public_game is Dictionary or not player_zero_game is Dictionary:
		_add_fail("initial_views", "STATE_ENVELOPE_INVALID", "Engine state envelope lacks game dictionaries.")
		return
	var public_hand_cards: Array = _zone_cards_from_view(public_game, "hand:0")
	var owner_hand_cards: Array = _zone_cards_from_view(player_zero_game, "hand:0")
	var rival_hand_cards: Array = _zone_cards_from_view(player_one.get("game", {}), "hand:0")
	var legal_zero: Variant = _engine.call("get_legal_actions", 0)
	var legal_one: Variant = _engine.call("get_legal_actions", 1)
	var failures: Array = []
	if not public_hand_cards.is_empty():
		failures.append("public hand reveals identities")
	if owner_hand_cards.size() != int(_config.get("hand_size", 5)):
		failures.append("owner hand size is incorrect")
	if not rival_hand_cards.is_empty():
		failures.append("rival sees another player's hand")
	if not legal_zero is Array or legal_zero.is_empty():
		failures.append("active player has no legal actions")
	if not legal_one is Array or not legal_one.is_empty():
		failures.append("inactive player received legal actions")
	if failures.is_empty():
		_add_pass("initial_views", "VIEWS_AND_PRIVACY_OK", "Initial public/private views and legal-action boundaries are coherent.", {
			"owner_hand_count": owner_hand_cards.size(),
			"active_legal_action_count": legal_zero.size(),
		})
	else:
		_add_fail("initial_views", "VIEWS_OR_PRIVACY_FAILED", "Initial view checks found inconsistencies.", {"failures": failures})


func _stage_external_interfaces() -> void:
	if not _engine_is_running() or _module == null:
		_add_skip("external_interfaces", "ENGINE_NOT_RUNNING", "External-interface checks require a running engine.")
		return
	var invalid_view: Variant = _engine.call("get_player_state", 999)
	var invalid_actions: Variant = _engine.call("get_legal_actions", 999)
	if not invalid_view is Dictionary or not invalid_view.get("game", {}) is Dictionary or not invalid_view["game"].has("view_error"):
		_add_fail("external_interfaces", "UNKNOWN_VIEWER_ACCEPTED", "Unknown player did not receive an explicit view error.", _safe_dictionary(invalid_view))
		return
	if not invalid_actions is Array or not invalid_actions.is_empty():
		_add_fail("external_interfaces", "UNKNOWN_VIEWER_ACTIONS", "Unknown player received legal actions.")
		return
	var bot_script: Variant = _loaded.get("res://src/ai/bot_adapter.gd", null)
	var policy_script: Variant = _loaded.get("res://src/ai/first_legal_policy.gd", null)
	if bot_script == null or policy_script == null:
		_add_skip("external_interfaces", "BOT_RESOURCES_UNAVAILABLE", "Bot adapter or baseline policy was not loaded.")
		return
	var public_state: Variant = _engine.call("get_public_state")
	if not public_state is Dictionary or not public_state.get("game", {}) is Dictionary:
		_add_fail("external_interfaces", "PUBLIC_STATE_INVALID", "Could not resolve active player for bot probe.")
		return
	var actor_id: Variant = public_state["game"].get("active_player", -1)
	if not actor_id is int or actor_id < 0:
		_add_fail("external_interfaces", "ACTIVE_PLAYER_INVALID", "Public state exposes an invalid active player.")
		return
	var module_state: Variant = _engine.call("export_module_state")
	if not module_state is Dictionary:
		_add_fail("external_interfaces", "MODULE_STATE_INVALID", "Engine did not export a bot-readable module state.")
		return
	var bot_choice: Variant = bot_script.choose(_module, module_state, actor_id, policy_script.new(), "diagnostic-bot-1")
	if not bot_choice is Dictionary or not bot_choice.get("ok", false):
		_add_fail("external_interfaces", "BOT_CHOICE_FAILED", "Validated baseline bot could not choose a legal action.", _safe_dictionary(bot_choice))
		return
	var action_value: Variant = bot_choice.get("value", null)
	if action_value == null or not action_value is Object or str(action_value.get("request_id")) != "diagnostic-bot-1":
		_add_fail("external_interfaces", "BOT_ACTION_INVALID", "Bot adapter did not produce a canonical action with caller-owned request id.")
		return
	_add_pass("external_interfaces", "EXTERNAL_INTERFACES_OK", "Unknown viewers are rejected and bot selection remains inside the canonical legal set.", {
		"actor_id": actor_id,
		"legal_index": bot_choice.get("legal_index", -1),
	})


func _stage_rejected_action_atomicity() -> void:
	if not _engine_is_running():
		_add_skip("rejected_action_atomicity", "ENGINE_NOT_RUNNING", "Rejected-action test requires a running engine.")
		return
	var action_script: Variant = _loaded.get("res://src/core/game_action.gd", null)
	if action_script == null:
		_add_skip("rejected_action_atomicity", "ACTION_SCRIPT_UNAVAILABLE", "GameAction could not be loaded.")
		return
	var before_digest: Dictionary = _safe_dictionary(_engine.call("state_digest"))
	var before_version: int = int(_engine.call("state_version"))
	var invalid_action: Object = action_script.new("unknown_diagnostic_action", 1, {}, "diagnostic-rejected")
	var result: Variant = _engine.call("perform_action", invalid_action)
	var after_digest: Dictionary = _safe_dictionary(_engine.call("state_digest"))
	var after_version: int = int(_engine.call("state_version"))
	var rejected: bool = result is Object and result.get("success") is bool and not bool(result.get("success"))
	var unchanged: bool = before_digest.get("value", "") == after_digest.get("value", "") and before_version == after_version
	if rejected and unchanged:
		_add_pass("rejected_action_atomicity", "REJECTION_ATOMIC", "A rejected action did not mutate state or advance state_version.", {
			"result_code": str(result.get("code")),
			"state_version": after_version,
		})
	else:
		_add_fail("rejected_action_atomicity", "REJECTION_MUTATED_STATE", "Rejected-action atomicity failed.", {
			"rejected": rejected,
			"unchanged": unchanged,
			"before_version": before_version,
			"after_version": after_version,
		})


func _stage_complete_match() -> void:
	if not _engine_is_running():
		_add_skip("complete_match", "ENGINE_NOT_RUNNING", "Complete-match simulation requires a running engine.")
		return
	var action_script: Variant = _loaded.get("res://src/core/game_action.gd", null)
	if action_script == null:
		_add_skip("complete_match", "ACTION_SCRIPT_UNAVAILABLE", "GameAction could not be loaded.")
		return
	var applied_count: int = 0
	var failure_details: Dictionary = {}
	while _engine_is_running() and applied_count < MAX_ACTIONS:
		var public_state: Variant = _engine.call("get_public_state")
		if not public_state is Dictionary:
			failure_details = {"reason": "public state invalid", "action_index": applied_count}
			break
		var game_state: Variant = public_state.get("game", {})
		if not game_state is Dictionary:
			failure_details = {"reason": "game state invalid", "action_index": applied_count}
			break
		var actor_value: Variant = game_state.get("active_player", -1)
		if not actor_value is int or actor_value < 0:
			failure_details = {"reason": "active player invalid", "action_index": applied_count}
			break
		var legal_value: Variant = _engine.call("get_legal_actions", actor_value)
		if not legal_value is Array or legal_value.is_empty():
			failure_details = {"reason": "no legal actions", "actor_id": actor_value, "action_index": applied_count}
			break
		var selected_value: Variant = legal_value[0]
		if not selected_value is Dictionary:
			failure_details = {"reason": "legal action is not dictionary", "action_index": applied_count}
			break
		var action_type: Variant = selected_value.get("type", "")
		var payload_value: Variant = selected_value.get("payload", {})
		if not action_type is String or not payload_value is Dictionary:
			failure_details = {"reason": "legal action shape invalid", "action_index": applied_count}
			break
		var action: Object = action_script.new(action_type, actor_value, payload_value, "diagnostic-%03d" % applied_count)
		var result: Variant = _engine.call("perform_action", action)
		if result == null or not result is Object or not bool(result.get("success")):
			failure_details = {
				"reason": "legal action rejected",
				"action_index": applied_count,
				"code": "INVALID_RESULT" if result == null or not result is Object else str(result.get("code")),
				"message": "" if result == null or not result is Object else str(result.get("message")),
			}
			break
		applied_count += 1
	if not failure_details.is_empty():
		_add_fail("complete_match", "MATCH_SIMULATION_FAILED", "The deterministic demo match failed before completion.", failure_details)
		return
	if applied_count >= MAX_ACTIONS and _engine_is_running():
		_add_fail("complete_match", "MATCH_ACTION_LIMIT", "The match did not terminate before the diagnostic action limit.", {
			"action_limit": MAX_ACTIONS,
		})
		return
	var final_state: Variant = _engine.call("get_public_state")
	var final_game: Dictionary = {}
	if final_state is Dictionary and final_state.get("game", {}) is Dictionary:
		final_game = final_state.get("game", {})
	var winner_ids: Variant = final_game.get("winner_ids", [])
	if str(_engine.call("lifecycle_name")) == "FINISHED" and winner_ids is Array and not winner_ids.is_empty():
		_add_pass("complete_match", "MATCH_FINISHED", "The example game completed from initial deal to declared winner.", {
			"actions_applied": applied_count,
			"winner_ids": winner_ids,
			"finished_reason": final_game.get("finished_reason", ""),
			"scores": final_game.get("scores", {}),
		})
	else:
		_add_fail("complete_match", "MATCH_FINAL_STATE_INVALID", "The match stopped without a valid FINISHED state and winner.", {
			"actions_applied": applied_count,
			"lifecycle": str(_engine.call("lifecycle_name")),
			"winner_ids": winner_ids,
		})


func _stage_state_integrity() -> void:
	if _engine == null:
		_add_skip("state_integrity", "ENGINE_UNAVAILABLE", "State-integrity checks require an engine.")
		return
	var consistency: Variant = _engine.call("validate_internal_consistency")
	if not consistency is Dictionary or not consistency.get("ok", false):
		_add_fail("state_integrity", "ENGINE_INTERNAL_STATE_INVALID", "Kernel internal consistency validation failed.", _safe_dictionary(consistency))
		return
	var digest: Dictionary = _safe_dictionary(_engine.call("state_digest"))
	var snapshot: Variant = _engine.call("export_runtime_snapshot")
	if not digest.get("ok", false) or str(digest.get("value", "")).length() != 64:
		_add_fail("state_integrity", "STATE_DIGEST_INVALID", "Engine state could not produce a SHA-256 digest.", digest)
		return
	if not snapshot is Dictionary:
		_add_fail("state_integrity", "RUNTIME_SNAPSHOT_INVALID", "Engine runtime snapshot is not a Dictionary.")
		return
	var snapshot_script: Variant = _loaded.get("res://src/core/runtime_snapshot.gd", null)
	if snapshot_script == null:
		_add_fail("state_integrity", "RUNTIME_SNAPSHOT_VALIDATOR_MISSING", "Canonical runtime snapshot validator was not loaded.")
		return
	var canonical_check: Variant = snapshot_script.validate(snapshot, false)
	if not canonical_check is Dictionary or not canonical_check.get("ok", false):
		_add_fail("state_integrity", "RUNTIME_SNAPSHOT_SCHEMA_INVALID", "Runtime snapshot failed canonical schema validation.", _safe_dictionary(canonical_check))
		return
	var state_version_value: Variant = snapshot.get("state_version", -1)
	var actions_value: Variant = snapshot.get("actions", [])
	var events_value: Variant = snapshot.get("events", [])
	if not state_version_value is int or not actions_value is Array or not events_value is Array:
		_add_fail("state_integrity", "RUNTIME_SNAPSHOT_SHAPE_INVALID", "Runtime snapshot has invalid version/action/event fields.")
		return
	if state_version_value != actions_value.size():
		_add_fail("state_integrity", "STATE_VERSION_ACTION_MISMATCH", "Committed action count does not equal state_version.", {
			"state_version": state_version_value,
			"action_count": actions_value.size(),
		})
		return
	var event_sequence_value: Variant = snapshot.get("event_sequence", -1)
	if not event_sequence_value is int or event_sequence_value != events_value.size():
		_add_fail("state_integrity", "EVENT_SEQUENCE_COUNT_MISMATCH", "Stored event count does not equal event_sequence.", {
			"event_sequence": event_sequence_value,
			"event_count": events_value.size(),
		})
		return
	_add_pass("state_integrity", "STATE_INTEGRITY_OK", "Digest and runtime-snapshot accounting are coherent.", {
		"digest": digest.get("value", ""),
		"state_version": state_version_value,
		"action_count": actions_value.size(),
		"event_count": events_value.size(),
	})


func _stage_persistence() -> void:
	if _engine == null:
		_add_skip("persistence", "ENGINE_UNAVAILABLE", "Persistence checks require an engine.")
		return
	var codec: Variant = _loaded.get("res://src/persistence/save_codec.gd", null)
	var store: Variant = _loaded.get("res://src/persistence/save_file_store.gd", null)
	if codec == null or store == null:
		_add_skip("persistence", "PERSISTENCE_SCRIPT_UNAVAILABLE", "Save codec or file store could not be loaded.")
		return
	var built: Variant = codec.build(_engine, str(_engine.call("module_version")))
	if not built is Dictionary or not built.get("ok", false):
		_add_fail("persistence", "SAVE_BUILD_FAILED", "Save package construction failed.", _safe_dictionary(built))
		return
	var encoded: Variant = codec.encode(built.get("value", {}), true)
	if not encoded is Dictionary or not encoded.get("ok", false):
		_add_fail("persistence", "SAVE_ENCODE_FAILED", "Save package encoding failed.", _safe_dictionary(encoded))
		return
	var decoded: Variant = codec.decode(str(encoded.get("value", "")))
	if not decoded is Dictionary or not decoded.get("ok", false):
		_add_fail("persistence", "SAVE_DECODE_FAILED", "Save package decode/checksum validation failed.", _safe_dictionary(decoded))
		return
	var decoded_package: Variant = decoded.get("value", {})
	var decoded_payload: Variant = decoded_package.get("payload", {}) if decoded_package is Dictionary else {}
	if not decoded_payload is Dictionary or not decoded_payload.get("state_version", null) is int:
		_add_fail("persistence", "SAVE_NUMERIC_TYPES_LOST", "Save round trip did not preserve integer types.")
		return
	var save_path: String = "user://uce_diagnostics/probes/persistence_probe.json"
	var stored: Variant = store.write_atomic(save_path, str(encoded.get("value", "")))
	if not stored is Dictionary or not stored.get("ok", false):
		_add_fail("persistence", "SAVE_FILE_WRITE_FAILED", "Atomic save-file write failed.", _safe_dictionary(stored))
		return
	var loaded_text: Variant = store.read(save_path)
	var reread_valid: bool = false
	if loaded_text is Dictionary and loaded_text.get("ok", false):
		var reread: Variant = codec.decode(str(loaded_text.get("value", "")))
		reread_valid = reread is Dictionary and reread.get("ok", false)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if not reread_valid:
		_add_fail("persistence", "SAVE_FILE_READ_FAILED", "Written save file could not be read and validated.", _safe_dictionary(loaded_text))
		return
	_add_pass("persistence", "PERSISTENCE_OK", "Build, encode, checksum, atomic write and read-back succeeded.", {
		"bytes": str(encoded.get("value", "")).to_utf8_buffer().size(),
	})


func _stage_replay() -> void:
	if _engine == null or _module == null:
		_add_skip("replay", "ENGINE_OR_MODULE_UNAVAILABLE", "Replay requires the completed engine and its module.")
		return
	var replay_script: Variant = _loaded.get("res://src/persistence/replay_service.gd", null)
	var module_script: Variant = _loaded.get("res://games/high_card_arena/high_card_arena_module.gd", null)
	if replay_script == null or module_script == null:
		_add_skip("replay", "REPLAY_SCRIPT_UNAVAILABLE", "Replay service or module script could not be loaded.")
		return
	var snapshot: Variant = _engine.call("export_runtime_snapshot")
	if not snapshot is Dictionary:
		_add_fail("replay", "REPLAY_SNAPSHOT_INVALID", "Engine did not export a replayable snapshot.")
		return
	var replay_result: Variant = replay_script.replay(module_script.new(), _config.duplicate(true), snapshot)
	if replay_result is Dictionary and replay_result.get("ok", false):
		_add_pass("replay", "REPLAY_MATCHED", "Seed plus accepted action log rebuilt the complete runtime snapshot.", {
			"expected_digest": replay_result.get("expected_digest", ""),
			"actual_digest": replay_result.get("actual_digest", ""),
		})
	else:
		_add_fail("replay", "REPLAY_FAILED", "Replay did not reproduce the saved state.", _safe_dictionary(replay_result))


func _stage_sync() -> void:
	if _engine == null:
		_add_skip("sync", "ENGINE_UNAVAILABLE", "Synchronization checks require an engine.")
		return
	var sync_script: Variant = _loaded.get("res://src/network/sync_packet.gd", null)
	if sync_script == null:
		_add_skip("sync", "SYNC_SCRIPT_UNAVAILABLE", "Sync packet script could not be loaded.")
		return
	var invalid_viewer: Variant = sync_script.create(_engine, -2, 0)
	if not invalid_viewer is Dictionary or invalid_viewer.get("ok", true):
		_add_fail("sync", "SYNC_INVALID_VIEWER_ACCEPTED", "Synchronization accepted a viewer id below the public sentinel.", _safe_dictionary(invalid_viewer))
		return
	var unknown_viewer: Variant = sync_script.create(_engine, 999, 0)
	if not unknown_viewer is Dictionary or unknown_viewer.get("ok", true):
		_add_fail("sync", "SYNC_UNKNOWN_VIEWER_ACCEPTED", "Synchronization accepted a player id absent from the game.", _safe_dictionary(unknown_viewer))
		return
	var sync_result: Variant = sync_script.create(_engine, 0, 0)
	if not sync_result is Dictionary or not sync_result.get("ok", false):
		_add_fail("sync", "SYNC_PACKET_FAILED", "Player synchronization packet construction failed.", _safe_dictionary(sync_result))
		return
	var packet: Variant = sync_result.get("value", {})
	if not packet is Dictionary or str(packet.get("state_digest", "")).length() != 64:
		_add_fail("sync", "SYNC_PACKET_INVALID", "Sync packet lacks a valid state digest.", _safe_dictionary(packet))
		return
	_add_pass("sync", "SYNC_PACKET_OK", "Client-safe state, visible events and digest were packaged.", {
		"event_count": packet.get("events", []).size() if packet.get("events", []) is Array else -1,
		"state_version": packet.get("state_version", -1),
	})


func _stage_determinism(seed: int) -> void:
	var engine_script: Variant = _loaded.get("res://src/core/universal_card_engine.gd", null)
	var module_script: Variant = _loaded.get("res://games/high_card_arena/high_card_arena_module.gd", null)
	if engine_script == null or module_script == null:
		_add_skip("determinism", "ENGINE_OR_MODULE_SCRIPT_UNAVAILABLE", "Determinism check requires engine and module scripts.")
		return
	var first: Object = engine_script.new(module_script.new(), _config.duplicate(true))
	var second: Object = engine_script.new(module_script.new(), _config.duplicate(true))
	if first == null or second == null or not bool(first.call("is_ready")) or not bool(second.call("is_ready")):
		_add_fail("determinism", "DETERMINISM_ENGINE_INVALID", "Could not construct comparison engines.")
		return
	var first_start: Variant = first.call("start", seed)
	var second_start: Variant = second.call("start", seed)
	if first_start == null or second_start == null or not bool(first_start.get("success")) or not bool(second_start.get("success")):
		_add_fail("determinism", "DETERMINISM_START_FAILED", "Comparison engines did not start.")
		return
	var first_state: Variant = first.call("get_player_state", 0)
	var second_state: Variant = second.call("get_player_state", 0)
	if not first_state is Dictionary or not second_state is Dictionary:
		_add_fail("determinism", "DETERMINISM_STATE_INVALID", "Comparison state views are invalid.")
		return
	var first_cards: Array = _zone_cards_from_view(first_state.get("game", {}), "hand:0")
	var second_cards: Array = _zone_cards_from_view(second_state.get("game", {}), "hand:0")
	if first_cards == second_cards and not first_cards.is_empty():
		_add_pass("determinism", "DETERMINISTIC_DEAL_OK", "Two engines with the same seed produced the same private deal.", {
			"card_count": first_cards.size(),
		})
	else:
		_add_fail("determinism", "DETERMINISTIC_DEAL_MISMATCH", "Same seed produced different or empty private deals.", {
			"first": first_cards,
			"second": second_cards,
		})


func _enter_stage(stage: String) -> void:
	_report["current_stage"] = stage
	_write_checkpoint()


func _write_checkpoint() -> void:
	if _report.is_empty():
		return
	var checkpoint: Dictionary = _report.duplicate(true)
	checkpoint["checkpoint_unix"] = int(Time.get_unix_time_from_system())
	_write_text_to_targets("uce_diagnostic_latest.json", JSON.stringify(checkpoint, "\t") + "\n")


func _finalize_report() -> void:
	var pass_count: int = 0
	var fail_count: int = 0
	var skip_count: int = 0
	var warning_count: int = 0
	for stage_value in _report.get("stages", []):
		if not stage_value is Dictionary:
			continue
		match str(stage_value.get("status", "")):
			"PASS": pass_count += 1
			"FAIL": fail_count += 1
			"SKIP": skip_count += 1
			"WARN": warning_count += 1
	var final_status: String = "PASS"
	if fail_count > 0:
		final_status = "FAIL"
	elif skip_count > 0 or warning_count > 0:
		final_status = "PASS_WITH_WARNINGS"
	_report["finished_unix"] = int(Time.get_unix_time_from_system())
	_report["summary"] = {
		"status": final_status,
		"pass": pass_count,
		"fail": fail_count,
		"skip": skip_count,
		"warn": warning_count,
		"total": pass_count + fail_count + skip_count + warning_count,
	}


func _add_pass(stage: String, code: String, message: String, details: Dictionary = {}) -> void:
	_add_stage(stage, "PASS", code, message, details)


func _add_fail(stage: String, code: String, message: String, details: Dictionary = {}) -> void:
	_add_stage(stage, "FAIL", code, message, details)


func _add_skip(stage: String, code: String, message: String, details: Dictionary = {}) -> void:
	_add_stage(stage, "SKIP", code, message, details)


func _add_stage(stage: String, status: String, code: String, message: String, details: Dictionary = {}) -> void:
	_report["stages"].append({
		"index": _report["stages"].size() + 1,
		"stage": stage,
		"status": status,
		"code": code,
		"message": message,
		"details": details.duplicate(true),
		"unix": int(Time.get_unix_time_from_system()),
	})
	var output: String = "[UCE-DIAG][%s][%s] %s" % [status, stage, message]
	if status == "FAIL":
		printerr(output)
	else:
		print(output)
	_write_checkpoint()


func _environment_info() -> Dictionary:
	return {
		"godot": Engine.get_version_info().duplicate(true),
		"os_name": OS.get_name(),
		"distribution": OS.get_distribution_name(),
		"processor_count": OS.get_processor_count(),
		"locale": OS.get_locale(),
		"project_path": ProjectSettings.globalize_path("res://"),
		"user_path": ProjectSettings.globalize_path("user://"),
		"command_line": OS.get_cmdline_args(),
	}


func _write_boot_marker() -> void:
	var marker: String = "UCE diagnostic boot reached at unix=%d\nproject=%s\n" % [
		int(Time.get_unix_time_from_system()),
		ProjectSettings.globalize_path("res://"),
	]
	_write_text_to_targets("uce_boot_marker_latest.txt", marker)


func _write_reports() -> Dictionary:
	var json_text: String = JSON.stringify(_report, "\t") + "\n"
	var text_lines: Array = []
	text_lines.append("ZAPITI UNIVERSAL ENGINE DIAGNOSTIC")
	text_lines.append("Build: %s" % BUILD_ID)
	text_lines.append("Status: %s" % str(_report.get("summary", {}).get("status", "UNKNOWN")))
	text_lines.append("")
	for stage_value in _report.get("stages", []):
		if stage_value is Dictionary:
			text_lines.append("[%s] %s — %s: %s" % [
				stage_value.get("status", "UNKNOWN"),
				stage_value.get("stage", "unknown"),
				stage_value.get("code", ""),
				stage_value.get("message", ""),
			])
			if not stage_value.get("details", {}).is_empty():
				text_lines.append(JSON.stringify(stage_value.get("details", {}), "\t"))
	var text: String = "\n".join(text_lines) + "\n"
	var paths: Array = []
	paths.append_array(_write_text_to_targets("uce_diagnostic_latest.json", json_text))
	paths.append_array(_write_text_to_targets("uce_diagnostic_latest.txt", text))
	return {"ok": not paths.is_empty(), "paths": paths}


func _write_text_to_targets(file_name: String, text: String) -> Array:
	var paths: Array = []
	var directories: Array = [
		ProjectSettings.globalize_path("res://diagnostic_logs"),
		ProjectSettings.globalize_path("user://uce_diagnostics"),
	]
	for directory_value in directories:
		var directory: String = directory_value
		var make_error: Error = DirAccess.make_dir_recursive_absolute(directory)
		if make_error != OK and not DirAccess.dir_exists_absolute(directory):
			continue
		var full_path: String = directory.path_join(file_name)
		var file: FileAccess = FileAccess.open(full_path, FileAccess.WRITE)
		if file == null:
			continue
		file.store_string(text)
		file.flush()
		file.close()
		paths.append(full_path)
	return paths


func _print_summary() -> void:
	var summary: Dictionary = _report.get("summary", {})
	print("[UCE-DIAG] FINAL STATUS: %s" % summary.get("status", "UNKNOWN"))
	print("[UCE-DIAG] PASS=%d FAIL=%d SKIP=%d WARN=%d" % [
		int(summary.get("pass", 0)),
		int(summary.get("fail", 0)),
		int(summary.get("skip", 0)),
		int(summary.get("warn", 0)),
	])
	for path_value in _report.get("report_paths", []):
		print("[UCE-DIAG] REPORT: %s" % path_value)


func _engine_running_or_finished() -> bool:
	if _engine == null or not _engine.has_method("lifecycle_name"):
		return false
	var lifecycle: String = str(_engine.call("lifecycle_name"))
	return lifecycle == "RUNNING" or lifecycle == "FINISHED"


func _engine_is_running() -> bool:
	return _engine != null and _engine.has_method("lifecycle_name") and str(_engine.call("lifecycle_name")) == "RUNNING"


func _zone_cards_from_view(game_view: Variant, zone_id: String) -> Array:
	if not game_view is Dictionary:
		return []
	var card_table: Variant = game_view.get("card_table", {})
	if not card_table is Dictionary:
		return []
	var zones: Variant = card_table.get("zones", {})
	if not zones is Dictionary:
		return []
	var zone: Variant = zones.get(zone_id, {})
	if not zone is Dictionary:
		return []
	var cards: Variant = zone.get("cards", [])
	if not cards is Array:
		return []
	return cards.duplicate(true)


func _safe_dictionary(value: Variant) -> Dictionary:
	if value is Dictionary:
		return value.duplicate(true)
	return {"value_type": typeof(value), "value_text": str(value)}


func _object_result_details(value: Variant) -> Dictionary:
	if value == null or not value is Object:
		return {}
	return {
		"success": value.get("success"),
		"code": value.get("code"),
		"message": value.get("message"),
		"state_version": value.get("state_version"),
		"event_sequence": value.get("event_sequence"),
	}
