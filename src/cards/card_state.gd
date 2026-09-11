extends RefCounted
## Validated pure-data state for card definitions, instances and zones.
##
## Invariants:
## - Definition, instance and zone ids are unique.
## - Every instance references an existing definition.
## - Every instance is placed in exactly one zone.
## - Zone capacities are respected.
## - Every operation is copy-on-write and validates its complete candidate.
## - Hidden views never expose stable identifiers for concealed cards.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")
const StateDigest = preload("res://src/state/state_digest.gd")

const STATE_KEYS := ["definitions", "instances", "zones"]
const ZONE_STATE_KEYS := ["cards", "definition"]
const ORDER_INPUT := "INPUT"
const ORDER_SOURCE := "SOURCE"
const ORDER_MODES := [ORDER_INPUT, ORDER_SOURCE]


static func create(
	definitions: Array,
	instances: Array,
	zones: Array,
	placements: Dictionary
) -> Dictionary:
	var definition_map := {}
	for raw_definition in definitions:
		var definition_check := CardDefinition.validate(raw_definition)
		if not definition_check["ok"]:
			return definition_check
		var definition: Dictionary = raw_definition
		var definition_id: String = definition["id"]
		if definition_map.has(definition_id):
			return _error("CARD_DEFINITION_DUPLICATE", "Duplicate card definition id: %s" % definition_id)
		definition_map[definition_id] = definition.duplicate(true)

	var instance_map := {}
	for raw_instance in instances:
		var instance_check := CardInstance.validate(raw_instance)
		if not instance_check["ok"]:
			return instance_check
		var instance: Dictionary = raw_instance
		var instance_id: String = instance["id"]
		if instance_map.has(instance_id):
			return _error("CARD_INSTANCE_DUPLICATE", "Duplicate card instance id: %s" % instance_id)
		if not definition_map.has(instance["definition_id"]):
			return _error(
				"CARD_DEFINITION_MISSING",
				"Card instance %s references unknown definition %s." % [instance_id, instance["definition_id"]]
			)
		instance_map[instance_id] = instance.duplicate(true)

	var zone_map := {}
	for raw_zone in zones:
		var zone_definition_check := ZoneDefinition.validate(raw_zone)
		if not zone_definition_check["ok"]:
			return zone_definition_check
		var zone: Dictionary = raw_zone
		var zone_id: String = zone["id"]
		if zone_map.has(zone_id):
			return _error("ZONE_DUPLICATE", "Duplicate zone id: %s" % zone_id)
		zone_map[zone_id] = {"definition": zone.duplicate(true), "cards": []}

	for raw_zone_id in placements.keys():
		if not raw_zone_id is String or not zone_map.has(raw_zone_id):
			return _error("PLACEMENT_ZONE_UNKNOWN", "Placements contain an unknown zone.")
		if not placements[raw_zone_id] is Array:
			return _error("PLACEMENT_LIST_INVALID", "Each placement value must be an Array.")
		zone_map[raw_zone_id]["cards"] = placements[raw_zone_id].duplicate()

	var state := {"definitions": definition_map, "instances": instance_map, "zones": zone_map}
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	return _success(state)


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("CARD_STATE_INVALID", "Card state must be a Dictionary.")
	var state: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(state, "$.card_state")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _error("CARD_STATE_KEYS_INVALID", "Card state requires exactly definitions, instances and zones.")
	if not state["definitions"] is Dictionary:
		return _error("CARD_DEFINITIONS_INVALID", "definitions must be a Dictionary.")
	if not state["instances"] is Dictionary:
		return _error("CARD_INSTANCES_INVALID", "instances must be a Dictionary.")
	if not state["zones"] is Dictionary:
		return _error("CARD_ZONES_INVALID", "zones must be a Dictionary.")

	for raw_definition_id in state["definitions"].keys():
		if not raw_definition_id is String:
			return _error("CARD_DEFINITION_KEY_INVALID", "Definition map keys must be Strings.")
		var definition: Variant = state["definitions"][raw_definition_id]
		var definition_check := CardDefinition.validate(definition)
		if not definition_check["ok"]:
			return definition_check
		if definition["id"] != raw_definition_id:
			return _error("CARD_DEFINITION_KEY_MISMATCH", "Definition map key does not match definition id.")

	for raw_instance_id in state["instances"].keys():
		if not raw_instance_id is String:
			return _error("CARD_INSTANCE_KEY_INVALID", "Instance map keys must be Strings.")
		var instance: Variant = state["instances"][raw_instance_id]
		var instance_check := CardInstance.validate(instance)
		if not instance_check["ok"]:
			return instance_check
		if instance["id"] != raw_instance_id:
			return _error("CARD_INSTANCE_KEY_MISMATCH", "Instance map key does not match instance id.")
		if not state["definitions"].has(instance["definition_id"]):
			return _error("CARD_DEFINITION_MISSING", "Card instance references an unknown definition.")

	var placement_counts := {}
	for raw_zone_id in state["zones"].keys():
		if not raw_zone_id is String:
			return _error("ZONE_KEY_INVALID", "Zone map keys must be Strings.")
		var zone_state: Variant = state["zones"][raw_zone_id]
		if not zone_state is Dictionary:
			return _error("ZONE_STATE_INVALID", "Each zone state must be a Dictionary.")
		var zone_state_keys: Array = zone_state.keys()
		zone_state_keys.sort()
		if zone_state_keys != ZONE_STATE_KEYS:
			return _error("ZONE_STATE_KEYS_INVALID", "Zone state requires exactly cards and definition.")
		var zone_check := ZoneDefinition.validate(zone_state["definition"])
		if not zone_check["ok"]:
			return zone_check
		if zone_state["definition"]["id"] != raw_zone_id:
			return _error("ZONE_KEY_MISMATCH", "Zone map key does not match zone definition id.")
		if not zone_state["cards"] is Array:
			return _error("ZONE_CARDS_INVALID", "Zone cards must be an Array.")
		var capacity: int = zone_state["definition"]["capacity"]
		if capacity >= 0 and zone_state["cards"].size() > capacity:
			return _error("ZONE_CAPACITY_EXCEEDED", "Zone %s exceeds its capacity." % raw_zone_id)
		var local_seen := {}
		for placed_instance_id in zone_state["cards"]:
			if not placed_instance_id is String or not state["instances"].has(placed_instance_id):
				return _error("PLACED_CARD_UNKNOWN", "Zone contains an unknown card instance.")
			if local_seen.has(placed_instance_id):
				return _error("PLACED_CARD_DUPLICATE", "Zone contains the same card instance twice.")
			local_seen[placed_instance_id] = true
			placement_counts[placed_instance_id] = int(placement_counts.get(placed_instance_id, 0)) + 1

	for instance_id in state["instances"].keys():
		var count: int = int(placement_counts.get(instance_id, 0))
		if count == 0:
			return _error("CARD_UNPLACED", "Card instance is not placed in any zone: %s" % instance_id)
		if count > 1:
			return _error("CARD_MULTIPLY_PLACED", "Card instance is placed in more than one zone: %s" % instance_id)
	return _ok()


