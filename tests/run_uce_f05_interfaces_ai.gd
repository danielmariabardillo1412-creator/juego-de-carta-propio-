extends SceneTree
## F05 hardening suite: viewer boundaries, legal actions, bots and demo integration.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const ModuleProtocol = preload("res://src/core/module_protocol.gd")
const LegalAction = preload("res://src/core/legal_action.gd")
const BotAdapter = preload("res://src/ai/bot_adapter.gd")
const FirstLegalPolicy = preload("res://src/ai/first_legal_policy.gd")
const IllegalBotPolicy = preload("res://tests/fixtures/illegal_bot_policy.gd")
const MalformedBotPolicy = preload("res://tests/fixtures/malformed_bot_policy.gd")
const MutatingBotPolicy = preload("res://tests/fixtures/mutating_bot_policy.gd")
const InvalidLegalActionModule = preload("res://tests/fixtures/invalid_legal_action_module.gd")
const HighCardArena = preload("res://games/high_card_arena/high_card_arena_module.gd")
const SyncPacket = preload("res://src/network/sync_packet.gd")
const StateDigest = preload("res://src/state/state_digest.gd")
const GameAction = preload("res://src/core/game_action.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-F05 PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F05 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var valid_action: Dictionary = LegalAction.create("play_card", 0, {"card": "c1"}, "Play", {"priority": 1})
	_expect(valid_action["ok"], "legal-action factory accepts pure canonical action")
	_expect(LegalAction.validate(valid_action["value"], 0)["ok"], "legal-action validator accepts canonical action")
	_expect(not LegalAction.validate(valid_action["value"], 1)["ok"], "legal-action validator rejects actor mismatch")
	var extra_key: Dictionary = valid_action["value"].duplicate(true)
	extra_key["unexpected"] = true
	_expect(not LegalAction.validate(extra_key)["ok"], "legal-action validator rejects unknown keys")
	_expect(not LegalAction.create("play_card", 0, {}, "Play", {"object": RefCounted.new()})["ok"], "legal-action factory rejects non-portable metadata")

	var duplicate_event_visibility: Dictionary = ModuleProtocol.validate_event_spec({
		"type": "private_notice",
		"payload": {},
		"visible_to": [0, 0],
	})
	_expect(not duplicate_event_visibility["ok"], "event protocol rejects duplicate visibility recipients")
	_expect(not ModuleProtocol.validate_event_spec({"type": "private_notice", "payload": {}, "visible_to": [-1]})["ok"], "event protocol rejects negative private viewer id")
	var duplicate_actions: Array = [valid_action["value"], valid_action["value"].duplicate(true)]
	_expect(not ModuleProtocol.validate_legal_actions(duplicate_actions, 0)["ok"], "legal-action protocol rejects duplicate advertised actions")

	var config: Dictionary = {
		"player_names": ["Ana", "Bruno"],
		"hand_size": 4,
		"target_score": 2,
		"starting_player": 1,
	}
	var module = HighCardArena.new()
	_expect_equal(module.module_version(), "2.0.0-hardened", "hardened game module declares new persistence version")
	_expect(not module.validate_config({"unknown": true})["ok"], "game config rejects unknown keys")
	var engine = UniversalCardEngine.new(module, config)
	_expect(engine.is_ready(), "hardened game module satisfies engine contract")
	_expect(engine.start(8128).success, "hardened game starts from nonzero starting player")
	_expect(engine.get_player_state(99)["game"].has("view_error"), "unknown player receives explicit view error")
	_expect(engine.get_legal_actions(99).is_empty(), "unknown player receives no legal actions")
	_expect(not SyncPacket.create(engine, 99, 0)["ok"], "sync rejects player id absent from game")
	_expect(SyncPacket.create(engine, -1, 0)["ok"], "public spectator synchronization remains available")
	var privacy_tamper: Dictionary = engine.export_module_state()
	privacy_tamper["cards"]["zones"]["hand:0"]["definition"]["visibility"] = "PUBLIC"
	_expect(not module.validate_state(privacy_tamper)["ok"], "game state rejects hand privacy downgrade")
	var turn_tamper: Dictionary = engine.export_module_state()
	turn_tamper["turn"]["active_index"] = (turn_tamper["turn"]["active_index"] + 1) % 2
	_expect(not module.validate_state(turn_tamper)["ok"], "game state rejects active player inconsistent with round history")

	var state_before: Dictionary = engine.export_module_state()
	var digest_before: Dictionary = StateDigest.sha256(state_before)
	var active_player: int = engine.get_public_state()["game"]["active_player"]
	var bot_choice: Dictionary = BotAdapter.choose(module, state_before, active_player, FirstLegalPolicy.new(), "f05-bot-1")
	_expect(bot_choice["ok"], "baseline bot chooses a canonical legal action")
	_expect_equal(bot_choice.get("legal_index", -1), 0, "baseline policy selects first canonical legal index")
	_expect_equal(bot_choice["value"].request_id, "f05-bot-1", "bot preserves caller-owned request id")
	var digest_after_choice: Dictionary = StateDigest.sha256(state_before)
	_expect_equal(digest_after_choice.get("value", ""), digest_before.get("value", ""), "bot selection does not mutate caller state")
	var mutating_choice: Dictionary = BotAdapter.choose(module, state_before, active_player, MutatingBotPolicy.new(), "f05-bot-2")
	_expect(mutating_choice["ok"], "policy-local argument mutation cannot contaminate canonical action set")
	_expect(not BotAdapter.choose(module, state_before, active_player, IllegalBotPolicy.new())["ok"], "bot rejects valid-looking action outside advertised set")
	_expect(not BotAdapter.choose(module, state_before, active_player, MalformedBotPolicy.new())["ok"], "bot rejects malformed policy output")
	_expect(not BotAdapter.choose(module, state_before, active_player, FirstLegalPolicy.new(), "bad request")["ok"], "bot rejects invalid request id")

	var hostile_module = InvalidLegalActionModule.new()
	var hostile_state: Dictionary = hostile_module.create_initial_state({"player_count": 2, "max_passes": 2}, 1)
	var hostile_choice: Dictionary = BotAdapter.choose(hostile_module, hostile_state, 0, FirstLegalPolicy.new())
	_expect(not hostile_choice["ok"], "bot rejects malformed legal-action enumeration from module")
	_expect_equal(hostile_choice["code"], "BOT_LEGAL_ACTIONS_INVALID", "malformed module action failure is attributed to module boundary")

	var safety: int = 64
	while engine.lifecycle_name() == "RUNNING" and safety > 0:
		var public_state: Dictionary = engine.get_public_state()
		var actor_id: int = public_state["game"]["active_player"]
		var legal: Array = engine.get_legal_actions(actor_id)
		_expect(not legal.is_empty(), "running hardened demo always exposes a legal action")
		if legal.is_empty():
			break
		var selected: Dictionary = legal[0]
		var applied = engine.perform_action(GameAction.new(selected["type"], actor_id, selected["payload"], "f05-auto-%d" % safety))
		_expect(applied.success, "hardened demo legal action commits")
		if not applied.success:
			break
		var runtime_state: Dictionary = engine.export_module_state()
		_expect_equal(runtime_state["turn"]["round_number"], runtime_state["round"]["number"], "generic and game-specific round counters remain synchronized")
		safety -= 1
	_expect(safety > 0, "hardened demo terminates before safety limit")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "hardened demo reaches terminal lifecycle")
	_expect(engine.validate_internal_consistency()["ok"], "terminal hardened demo passes kernel consistency validation")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
