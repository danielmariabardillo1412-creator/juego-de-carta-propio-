extends SceneTree
## F04 hardening suite: typed saves, sandboxed files, replay and sync packets.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const MinimalTurnModule = preload("res://tests/fixtures/minimal_turn_module.gd")
const SaveCodec = preload("res://src/persistence/save_codec.gd")
const SaveFileStore = preload("res://src/persistence/save_file_store.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const SyncPacket = preload("res://src/network/sync_packet.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-F04 PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F04 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var config: Dictionary = {"player_count": 2, "max_passes": 2, "ratio": 1.0}
	var engine = UniversalCardEngine.new(MinimalTurnModule.new(), config)
	_expect(engine.is_ready(), "persistence fixture engine constructs")
	_expect(engine.start(44).success, "persistence fixture starts")
	_expect(engine.perform_action(GameAction.new("pass", 0, {}, "f04-1")).success, "first replay action commits")
	_expect(engine.perform_action(GameAction.new("pass", 1, {}, "f04-2")).success, "second replay action commits")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "fixture reaches finished lifecycle")

	var package: Dictionary = SaveCodec.build(engine)
	_expect(package["ok"], "typed save package builds")
	_expect_equal(package["value"]["module_id"], engine.module_id(), "save promotes module id to package header")
	_expect_equal(package["value"]["engine_version"], 1, "save promotes engine schema version")
	var encoded: Dictionary = SaveCodec.encode(package["value"], true)
	_expect(encoded["ok"], "typed save encodes")
	var decoded: Dictionary = SaveCodec.decode(encoded["value"])
	_expect(decoded["ok"], "typed save decodes")
	_expect(decoded["value"]["payload"]["state_version"] is int, "save preserves int type")
	_expect(decoded["value"]["payload"]["config"]["ratio"] is float, "save preserves float type")
	_expect_equal(decoded["value"], package["value"], "save round trip is structurally exact")
	var header_tamper: Dictionary = package["value"].duplicate(true)
	header_tamper["module_id"] = "other.module"
	_expect(not SaveCodec.validate(header_tamper)["ok"], "save header cannot disagree with payload")
	var checksum_tamper: Dictionary = package["value"].duplicate(true)
	checksum_tamper["payload"]["state_version"] += 1
	_expect(not SaveCodec.validate(checksum_tamper)["ok"], "payload tampering fails integrity")
	var typed_extra_key: Dictionary = SaveCodec.decode('{"t":"nil","v":1}')
	_expect(not typed_extra_key["ok"], "typed nil node rejects unknown value field")
	_expect_equal(typed_extra_key["code"], "SAVE_TYPED_KEYS_INVALID", "typed-node key failure is explicit")
	var noncanonical_int: Dictionary = SaveCodec.decode('{"t":"int","v":"01"}')
	_expect(not noncanonical_int["ok"], "typed integer rejects noncanonical representation")
	_expect_equal(noncanonical_int["code"], "SAVE_TYPED_INT_NONCANONICAL", "noncanonical integer failure is explicit")
	var noncanonical_float: Dictionary = SaveCodec.decode('{"t":"float","v":"01.0"}')
	_expect(not noncanonical_float["ok"], "typed float rejects noncanonical representation")
	_expect_equal(noncanonical_float["code"], "SAVE_TYPED_FLOAT_NONCANONICAL", "noncanonical float failure is explicit")

	_expect(not SaveFileStore.validate_path("res://save.json")["ok"], "file store rejects project-resource writes")
	_expect(not SaveFileStore.validate_path("user://../escape.json")["ok"], "file store rejects traversal")
	_expect(not SaveFileStore.validate_path("user://slot.json.bak")["ok"], "file store reserves backup suffix")
	_expect(SaveFileStore.validate_path("user://uce_tests/f04.json")["ok"], "file store accepts sandboxed nested path")
	var save_path: String = "user://uce_tests/f04.json"
	var stored: Dictionary = SaveFileStore.write_atomic(save_path, encoded["value"])
	_expect(stored["ok"], "sandboxed save commits atomically")
	var loaded: Dictionary = SaveFileStore.read_recoverable(save_path)
	_expect(loaded["ok"], "recoverable read loads committed primary")
	_expect_equal(loaded.get("source", ""), "PRIMARY", "recoverable read reports primary source")
	_expect(SaveCodec.decode(loaded["value"])["ok"], "file round trip remains a valid save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))

	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay_from_snapshot(MinimalTurnModule.new(), snapshot)
	_expect(replay["ok"], "fresh module replays full snapshot exactly")
	_expect_equal(replay["expected_digest"], replay["actual_digest"], "replay complete digests match")
	var script_replay: Dictionary = ReplayService.replay_script(MinimalTurnModule, snapshot)
	_expect(script_replay["ok"], "module Script creates fresh replay instance")
	var difference: Dictionary = ReplayService.first_difference(
		{"a": [1, 2], "b": true},
		{"a": [1, 3], "b": true}
	)
	_expect_equal(difference["path"], "$.a[1]", "replay drift reports first structural path")
	_expect_equal(difference["reason"], "VALUE_MISMATCH", "replay drift reports mismatch reason")

	var sync: Dictionary = SyncPacket.create(engine, 0, 0)
	_expect(sync["ok"], "versioned player sync packet builds")
	_expect(SyncPacket.validate(sync["value"])["ok"], "sync packet validates independently")
	_expect_equal(sync["value"]["schema"], SyncPacket.SCHEMA, "sync packet exposes protocol schema")
	_expect(sync["value"]["events_digest"].length() == 64, "sync packet protects event list")
	var unknown_viewer: Dictionary = SyncPacket.create(engine, 99, 0)
	_expect(not unknown_viewer["ok"], "sync rejects player id absent from module")
	var ahead: Dictionary = SyncPacket.create(engine, 0, engine.event_sequence() + 1)
	_expect(not ahead["ok"], "sync cursor cannot be ahead of server sequence")
	var sync_tamper: Dictionary = sync["value"].duplicate(true)
	sync_tamper["state"]["game"]["pass_count"] = 999
	_expect(not SyncPacket.validate(sync_tamper)["ok"], "sync state tampering fails digest")
	var event_tamper: Dictionary = sync["value"].duplicate(true)
	event_tamper["events"][0]["sequence"] = 0
	_expect(not SyncPacket.validate(event_tamper)["ok"], "sync rejects event outside cursor bounds")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
