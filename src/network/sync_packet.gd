extends RefCounted
## Produces and validates a client-safe synchronization packet from one engine.

const StateDigest = preload("res://src/state/state_digest.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const GameEvent = preload("res://src/core/game_event.gd")

const SCHEMA := "zapiti-universal-engine-sync"
const VERSION := 2
const PACKET_KEYS := [
	"after_sequence",
	"event_sequence",
	"events",
	"events_digest",
	"lifecycle",
	"module_id",
	"module_version",
	"schema",
	"state",
	"state_digest",
	"state_version",
	"version",
	"viewer_id",
]


static func create(engine: Object, viewer_id: int = -1, after_sequence: int = 0) -> Dictionary:
	if engine == null:
		return _error("SYNC_ENGINE_MISSING", "A compatible engine is required.")
	if viewer_id < -1:
		return _error("SYNC_VIEWER_INVALID", "viewer_id must be -1 or a non-negative player id.")
	if after_sequence < 0:
		return _error("SYNC_SEQUENCE_INVALID", "after_sequence must be zero or greater.")
	var required_methods: Array = [
		"get_public_state",
		"get_events",
		"module_id",
		"module_version",
		"lifecycle_name",
	]
	for method_name in required_methods:
		if not engine.has_method(method_name):
			return _error("SYNC_ENGINE_INVALID", "Engine lacks synchronization method: %s" % method_name)
	if viewer_id >= 0 and not engine.has_method("get_player_state"):
		return _error("SYNC_ENGINE_INVALID", "Engine lacks player-state synchronization method.")
	var state: Variant
	if viewer_id >= 0:
		state = engine.call("get_player_state", viewer_id)
	else:
		state = engine.call("get_public_state")
	if not state is Dictionary or not state.get("engine", null) is Dictionary or not state.get("game", null) is Dictionary:
		return _error("SYNC_STATE_INVALID", "Engine returned an invalid synchronization state.")
	if state["game"].has("view_error"):
		var view_error: Variant = state["game"]["view_error"]
		return _error(
			"SYNC_VIEW_FAILED",
			"Engine view failed: %s — %s" % [view_error.get("code", "UNKNOWN"), view_error.get("message", "")]
		)
	var state_version: Variant = state["engine"].get("state_version", -1)
	var event_sequence: Variant = state["engine"].get("event_sequence", -1)
	if not state_version is int or state_version < 0 or not event_sequence is int or event_sequence < 0:
		return _error("SYNC_COUNTER_INVALID", "Engine state contains invalid counters.")
	if after_sequence > event_sequence:
		return _error("SYNC_SEQUENCE_AHEAD", "after_sequence cannot exceed current event sequence.")
	var events: Variant = engine.call("get_events", after_sequence, viewer_id)
	if not events is Array:
		return _error("SYNC_EVENTS_INVALID", "Engine returned an invalid event list.")
	var state_digest: Dictionary = StateDigest.sha256(state)
	if not state_digest["ok"]:
		return state_digest
	var events_digest: Dictionary = StateDigest.sha256(events)
	if not events_digest["ok"]:
		return events_digest
	var packet: Dictionary = {
		"schema": SCHEMA,
		"version": VERSION,
		"viewer_id": viewer_id,
		"after_sequence": after_sequence,
		"module_id": engine.call("module_id"),
		"module_version": engine.call("module_version"),
		"lifecycle": engine.call("lifecycle_name"),
		"state_version": state_version,
		"event_sequence": event_sequence,
		"state_digest": state_digest["value"],
		"events_digest": events_digest["value"],
		"state": state,
		"events": events,
	}
	var packet_check: Dictionary = validate(packet)
	if not packet_check["ok"]:
		return packet_check
	return {"ok": true, "code": "OK", "message": "", "value": packet}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("SYNC_PACKET_INVALID", "Sync packet must be a Dictionary.")
	var packet: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(packet, "$.sync_packet")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = packet.keys()
	keys.sort()
	if keys != PACKET_KEYS:
		return _error("SYNC_PACKET_KEYS_INVALID", "Sync packet has missing or unknown keys.")
	if packet["schema"] != SCHEMA or packet["version"] != VERSION:
		return _error("SYNC_SCHEMA_UNSUPPORTED", "Sync schema/version is unsupported.")
	if not packet["viewer_id"] is int or packet["viewer_id"] < -1:
		return _error("SYNC_VIEWER_INVALID", "Sync viewer id is invalid.")
	if not packet["after_sequence"] is int or packet["after_sequence"] < 0:
		return _error("SYNC_SEQUENCE_INVALID", "Sync after_sequence is invalid.")
	if not packet["state_version"] is int or packet["state_version"] < 0:
		return _error("SYNC_COUNTER_INVALID", "Sync state_version is invalid.")
	if not packet["event_sequence"] is int or packet["event_sequence"] < 0:
		return _error("SYNC_COUNTER_INVALID", "Sync event_sequence is invalid.")
	if packet["after_sequence"] > packet["event_sequence"]:
		return _error("SYNC_SEQUENCE_AHEAD", "Sync cursor exceeds packet event sequence.")
	for text_key in ["module_id", "module_version", "lifecycle"]:
		if not packet[text_key] is String or packet[text_key].is_empty():
			return _error("SYNC_IDENTITY_INVALID", "Sync identity/lifecycle fields must be non-empty Strings.")
	if not packet["state"] is Dictionary or not packet["events"] is Array:
		return _error("SYNC_CONTENT_INVALID", "Sync state/events fields are invalid.")
	if not packet["state_digest"] is String or packet["state_digest"].length() != 64:
		return _error("SYNC_DIGEST_INVALID", "Sync state digest is invalid.")
	if not packet["events_digest"] is String or packet["events_digest"].length() != 64:
		return _error("SYNC_DIGEST_INVALID", "Sync events digest is invalid.")
	if not packet["state"].get("engine", null) is Dictionary:
		return _error("SYNC_STATE_INVALID", "Sync state lacks engine envelope.")
	var engine_envelope: Dictionary = packet["state"]["engine"]
	if engine_envelope.get("module_id", "") != packet["module_id"]:
		return _error("SYNC_MODULE_MISMATCH", "Packet module_id differs from state envelope.")
	if engine_envelope.get("module_version", "") != packet["module_version"]:
		return _error("SYNC_MODULE_VERSION_MISMATCH", "Packet module_version differs from state envelope.")
	if engine_envelope.get("lifecycle", "") != packet["lifecycle"]:
		return _error("SYNC_LIFECYCLE_MISMATCH", "Packet lifecycle differs from state envelope.")
	if engine_envelope.get("state_version", -1) != packet["state_version"]:
		return _error("SYNC_STATE_VERSION_MISMATCH", "Packet state version differs from state envelope.")
	if engine_envelope.get("event_sequence", -1) != packet["event_sequence"]:
		return _error("SYNC_EVENT_SEQUENCE_MISMATCH", "Packet event sequence differs from state envelope.")
	var previous_sequence: int = packet["after_sequence"]
	for index in range(packet["events"].size()):
		var event_result: Dictionary = GameEvent.from_dict(packet["events"][index])
		if not event_result["ok"]:
			return _error("SYNC_EVENT_INVALID", "Sync event %d is invalid: %s" % [index, event_result["code"]])
		var sequence: int = event_result["value"].sequence
		if sequence <= previous_sequence or sequence > packet["event_sequence"]:
			return _error("SYNC_EVENT_ORDER_INVALID", "Visible event sequences must be strictly increasing inside cursor bounds.")
		previous_sequence = sequence
	var state_digest: Dictionary = StateDigest.sha256(packet["state"])
	var events_digest: Dictionary = StateDigest.sha256(packet["events"])
	if not state_digest["ok"] or not events_digest["ok"]:
		return _error("SYNC_DIGEST_FAILED", "Sync packet content could not be digested.")
	if state_digest["value"] != packet["state_digest"] or events_digest["value"] != packet["events_digest"]:
		return _error("SYNC_DIGEST_MISMATCH", "Sync packet integrity check failed.")
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