static func move_card(
	state: Dictionary,
	instance_id: String,
	from_zone_id: String,
	to_zone_id: String,
	destination_index: int = -1
) -> Dictionary:
	var result: Dictionary = move_cards(
		state,
		[instance_id],
		from_zone_id,
		to_zone_id,
		destination_index,
		ORDER_INPUT
	)
	if not result["ok"]:
		return result
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": result["value"],
		"movement": result["movements"][0],
	}


static func move_cards(
	state: Dictionary,
	instance_ids: Array,
	from_zone_id: String,
	to_zone_id: String,
	destination_index: int = -1,
	order_mode: String = ORDER_INPUT
) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if instance_ids.is_empty():
		return _error("CARD_MOVE_EMPTY", "At least one card must be moved.")
	if order_mode not in ORDER_MODES:
		return _error("CARD_MOVE_ORDER_INVALID", "Card move order mode is unsupported.")
	if not state["zones"].has(from_zone_id):
		return _error("SOURCE_ZONE_UNKNOWN", "Source zone does not exist.")
	if not state["zones"].has(to_zone_id):
		return _error("DESTINATION_ZONE_UNKNOWN", "Destination zone does not exist.")

	var source_cards: Array = state["zones"][from_zone_id]["cards"]
	var seen: Dictionary = {}
	var selected: Array = []
	var source_indices: Dictionary = {}
	for raw_instance_id in instance_ids:
		if not raw_instance_id is String or seen.has(raw_instance_id):
			return _error("CARD_MOVE_IDS_INVALID", "Moved card ids must be unique Strings.")
		var source_index: int = source_cards.find(raw_instance_id)
		if source_index < 0:
			return _error("CARD_NOT_IN_SOURCE", "Every moved card must be in the declared source zone.")
		seen[raw_instance_id] = true
		selected.append(raw_instance_id)
		source_indices[raw_instance_id] = source_index
	if order_mode == ORDER_SOURCE:
		var source_ordered: Array = []
		for existing_id in source_cards:
			if seen.has(existing_id):
				source_ordered.append(existing_id)
		selected = source_ordered

	var remaining_source: Array = []
	for existing_id in source_cards:
		if not seen.has(existing_id):
			remaining_source.append(existing_id)
	var destination_cards: Array
	if from_zone_id == to_zone_id:
		destination_cards = remaining_source
	else:
		destination_cards = state["zones"][to_zone_id]["cards"].duplicate()
		var capacity: int = state["zones"][to_zone_id]["definition"]["capacity"]
		if capacity >= 0 and destination_cards.size() + selected.size() > capacity:
			return _error("DESTINATION_CAPACITY_EXCEEDED", "Destination zone lacks capacity.")

	var insertion_index: int = destination_cards.size() if destination_index == -1 else destination_index
	if insertion_index < 0 or insertion_index > destination_cards.size():
		return _error("DESTINATION_INDEX_INVALID", "Destination index is outside the post-removal zone bounds.")
	for offset in range(selected.size()):
		destination_cards.insert(insertion_index + offset, selected[offset])

	var next_state: Dictionary = state.duplicate(true)
	if from_zone_id == to_zone_id:
		next_state["zones"][from_zone_id]["cards"] = destination_cards
	else:
		next_state["zones"][from_zone_id]["cards"] = remaining_source
		next_state["zones"][to_zone_id]["cards"] = destination_cards
	var next_check := validate(next_state)
	if not next_check["ok"]:
		return next_check
	var conservation: Dictionary = validate_conservation(state, next_state, true)
	if not conservation["ok"]:
		return conservation

	var movements: Array = []
	for offset in range(selected.size()):
		var moved_id: String = selected[offset]
		movements.append({
			"instance_id": moved_id,
			"from_zone_id": from_zone_id,
			"to_zone_id": to_zone_id,
			"source_index": source_indices[moved_id],
			"destination_index": insertion_index + offset,
		})
	return {"ok": true, "code": "OK", "message": "", "value": next_state, "movements": movements}


