extends RefCounted
## Read-only queries over card state.

const CardState = preload("res://src/cards/card_state.gd")


static func cards_in_zone(card_state: Dictionary, zone_id: String) -> Dictionary:
	var ids_result = CardState.zone_card_ids(card_state, zone_id)
	if not ids_result["ok"]:
		return ids_result
	var cards: Array = []
	for instance_id in ids_result["value"]:
		var instance: Dictionary = card_state["instances"][instance_id]
		cards.append({
			"instance": instance.duplicate(true),
			"definition": card_state["definitions"][instance["definition_id"]].duplicate(true),
		})
	return {"ok": true, "code": "OK", "message": "", "value": cards}


static func filter_by_attribute(
	card_state: Dictionary,
	zone_id: String,
	attribute: String,
	expected: Variant
) -> Dictionary:
	var cards_result = cards_in_zone(card_state, zone_id)
	if not cards_result["ok"]:
		return cards_result
	var result: Array = []
	for card in cards_result["value"]:
		if card["definition"]["attributes"].get(attribute, null) == expected:
			result.append(card)
	return {"ok": true, "code": "OK", "message": "", "value": result}


static func highest_by_attribute(card_state: Dictionary, instance_ids: Array, attribute: String) -> Dictionary:
	var state_check = CardState.validate(card_state)
	if not state_check["ok"]:
		return state_check
	if instance_ids.is_empty():
		return _error("CARD_QUERY_EMPTY", "At least one card is required for comparison.")
	if attribute.is_empty():
		return _error("CARD_QUERY_ATTRIBUTE_EMPTY", "Compared attribute cannot be empty.")
	var best_value: Variant = null
	var winners: Array = []
	for instance_id in instance_ids:
		if not instance_id is String or not card_state.get("instances", {}).has(instance_id):
			return _error("CARD_QUERY_INSTANCE_UNKNOWN", "Unknown card instance.")
		var instance: Dictionary = card_state["instances"][instance_id]
		var definition: Dictionary = card_state["definitions"][instance["definition_id"]]
		var value: Variant = definition["attributes"].get(attribute, null)
		if not (value is int or value is float):
			return _error("CARD_QUERY_ATTRIBUTE_NOT_NUMERIC", "Compared card attribute must be numeric.")
		if best_value == null or value > best_value:
			best_value = value
			winners = [instance_id]
		elif value == best_value:
			winners.append(instance_id)
	return {"ok": true, "code": "OK", "message": "", "value": {"best": best_value, "instance_ids": winners}}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
