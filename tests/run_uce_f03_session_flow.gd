extends SceneTree
## F03 hardening suite: players, turn cycles, phase graphs and scoring.

const PlayerRegistry = preload("res://src/session/player_registry.gd")
const TurnState = preload("res://src/turns/turn_state.gd")
const PhaseMachine = preload("res://src/turns/phase_machine.gd")
const ScoreState = preload("res://src/scoring/score_state.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-F03 PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F03 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var registry: Dictionary = PlayerRegistry.create([
		PlayerRegistry.make_player(7, "Seven", 2, 10, {"avatar": "a"}),
		PlayerRegistry.make_player(3, "Three", 0, 10, {}, false),
		PlayerRegistry.make_player(5, "Five", 1, 11),
	], [
		PlayerRegistry.make_team(10, "North"),
		PlayerRegistry.make_team(11, "South"),
	])
	_expect(registry["ok"], "player registry accepts pure bounded data")
	_expect_equal(PlayerRegistry.seat_order(registry["value"]), [3, 5, 7], "seat order is independent of storage order")
	_expect_equal(PlayerRegistry.seat_order(registry["value"], true), [5, 7], "active seat order excludes inactive players")
	_expect_equal(PlayerRegistry.team_members(registry["value"], 10), [3, 7], "team membership resolves deterministically")
	_expect_equal(PlayerRegistry.team_members(registry["value"], 10, true), [7], "active team membership is filtered")
	var bad_name: Dictionary = PlayerRegistry.create([PlayerRegistry.make_player(0, " padded ", 0)])
	_expect(not bad_name["ok"], "untrimmed player names are rejected")
	var bad_metadata: Dictionary = PlayerRegistry.create([
		PlayerRegistry.make_player(0, "P", 0, -1, {"object": RefCounted.new()}),
	])
	_expect(not bad_metadata["ok"], "registry metadata rejects runtime objects")
	var toggled: Dictionary = PlayerRegistry.set_active(registry["value"], 3, true)
	_expect(toggled["ok"], "player activity changes through validated copy")
	_expect_equal(PlayerRegistry.player_ids(toggled["value"], true).size(), 3, "activity update affects active query")
	_expect(not registry["value"]["players"][1]["active"], "activity update leaves source registry unchanged")

	var turn: Dictionary = TurnState.create([0, 1, 2, 3], 2)
	_expect(turn["ok"], "turn cursor starts at arbitrary seat")
	_expect_equal(TurnState.active_player(turn["value"]), 2, "requested starting player is active")
	_expect_equal(TurnState.round_anchor_player(turn["value"]), 2, "round anchor freezes starting player")
	var t1: Dictionary = TurnState.advance(turn["value"])
	var t2: Dictionary = TurnState.advance(t1["value"])
	var t3: Dictionary = TurnState.advance(t2["value"])
	_expect_equal(t1["value"]["round_number"], 1, "partial traversal does not increment round")
	_expect_equal(t2["value"]["round_number"], 1, "array-boundary wrap is not mistaken for full round")
	_expect_equal(t3["value"]["round_number"], 1, "round remains one until anchor is reached")
	var t4: Dictionary = TurnState.advance(t3["value"])
	_expect_equal(TurnState.active_player(t4["value"]), 2, "full cycle returns to anchor")
	_expect_equal(t4["value"]["round_number"], 2, "full cycle increments round exactly once")
	_expect_equal(turn["value"]["turn_number"], 1, "turn advancement is immutable")

	var reverse_turn: Dictionary = TurnState.create([0, 1, 2, 3], 2, TurnState.DIRECTION_REVERSE)
	var reverse_after: Dictionary = TurnState.advance(reverse_turn["value"], 4)
	_expect_equal(TurnState.active_player(reverse_after["value"]), 2, "reverse full cycle returns to anchor")
	_expect_equal(reverse_after["value"]["round_number"], 2, "reverse direction counts full round correctly")
	var removed_active: Dictionary = TurnState.remove_player(turn["value"], 2)
	_expect(removed_active["ok"], "active player can be removed without invalid cursor")
	_expect_equal(TurnState.active_player(removed_active["value"]), 3, "forward removal selects next player")
	_expect_equal(TurnState.round_anchor_player(removed_active["value"]), 3, "removed anchor is replaced by active player")
	var remove_last: Dictionary = TurnState.remove_player(TurnState.create([9])["value"], 9)
	_expect(not remove_last["ok"], "turn order cannot remove final participant")

	var valid_phase: Dictionary = PhaseMachine.create({
		"initial": "setup",
		"terminal": ["done"],
		"transitions": {
			"setup": ["play"],
			"play": ["play", "done"],
			"done": [],
		},
	})
	_expect(valid_phase["ok"], "reachable phase graph builds")
	var play_phase: Dictionary = PhaseMachine.transition(valid_phase["value"], "play")
	_expect(play_phase["ok"], "legal phase transition commits")
	var repeat_phase: Dictionary = PhaseMachine.transition(play_phase["value"], "play")
	_expect(repeat_phase["ok"], "explicit self-transition remains supported")
	_expect_equal(repeat_phase["value"]["entry_count"]["play"], 2, "phase entry count tracks repeated entry")
	var done_phase: Dictionary = PhaseMachine.transition(repeat_phase["value"], "done")
	_expect(PhaseMachine.is_terminal(done_phase["value"]), "terminal phase is recognized")
	var unreachable: Dictionary = PhaseMachine.create({
		"initial": "a",
		"terminal": ["b"],
		"transitions": {"a": ["b"], "b": [], "orphan": []},
	})
	_expect(not unreachable["ok"], "unreachable declared phase is rejected")
	_expect_equal(unreachable["code"], "PHASE_UNREACHABLE", "unreachable phase has explicit code")
	var terminal_loop: Dictionary = PhaseMachine.create({
		"initial": "a",
		"terminal": ["b"],
		"transitions": {"a": ["b"], "b": ["a"]},
	})
	_expect(not terminal_loop["ok"], "terminal phase cannot keep outgoing transitions")

	var high_scores: Dictionary = ScoreState.create([0, 1], 0, 3)
	_expect(high_scores["ok"], "default high-score table builds")
	var high_added: Dictionary = ScoreState.add(high_scores["value"], 1, 3)
	_expect(ScoreState.target_reached(high_added["value"]), "AT_LEAST target detects")
	_expect_equal(ScoreState.leader_ids(high_added["value"]), [1], "HIGH leader semantics select maximum")
	var low_scores: Dictionary = ScoreState.create(
		[0, 1],
		10,
		0,
		ScoreState.TARGET_AT_MOST,
		ScoreState.LEADER_LOW
	)
	var low_set: Dictionary = ScoreState.set_score(low_scores["value"], 0, 0)
	_expect(ScoreState.target_reached(low_set["value"]), "AT_MOST target detects low-score victory")
	_expect_equal(ScoreState.leader_ids(low_set["value"]), [0], "LOW leader semantics select minimum")
	var exact_scores: Dictionary = ScoreState.create([0], 0, 2, ScoreState.TARGET_EXACT)
	var exact_overshoot: Dictionary = ScoreState.set_score(exact_scores["value"], 0, 3)
	_expect(not ScoreState.target_reached(exact_overshoot["value"]), "EXACT target rejects overshoot")
	var exact_hit: Dictionary = ScoreState.set_score(exact_scores["value"], 0, 2)
	_expect(ScoreState.participant_target_reached(exact_hit["value"], 0), "participant target query detects exact hit")
	var bad_score: Dictionary = ScoreState.set_score(exact_scores["value"], 0, "two")
	_expect(not bad_score["ok"], "non-numeric score is rejected")
	var damaged_scores: Dictionary = high_scores["value"].duplicate(true)
	damaged_scores["scores"] = {"01": 2}
	_expect(not ScoreState.validate(damaged_scores)["ok"], "noncanonical participant score key is rejected")


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