static func reorder_zone(state: Dictionary, zone_id: String, ordered_instance_ids: Array) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if not state["zones"].has(zone_id):
		return _error("ZONE_UNKNOWN", "Unknown zone.")
	var current: Array = state["zones"][zone_id]["cards"]
	if ordered_instance_ids.size() != current.size():
		return _error("ZONE_REORDER_SIZE_MISMATCH", "Reordered zone must contain the same number of cards.")
	var current_set: Dictionary = {}
	for instance_id in current:
		current_set[instance_id] = true
	var seen: Dictionary = {}
	for instance_id in ordered_instance_ids:
		if not instance_id is String or not current_set.has(instance_id) or seen.has(instance_id):
			return _error("ZONE_REORDER_NOT_PERMUTATION", "Reordered zone must be an exact card permutation.")
		seen[instance_id] = true
	var next_state: Dictionary = state.duplicate(true)
	next_state["zones"][zone_id]["cards"] = ordered_instance_ids.duplicate()
	var next_check := validate(next_state)
	if not next_check["ok"]:
		return next_check
	var conservation: Dictionary = validate_conservation(state, next_state, true)
	if not conservation["ok"]:
		return conservation
	return _success(next_state)


static func update_instance_metadata(state: Dictionary, instance_id: String, metadata: Dictionary) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if not state["instances"].has(instance_id):
		return _error("CARD_INSTANCE_UNKNOWN", "Unknown card instance.")
	var candidate_instance: Dictionary = state["instances"][instance_id].duplicate(true)
	candidate_instance["metadata"] = metadata.duplicate(true)
	var instance_check := CardInstance.validate(candidate_instance)
	if not instance_check["ok"]:
		return instance_check
	var next_state: Dictionary = state.duplicate(true)
	next_state["instances"][instance_id] = candidate_instance
	var next_check := validate(next_state)
	if not next_check["ok"]:
		return next_check
	return _success(next_state)


