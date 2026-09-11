extends SceneTree
## Headless suite for UCE-02 card definitions, instances, zones and moves.
## Run:
##   godot --headless --path . --script res://tests/run_uce_02_cards.gd

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const CardState = preload("res://src/cards/card_state.gd")
const DrawCardModule = preload("res://tests/fixtures/draw_card_module.gd")

var _failures: Array = []
var _checks := 0


func _init() -> void:
	_run_schema_suite()
	_run_state_suite()
	_run_integration_suite()
	if _failures.is_empty():
		print("UCE-02 PASS: %d checks" % _checks)
		quit(0)
		return

	printerr("UCE-02 FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_schema_suite() -> void:
	var definition := CardDefinition.create("ace_spades", {"suit": "spades", "rank": 1}, ["ace"])
	_expect(definition["ok"], "valid card definition is accepted")
	_expect_equal(definition["value"]["attributes"]["rank"], 1, "definition preserves generic attributes")

	var blank_definition := CardDefinition.create(" ", {}, [])
	_expect(not blank_definition["ok"], "blank definition id is rejected")
	_expect_equal(blank_definition["code"], "CARD_DEFINITION_ID_INVALID", "blank definition has precise code")

	var duplicate_tag := CardDefinition.create("tagged", {}, ["same", "same"])
	_expect(not duplicate_tag["ok"], "duplicate tags are rejected")
	_expect_equal(duplicate_tag["code"], "CARD_TAG_DUPLICATE", "duplicate tag has precise code")

	var spaced_id := CardDefinition.create("bad id", {}, [])
	_expect(not spaced_id["ok"], "identifier whitespace is rejected")
	_expect_equal(spaced_id["code"], "CARD_DEFINITION_ID_INVALID", "identifier whitespace has precise code")

	var instance := CardInstance.create("physical-01", "ace_spades", {"foil": false})
	_expect(instance["ok"], "valid card instance is accepted")
	_expect_equal(instance["value"]["definition_id"], "ace_spades", "instance references definition")

	var owner_zone := ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], 3)
	_expect(owner_zone["ok"], "owner-visible zone is accepted")
	_expect(ZoneDefinition.can_view_identities(owner_zone["value"], 0), "owner can view owner zone")
	_expect(not ZoneDefinition.can_view_identities(owner_zone["value"], 1), "other player cannot view owner zone")

	var invalid_owner_zone := ZoneDefinition.create("bad_hand", ZoneDefinition.VISIBILITY_OWNER)
	_expect(not invalid_owner_zone["ok"], "owner visibility without owner is rejected")
	_expect_equal(invalid_owner_zone["code"], "ZONE_OWNER_REQUIRED", "owner requirement has precise code")

	var listed_zone := ZoneDefinition.create("team_hand", ZoneDefinition.VISIBILITY_LISTED, -1, [0, 2])
	_expect(listed_zone["ok"], "listed visibility zone is accepted")
	_expect(ZoneDefinition.can_view_identities(listed_zone["value"], 2), "listed viewer can see identities")
	_expect(not ZoneDefinition.can_view_identities(listed_zone["value"], 1), "unlisted viewer cannot see identities")


func _run_state_suite() -> void:
	var built := _build_sample_state()
	_expect(built["ok"], "valid card state is constructed")
	var state: Dictionary = built["value"]
	_expect_equal(state["instances"].size(), 3, "state contains all physical instances")
	_expect_equal(state["zones"]["draw"]["cards"].size(), 2, "draw zone receives ordered cards")

	var public_view := CardState.view_for(state, -1)
	_expect(public_view["ok"], "public view can be generated")
	_expect_equal(public_view["value"]["zones"]["table"]["cards"].size(), 1, "public zone reveals card identity")
	_expect_equal(public_view["value"]["zones"]["draw"]["cards"].size(), 0, "hidden zone redacts identities")
	_expect_equal(public_view["value"]["zones"]["draw"]["count"], 2, "hidden zone still reveals count")

	var owner_view := CardState.view_for(state, 0)
	_expect(owner_view["value"]["zones"]["hand:0"]["identities_visible"], "owner hand identities are visible to owner")
	var rival_view := CardState.view_for(state, 1)
	_expect(not rival_view["value"]["zones"]["hand:0"]["identities_visible"], "owner hand identities are hidden from rival")

	var move_result := CardState.move_card(state, "card-002", "draw", "hand:0")
	_expect(move_result["ok"], "card can move between zones")
	_expect_equal(state["zones"]["draw"]["cards"].size(), 2, "move does not mutate original state")
	_expect_equal(move_result["value"]["zones"]["draw"]["cards"].size(), 1, "move removes card from source")
	_expect_equal(move_result["value"]["zones"]["hand:0"]["cards"], ["card-002"], "move appends card to destination")

	var location := CardState.locate_card(move_result["value"], "card-002")
	_expect(location["ok"], "moved card can be located")
	_expect_equal(location["zone_id"], "hand:0", "location reports destination zone")
	_expect_equal(location["index"], 0, "location reports destination index")

	var wrong_source := CardState.move_card(state, "card-002", "table", "hand:0")
	_expect(not wrong_source["ok"], "wrong source declaration is rejected")
	_expect_equal(wrong_source["code"], "CARD_NOT_IN_SOURCE", "wrong source has precise code")

	var full_state = move_result["value"]
	var second_move := CardState.move_card(full_state, "card-001", "draw", "hand:0")
	_expect(second_move["ok"], "second card fits destination capacity")
	var overflow := CardState.move_card(second_move["value"], "card-003", "table", "hand:0")
	_expect(not overflow["ok"], "move into full zone is rejected")
	_expect_equal(overflow["code"], "DESTINATION_CAPACITY_EXCEEDED", "capacity rejection has precise code")
	_expect_equal(second_move["value"]["zones"]["table"]["cards"], ["card-003"], "failed move leaves supplied state unchanged")

	var duplicate_placement := _build_duplicate_placement_state()
	_expect(not duplicate_placement["ok"], "same instance cannot be placed twice")
	_expect_equal(duplicate_placement["code"], "CARD_MULTIPLY_PLACED", "multiple placement has precise code")

	var unplaced := _build_unplaced_state()
	_expect(not unplaced["ok"], "every instance must belong to a zone")
	_expect_equal(unplaced["code"], "CARD_UNPLACED", "unplaced card has precise code")


