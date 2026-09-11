extends SceneTree
## End-to-end theoretical acceptance suite for the complete experimental engine.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const HighCardArena = preload("res://games/high_card_arena/high_card_arena_module.gd")
const PlayerRegistry = preload("res://src/session/player_registry.gd")
const TurnState = preload("res://src/turns/turn_state.gd")
const PhaseMachine = preload("res://src/turns/phase_machine.gd")
const ScoreState = preload("res://src/scoring/score_state.gd")
const StateDigest = preload("res://src/state/state_digest.gd")
const SaveCodec = preload("res://src/persistence/save_codec.gd")
const SaveFileStore = preload("res://src/persistence/save_file_store.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const SyncPacket = preload("res://src/network/sync_packet.gd")
const ConditionEvaluator = preload("res://src/rules/condition_evaluator.gd")
const EffectExecutor = preload("res://src/rules/effect_executor.gd")
const GameCatalog = preload("res://src/core/game_catalog.gd")
const BotAdapter = preload("res://src/ai/bot_adapter.gd")
const FirstLegalPolicy = preload("res://src/ai/first_legal_policy.gd")
const ActionMutationModule = preload("res://tests/fixtures/action_mutation_module.gd")

var _checks = 0
var _failures: Array = []


func _initialize() -> void:
	_test_services()
	_test_complete_game()
	if _failures.is_empty():
		print("ZAPITI UNIVERSAL ENGINE COMPLETE PASS: %d checks" % _checks)
		quit(0)
	else:
		printerr("ZAPITI UNIVERSAL ENGINE COMPLETE FAIL: %d/%d" % [_failures.size(), _checks])
		for failure in _failures:
			printerr(" - " + failure)
		quit(1)


func _test_services() -> void:
	var registry = PlayerRegistry.create([
		PlayerRegistry.make_player(0, "A", 0),
		PlayerRegistry.make_player(1, "B", 1),
	])
	_expect(registry["ok"], "player registry builds")
	_expect_equal(PlayerRegistry.player_ids(registry["value"]), [0, 1], "player registry preserves order")

	var turn = TurnState.create([0, 1], 0)
	_expect(turn["ok"], "turn state builds")
	_expect_equal(TurnState.active_player(turn["value"]), 0, "turn starts at requested player")
	var advanced = TurnState.advance(turn["value"])
	_expect_equal(TurnState.active_player(advanced["value"]), 1, "turn advances")
	_expect_equal(turn["value"]["active_index"], 0, "turn advance is immutable")

	var phases = PhaseMachine.create({
		"initial": "A",
		"terminal": ["C"],
		"transitions": {"A": ["B"], "B": ["C"], "C": []},
	})
	_expect(phases["ok"], "phase machine builds")
	var phase_b = PhaseMachine.transition(phases["value"], "B")
	_expect(phase_b["ok"], "legal phase transition works")
	_expect(not PhaseMachine.transition(phases["value"], "C")["ok"], "illegal phase transition rejects")
	_expect(not PhaseMachine.create({
		"initial": "A",
		"terminal": ["B"],
		"transitions": {"A": ["B"]},
	})["ok"], "phase graph rejects destination without its own node")
	var damaged_phase: Dictionary = phase_b["value"].duplicate(true)
	damaged_phase["history"].append("A")
	_expect(not PhaseMachine.validate(damaged_phase)["ok"], "phase validation rejects incoherent history")

	var scores = ScoreState.create([0, 1], 0, 2)
	var score_one = ScoreState.add(scores["value"], 1, 2)
	_expect(ScoreState.target_reached(score_one["value"]), "score target detects")
	_expect_equal(ScoreState.leader_ids(score_one["value"]), [1], "score leader resolves")
	_expect_equal(scores["value"]["scores"]["1"], 0, "score mutation is immutable")

	var digest_a = StateDigest.sha256({"b": 2, "a": 1})
	var digest_b = StateDigest.sha256({"a": 1, "b": 2})
	_expect_equal(digest_a["value"], digest_b["value"], "canonical digest ignores dictionary insertion order")

	var condition = ConditionEvaluator.evaluate({
		"op": "all",
		"conditions": [
			{"op": "gte", "left": {"path": "score"}, "right": 3},
			{"op": "equals", "left": {"path": "phase"}, "right": "PLAY"},
		],
	}, {"score": 3, "phase": "PLAY"})
	_expect(condition["ok"] and condition["value"], "condition language evaluates nested conditions")
	var effects = EffectExecutor.apply_all({"score": 1, "log": []}, [
		{"type": "increment", "path": "score", "amount": 2},
		{"type": "append", "path": "log", "value": "done"},
	])
	_expect_equal(effects["value"], {"score": 3, "log": ["done"]}, "effect language applies atomically")

	var catalog = GameCatalog.new()
	var registered = catalog.register("example.high_card_arena", "res://games/high_card_arena/high_card_arena_module.gd", "High Card Arena")
	_expect(registered["ok"], "game catalog registers module")
	_expect(catalog.create_module("example.high_card_arena")["ok"], "game catalog instantiates module")

	var isolation_engine = UniversalCardEngine.new(ActionMutationModule.new(), {})
	_expect(isolation_engine.is_ready(), "action mutation fixture satisfies engine contract")
	_expect(isolation_engine.start(1).success, "action mutation fixture starts")
	var isolated_action = GameAction.new("increment", 0, {"amount": 1}, "mutation-isolation")
	var isolated_result = isolation_engine.perform_action(isolated_action)
	_expect(isolated_result.success, "validator action mutation cannot contaminate reduction")
	_expect_equal(isolation_engine.export_module_state()["count"], 1, "isolated action applies canonical payload")
	_expect_equal(isolation_engine.export_runtime_snapshot()["actions"][0]["type"], "increment", "action log retains canonical type")
	_expect_equal(isolation_engine.export_runtime_snapshot()["actions"][0]["payload"], {"amount": 1}, "action log retains canonical payload")


func _test_complete_game() -> void:
	var config = {"player_names": ["Ana", "Bruno"], "hand_size": 5, "target_score": 3, "starting_player": 0}
	var module = HighCardArena.new()
	var engine = UniversalCardEngine.new(module, config)
	_expect(engine.is_ready(), "complete module satisfies engine contract")
	var start_result = engine.start(123456)
	_expect(start_result.success, "complete game starts")
	_expect_equal(engine.lifecycle_name(), "RUNNING", "complete game starts running")
	_expect_equal(engine.get_public_state()["game"]["card_table"]["zones"]["hand:0"]["cards"], [], "public state hides private hand")
	_expect_equal(engine.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"].size(), 5, "owner sees private hand")
	_expect(engine.get_legal_actions(0).size() == 6, "active player receives card actions plus concede")
	_expect(engine.get_legal_actions(1).is_empty(), "inactive player receives no legal actions")
	_expect(engine.get_player_state(99)["game"].has("view_error"), "unknown player view is rejected")
	_expect(engine.get_legal_actions(99).is_empty(), "unknown player receives no legal actions")
	var bot_choice = BotAdapter.choose(module, engine.export_module_state(), 0, FirstLegalPolicy.new())
	_expect(bot_choice["ok"], "bot adapter converts legal choice into GameAction")
	_expect_equal(bot_choice["value"].request_id, "", "bot adapter does not reuse a fixed request id")
	var bot_choice_with_request = BotAdapter.choose(
		module,
		engine.export_module_state(),
		0,
		FirstLegalPolicy.new(),
		"bot-diagnostic-001"
	)
	_expect_equal(bot_choice_with_request["value"].request_id, "bot-diagnostic-001", "bot adapter accepts caller-owned request id")

	var duplicate_probe: Dictionary = engine.get_legal_actions(0)[0]
	var first_action = GameAction.new(duplicate_probe["type"], 0, duplicate_probe["payload"], "request-first")
	var first_result = engine.perform_action(first_action)
	_expect(first_result.success, "first legal play commits")
	var duplicate_result = engine.perform_action(GameAction.new(duplicate_probe["type"], 1, duplicate_probe["payload"], "request-first"))
	_expect(not duplicate_result.success and duplicate_result.code == "REQUEST_ID_DUPLICATE", "request deduplication rejects replayed id")

	var safety = 100
	while engine.lifecycle_name() == "RUNNING" and safety > 0:
		var public_state: Dictionary = engine.get_public_state()
		var actor_id: int = public_state["game"]["active_player"]
		var legal: Array = engine.get_legal_actions(actor_id)
		_expect(not legal.is_empty(), "running actor always has legal action")
		var selected: Dictionary = legal[0]
		var action = GameAction.new(selected["type"], actor_id, selected["payload"], "auto-%d" % safety)
		var applied = engine.perform_action(action)
		_expect(applied.success, "automated legal action commits")
		safety -= 1
	_expect(safety > 0, "game terminates without infinite loop")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "complete game reaches FINISHED")
	var final_state: Dictionary = engine.get_public_state()
	_expect(not final_state["game"]["winner_ids"].is_empty(), "complete game reports winner or tied leaders")
	_expect(final_state["game"]["finished_reason"] in ["TARGET_REACHED", "HANDS_EXHAUSTED"], "complete game reports finish reason")
	_expect(engine.get_events(0, -1).size() > 5, "complete game emits event stream")

	var digest = engine.state_digest()
	_expect(digest["ok"] and digest["value"].length() == 64, "engine state has SHA-256 digest")
	var save = SaveCodec.build(engine, engine.module_version())
	_expect(save["ok"], "save package builds")
	var encoded = SaveCodec.encode(save["value"], true)
	_expect(encoded["ok"], "save package encodes")
	_expect(not SaveCodec.build(engine, "wrong-version")["ok"], "save rejects module-version mismatch")
	var decoded = SaveCodec.decode(encoded["value"])
	_expect(decoded["ok"], "save package decodes and verifies checksum")
	_expect(decoded["value"]["payload"]["state_version"] is int, "save round trip preserves integer state_version")
	_expect(decoded["value"]["payload"]["seed"] is int, "save round trip preserves integer seed")
	var save_path := "user://zapiti_universal_engine_complete_test.json"
	var stored = SaveFileStore.write_atomic(save_path, encoded["value"])
	_expect(stored["ok"], "save file writes through temporary commit")
	var loaded = SaveFileStore.read(save_path)
	_expect(loaded["ok"] and SaveCodec.decode(loaded["value"])["ok"], "saved file reads and validates")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var tampered: Dictionary = decoded["value"].duplicate(true)
	tampered["payload"]["state_version"] += 1
	_expect(not SaveCodec.validate(tampered)["ok"], "tampered save fails checksum")

	var replay_snapshot: Dictionary = engine.export_runtime_snapshot()
	var replay = ReplayService.replay(HighCardArena.new(), config, replay_snapshot)
	_expect(replay["ok"], "accepted action log replays to identical complete runtime snapshot")
	var replay_tampered: Dictionary = replay_snapshot.duplicate(true)
	replay_tampered["event_sequence"] += 1
	_expect(not ReplayService.replay(HighCardArena.new(), config, replay_tampered)["ok"], "replay rejects event-sequence divergence")
	var wrong_config: Dictionary = config.duplicate(true)
	wrong_config["target_score"] = 2
	_expect(not ReplayService.replay(HighCardArena.new(), wrong_config, replay_snapshot)["ok"], "replay rejects config mismatch")
	var sync = SyncPacket.create(engine, 0, 0)
	_expect(sync["ok"], "player synchronization packet builds")
	_expect(not SyncPacket.create(engine, -2, 0)["ok"], "sync rejects viewer ids below public sentinel")
	_expect(sync["value"]["state_digest"].length() == 64, "sync packet includes digest")
	_expect(sync["value"]["events"].size() > 0, "sync packet includes visible events")

	var second_engine = UniversalCardEngine.new(HighCardArena.new(), config)
	var third_engine = UniversalCardEngine.new(HighCardArena.new(), config)
	second_engine.start(123456)
	third_engine.start(123456)
	_expect_equal(
		second_engine.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"],
		third_engine.get_player_state(0)["game"]["card_table"]["zones"]["hand:0"]["cards"],
		"same seed creates identical private deal"
	)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
