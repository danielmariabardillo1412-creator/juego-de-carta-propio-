extends SceneTree
## Headless suite for UCE-03 deterministic RNG, shuffle and deal.
## Run:
##   godot --headless --path . --script res://tests/run_uce_03_random_deal.gd

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const CardState = preload("res://src/cards/card_state.gd")
const CardRandomizer = preload("res://src/cards/card_randomizer.gd")
const DealService = preload("res://src/cards/deal_service.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")
const ShuffleDealModule = preload("res://tests/fixtures/shuffle_deal_module.gd")

var _failures: Array = []
var _checks := 0


func _init() -> void:
	_run_rng_suite()
	_run_shuffle_suite()
	_run_deal_suite()
	_run_integration_suite()
	if _failures.is_empty():
		print("UCE-03 PASS: %d checks" % _checks)
		quit(0)
		return

	printerr("UCE-03 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_rng_suite() -> void:
	var created = DeterministicRng.create(1)
	_expect(created["ok"], "non-negative seed creates RNG state")
	_expect_equal(created["value"]["algorithm"], "lcg31-v1", "RNG records algorithm id")
	_expect_equal(created["value"]["state"], 1, "RNG preserves seed within modulus")
	_expect_equal(created["value"]["draws"], 0, "new RNG has zero draws")

	var negative = DeterministicRng.create(-1)
	_expect(not negative["ok"], "negative seed is rejected")
	_expect_equal(negative["code"], "RNG_SEED_INVALID", "negative seed has precise code")

	var first = DeterministicRng.next_raw(created["value"])
	var second = DeterministicRng.next_raw(first["state"])
	var third = DeterministicRng.next_raw(second["state"])
	_expect_equal(first["value"], 1103527590, "first known-vector value matches")
	_expect_equal(second["value"], 377401575, "second known-vector value matches")
	_expect_equal(third["value"], 662824084, "third known-vector value matches")
	_expect_equal(third["state"]["draws"], 3, "known vector advances draw count")
	_expect_equal(created["value"]["draws"], 0, "RNG operations do not mutate input snapshot")

	var bounded = DeterministicRng.next_int(created["value"], 6)
	_expect(bounded["ok"], "bounded random value is produced")
	_expect(bounded["value"] >= 0 and bounded["value"] < 6, "bounded value stays inside range")
	var invalid_bound = DeterministicRng.next_int(created["value"], 0)
	_expect(not invalid_bound["ok"], "zero bound is rejected")
	_expect_equal(invalid_bound["code"], "RNG_BOUND_INVALID", "invalid bound has precise code")

	var repeated = DeterministicRng.next_raw(created["value"])
	_expect_equal(repeated["value"], first["value"], "same snapshot reproduces same next value")
	_expect_equal(repeated["state"], first["state"], "same snapshot reproduces same next state")


func _run_shuffle_suite() -> void:
	var rng = DeterministicRng.create(1)["value"]
	var values := ["a", "b", "c", "d", "e", "f"]
	var shuffled = DeterministicRng.shuffle_values(rng, values)
	_expect(shuffled["ok"], "generic array shuffle succeeds")
	_expect_equal(shuffled["value"], ["c", "d", "b", "e", "f", "a"], "shuffle matches known vector")
	_expect_equal(shuffled["draws_used"], 5, "six-value shuffle consumes five accepted draws")
	_expect_equal(values, ["a", "b", "c", "d", "e", "f"], "shuffle does not mutate supplied array")
	_expect_equal(shuffled["state"]["draws"], 5, "shuffle returns advanced RNG state")

	var repeated = DeterministicRng.shuffle_values(rng, values)
	_expect_equal(repeated["value"], shuffled["value"], "same seed produces same shuffle")
	var different_rng = DeterministicRng.create(44)["value"]
	var different = DeterministicRng.shuffle_values(different_rng, values)
	_expect(different["value"] != shuffled["value"], "different seed changes fixture shuffle")

	var card_state = _build_six_card_state()
	var card_shuffle = CardRandomizer.shuffle_zone(card_state, "deck", different_rng)
	_expect(card_shuffle["ok"], "card zone shuffle succeeds")
	_expect_equal(
		card_shuffle["order_after"],
		["card-005", "card-003", "card-006", "card-004", "card-001", "card-002"],
		"card zone shuffle matches known seed-44 order"
	)
	_expect_equal(card_state["zones"]["deck"]["cards"], _ordered_card_ids(), "card shuffle preserves original state")
	_expect_equal(card_shuffle["value"]["zones"]["deck"]["cards"], card_shuffle["order_after"], "shuffled order is committed to returned state")
	_expect_equal(card_shuffle["rng_state"]["draws"], 5, "card shuffle returns replayable RNG snapshot")

	var missing_zone = CardRandomizer.shuffle_zone(card_state, "missing", different_rng)
	_expect(not missing_zone["ok"], "unknown shuffle zone is rejected")
	_expect_equal(missing_zone["code"], "SHUFFLE_ZONE_UNKNOWN", "unknown shuffle zone has precise code")


func _run_deal_suite() -> void:
	var card_state = _build_six_card_state()
	var rng = DeterministicRng.create(44)["value"]
	var shuffled = CardRandomizer.shuffle_zone(card_state, "deck", rng)
	var dealt = DealService.deal_round_robin(
		shuffled["value"],
		"deck",
		["hand:0", "hand:1"],
		2,
		DealService.TAKE_FROM_END
	)
	_expect(dealt["ok"], "round-robin deal succeeds")
	_expect_equal(dealt["value"]["zones"]["hand:0"]["cards"], ["card-002", "card-004"], "first destination receives alternating cards")
	_expect_equal(dealt["value"]["zones"]["hand:1"]["cards"], ["card-001", "card-006"], "second destination receives alternating cards")
	_expect_equal(dealt["value"]["zones"]["deck"]["cards"], ["card-005", "card-003"], "undealt cards preserve remaining order")
	_expect_equal(dealt["movements"].size(), 4, "deal reports every movement")
	_expect_equal(dealt["dealt_by_zone"]["hand:0"], ["card-002", "card-004"], "deal reports cards by destination")
	_expect_equal(shuffled["value"]["zones"]["hand:0"]["cards"].size(), 0, "deal does not mutate supplied shuffled state")

	var start_deal = DealService.deal_round_robin(
		card_state,
		"deck",
		["hand:0", "hand:1"],
		1,
		DealService.TAKE_FROM_START
	)
	_expect(start_deal["ok"], "deal can take from start of source")
	_expect_equal(start_deal["value"]["zones"]["hand:0"]["cards"], ["card-001"], "start mode takes first card for first destination")
	_expect_equal(start_deal["value"]["zones"]["hand:1"]["cards"], ["card-002"], "start mode takes next first card")

	var insufficient = DealService.deal_round_robin(card_state, "deck", ["hand:0", "hand:1"], 4)
	_expect(not insufficient["ok"], "insufficient source rejects complete deal")
	_expect_equal(insufficient["code"], "DEAL_SOURCE_INSUFFICIENT", "insufficient source has precise code")
	_expect_equal(card_state["zones"]["deck"]["cards"], _ordered_card_ids(), "failed insufficient deal leaves source unchanged")

	var duplicate = DealService.deal_round_robin(card_state, "deck", ["hand:0", "hand:0"], 1)
	_expect(not duplicate["ok"], "duplicate destination is rejected")
	_expect_equal(duplicate["code"], "DEAL_DESTINATION_DUPLICATE", "duplicate destination has precise code")

	var capacity_state = _build_capacity_state()
	var capacity = DealService.deal_round_robin(capacity_state, "deck", ["hand:0", "hand:1"], 2)
	_expect(not capacity["ok"], "capacity shortage rejects complete deal before movement")
	_expect_equal(capacity["code"], "DEAL_CAPACITY_EXCEEDED", "capacity shortage has precise code")
	_expect_equal(capacity_state["zones"]["deck"]["cards"], _ordered_card_ids(), "capacity failure leaves source untouched")

	var source_as_destination = DealService.deal_round_robin(card_state, "deck", ["deck"], 1)
	_expect(not source_as_destination["ok"], "source cannot also be destination")
	_expect_equal(source_as_destination["code"], "DEAL_SOURCE_IS_DESTINATION", "source/destination conflict has precise code")


func _run_integration_suite() -> void:
	var first_engine := UniversalCardEngine.new(ShuffleDealModule.new(), {})
	var second_engine := UniversalCardEngine.new(ShuffleDealModule.new(), {})
	_expect(first_engine.is_ready(), "shuffle/deal fixture satisfies universal module contract")
	var first_start = first_engine.start(44)
	var second_start = second_engine.start(44)
	_expect(first_start.success, "first deterministic fixture starts")
	_expect(second_start.success, "second deterministic fixture starts")
	_expect_equal(first_engine.lifecycle_name(), "FINISHED", "fixture may finish during start")
	_expect_equal(first_engine.export_runtime_snapshot()["module_state"], second_engine.export_runtime_snapshot()["module_state"], "same seed produces identical integrated state")

	var snapshot: Dictionary = first_engine.export_runtime_snapshot()
	_expect_equal(snapshot["module_state"]["dealt_by_zone"]["hand:0"], ["card-002", "card-004"], "integrated fixture preserves expected first hand")
	_expect_equal(snapshot["module_state"]["rng"]["draws"], 5, "integrated fixture stores advanced RNG state")
	_expect_equal(snapshot["events"].size(), 2, "start-finished fixture records lifecycle events")

	var public_view: Dictionary = first_engine.get_public_state()
	_expect_equal(public_view["game"]["card_table"]["zones"]["hand:0"]["count"], 2, "public sees hand count")
	_expect_equal(public_view["game"]["card_table"]["zones"]["hand:0"]["cards"].size(), 0, "public cannot see private hand identities")
	var player_zero_view: Dictionary = first_engine.get_player_state(0)
	_expect_equal(player_zero_view["game"]["card_table"]["zones"]["hand:0"]["cards"].size(), 2, "owner sees own dealt cards")
	_expect_equal(player_zero_view["game"]["card_table"]["zones"]["hand:1"]["cards"].size(), 0, "owner cannot see rival hand")

	var different_engine := UniversalCardEngine.new(ShuffleDealModule.new(), {})
	var different_start = different_engine.start(1)
	_expect(different_start.success, "different-seed fixture starts")
	_expect(different_engine.export_runtime_snapshot()["module_state"]["shuffle_order"] != snapshot["module_state"]["shuffle_order"], "different integrated seed changes shuffle order")


func _build_six_card_state(hand_capacity: int = 3) -> Dictionary:
	var definitions: Array = []
	var instances: Array = []
	for number in range(1, 7):
		var definition = CardDefinition.create("rank-%d" % number, {"rank": number})["value"]
		var instance = CardInstance.create("card-%03d" % number, "rank-%d" % number)["value"]
		definitions.append(definition)
		instances.append(instance)
	var deck = ZoneDefinition.create("deck", ZoneDefinition.VISIBILITY_HIDDEN)["value"]
	var hand_zero = ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], hand_capacity)["value"]
	var hand_one = ZoneDefinition.create("hand:1", ZoneDefinition.VISIBILITY_OWNER, 1, [], hand_capacity)["value"]
	return CardState.create(
		definitions,
		instances,
		[deck, hand_zero, hand_one],
		{"deck": _ordered_card_ids(), "hand:0": [], "hand:1": []}
	)["value"]


func _build_capacity_state() -> Dictionary:
	return _build_six_card_state(1)


func _ordered_card_ids() -> Array:
	return ["card-001", "card-002", "card-003", "card-004", "card-005", "card-006"]


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
