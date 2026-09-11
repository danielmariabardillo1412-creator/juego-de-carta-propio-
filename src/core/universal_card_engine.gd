extends RefCounted
## Universal deterministic card-game session kernel.
##
## The kernel owns lifecycle, atomic action dispatch, event sequencing, hidden
## information boundaries, request deduplication and canonical snapshots. A rule
## module may propose transitions, but only the kernel commits validated data.

const GameAction = preload("res://src/core/game_action.gd")
const GameEvent = preload("res://src/core/game_event.gd")
const EngineResult = preload("res://src/core/engine_result.gd")
const ModuleContract = preload("res://src/core/module_contract.gd")
const ModuleProtocol = preload("res://src/core/module_protocol.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const RuntimeSnapshot = preload("res://src/core/runtime_snapshot.gd")
const StateDigest = preload("res://src/state/state_digest.gd")

enum Lifecycle {
	CREATED,
	RUNNING,
	FINISHED,
	CLOSED,
}

const LIFECYCLE_NAMES := {
	Lifecycle.CREATED: "CREATED",
	Lifecycle.RUNNING: "RUNNING",
	Lifecycle.FINISHED: "FINISHED",
	Lifecycle.CLOSED: "CLOSED",
}

var _module: Object
var _module_id: String = ""
var _module_version: String = ""
var _config: Dictionary = {}
var _state: Dictionary = {}
var _lifecycle: int = Lifecycle.CREATED
var _seed: int = -1
var _state_version: int = 0
var _event_sequence: int = 0
var _events: Array = []
var _action_log: Array = []
var _seen_request_ids: Dictionary = {}
var _construction_error: Dictionary = {}


func _init(module: Object, config: Dictionary = {}) -> void:
	_module = module
	_config = config.duplicate(true)
	var config_check: Dictionary = PureDataValidator.validate(_config, "$.config")
	if not config_check["ok"]:
		_construction_error = config_check
		return
	var contract: Dictionary = ModuleContract.validate_module(module)
	if not contract["ok"]:
		_construction_error = contract
		return
	_module_id = contract["module_id"]
	_module_version = contract["module_version"]
	if _module.has_method("validate_config"):
		var config_validation: Variant = _module.call("validate_config", _config.duplicate(true))
		var protocol_check: Dictionary = ModuleProtocol.validate_decision(config_validation, "validate_config")
		if not protocol_check["ok"]:
			_construction_error = protocol_check
			return
		if not config_validation["ok"]:
			_construction_error = {
				"ok": false,
				"code": config_validation["code"],
				"message": config_validation["message"],
			}


func is_ready() -> bool:
	return _construction_error.is_empty()


func construction_error() -> Dictionary:
	return _construction_error.duplicate(true)


func module_id() -> String:
	return _module_id


func module_version() -> String:
	return _module_version


func lifecycle_name() -> String:
	return LIFECYCLE_NAMES.get(_lifecycle, "UNKNOWN")


func state_version() -> int:
	return _state_version


func event_sequence() -> int:
	return _event_sequence


func start(seed: int) -> Object:
	if not is_ready():
		return _failure(
			_construction_error.get("code", "MODULE_INVALID"),
			_construction_error.get("message", "Game module is invalid.")
		)
	if _lifecycle != Lifecycle.CREATED:
		return _failure("ENGINE_ALREADY_STARTED", "The engine can only be started once.")
	if seed < 0:
		return _failure("SEED_INVALID", "An explicit non-negative seed is required.")
	var identity_check: Dictionary = _validate_identity_stability()
	if not identity_check["ok"]:
		return _failure(identity_check["code"], identity_check["message"])

	var initial: Variant = _module.call("create_initial_state", _config.duplicate(true), seed)
	if not initial is Dictionary:
		return _failure("INITIAL_STATE_INVALID", "create_initial_state() must return a Dictionary.")
	var initial_state: Dictionary = initial
	if initial_state.has("initialization_error"):
		var initial_keys: Array = initial_state.keys()
		initial_keys.sort()
		if initial_keys != ["initialization_error"]:
			return _failure("INITIALIZATION_ERROR_ENVELOPE_INVALID", "Initialization failure cannot contain state fields.")
		var initialization_error: Variant = initial_state["initialization_error"]
		var error_check: Dictionary = ModuleProtocol.validate_decision(initialization_error, "create_initial_state")
		if not error_check["ok"]:
			return _failure(error_check["code"], error_check["message"])
		if initialization_error["ok"]:
			return _failure("INITIALIZATION_ERROR_ENVELOPE_INVALID", "Initialization error envelope cannot report success.")
		return _failure(initialization_error["code"], initialization_error["message"])
	var initial_state_check: Dictionary = PureDataValidator.validate(initial_state, "$.module_state")
	if not initial_state_check["ok"]:
		return _failure(initial_state_check["code"], initial_state_check["message"])
	var module_state_check: Dictionary = _validate_module_state(initial_state)
	if not module_state_check["ok"]:
		return _failure(module_state_check["code"], module_state_check["message"])
	var finished_value: Variant = _module.call("is_finished", initial_state.duplicate(true))
	if not finished_value is bool:
		return _failure("FINISHED_RESULT_INVALID", "is_finished() must return a bool.")

	var next_lifecycle: int = Lifecycle.FINISHED if finished_value else Lifecycle.RUNNING
	var next_events: Array = []
	var started_event: Dictionary = _create_event(1, "engine_started", {
		"module_id": _module_id,
		"module_version": _module_version,
		"seed": seed,
		"lifecycle": LIFECYCLE_NAMES[next_lifecycle],
	})
	if not started_event["ok"]:
		return _failure(started_event["code"], started_event["message"])
	next_events.append(started_event["value"])
	if next_lifecycle == Lifecycle.FINISHED:
		var finished_event: Dictionary = _create_event(2, "engine_finished", {"state_version": 0})
		if not finished_event["ok"]:
			return _failure(finished_event["code"], finished_event["message"])
		next_events.append(finished_event["value"])
	var candidate: Dictionary = _snapshot_from_parts(
		initial_state,
		next_lifecycle,
		seed,
		0,
		next_events.size(),
		[],
		next_events,
		{}
	)
	var snapshot_check: Dictionary = RuntimeSnapshot.validate(candidate)
	if not snapshot_check["ok"]:
		return _failure(snapshot_check["code"], snapshot_check["message"])

	_seed = seed
	_state = initial_state.duplicate(true)
	_lifecycle = next_lifecycle
	_event_sequence = next_events.size()
	_events = next_events
	return _success("ENGINE_STARTED", "Engine started.")


func perform_action(action: Object) -> Object:
	if _lifecycle != Lifecycle.RUNNING:
		return _failure("ENGINE_NOT_RUNNING", "Actions require a running engine.")
	var consistency: Dictionary = validate_internal_consistency()
	if not consistency["ok"]:
		return _failure("ENGINE_INTERNAL_STATE_INVALID", "%s: %s" % [consistency["code"], consistency["message"]])
	var identity_check: Dictionary = _validate_identity_stability()
	if not identity_check["ok"]:
		return _failure(identity_check["code"], identity_check["message"])
	if action == null or not action.has_method("to_dict"):
		return _failure("ACTION_OBJECT_INVALID", "Action does not implement to_dict().")
	var action_snapshot: Variant = action.call("to_dict")
	if not action_snapshot is Dictionary:
		return _failure("ACTION_SERIALIZATION_INVALID", "Action to_dict() must return a Dictionary.")
	action_snapshot = action_snapshot.duplicate(true)
	var canonical_action: Dictionary = GameAction.from_dict(action_snapshot)
	if not canonical_action["ok"]:
		return _failure(canonical_action["code"], canonical_action["message"])
	var canonical_action_object: Object = canonical_action["value"]
	var request_id: String = canonical_action_object.request_id
	if not request_id.is_empty() and _seen_request_ids.has(request_id):
		return _failure("REQUEST_ID_DUPLICATE", "This request id was already committed.")

	var validation_action: Object = canonical_action_object
	var validation: Variant = _module.call("validate_action", _state.duplicate(true), validation_action)
	var validation_check: Dictionary = ModuleProtocol.validate_decision(validation, "validate_action")
	if not validation_check["ok"]:
		return _failure(validation_check["code"], validation_check["message"])
	if not validation["ok"]:
		return _failure(validation["code"], validation["message"])

	var transition_action_result: Dictionary = GameAction.from_dict(action_snapshot)
	if not transition_action_result["ok"]:
		return _failure(transition_action_result["code"], transition_action_result["message"])
	var transition: Variant = _module.call("reduce", _state.duplicate(true), transition_action_result["value"])
	var transition_check: Dictionary = ModuleProtocol.validate_transition(transition)
	if not transition_check["ok"]:
		return _failure(transition_check["code"], transition_check["message"])
	var event_build: Dictionary = _build_pending_events(transition["events"], _event_sequence)
	if not event_build["ok"]:
		return _failure(event_build["code"], event_build["message"])
	var next_state: Dictionary = transition["state"].duplicate(true)
	var next_state_check: Dictionary = PureDataValidator.validate(next_state, "$.module_state")
	if not next_state_check["ok"]:
		return _failure(next_state_check["code"], next_state_check["message"])
	var module_state_check: Dictionary = _validate_module_state(next_state)
	if not module_state_check["ok"]:
		return _failure(module_state_check["code"], module_state_check["message"])
	var finished_value: Variant = _module.call("is_finished", next_state.duplicate(true))
	if not finished_value is bool:
		return _failure("FINISHED_RESULT_INVALID", "is_finished() must return a bool.")

	var next_state_version: int = _state_version + 1
	var next_action_log: Array = _action_log.duplicate(true)
	next_action_log.append(action_snapshot.duplicate(true))
	var next_request_ids: Dictionary = _seen_request_ids.duplicate(true)
	if not request_id.is_empty():
		next_request_ids[request_id] = next_state_version
	var next_events: Array = _events.duplicate()
	for pending_event in event_build["events"]:
		next_events.append(pending_event)
	var next_event_sequence: int = _event_sequence + event_build["events"].size()
	var next_lifecycle: int = Lifecycle.FINISHED if finished_value else Lifecycle.RUNNING
	if finished_value:
		var finish_event: Dictionary = _create_event(
			next_event_sequence + 1,
			"engine_finished",
			{"state_version": next_state_version}
		)
		if not finish_event["ok"]:
			return _failure(finish_event["code"], finish_event["message"])
		next_events.append(finish_event["value"])
		next_event_sequence += 1
	var candidate: Dictionary = _snapshot_from_parts(
		next_state,
		next_lifecycle,
		_seed,
		next_state_version,
		next_event_sequence,
		next_action_log,
		next_events,
		next_request_ids
	)
	var snapshot_check: Dictionary = RuntimeSnapshot.validate(candidate)
	if not snapshot_check["ok"]:
		return _failure(snapshot_check["code"], snapshot_check["message"])

	_state = next_state
	_lifecycle = next_lifecycle
	_state_version = next_state_version
	_event_sequence = next_event_sequence
	_action_log = next_action_log
	_events = next_events
	_seen_request_ids = next_request_ids
	return _success("ACTION_APPLIED", "Action applied.")


func get_public_state() -> Dictionary:
	if _lifecycle == Lifecycle.CREATED:
		return _engine_envelope({})
	var view: Variant = _module.call("get_public_state", _state.duplicate(true))
	var view_check: Dictionary = ModuleProtocol.validate_view(view, "$.public_view")
	if not view_check["ok"]:
		return _engine_envelope({"view_error": {"code": view_check["code"], "message": view_check["message"]}})
	return _engine_envelope(view)


func get_player_state(viewer_id: int) -> Dictionary:
	if viewer_id < 0:
		return _engine_envelope({"view_error": {"code": "VIEWER_ID_INVALID", "message": "viewer_id must be non-negative."}})
	if _lifecycle == Lifecycle.CREATED:
		return _engine_envelope({})
	var viewer_check: Dictionary = _validate_viewer(viewer_id)
	if not viewer_check["ok"]:
		return _engine_envelope({"view_error": {"code": viewer_check["code"], "message": viewer_check["message"]}})
	var view: Variant = _module.call("get_player_state", _state.duplicate(true), viewer_id)
	var view_check: Dictionary = ModuleProtocol.validate_view(view, "$.player_view")
	if not view_check["ok"]:
		return _engine_envelope({"view_error": {"code": view_check["code"], "message": view_check["message"]}})
	return _engine_envelope(view)


func get_legal_actions(viewer_id: int) -> Array:
	if viewer_id < 0 or _lifecycle != Lifecycle.RUNNING or not _module.has_method("get_legal_actions"):
		return []
	var viewer_check: Dictionary = _validate_viewer(viewer_id)
	if not viewer_check["ok"]:
		return []
	var actions: Variant = _module.call("get_legal_actions", _state.duplicate(true), viewer_id)
	var check: Dictionary = ModuleProtocol.validate_legal_actions(actions, viewer_id)
	if not check["ok"]:
		return []
	return actions.duplicate(true)


func get_events(after_sequence: int = 0, viewer_id: int = -1) -> Array:
	if after_sequence < 0 or viewer_id < -1:
		return []
	var result: Array = []
	for event in _events:
		if event.sequence > after_sequence and event.is_visible_to(viewer_id):
			result.append(event.to_dict())
	return result


func export_module_state() -> Dictionary:
	return _state.duplicate(true)


func state_digest() -> Dictionary:
	return StateDigest.sha256(_state)


func export_runtime_snapshot() -> Dictionary:
	return _snapshot_from_parts(
		_state,
		_lifecycle,
		_seed,
		_state_version,
		_event_sequence,
		_action_log,
		_events,
		_seen_request_ids
	)


func validate_internal_consistency() -> Dictionary:
	var snapshot: Dictionary = export_runtime_snapshot()
	var snapshot_check: Dictionary = RuntimeSnapshot.validate(snapshot)
	if not snapshot_check["ok"]:
		return snapshot_check
	if _lifecycle == Lifecycle.CREATED:
		return _ok()
	var module_state_check: Dictionary = _validate_module_state(_state)
	if not module_state_check["ok"]:
		return module_state_check
	var finished_value: Variant = _module.call("is_finished", _state.duplicate(true))
	if not finished_value is bool:
		return _dict_error("FINISHED_RESULT_INVALID", "is_finished() must return a bool.")
	if _lifecycle == Lifecycle.RUNNING and finished_value:
		return _dict_error("LIFECYCLE_STATE_MISMATCH", "RUNNING lifecycle cannot contain a finished module state.")
	if _lifecycle == Lifecycle.FINISHED and not finished_value:
		return _dict_error("LIFECYCLE_STATE_MISMATCH", "FINISHED lifecycle requires a finished module state.")
	return _ok()


func close() -> Object:
	if _lifecycle == Lifecycle.CREATED:
		return _failure("ENGINE_NOT_STARTED", "An unstarted engine cannot be closed as a session.")
	if _lifecycle == Lifecycle.CLOSED:
		return _failure("ENGINE_ALREADY_CLOSED", "The engine is already closed.")
	var close_event: Dictionary = _create_event(
		_event_sequence + 1,
		"engine_closed",
		{"state_version": _state_version}
	)
	if not close_event["ok"]:
		return _failure(close_event["code"], close_event["message"])
	var next_events: Array = _events.duplicate()
	next_events.append(close_event["value"])
	var candidate: Dictionary = _snapshot_from_parts(
		_state,
		Lifecycle.CLOSED,
		_seed,
		_state_version,
		_event_sequence + 1,
		_action_log,
		next_events,
		_seen_request_ids
	)
	var snapshot_check: Dictionary = RuntimeSnapshot.validate(candidate)
	if not snapshot_check["ok"]:
		return _failure(snapshot_check["code"], snapshot_check["message"])
	_lifecycle = Lifecycle.CLOSED
	_event_sequence += 1
	_events = next_events
	return _success("ENGINE_CLOSED", "Engine closed.")


func _validate_identity_stability() -> Dictionary:
	var current: Dictionary = ModuleContract.validate_module(_module)
	if not current["ok"]:
		return current
	if current["module_id"] != _module_id or current["module_version"] != _module_version:
		return _dict_error("MODULE_IDENTITY_DRIFT", "module_id/module_version changed after engine construction.")
	return _ok()


func _validate_viewer(viewer_id: int) -> Dictionary:
	if viewer_id < 0:
		return _dict_error("VIEWER_ID_INVALID", "viewer_id must be non-negative.")
	if not _module.has_method("validate_viewer"):
		return _ok()
	var value: Variant = _module.call("validate_viewer", _state.duplicate(true), viewer_id)
	var protocol_check: Dictionary = ModuleProtocol.validate_decision(value, "validate_viewer")
	if not protocol_check["ok"]:
		return protocol_check
	if not value["ok"]:
		return _dict_error(value["code"], value["message"])
	return _ok()


func _validate_module_state(state: Dictionary) -> Dictionary:
	if not _module.has_method("validate_state"):
		return _ok()
	var value: Variant = _module.call("validate_state", state.duplicate(true))
	var protocol_check: Dictionary = ModuleProtocol.validate_decision(value, "validate_state")
	if not protocol_check["ok"]:
		return protocol_check
	if not value["ok"]:
		return _dict_error(value["code"], value["message"])
	return _ok()


func _build_pending_events(specs: Array, starting_sequence: int) -> Dictionary:
	var pending: Array = []
	var next_sequence: int = starting_sequence
	for index in range(specs.size()):
		var spec_check: Dictionary = ModuleProtocol.validate_event_spec(specs[index], index)
		if not spec_check["ok"]:
			return spec_check
		var spec: Dictionary = specs[index]
		next_sequence += 1
		var event_result: Dictionary = _create_event(
			next_sequence,
			spec["type"],
			spec["payload"],
			spec.get("visible_to", [])
		)
		if not event_result["ok"]:
			return event_result
		pending.append(event_result["value"])
	return {"ok": true, "code": "OK", "message": "", "events": pending}


func _create_event(sequence: int, type: String, payload: Dictionary = {}, visible_to: Array = []) -> Dictionary:
	var event = GameEvent.new(sequence, type, payload, visible_to)
	var shape: Dictionary = event.validate_shape()
	if not shape["ok"]:
		return shape
	return {"ok": true, "code": "OK", "message": "", "value": event}


func _snapshot_from_parts(
	module_state: Dictionary,
	lifecycle: int,
	seed: int,
	version: int,
	sequence: int,
	actions_source: Array,
	events_source: Array,
	request_ids_source: Dictionary
) -> Dictionary:
	var actions: Array = actions_source.duplicate(true)
	var events_data: Array = []
	for event in events_source:
		events_data.append(event.to_dict())
	return {
		"engine_schema": RuntimeSnapshot.SCHEMA,
		"engine_version": RuntimeSnapshot.VERSION,
		"module_id": _module_id,
		"module_version": _module_version,
		"config": _config.duplicate(true),
		"lifecycle": LIFECYCLE_NAMES.get(lifecycle, "UNKNOWN"),
		"seed": seed,
		"state_version": version,
		"event_sequence": sequence,
		"module_state": module_state.duplicate(true),
		"actions": actions,
		"events": events_data,
		"request_ids": request_ids_source.duplicate(true),
	}


func _engine_envelope(module_view: Dictionary) -> Dictionary:
	return {
		"engine": {
			"engine_schema": RuntimeSnapshot.SCHEMA,
			"engine_version": RuntimeSnapshot.VERSION,
			"module_id": _module_id,
			"module_version": _module_version,
			"lifecycle": lifecycle_name(),
			"seed": _seed,
			"state_version": _state_version,
			"event_sequence": _event_sequence,
		},
		"game": module_view.duplicate(true),
	}


func _success(code: String, message: String) -> Object:
	return EngineResult.new(true, code, message, _state_version, _event_sequence)


func _failure(code: String, message: String) -> Object:
	return EngineResult.new(false, code, message, _state_version, _event_sequence)


func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _dict_error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
