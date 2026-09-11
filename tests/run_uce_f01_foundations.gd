extends SceneTree
## Foundation hardening suite: kernel contracts, snapshots and atomic rejection.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const RuntimeSnapshot = preload("res://src/core/runtime_snapshot.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const StateDigest = preload("res://src/state/state_digest.gd")
const GameCatalog = preload("res://src/core/game_catalog.gd")
const MinimalTurnModule = preload("res://tests/fixtures/minimal_turn_module.gd")
const IdentityDriftModule = preload("res://tests/fixtures/identity_drift_module.gd")
const MalformedTransitionModule = preload("res://tests/fixtures/malformed_transition_module.gd")
const InvalidViewModule = preload("res://tests/fixtures/invalid_view_module.gd")
const InvalidLegalActionModule = preload("res://tests/fixtures/invalid_legal_action_module.gd")
const ReservedEventModule = preload("res://tests/fixtures/reserved_event_module.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-F01 PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F01 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var digest_a: Dictionary = StateDigest.sha256({"b": 2, "a": 1})
	var digest_b: Dictionary = StateDigest.sha256({"a": 1, "b": 2})
	var digest_float: Dictionary = StateDigest.sha256(1.0)
	var digest_int: Dictionary = StateDigest.sha256(1)
	_expect_equal(digest_a["value"], digest_b["value"], "digest ignores Dictionary insertion order")
	_expect(digest_float["value"] != digest_int["value"], "digest distinguishes int and float")
	var deep_value: Variant = {}
	for _depth in range(PureDataValidator.MAX_DEPTH + 2):
		deep_value = {"child": deep_value}
	var deep_check: Dictionary = PureDataValidator.validate(deep_value)
	_expect(not deep_check["ok"], "pure-data depth limit rejects pathological nesting")
	_expect_equal(deep_check["code"], "DATA_DEPTH_EXCEEDED", "depth rejection has explicit code")

	var catalog = GameCatalog.new()
	var catalog_register: Dictionary = catalog.register(
		"fixture.minimal_turn.v1",
		"res://tests/fixtures/minimal_turn_module.gd",
		"Minimal fixture"
	)
	_expect(catalog_register["ok"], "catalog registers a complete module contract")
	var catalog_create: Dictionary = catalog.create_module("fixture.minimal_turn.v1")
	_expect(catalog_create["ok"], "catalog recreates a module with stable identity")
	_expect_equal(catalog.list_entries()[0]["module_version"], "1.0.0-fixture", "catalog freezes declared module version")

	var engine = UniversalCardEngine.new(MinimalTurnModule.new(), {"player_count": 2, "max_passes": 3})
	_expect(engine.is_ready(), "valid module constructs")
	var created_snapshot: Dictionary = engine.export_runtime_snapshot()
	_expect(RuntimeSnapshot.validate(created_snapshot)["ok"], "CREATED snapshot validates")
	_expect_equal(created_snapshot["engine_schema"], RuntimeSnapshot.SCHEMA, "snapshot exposes schema")
	_expect_equal(created_snapshot["request_ids"], {}, "CREATED snapshot has empty request index")
	var premature_close = engine.close()
	_expect(not premature_close.success, "unstarted session cannot close")
	_expect_equal(premature_close.code, "ENGINE_NOT_STARTED", "premature close has explicit code")

	var started = engine.start(77)
	_expect(started.success, "engine starts")
	_expect(engine.validate_internal_consistency()["ok"], "started engine is internally consistent")
	var whitespace_action = engine.perform_action(GameAction.new("   ", 0, {}, "ws-type"))
	_expect(not whitespace_action.success, "whitespace action type is rejected")
	var whitespace_request = engine.perform_action(GameAction.new("pass", 0, {}, "   "))
	_expect(not whitespace_request.success, "whitespace request id is rejected")
	var before_rejection: Dictionary = engine.export_runtime_snapshot()
	var wrong_actor = engine.perform_action(GameAction.new("pass", 1, {}, "wrong-actor"))
	_expect(not wrong_actor.success, "module rejection remains a failure")
	_expect_equal(engine.export_runtime_snapshot(), before_rejection, "rejected action changes no runtime field")

	var applied = engine.perform_action(GameAction.new("pass", 0, {}, "f01-1"))
	_expect(applied.success, "legal action commits")
	var committed: Dictionary = engine.export_runtime_snapshot()
	_expect_equal(committed["request_ids"], {"f01-1": 1}, "request index records committed version")
	_expect(RuntimeSnapshot.validate(committed, false)["ok"], "committed snapshot validates")
	var duplicate_before: Dictionary = engine.export_runtime_snapshot()
	var duplicate = engine.perform_action(GameAction.new("pass", 1, {}, "f01-1"))
	_expect(not duplicate.success, "duplicate request is rejected")
	_expect_equal(duplicate.code, "REQUEST_ID_DUPLICATE", "duplicate request has explicit code")
	_expect_equal(engine.export_runtime_snapshot(), duplicate_before, "duplicate rejection is fully atomic")

	var exported: Dictionary = engine.export_runtime_snapshot()
	exported["module_state"]["pass_count"] = 999
	exported["request_ids"]["fake"] = 99
	_expect_equal(engine.export_module_state()["pass_count"], 1, "exported snapshot cannot mutate engine state")
	_expect(not engine.export_runtime_snapshot()["request_ids"].has("fake"), "exported request index is isolated")

	var tampered_requests: Dictionary = engine.export_runtime_snapshot()
	tampered_requests["request_ids"] = {}
	_expect(not RuntimeSnapshot.validate(tampered_requests, false)["ok"], "snapshot rejects missing request index")
	var tampered_events: Dictionary = engine.export_runtime_snapshot()
	tampered_events["events"][0]["sequence"] = 2
	_expect(not RuntimeSnapshot.validate(tampered_events, false)["ok"], "snapshot rejects event sequence gaps")
	var tampered_start_seed: Dictionary = engine.export_runtime_snapshot()
	tampered_start_seed["events"][0]["payload"]["seed"] = 999
	_expect(not RuntimeSnapshot.validate(tampered_start_seed, false)["ok"], "snapshot rejects start-event seed mismatch")
	var forged_engine_event: Dictionary = engine.export_runtime_snapshot()
	forged_engine_event["events"][1]["type"] = "engine_forged"
	_expect(not RuntimeSnapshot.validate(forged_engine_event, false)["ok"], "snapshot rejects unknown reserved engine event")

	var drift_engine = UniversalCardEngine.new(IdentityDriftModule.new(), {"player_count": 2, "max_passes": 1})
	_expect(drift_engine.is_ready(), "identity drift module passes initial construction")
	var drift_start = drift_engine.start(1)
	_expect(not drift_start.success, "module identity drift is rejected before start")
	_expect_equal(drift_start.code, "MODULE_IDENTITY_DRIFT", "identity drift has explicit code")

	var malformed_engine = UniversalCardEngine.new(MalformedTransitionModule.new(), {"player_count": 2, "max_passes": 2})
	_expect(malformed_engine.start(2).success, "malformed transition fixture starts")
	var malformed_before: Dictionary = malformed_engine.export_runtime_snapshot()
	var malformed_result = malformed_engine.perform_action(GameAction.new("pass", 0, {}, "malformed"))
	_expect(not malformed_result.success, "transition with unknown key is rejected")
	_expect_equal(malformed_result.code, "TRANSITION_KEYS_INVALID", "unknown transition key is identified")
	_expect_equal(malformed_engine.export_runtime_snapshot(), malformed_before, "malformed transition is atomic")

	var reserved_engine = UniversalCardEngine.new(ReservedEventModule.new(), {"player_count": 2, "max_passes": 2})
	_expect(reserved_engine.start(5).success, "reserved-event fixture starts")
	var reserved_before: Dictionary = reserved_engine.export_runtime_snapshot()
	var reserved_result = reserved_engine.perform_action(GameAction.new("pass", 0, {}, "reserved-event"))
	_expect(not reserved_result.success, "module cannot emit reserved engine event")
	_expect_equal(reserved_result.code, "EVENT_TYPE_RESERVED", "reserved event namespace has explicit code")
	_expect_equal(reserved_engine.export_runtime_snapshot(), reserved_before, "reserved event rejection is atomic")

	var view_engine = UniversalCardEngine.new(InvalidViewModule.new(), {"player_count": 2, "max_passes": 2})
	_expect(view_engine.start(3).success, "invalid-view fixture starts")
	var view: Dictionary = view_engine.get_public_state()
	_expect(view["game"].has("view_error"), "non-portable view becomes explicit view error")
	_expect_equal(view["game"]["view_error"]["code"], "DATA_TYPE_UNSUPPORTED", "view error preserves validator code")

	var legal_engine = UniversalCardEngine.new(InvalidLegalActionModule.new(), {"player_count": 2, "max_passes": 2})
	_expect(legal_engine.start(4).success, "invalid-legal-action fixture starts")
	_expect_equal(legal_engine.get_legal_actions(0), [], "legal action for wrong actor is suppressed")

	var close_result = engine.close()
	_expect(close_result.success, "running engine can close")
	_expect_equal(engine.lifecycle_name(), "CLOSED", "close changes lifecycle")
	_expect(engine.validate_internal_consistency()["ok"], "closed engine remains internally consistent")
	_expect_equal(engine.export_runtime_snapshot()["events"].back()["type"], "engine_closed", "closed snapshot ends with close event")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
