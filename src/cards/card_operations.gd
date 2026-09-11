extends RefCounted
## Higher-level atomic card movements built on CardState.

const CardState = preload("res://src/cards/card_state.gd")
const DealService = preload("res://src/cards/deal_service.gd")


static func draw(
	card_state: Dictionary,
	source_zone_id: String,
	destination_zone_id: String,
	count: int = 1,
	take_mode: String = DealService.TAKE_FROM_END
) -> Dictionary:
	var dealt: Dictionary = DealService.deal_round_robin(
		card_state,
		source_zone_id,
		[destination_zone_id],
		count,
		take_mode
	)
	if not dealt["ok"]:
		return dealt
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": dealt["value"],
		"drawn": dealt["dealt_by_zone"][destination_zone_id].duplicate(),
		"movements": dealt["movements"].duplicate(true),
	}


static func move_many(
	card_state: Dictionary,
	instance_ids: Array,
	from_zone_id: String,
	to_zone_id: String,
	destination_index: int = -1,
	order_mode: String = CardState.ORDER_INPUT
) -> Dictionary:
	if from_zone_id == to_zone_id:
		return _error("MOVE_MANY_SAME_ZONE", "Use CardState.reorder_zone() for same-zone bulk reordering.")
	return CardState.move_cards(
		card_state,
		instance_ids,
		from_zone_id,
		to_zone_id,
		destination_index,
		order_mode
	)


static func transfer_all(card_state: Dictionary, from_zone_id: String, to_zone_id: String) -> Dictionary:
	if from_zone_id == to_zone_id:
		return _error("TRANSFER_SAME_ZONE", "Source and destination zones must differ.")
	var zone_result: Dictionary = CardState.zone_card_ids(card_state, from_zone_id)
	if not zone_result["ok"]:
		return zone_result
	if zone_result["value"].is_empty():
		return {
			"ok": true,
			"code": "OK",
			"message": "",
			"value": card_state.duplicate(true),
			"movements": [],
		}
	return CardState.move_cards(
		card_state,
		zone_result["value"],
		from_zone_id,
		to_zone_id,
		-1,
		CardState.ORDER_SOURCE
	)


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
