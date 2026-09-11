extends RefCounted
## Canonical schema and invariant validator for complete engine snapshots.

const GameAction = preload("res://src/core/game_action.gd")
const GameEvent = preload("res://src/core/game_event.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const IdentifierRules = preload("res://src/core/identifier_rules.gd")

const SCHEMA := "zapiti-universal-engine-runtime"
const VERSION := 1
const KEYS := [
	"actions", "config", "engine_schema", "engine_version", "event_sequence",
	"events", "lifecycle", "module_id", "module_state", "module_version",
	"request_ids", "seed", "state_version",
]


static func validate(value: Variant, allow_created: bool = true) -> Dictionary:
	if not value is Dictionary:
		return _error("SNAPSHOT_INVALID", "Runtime snapshot must be a Dictionary.")
	var snapshot: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(snapshot, "$.runtime_snapshot")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = snapshot.keys()
	keys.sort()
	if keys != KEYS:
		return _error("SNAPSHOT_KEYS_INVALID", "Runtime snapshot has missing or unknown keys.")
	if snapshot["engine_schema"] != SCHEMA or snapshot["engine_version"] != VERSION:
		return _error("SNAPSHOT_SCHEMA_UNSUPPORTED", "Runtime snapshot schema/version is unsupported.")
	var module_id_check: Dictionary = IdentifierRules.validate_symbol(
		snapshot["module_id"], "module_id", IdentifierRules.MAX_MODULE_ID_LENGTH
	)
	if not module_id_check["ok"]:
		return module_id_check
	var module_version_check: Dictionary = IdentifierRules.validate_symbol(
		snapshot["module_version"], "module_version", IdentifierRules.MAX_MODULE_VERSION_LENGTH
	)
	if not module_version_check["ok"]:
		return module_version_check
	if not snapshot["config"] is Dictionary or not snapshot["module_state"] is Dictionary:
		return _error("SNAPSHOT_STATE_INVALID", "Snapshot config and module_state must be Dictionaries.")
	if not snapshot["actions"] is Array or not snapshot["events"] is Array or not snapshot["request_ids"] is Dictionary:
		return _error("SNAPSHOT_LOG_INVALID", "Snapshot actions, events and request_ids have invalid types.")
	if not snapshot["seed"] is int or not snapshot["state_version"] is int or not snapshot["event_sequence"] is int:
		return _error("SNAPSHOT_COUNTER_INVALID", "Snapshot seed and counters must be integers.")
	if not snapshot["lifecycle"] is String:
		return _error("SNAPSHOT_LIFECYCLE_INVALID", "Snapshot lifecycle must be a String.")
	var allowed_lifecycles: Array = ["RUNNING", "FINISHED", "CLOSED"]
	if allow_created:
		allowed_lifecycles.append("CREATED")
	if snapshot["lifecycle"] not in allowed_lifecycles:
		return _error("SNAPSHOT_LIFECYCLE_INVALID", "Snapshot lifecycle is unsupported.")
	if snapshot["state_version"] < 0 or snapshot["event_sequence"] < 0:
		return _error("SNAPSHOT_COUNTER_INVALID", "Snapshot counters cannot be negative.")
	if snapshot["state_version"] != snapshot["actions"].size():
		return _error("SNAPSHOT_ACTION_COUNT_MISMATCH", "state_version must equal committed action count.")
	if snapshot["event_sequence"] != snapshot["events"].size():
		return _error("SNAPSHOT_EVENT_COUNT_MISMATCH", "event_sequence must equal stored event count.")
	if snapshot["lifecycle"] == "CREATED":
		if snapshot["seed"] != -1 or snapshot["state_version"] != 0 or snapshot["event_sequence"] != 0:
			return _error("SNAPSHOT_CREATED_INVALID", "CREATED snapshot must have seed -1 and empty logs.")
		if not snapshot["module_state"].is_empty() or not snapshot["request_ids"].is_empty():
			return _error("SNAPSHOT_CREATED_INVALID", "CREATED snapshot must have empty state and request ids.")
		return _ok()
	if snapshot["seed"] < 0:
		return _error("SNAPSHOT_SEED_INVALID", "Started snapshot seed must be non-negative.")

	var action_request_versions: Dictionary = {}
	for index in range(snapshot["actions"].size()):
		var action_result: Dictionary = GameAction.from_dict(snapshot["actions"][index])
		if not action_result["ok"]:
			return _error("SNAPSHOT_ACTION_INVALID", "Action %d is invalid: %s" % [index, action_result["code"]])
		var action_object: Object = action_result["value"]
		var request_id: String = action_object.request_id
		if not request_id.is_empty():
			if action_request_versions.has(request_id):
				return _error("SNAPSHOT_REQUEST_DUPLICATE", "Committed action request ids must be unique.")
			action_request_versions[request_id] = index + 1
	if snapshot["request_ids"] != action_request_versions:
		return _error("SNAPSHOT_REQUEST_INDEX_MISMATCH", "request_ids must exactly index committed action requests.")

	var started_count: int = 0
	var finished_count: int = 0
	var closed_count: int = 0
	for index in range(snapshot["events"].size()):
		var raw_event: Dictionary = snapshot["events"][index]
		var event_result: Dictionary = GameEvent.from_dict(raw_event)
		if not event_result["ok"]:
			return _error("SNAPSHOT_EVENT_INVALID", "Event %d is invalid: %s" % [index, event_result["code"]])
		var event_object: Object = event_result["value"]
		if event_object.sequence != index + 1:
			return _error("SNAPSHOT_EVENT_SEQUENCE_GAP", "Event sequences must be contiguous from one.")
		var event_type: String = event_object.type
		if event_type.begins_with("engine_"):
			if not event_object.visible_to.is_empty():
				return _error("SNAPSHOT_ENGINE_EVENT_PRIVATE", "Engine lifecycle events must be public.")
			match event_type:
				"engine_started":
					started_count += 1
					if index != 0:
						return _error("SNAPSHOT_START_EVENT_POSITION_INVALID", "engine_started must be the first event.")
					var start_payload: Dictionary = event_object.payload
					var start_keys: Array = start_payload.keys()
					start_keys.sort()
					if start_keys != ["lifecycle", "module_id", "module_version", "seed"]:
						return _error("SNAPSHOT_START_EVENT_PAYLOAD_INVALID", "engine_started payload keys are invalid.")
					if start_payload["module_id"] != snapshot["module_id"] or start_payload["module_version"] != snapshot["module_version"]:
						return _error("SNAPSHOT_START_EVENT_IDENTITY_MISMATCH", "engine_started identity differs from snapshot identity.")
					if start_payload["seed"] != snapshot["seed"]:
						return _error("SNAPSHOT_START_EVENT_SEED_MISMATCH", "engine_started seed differs from snapshot seed.")
					if start_payload["lifecycle"] not in ["RUNNING", "FINISHED"]:
						return _error("SNAPSHOT_START_EVENT_LIFECYCLE_INVALID", "engine_started lifecycle is invalid.")
				"engine_finished":
					finished_count += 1
					var finish_payload_check: Dictionary = _validate_state_version_event_payload(event_object.payload, snapshot["state_version"], "engine_finished")
					if not finish_payload_check["ok"]:
						return finish_payload_check
				"engine_closed":
					closed_count += 1
					var close_payload_check: Dictionary = _validate_state_version_event_payload(event_object.payload, snapshot["state_version"], "engine_closed")
					if not close_payload_check["ok"]:
						return close_payload_check
				_:
					return _error("SNAPSHOT_ENGINE_EVENT_UNKNOWN", "Unknown reserved engine event type: %s" % event_type)
	if started_count != 1:
		return _error("SNAPSHOT_START_EVENT_COUNT_INVALID", "Started snapshot must contain exactly one engine_started event.")
	var last_event: Dictionary = snapshot["events"].back()
	match snapshot["lifecycle"]:
		"RUNNING":
			if finished_count != 0 or closed_count != 0:
				return _error("SNAPSHOT_RUNNING_EVENT_MISMATCH", "RUNNING snapshot cannot contain finish/close lifecycle events.")
		"FINISHED":
			if finished_count != 1 or closed_count != 0 or last_event["type"] != "engine_finished":
				return _error("SNAPSHOT_FINISH_EVENT_MISSING", "FINISHED snapshot must contain one final engine_finished event and no close event.")
		"CLOSED":
			if closed_count != 1 or finished_count > 1 or last_event["type"] != "engine_closed":
				return _error("SNAPSHOT_CLOSE_EVENT_MISSING", "CLOSED snapshot must contain one final engine_closed event.")
	if snapshot["events"][0]["payload"]["lifecycle"] == "FINISHED" and (snapshot["state_version"] != 0 or finished_count != 1):
		return _error("SNAPSHOT_INITIAL_FINISH_MISMATCH", "An initially finished session must finish at state_version zero.")
	return _ok()


static func _validate_state_version_event_payload(payload: Dictionary, expected_version: int, event_type: String) -> Dictionary:
	var keys: Array = payload.keys()
	keys.sort()
	if keys != ["state_version"] or not payload["state_version"] is int:
		return _error("SNAPSHOT_ENGINE_EVENT_PAYLOAD_INVALID", "%s payload must contain exactly integer state_version." % event_type)
	if payload["state_version"] != expected_version:
		return _error("SNAPSHOT_ENGINE_EVENT_VERSION_MISMATCH", "%s state_version differs from snapshot state_version." % event_type)
	return _ok()


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