static func locate_card(state: Dictionary, instance_id: String) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if not state["instances"].has(instance_id):
		return _error("CARD_INSTANCE_UNKNOWN", "Unknown card instance.")
	for zone_id in state["zones"].keys():
		var index: int = state["zones"][zone_id]["cards"].find(instance_id)
		if index >= 0:
			return {"ok": true, "code": "OK", "message": "", "zone_id": zone_id, "index": index}
	return _error("CARD_UNPLACED", "Card instance has no zone.")


static func zone_card_ids(state: Dictionary, zone_id: String) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if not state["zones"].has(zone_id):
		return _error("ZONE_UNKNOWN", "Unknown zone.")
	return _success_array(state["zones"][zone_id]["cards"])


static func inventory_digest(state: Dictionary) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	return StateDigest.sha256({
		"definitions": state["definitions"],
		"instances": state["instances"],
	})


static func validate_conservation(before: Dictionary, after: Dictionary, require_same_zone_definitions: bool = false) -> Dictionary:
	var before_check := validate(before)
	if not before_check["ok"]:
		return before_check
	var after_check := validate(after)
	if not after_check["ok"]:
		return after_check
	if before["definitions"] != after["definitions"]:
		return _error("CARD_DEFINITIONS_CHANGED", "Card definitions changed during a conserving operation.")
	if before["instances"] != after["instances"]:
		return _error("CARD_INSTANCES_CHANGED", "Card instances changed during a conserving operation.")
	if require_same_zone_definitions:
		if before["zones"].keys().size() != after["zones"].keys().size():
			return _error("CARD_ZONES_CHANGED", "Zone set changed during a conserving operation.")
		for zone_id in before["zones"].keys():
			if not after["zones"].has(zone_id) or before["zones"][zone_id]["definition"] != after["zones"][zone_id]["definition"]:
				return _error("CARD_ZONES_CHANGED", "Zone definitions changed during a conserving operation.")
	return _ok()


static func view_for(state: Dictionary, viewer_id: int = -1) -> Dictionary:
	var state_check := validate(state)
	if not state_check["ok"]:
		return state_check
	if viewer_id < -1:
		return _error("VIEWER_ID_INVALID", "Viewer id must be -1 or greater.")

	var zones_view := {}
	for zone_id in state["zones"].keys():
		var zone_state: Dictionary = state["zones"][zone_id]
		var zone_definition: Dictionary = zone_state["definition"]
		var identities_visible: bool = ZoneDefinition.can_view_identities(zone_definition, viewer_id)
		var count_visible: bool = ZoneDefinition.can_view_count(zone_definition, viewer_id)
		var visible_indices: Array = ZoneDefinition.visible_indices(
			zone_definition,
			zone_state["cards"].size(),
			viewer_id
		)
		var visible_lookup: Dictionary = {}
		for index in visible_indices:
			visible_lookup[index] = true
		var cards_view: Array = []
		var slots_view: Array = []
		if count_visible:
			for index in range(zone_state["cards"].size()):
				var card_value: Variant = null
				var visible: bool = visible_lookup.has(index)
				if visible:
					var instance_id: String = zone_state["cards"][index]
					var instance: Dictionary = state["instances"][instance_id]
					card_value = {
						"instance": instance.duplicate(true),
						"definition": state["definitions"][instance["definition_id"]].duplicate(true),
					}
					cards_view.append(card_value.duplicate(true))
				slots_view.append({"index": index, "visible": visible, "card": card_value})
		zones_view[zone_id] = {
			"definition": zone_definition.duplicate(true),
			"count": zone_state["cards"].size() if count_visible else -1,
			"count_visible": count_visible,
			"identities_visible": identities_visible,
			"cards": cards_view,
			"slots": slots_view,
		}

	return {"ok": true, "code": "OK", "message": "", "value": {"zones": zones_view}}


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _success_array(value: Array) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate()}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