func _run_integration_suite() -> void:
	var engine := UniversalCardEngine.new(DrawCardModule.new(), {"max_draws": 2})
	_expect(engine.is_ready(), "draw fixture satisfies UCE-01 module contract")
	var start_result = engine.start(44)
	_expect(start_result.success, "draw fixture starts through universal engine")

	var initial_public: Dictionary = engine.get_public_state()
	_expect_equal(initial_public["game"]["card_table"]["zones"]["draw_pile"]["count"], 2, "public state exposes draw count")
	_expect_equal(initial_public["game"]["card_table"]["zones"]["draw_pile"]["cards"].size(), 0, "public state hides draw identities")

	var first_draw = engine.perform_action(GameAction.new("draw", 0, {}, "draw-1"))
	_expect(first_draw.success, "first draw action commits")
	_expect_equal(engine.state_version(), 1, "draw increments engine state version")
	var player_view: Dictionary = engine.get_player_state(0)
	_expect_equal(player_view["game"]["card_table"]["zones"]["hand:0"]["cards"].size(), 1, "player sees card received in hand")
	_expect_equal(player_view["game"]["card_table"]["zones"]["hand:0"]["cards"][0]["instance"]["id"], "card-002", "ordered draw takes top card")

	var anonymous_events: Array = engine.get_events(0, -1)
	var player_events: Array = engine.get_events(0, 0)
	_expect_equal(anonymous_events.size(), 2, "anonymous viewer receives only public start and draw events")
	_expect_equal(player_events.size(), 3, "player receives private card receipt")

	var second_draw = engine.perform_action(GameAction.new("draw", 0, {}, "draw-2"))
	_expect(second_draw.success, "second draw action commits")
	_expect_equal(engine.lifecycle_name(), "FINISHED", "fixture finishes after configured draws")
	var snapshot: Dictionary = engine.export_runtime_snapshot()
	_expect_equal(snapshot["module_state"]["cards"]["zones"]["hand:0"]["cards"], ["card-002", "card-001"], "snapshot preserves ordered hand")
	_expect_equal(snapshot["actions"].size(), 2, "snapshot records both draw actions")


func _build_sample_state() -> Dictionary:
	var red = CardDefinition.create("red", {"value": 1}, ["colour"])["value"]
	var blue = CardDefinition.create("blue", {"value": 2}, ["colour"])["value"]
	var first = CardInstance.create("card-001", "red")["value"]
	var second = CardInstance.create("card-002", "blue")["value"]
	var third = CardInstance.create("card-003", "red")["value"]
	var draw = ZoneDefinition.create("draw", ZoneDefinition.VISIBILITY_HIDDEN)["value"]
	var hand = ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], 2)["value"]
	var table = ZoneDefinition.create("table", ZoneDefinition.VISIBILITY_PUBLIC)["value"]
	return CardState.create(
		[red, blue],
		[first, second, third],
		[draw, hand, table],
		{"draw": ["card-001", "card-002"], "hand:0": [], "table": ["card-003"]}
	)


func _build_duplicate_placement_state() -> Dictionary:
	var definition = CardDefinition.create("one")["value"]
	var instance = CardInstance.create("copy", "one")["value"]
	var first_zone = ZoneDefinition.create("a", ZoneDefinition.VISIBILITY_PUBLIC)["value"]
	var second_zone = ZoneDefinition.create("b", ZoneDefinition.VISIBILITY_PUBLIC)["value"]
	return CardState.create(
		[definition],
		[instance],
		[first_zone, second_zone],
		{"a": ["copy"], "b": ["copy"]}
	)


func _build_unplaced_state() -> Dictionary:
	var definition = CardDefinition.create("one")["value"]
	var instance = CardInstance.create("copy", "one")["value"]
	var zone = ZoneDefinition.create("empty", ZoneDefinition.VISIBILITY_PUBLIC)["value"]
	return CardState.create([definition], [instance], [zone], {"empty": []})


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — expected=%s actual=%s" % [description, str(expected), str(actual)])
