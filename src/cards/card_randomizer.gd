extends RefCounted
## Deterministic operations that change only card ordering.

const CardState = preload("res://src/cards/card_state.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")


static func shuffle_zone(
	card_state: Dictionary,
	zone_id: String,
	rng_state: Dictionary
) -> Dictionary:
	var card_check := CardState.validate(card_state)
	if not card_check["ok"]:
		return card_check
	var rng_check := DeterministicRng.validate(rng_state)
	if not rng_check["ok"]:
		return rng_check
	if not card_state["zones"].has(zone_id):
		return _error("SHUFFLE_ZONE_UNKNOWN", "Cannot shuffle an unknown zone.")

	var before: Array = card_state["zones"][zone_id]["cards"].duplicate()
	var shuffled: Dictionary = DeterministicRng.shuffle_values(rng_state, before)
	if not shuffled["ok"]:
		return shuffled
	var reordered: Dictionary = CardState.reorder_zone(card_state, zone_id, shuffled["value"])
	if not reordered["ok"]:
		return reordered
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": reordered["value"],
		"rng_state": shuffled["state"],
		"zone_id": zone_id,
		"order_before": before,
		"order_after": shuffled["value"].duplicate(),
		"draws_used": shuffled["draws_used"],
	}


static func cut_zone(card_state: Dictionary, zone_id: String, cut_index: int) -> Dictionary:
	var card_check := CardState.validate(card_state)
	if not card_check["ok"]:
		return card_check
	if not card_state["zones"].has(zone_id):
		return _error("CUT_ZONE_UNKNOWN", "Cannot cut an unknown zone.")
	var cards: Array = card_state["zones"][zone_id]["cards"]
	if cut_index < 0 or cut_index > cards.size():
		return _error("CUT_INDEX_INVALID", "cut_index is outside zone bounds.")
	var reordered: Array = []
	for index in range(cut_index, cards.size()):
		reordered.append(cards[index])
	for index in range(cut_index):
		reordered.append(cards[index])
	var result: Dictionary = CardState.reorder_zone(card_state, zone_id, reordered)
	if not result["ok"]:
		return result
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": result["value"],
		"zone_id": zone_id,
		"cut_index": cut_index,
		"order_before": cards.duplicate(),
		"order_after": reordered.duplicate(),
	}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
