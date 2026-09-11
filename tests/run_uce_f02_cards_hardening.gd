extends SceneTree
## F02 hardening suite: card inventory, zone privacy and atomic movement.

const DeckBuilder = preload("res://src/cards/deck_builder.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const CardState = preload("res://src/cards/card_state.gd")
const CardOperations = preload("res://src/cards/card_operations.gd")
const CardRandomizer = preload("res://src/cards/card_randomizer.gd")
const DealService = preload("res://src/cards/deal_service.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")

var _failures: Array = []
var _checks: int = 0


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("UCE-F02 PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("UCE-F02 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var deck: Dictionary = DeckBuilder.build([
		{"id": "alpha", "count": 2, "attributes": {"value": 1}, "tags": ["low"]},
		{"id": "beta", "count": 2, "attributes": {"value": 2}, "tags": ["high"]},
	], "unit")
	_expect(deck["ok"], "strict deck builder accepts valid specifications")
	_expect_equal(deck["instances"].size(), 4, "deck builder creates requested instances")
	_expect_equal(deck["instances"][0]["metadata"]["copy_index"], 0, "instance copy index is deterministic")
	_expect_equal(deck["instances"][0]["metadata"]["serial"], 1, "instance serial is explicit")
	_expect_equal(deck["next_serial"], 5, "deck builder returns next serial")
	var unknown_spec: Dictionary = DeckBuilder.build([{"id": "x", "count": 1, "mystery": true}])
	_expect(not unknown_spec["ok"], "unknown deck-spec keys are rejected")
	_expect_equal(unknown_spec["code"], "DECK_SPEC_KEYS_INVALID", "unknown spec has explicit code")
	var bad_prefix: Dictionary = DeckBuilder.build([{"id": "x"}], "bad prefix")
	_expect(not bad_prefix["ok"], "invalid generated-id prefix is rejected")
	var reserved_metadata: Dictionary = DeckBuilder.build([
		{"id": "x", "instance_metadata": {"serial": 99}},
	])
	_expect(not reserved_metadata["ok"], "reserved instance metadata cannot be forged")

	var hidden_count: Dictionary = ZoneDefinition.create(
		"secret",
		ZoneDefinition.VISIBILITY_HIDDEN,
		-1,
		[],
		-1,
		{},
		ZoneDefinition.COUNT_IDENTITIES
	)
	_expect(hidden_count["ok"], "zone may hide both identities and exact count")
	var invalid_edge_reveal: Dictionary = ZoneDefinition.create(
		"invalid_edge",
		ZoneDefinition.VISIBILITY_HIDDEN,
		-1,
		[],
		-1,
		{},
		ZoneDefinition.COUNT_IDENTITIES,
		0,
		1
	)
	_expect(not invalid_edge_reveal["ok"], "edge reveal cannot coexist with hidden count")
	var edge_zone: Dictionary = ZoneDefinition.create(
		"edge",
		ZoneDefinition.VISIBILITY_HIDDEN,
		-1,
		[],
		-1,
		{},
		ZoneDefinition.COUNT_PUBLIC,
		0,
		1
	)
	_expect(edge_zone["ok"], "hidden pile may reveal only its public end card")
	var owner_zone: Dictionary = ZoneDefinition.create(
		"hand:0",
		ZoneDefinition.VISIBILITY_OWNER,
		0,
		[],
		4
	)
	var table_zone: Dictionary = ZoneDefinition.create("table", ZoneDefinition.VISIBILITY_PUBLIC, -1, [], 1)
	var state_result: Dictionary = CardState.create(
		deck["definitions"],
		deck["instances"],
		[hidden_count["value"], edge_zone["value"], owner_zone["value"], table_zone["value"]],
		{
			"secret": ["unit-00001", "unit-00002"],
			"edge": ["unit-00003", "unit-00004"],
			"hand:0": [],
			"table": [],
		}
	)
	_expect(state_result["ok"], "card state validates complete inventory")
	var state: Dictionary = state_result["value"]
	var public_view: Dictionary = CardState.view_for(state, -1)
	_expect(public_view["ok"], "public card view builds")
	_expect_equal(public_view["value"]["zones"]["secret"]["count"], -1, "hidden count is redacted")
	_expect_equal(public_view["value"]["zones"]["secret"]["slots"], [], "hidden count exposes no positional slots")
	_expect_equal(public_view["value"]["zones"]["edge"]["count"], 2, "public pile count remains visible")
	_expect_equal(public_view["value"]["zones"]["edge"]["slots"].size(), 2, "visible count produces positional slots")
	_expect(not public_view["value"]["zones"]["edge"]["slots"][0]["visible"], "concealed edge slot has no identity")
	_expect(public_view["value"]["zones"]["edge"]["slots"][1]["visible"], "configured public end card is visible")
	_expect_equal(public_view["value"]["zones"]["edge"]["cards"].size(), 1, "compatibility card list contains visible identities only")
	_expect_equal(
		public_view["value"]["zones"]["edge"]["cards"][0]["instance"]["id"],
		"unit-00004",
		"public reveal exposes correct physical card"
	)

	var before_inventory: Dictionary = CardState.inventory_digest(state)
	var batch_move: Dictionary = CardOperations.move_many(
		state,
		["unit-00004", "unit-00003"],
		"edge",
		"hand:0"
	)
	_expect(batch_move["ok"], "bulk move commits as one validated operation")
	_expect_equal(state["zones"]["edge"]["cards"], ["unit-00003", "unit-00004"], "bulk move does not mutate source state")
	_expect_equal(batch_move["value"]["zones"]["hand:0"]["cards"], ["unit-00004", "unit-00003"], "input order is preserved by default")
	_expect_equal(batch_move["movements"][0]["source_index"], 1, "movement records original source index")
	_expect_equal(batch_move["movements"][1]["destination_index"], 1, "movement records committed destination index")
	var after_inventory: Dictionary = CardState.inventory_digest(batch_move["value"])
	_expect_equal(before_inventory["value"], after_inventory["value"], "movement conserves card inventory exactly")
	var owner_view: Dictionary = CardState.view_for(batch_move["value"], 0)
	_expect_equal(owner_view["value"]["zones"]["hand:0"]["cards"].size(), 2, "owner receives full private identities")
	var rival_view: Dictionary = CardState.view_for(batch_move["value"], 1)
	_expect_equal(rival_view["value"]["zones"]["hand:0"]["cards"], [], "non-owner receives no private identity")
	_expect_equal(rival_view["value"]["zones"]["hand:0"]["slots"].size(), 2, "non-owner sees only opaque hand positions")

	var capacity_before: Dictionary = batch_move["value"].duplicate(true)
	var capacity_fail: Dictionary = CardOperations.move_many(
		capacity_before,
		["unit-00004", "unit-00003"],
		"hand:0",
		"table"
	)
	_expect(not capacity_fail["ok"], "bulk move prevalidates complete destination capacity")
	_expect_equal(capacity_fail["code"], "DESTINATION_CAPACITY_EXCEEDED", "capacity failure has explicit code")
	_expect_equal(capacity_before, batch_move["value"], "failed capacity move changes no supplied field")
	var duplicate_fail: Dictionary = CardState.move_cards(
		batch_move["value"],
		["unit-00004", "unit-00004"],
		"hand:0",
		"edge"
	)
	_expect(not duplicate_fail["ok"], "duplicate ids in one movement are rejected")

	var same_zone: Dictionary = CardState.move_cards(
		batch_move["value"],
		["unit-00004"],
		"hand:0",
		"hand:0",
		1
	)
	_expect(same_zone["ok"], "same-zone movement supports explicit post-removal index")
	_expect_equal(same_zone["value"]["zones"]["hand:0"]["cards"], ["unit-00003", "unit-00004"], "same-zone movement reorders deterministically")
	var invalid_permutation: Dictionary = CardState.reorder_zone(
		same_zone["value"],
		"hand:0",
		["unit-00003", "unit-00003"]
	)
	_expect(not invalid_permutation["ok"], "zone reorder requires exact permutation")
	var metadata_update: Dictionary = CardState.update_instance_metadata(
		same_zone["value"],
		"unit-00003",
		{"copy_index": 0, "serial": 3, "face_up": true}
	)
	_expect(metadata_update["ok"], "physical card metadata can change through validated operation")
	_expect(not same_zone["value"]["instances"]["unit-00003"]["metadata"].has("face_up"), "metadata update is immutable")
	var invalid_metadata: Dictionary = CardState.update_instance_metadata(
		same_zone["value"],
		"unit-00003",
		{"bad": RefCounted.new()}
	)
	_expect(not invalid_metadata["ok"], "instance metadata rejects non-portable objects")

	var deal_state: Dictionary = _make_deal_state(deck)
	var deal_before_digest: Dictionary = CardState.inventory_digest(deal_state)
	var unequal_deal: Dictionary = DealService.deal_counts(
		deal_state,
		"deck",
		["hand:0", "hand:1"],
		{"hand:0": 1, "hand:1": 2},
		DealService.TAKE_FROM_END
	)
	_expect(unequal_deal["ok"], "round-robin deal supports unequal destination counts")
	_expect_equal(unequal_deal["value"]["zones"]["hand:0"]["cards"], ["unit-00004"], "first destination receives requested card")
	_expect_equal(unequal_deal["value"]["zones"]["hand:1"]["cards"], ["unit-00003", "unit-00002"], "unequal destination continues in later round")
	_expect_equal(unequal_deal["value"]["zones"]["deck"]["cards"], ["unit-00001"], "undealt source order is preserved")
	_expect_equal(deal_state["zones"]["deck"]["cards"].size(), 4, "deal leaves original state intact")
	var deal_after_digest: Dictionary = CardState.inventory_digest(unequal_deal["value"])
	_expect_equal(deal_before_digest["value"], deal_after_digest["value"], "deal conserves exact inventory")

	var cut: Dictionary = CardRandomizer.cut_zone(deal_state, "deck", 2)
	_expect(cut["ok"], "zone cut is a validated deterministic reorder")
	_expect_equal(cut["value"]["zones"]["deck"]["cards"], ["unit-00003", "unit-00004", "unit-00001", "unit-00002"], "cut order is correct")
	var rng: Dictionary = DeterministicRng.create(123)["value"]
	var shuffle: Dictionary = CardRandomizer.shuffle_zone(deal_state, "deck", rng)
	_expect(shuffle["ok"], "shuffle survives hardened conservation checks")
	var shuffle_digest: Dictionary = CardState.inventory_digest(shuffle["value"])
	_expect_equal(deal_before_digest["value"], shuffle_digest["value"], "shuffle conserves exact inventory")


func _make_deal_state(deck: Dictionary) -> Dictionary:
	var deck_zone: Dictionary = ZoneDefinition.create("deck", ZoneDefinition.VISIBILITY_HIDDEN)["value"]
	var hand_zero: Dictionary = ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], 4)["value"]
	var hand_one: Dictionary = ZoneDefinition.create("hand:1", ZoneDefinition.VISIBILITY_OWNER, 1, [], 4)["value"]
	return CardState.create(
		deck["definitions"],
		deck["instances"],
		[deck_zone, hand_zero, hand_one],
		{
			"deck": ["unit-00001", "unit-00002", "unit-00003", "unit-00004"],
			"hand:0": [],
			"hand:1": [],
		}
	)["value"]


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
