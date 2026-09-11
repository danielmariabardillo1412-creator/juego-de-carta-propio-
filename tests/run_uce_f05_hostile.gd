extends SceneTree
## Hostile and adversarial checks for the UCE F05 package.
## Executed separately from the packaged suites; the packaged suites are not
## modified by this script. Run with:
##   godot --headless --path . --script res://tests/run_uce_f05_hostile.gd

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const HighCardArena = preload("res://games/high_card_arena/high_card_arena_module.gd")
const SaveCodec = preload("res://src/persistence/save_codec.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const SyncPacket = preload("res://src/network/sync_packet.gd")
const BotAdapter = preload("res://src/ai/bot_adapter.gd")
const FirstLegalPolicy = preload("res://src/ai/first_legal_policy.gd")
const IllegalBotPolicy = preload("res://tests/fixtures/illegal_bot_policy.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_same_seed_same_result()
	_different_seed_different_result()
	_failed_action_is_atomic()
	_repeated_request_executes_once()
	_public_view_hides_private_cards()
	_player_cannot_see_rival_hand()
	_unknown_player_rejected()
	_no_card_lost_or_duplicated()
	_save_load_preserves_snapshot()
	_replay_reproduces_snapshot()
	_bot_only_legal_actions()
	_demo_reaches_terminal_state()
	_terminal_accepts_no_actions()
	if _failures.is_empty():
		print("UCE-F05 HOSTILE PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F05 HOSTILE FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _same_seed_same_result() -> void:
	var config: Dictionary = _config()
	var first := UniversalCardEngine.new(HighCardArena.new(), config)
	var second := UniversalCardEngine.new(HighCardArena.new(), config)
	_expect(first.start(8128).success, "same-seed first engine starts")
	_expect(second.start(8128).success, "same-seed second engine starts")
	_expect_equal(
		first.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"],
		second.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"],
		"same seed deals the same private hand"
	)
	_expect_equal(
		first.state_digest().get("value", ""),
		second.state_digest().get("value", ""),
		"same seed produces the same state digest"
	)


func _different_seed_different_result() -> void:
	var config: Dictionary = _config()
	var first := UniversalCardEngine.new(HighCardArena.new(), config)
	var second := UniversalCardEngine.new(HighCardArena.new(), config)
	first.start(8128)
	second.start(8129)
	_expect(
		first.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"]
		!= second.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"],
		"different seed can produce a different sequence"
	)


func _failed_action_is_atomic() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var state_before: Dictionary = engine.export_module_state()
	var snapshot_before: Dictionary = engine.export_runtime_snapshot()
	var version_before: int = engine.state_version()
	var sequence_before: int = engine.event_sequence()
	var other_hand: Array = engine.get_player_state(1)["game"]["card_table"]["zones"]["hand:1"]["cards"]
	var result = engine.perform_action(GameAction.new("play_card", 0, {"instance_id": other_hand[0]}, "hostile-atomic"))
	_expect(not result.success, "playing a card from another hand is rejected")
	_expect_equal(engine.export_module_state(), state_before, "rejected action leaves module state unchanged")
	_expect_equal(engine.export_runtime_snapshot(), snapshot_before, "rejected action leaves snapshot unchanged")
	_expect_equal(engine.state_version(), version_before, "rejected action does not advance state version")
	_expect_equal(engine.event_sequence(), sequence_before, "rejected action does not append events")


func _repeated_request_executes_once() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var legal: Array = engine.get_legal_actions(0)
	var first: Dictionary = legal[0]
	var applied = engine.perform_action(GameAction.new(first["type"], 0, first["payload"], "hostile-repeat"))
	_expect(applied.success, "first request with fresh id commits")
	_expect_equal(engine.export_runtime_snapshot()["actions"].size(), 1, "one action is committed")
	var repeated = engine.perform_action(GameAction.new("concede", 1, {}, "hostile-repeat"))
	_expect(not repeated.success, "repeated request id is rejected")
	_expect_equal(repeated.code, "REQUEST_ID_DUPLICATE", "rejection code identifies duplicate request id")
	_expect_equal(engine.export_runtime_snapshot()["actions"].size(), 1, "repeated request does not execute twice")
	_expect_equal(engine.state_version(), 1, "duplicate attempt does not advance version")


func _public_view_hides_private_cards() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var public_view: Dictionary = engine.get_public_state()
	_expect_equal(
		public_view["game"]["card_table"]["zones"]["hand:0"]["cards"].size(),
		0,
		"public view reveals no private hand identities"
	)
	_expect_equal(
		public_view["game"]["card_table"]["zones"]["hand:1"]["cards"].size(),
		0,
		"public view reveals no second private hand identities"
	)
	var hand_size: int = _config()["hand_size"]
	_expect_equal(
		engine.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"].size(),
		hand_size,
		"owner view reveals own hand"
	)


func _player_cannot_see_rival_hand() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	_expect_equal(
		engine.get_player_state(0)["game"]["card_table"]["zones"]["hand:1"]["cards"].size(),
		0,
		"player zero cannot see rival hand identities"
	)
	_expect_equal(
		engine.get_player_state(1)["game"]["card_table"]["zones"]["hand:0"]["cards"].size(),
		0,
		"player one cannot see rival hand identities"
	)


func _unknown_player_rejected() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	_expect(engine.get_player_state(99)["game"].has("view_error"), "unknown viewer receives explicit view error")
	_expect(engine.get_legal_actions(99).is_empty(), "unknown viewer receives no legal actions")
	var sync: Dictionary = SyncPacket.create(engine, 99, 0)
	_expect(not sync["ok"], "sync packet rejects player id absent from the game")
	var acted = engine.perform_action(GameAction.new("play_card", 99, {}, "hostile-ghost"))
	_expect(not acted.success, "action by nonexistent player is rejected")


func _no_card_lost_or_duplicated() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	_expect(_inventory_consistent(engine.export_module_state()), "initial inventory is complete and unique")
	var legal: Array = engine.get_legal_actions(0)
	for index in range(2):
		var selected: Dictionary = legal[0]
		var applied = engine.perform_action(GameAction.new(selected["type"], 0, selected["payload"], "hostile-inv-%d" % index))
		_expect(applied.success, "inventory-step action %d commits" % index)
		_expect(_inventory_consistent(engine.export_module_state()), "inventory stays complete after action %d" % index)
		legal = engine.get_legal_actions(1)
		var second: Dictionary = legal[0]
		var applied_second = engine.perform_action(GameAction.new(second["type"], 1, second["payload"], "hostile-inv2-%d" % index))
		_expect(applied_second.success, "inventory-step second action %d commits" % index)
		_expect(_inventory_consistent(engine.export_module_state()), "inventory stays complete after second action %d" % index)
		legal = engine.get_legal_actions(0)


func _inventory_consistent(module_state: Dictionary) -> bool:
	var cards: Dictionary = module_state["cards"]
	var zone_ids: Array = cards["zones"].keys()
	var seen: Dictionary = {}
	var total: int = 0
	for zone_id in zone_ids:
		var zone_cards: Array = cards["zones"][zone_id]["cards"]
		total += zone_cards.size()
		for instance_id in zone_cards:
			if seen.has(instance_id):
				return false
			seen[instance_id] = true
	return seen.size() == cards["instances"].size() and total == cards["instances"].size()


func _save_load_preserves_snapshot() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var built: Dictionary = SaveCodec.build(engine, engine.module_version())
	_expect(built["ok"], "save package builds for hostile persistence check")
	var encoded: Dictionary = SaveCodec.encode(built["value"], true)
	_expect(encoded["ok"], "save package encodes")
	var decoded: Dictionary = SaveCodec.decode(encoded["value"])
	_expect(decoded["ok"], "save package decodes")
	_expect_equal(decoded["value"]["payload"], snapshot, "save/load preserves the complete runtime snapshot")


func _replay_reproduces_snapshot() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay: Dictionary = ReplayService.replay(HighCardArena.new(), _config(), snapshot)
	_expect(replay["ok"], "replay reproduces the running snapshot")
	_expect_equal(replay["expected_digest"], replay["actual_digest"], "replay digests match for running snapshot")
	var finished_engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	finished_engine.start(8128)
	_play_to_finish(finished_engine)
	var finished_snapshot: Dictionary = finished_engine.export_runtime_snapshot()
	var finished_replay: Dictionary = ReplayService.replay(HighCardArena.new(), _config(), finished_snapshot)
	_expect(finished_replay["ok"], "replay reproduces the finished snapshot")
	_expect_equal(
		finished_replay["expected_digest"],
		finished_replay["actual_digest"],
		"replay digests match for finished snapshot"
	)


func _bot_only_legal_actions() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	var actor_id: int = 0
	var legal: Array = engine.get_legal_actions(actor_id)
	var choice: Dictionary = BotAdapter.choose(
		HighCardArena.new(),
		engine.export_module_state(),
		actor_id,
		FirstLegalPolicy.new(),
		"hostile-bot"
	)
	_expect(choice["ok"], "baseline bot produces a canonical action")
	_expect_equal(choice["value"].request_id, "hostile-bot", "bot preserves caller-owned request id")
	var chosen: Dictionary = choice["value"].to_dict()
	var contained: bool = false
	for candidate in legal:
		if candidate["type"] == chosen["type"] and candidate["payload"] == chosen["payload"]:
			contained = true
	_expect(contained, "bot action appears verbatim in the advertised legal set")
	var illegal: Dictionary = BotAdapter.choose(
		HighCardArena.new(),
		engine.export_module_state(),
		actor_id,
		IllegalBotPolicy.new(),
		"hostile-illegal"
	)
	_expect(not illegal["ok"], "bot cannot execute an action outside the legal set")
	var applied = engine.perform_action(choice["value"])
	_expect(applied.success, "the canonical bot action itself commits")


func _demo_reaches_terminal_state() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	_expect_equal(engine.lifecycle_name(), "RUNNING", "demo engine starts running")
	var steps: int = _play_to_finish(engine)
	_expect(steps > 0, "demo game advances before finishing")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "demo game reaches terminal state")
	var final_public: Dictionary = engine.get_public_state()["game"]
	_expect(not final_public["winner_ids"].is_empty(), "terminal state declares a winner or leaders")
	_expect(
		final_public["finished_reason"] in ["TARGET_REACHED", "HANDS_EXHAUSTED"],
		"terminal state reports a valid finish reason"
	)


func _terminal_accepts_no_actions() -> void:
	var engine := UniversalCardEngine.new(HighCardArena.new(), _config())
	engine.start(8128)
	_play_to_finish(engine)
	_expect_equal(engine.lifecycle_name(), "FINISHED", "terminal precondition reached")
	var version_before: int = engine.state_version()
	var after = engine.perform_action(GameAction.new("concede", 0, {}, "hostile-after-finish"))
	_expect(not after.success, "normal action after terminal state is rejected")
	_expect_equal(engine.state_version(), version_before, "post-terminal action does not change version")
	_expect(engine.get_legal_actions(0).is_empty() and engine.get_legal_actions(1).is_empty(), "no legal actions after terminal state")


func _play_to_finish(engine: Object) -> int:
	var steps: int = 0
	var safety: int = 200
	while engine.lifecycle_name() == "RUNNING" and safety > 0:
		var public_state: Dictionary = engine.get_public_state()
		var actor_id: int = public_state["game"]["active_player"]
		var legal: Array = engine.get_legal_actions(actor_id)
		if legal.is_empty():
			return steps
		var selected: Dictionary = legal[0]
		var applied = engine.perform_action(GameAction.new(selected["type"], actor_id, selected["payload"], "hostile-auto-%d" % steps))
		if not applied.success:
			return steps
		steps += 1
		safety -= 1
	return steps


func _config() -> Dictionary:
	return {
		"player_names": ["Ana", "Bruno"],
		"hand_size": 5,
		"target_score": 3,
		"starting_player": 0,
	}


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
