extends RefCounted
## Atomic deterministic dealing operations.
##
## A complete deal is prevalidated and committed once. No destination can receive
## a partial hand when a later capacity or source check fails.

const CardState = preload("res://src/cards/card_state.gd")

const TAKE_FROM_END := "END"
const TAKE_FROM_START := "START"
const TAKE_MODES := [TAKE_FROM_END, TAKE_FROM_START]


static func deal_round_robin(
	card_state: Dictionary,
	source_zone_id: String,
	destination_zone_ids: Array,
	cards_per_destination: int,
	take_mode: String = TAKE_FROM_END
) -> Dictionary:
	if cards_per_destination <= 0:
		return _error("DEAL_COUNT_INVALID", "cards_per_destination must be greater than zero.")
	var counts: Dictionary = {}
	for raw_zone_id in destination_zone_ids:
		if raw_zone_id is String:
			counts[raw_zone_id] = cards_per_destination
	return deal_counts(card_state, source_zone_id, destination_zone_ids, counts, take_mode)


static func deal_counts(
	card_state: Dictionary,
	source_zone_id: String,
	destination_zone_ids: Array,
	cards_by_destination: Dictionary,
	take_mode: String = TAKE_FROM_END
) -> Dictionary:
	var state_check := CardState.validate(card_state)
	if not state_check["ok"]:
		return state_check
	if not card_state["zones"].has(source_zone_id):
		return _error("DEAL_SOURCE_UNKNOWN", "Deal source zone does not exist.")
	if destination_zone_ids.is_empty():
		return _error("DEAL_DESTINATIONS_EMPTY", "At least one destination zone is required.")
	if take_mode not in TAKE_MODES:
		return _error("DEAL_TAKE_MODE_INVALID", "Deal take mode is not supported.")
	if not cards_by_destination is Dictionary:
		return _error("DEAL_COUNTS_INVALID", "cards_by_destination must be a Dictionary.")

	var seen_destinations: Dictionary = {}
	var total_required: int = 0
	for raw_zone_id in destination_zone_ids:
		if not raw_zone_id is String:
			return _error("DEAL_DESTINATION_INVALID", "Destination zone ids must be Strings.")
		var zone_id: String = raw_zone_id
		if zone_id == source_zone_id:
			return _error("DEAL_SOURCE_IS_DESTINATION", "Source zone cannot also be a destination.")
		if seen_destinations.has(zone_id):
			return _error("DEAL_DESTINATION_DUPLICATE", "Destination zones must be unique.")
		if not card_state["zones"].has(zone_id):
			return _error("DEAL_DESTINATION_UNKNOWN", "Deal destination zone does not exist: %s" % zone_id)
		if not cards_by_destination.has(zone_id):
			return _error("DEAL_COUNT_MISSING", "Destination has no declared card count: %s" % zone_id)
		var count: Variant = cards_by_destination[zone_id]
		if not count is int or count <= 0:
			return _error("DEAL_COUNT_INVALID", "Every destination count must be a positive integer.")
		seen_destinations[zone_id] = true
		total_required += count
	for raw_count_zone in cards_by_destination.keys():
		if not raw_count_zone is String or not seen_destinations.has(raw_count_zone):
			return _error("DEAL_COUNT_DESTINATION_UNKNOWN", "cards_by_destination contains an undeclared destination.")

	var source_count: int = card_state["zones"][source_zone_id]["cards"].size()
	if source_count < total_required:
		return _error(
			"DEAL_SOURCE_INSUFFICIENT",
			"Source zone contains %d cards but %d are required." % [source_count, total_required]
		)
	for zone_id in destination_zone_ids:
		var destination: Dictionary = card_state["zones"][zone_id]
		var capacity: int = destination["definition"]["capacity"]
		var requested: int = cards_by_destination[zone_id]
		if capacity >= 0 and destination["cards"].size() + requested > capacity:
			return _error("DEAL_CAPACITY_EXCEEDED", "Destination zone lacks capacity: %s" % zone_id)

	var next_state: Dictionary = card_state.duplicate(true)
	var movements: Array = []
	var dealt_by_zone: Dictionary = {}
	var dealt_counts: Dictionary = {}
	for zone_id in destination_zone_ids:
		dealt_by_zone[zone_id] = []
		dealt_counts[zone_id] = 0

	while movements.size() < total_required:
		for zone_id in destination_zone_ids:
			if dealt_counts[zone_id] >= cards_by_destination[zone_id]:
				continue
			var source_cards: Array = next_state["zones"][source_zone_id]["cards"]
			var source_index: int = source_cards.size() - 1 if take_mode == TAKE_FROM_END else 0
			var instance_id: String = source_cards[source_index]
			source_cards.remove_at(source_index)
			var destination_cards: Array = next_state["zones"][zone_id]["cards"]
			var destination_index: int = destination_cards.size()
			destination_cards.append(instance_id)
			dealt_by_zone[zone_id].append(instance_id)
			dealt_counts[zone_id] = int(dealt_counts[zone_id]) + 1
			movements.append({
				"instance_id": instance_id,
				"from_zone_id": source_zone_id,
				"to_zone_id": zone_id,
				"source_index": source_index,
				"destination_index": destination_index,
			})

	var next_check := CardState.validate(next_state)
	if not next_check["ok"]:
		return next_check
	var conservation: Dictionary = CardState.validate_conservation(card_state, next_state, true)
	if not conservation["ok"]:
		return conservation
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": next_state,
		"source_zone_id": source_zone_id,
		"destination_zone_ids": destination_zone_ids.duplicate(),
		"cards_by_destination": cards_by_destination.duplicate(true),
		"take_mode": take_mode,
		"movements": movements,
		"dealt_by_zone": dealt_by_zone,
	}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
