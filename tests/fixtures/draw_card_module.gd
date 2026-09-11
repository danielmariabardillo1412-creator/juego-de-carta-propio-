extends RefCounted
## Tiny integration fixture proving that UCE-01 can host the UCE-02 card state.
## It is not intended to be a real game.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const CardState = preload("res://src/cards/card_state.gd")


func module_id() -> String:
	return "fixture.draw_cards.v1"

func module_version() -> String:
	return "1.0.0-fixture"


func create_initial_state(config: Dictionary, seed: int) -> Dictionary:
	var red_definition := CardDefinition.create("red", {"colour": "red", "value": 1}, ["basic"])
	var blue_definition := CardDefinition.create("blue", {"colour": "blue", "value": 2}, ["basic"])
	var first_card := CardInstance.create("card-001", "red", {"serial": 1})
	var second_card := CardInstance.create("card-002", "blue", {"serial": 2})
	var draw_zone := ZoneDefinition.create("draw_pile", ZoneDefinition.VISIBILITY_HIDDEN)
	var hand_zone := ZoneDefinition.create("hand:0", ZoneDefinition.VISIBILITY_OWNER, 0, [], 2)

	var cards_result := CardState.create(
		[red_definition["value"], blue_definition["value"]],
		[first_card["value"], second_card["value"]],
		[draw_zone["value"], hand_zone["value"]],
		{
			"draw_pile": ["card-001", "card-002"],
			"hand:0": [],
		}
	)
	return {
		"seed": seed,
		"draws": 0,
		"max_draws": int(config.get("max_draws", 2)),
		"cards": cards_result["value"],
	}


func validate_action(state: Dictionary, action: Object) -> Dictionary:
	if action.type != "draw":
		return _failure("ACTION_UNKNOWN", "Fixture only supports draw.")
	if action.actor_id != 0:
		return _failure("WRONG_ACTOR", "Only player 0 exists in this fixture.")
	if not action.payload.is_empty():
		return _failure("DRAW_PAYLOAD_INVALID", "Draw does not accept a payload.")
	var draw_cards := CardState.zone_card_ids(state["cards"], "draw_pile")
	if not draw_cards["ok"]:
		return draw_cards
	if draw_cards["value"].is_empty():
		return _failure("DRAW_PILE_EMPTY", "No card remains to draw.")
	return _success()


func reduce(state: Dictionary, action: Object) -> Dictionary:
	var draw_cards := CardState.zone_card_ids(state["cards"], "draw_pile")
	var instance_id: String = draw_cards["value"].back()
	var moved := CardState.move_card(state["cards"], instance_id, "draw_pile", "hand:0")
	if not moved["ok"]:
		return moved

	var next_state: Dictionary = state.duplicate(true)
	next_state["cards"] = moved["value"]
	next_state["draws"] += 1
	var instance: Dictionary = next_state["cards"]["instances"][instance_id]
	return {
		"ok": true,
		"state": next_state,
		"events": [
			{
				"type": "card_drawn",
				"payload": {
					"actor_id": action.actor_id,
					"remaining": draw_cards["value"].size() - 1,
				},
				"visible_to": [],
			},
			{
				"type": "card_received",
				"payload": {
					"instance_id": instance_id,
					"definition_id": instance["definition_id"],
				},
				"visible_to": [action.actor_id],
			},
		],
	}


func get_public_state(state: Dictionary) -> Dictionary:
	var view := CardState.view_for(state["cards"], -1)
	return {
		"draws": state["draws"],
		"card_table": view["value"],
	}


func get_player_state(state: Dictionary, viewer_id: int) -> Dictionary:
	var view := CardState.view_for(state["cards"], viewer_id)
	return {
		"draws": state["draws"],
		"card_table": view["value"],
	}


func is_finished(state: Dictionary) -> bool:
	return state["draws"] >= state["max_draws"]


func _success() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
