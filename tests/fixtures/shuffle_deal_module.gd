extends RefCounted
## Integration fixture for deterministic shuffle and atomic round-robin deal.
## It finishes during start(); no player action is part of this fixture.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const CardState = preload("res://src/cards/card_state.gd")
const CardRandomizer = preload("res://src/cards/card_randomizer.gd")
const DealService = preload("res://src/cards/deal_service.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")


func module_id() -> String:
	return "fixture.shuffle_deal.v1"

func module_version() -> String:
	return "1.0.0-fixture"


func create_initial_state(_config: Dictionary, seed: int) -> Dictionary:
	var definitions: Array = []
	var instances: Array = []
	var placements: Array = []
	for number in range(1, 7):
		var definition_result := CardDefinition.create("rank-%d" % number, {"rank": number}, ["fixture"])
		var instance_result := CardInstance.create("card-%03d" % number, "rank-%d" % number)
		definitions.append(definition_result["value"])
		instances.append(instance_result["value"])
		placements.append(instance_result["value"]["id"])

	var deck_result := ZoneDefinition.create("deck", ZoneDefinition.VISIBILITY_HIDDEN)
	var hand_zero_result := ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], 3)
	var hand_one_result := ZoneDefinition.create("hand:1", ZoneDefinition.VISIBILITY_OWNER, 1, [], 3)
	var cards_result := CardState.create(
		definitions,
		instances,
		[deck_result["value"], hand_zero_result["value"], hand_one_result["value"]],
		{"deck": placements, "hand:0": [], "hand:1": []}
	)
	var rng_result := DeterministicRng.create(seed)
	var shuffle_result := CardRandomizer.shuffle_zone(cards_result["value"], "deck", rng_result["value"])
	var deal_result := DealService.deal_round_robin(
		shuffle_result["value"],
		"deck",
		["hand:0", "hand:1"],
		2,
		DealService.TAKE_FROM_END
	)
	return {
		"seed": seed,
		"rng": shuffle_result["rng_state"],
		"cards": deal_result["value"],
		"shuffle_order": shuffle_result["order_after"],
		"dealt_by_zone": deal_result["dealt_by_zone"],
	}


func validate_action(_state: Dictionary, _action: Object) -> Dictionary:
	return _failure("FIXTURE_FINISHED", "This fixture finishes during engine start.")


func reduce(_state: Dictionary, _action: Object) -> Dictionary:
	return _failure("FIXTURE_FINISHED", "This fixture has no transitions.")


func get_public_state(state: Dictionary) -> Dictionary:
	var view := CardState.view_for(state["cards"], -1)
	return {
		"seed": state["seed"],
		"card_table": view["value"],
	}


func get_player_state(state: Dictionary, viewer_id: int) -> Dictionary:
	var view := CardState.view_for(state["cards"], viewer_id)
	return {
		"seed": state["seed"],
		"card_table": view["value"],
	}


func is_finished(_state: Dictionary) -> bool:
	return true


func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
