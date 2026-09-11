extends SceneTree
## Headless smoke suite for the UCE-01 action/event pipeline.
## Run:
##   godot --headless --path . --script res://tests/run_uce_01_smoke.gd

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const MinimalTurnModule = preload("res://tests/fixtures/minimal_turn_module.gd")

var _failures: Array = []
var _checks := 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-01 PASS: %d checks" % _checks)
		quit(0)
		return

	printerr("UCE-01 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var engine = UniversalCardEngine.new(
		MinimalTurnModule.new(),
		{"player_count": 2, "max_passes": 2}
	)
	_expect(engine.is_ready(), "valid module passes runtime contract")

	var start_result = engine.start(12345)
	_expect(start_result.success, "engine starts with explicit seed")
	_expect_equal(engine.lifecycle_name(), "RUNNING", "lifecycle becomes RUNNING")
	_expect_equal(engine.state_version(), 0, "start does not count as a game transition")
	_expect_equal(engine.get_public_state()["game"]["current_actor"], 0, "initial actor is player 0")

	var events_before_invalid: int = engine.get_events().size()
	var malformed_result = engine.perform_action(
		GameAction.new("pass", 0, {"object": MinimalTurnModule.new()}, "bad-payload")
	)
	_expect(not malformed_result.success, "non-portable action payload is rejected")
	_expect_equal(malformed_result.code, "DATA_TYPE_UNSUPPORTED", "payload rejection identifies unsupported data")

	var invalid_result = engine.perform_action(GameAction.new("pass", 1, {}, "bad-1"))
	_expect(not invalid_result.success, "wrong actor action is rejected")
	_expect_equal(invalid_result.code, "WRONG_ACTOR", "module rejection code is preserved")
	_expect_equal(engine.state_version(), 0, "rejected action does not mutate state version")
	_expect_equal(engine.get_events().size(), events_before_invalid, "rejected action emits no events")

	var first_result = engine.perform_action(GameAction.new("pass", 0, {}, "req-1"))
	_expect(first_result.success, "first legal action is applied")
	_expect_equal(engine.state_version(), 1, "legal action increments state version")
	_expect_equal(engine.get_public_state()["game"]["current_actor"], 1, "turn advances to player 1")

	var public_events: Array = engine.get_events(0, -1)
	var player_zero_events: Array = engine.get_events(0, 0)
	var player_one_events: Array = engine.get_events(0, 1)
	_expect_equal(public_events.size(), 2, "public reader sees engine_started and turn_passed")
	_expect_equal(player_zero_events.size(), 3, "actor sees its private action receipt")
	_expect_equal(player_one_events.size(), 2, "other player cannot see private action receipt")

	var second_result = engine.perform_action(GameAction.new("pass", 1, {}, "req-2"))
	_expect(second_result.success, "second legal action is applied")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "fixture completion closes gameplay")
	_expect_equal(engine.state_version(), 2, "second action increments state version")

	var after_finish = engine.perform_action(GameAction.new("pass", 0))
	_expect(not after_finish.success, "actions after completion are rejected")
	_expect_equal(after_finish.code, "ENGINE_NOT_RUNNING", "finished rejection is explicit")

	var snapshot: Dictionary = engine.export_runtime_snapshot()
	_expect_equal(snapshot["actions"].size(), 2, "snapshot contains only committed actions")
	_expect_equal(snapshot["module_state"]["pass_count"], 2, "snapshot contains committed module state")
	_expect_equal(snapshot["lifecycle"], "FINISHED", "snapshot reports lifecycle")

	var close_result = engine.close()
	_expect(close_result.success, "finished engine can be closed")
	_expect_equal(engine.lifecycle_name(), "CLOSED", "close moves lifecycle to CLOSED")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
