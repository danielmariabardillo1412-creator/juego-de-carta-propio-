extends RefCounted
## Portable definition of an ordered card zone.
##
## Visibility has two layers:
## - full identity visibility (PUBLIC / OWNER / LISTED / HIDDEN);
## - optional public edge reveals for piles such as a face-up top card.
##
## Count visibility is independent. A zone may hide its exact size from viewers
## who cannot see all identities. Hidden viewers never receive stable opaque card
## identifiers, preventing card tracking across zones.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const VISIBILITY_PUBLIC := "PUBLIC"
const VISIBILITY_OWNER := "OWNER"
const VISIBILITY_HIDDEN := "HIDDEN"
const VISIBILITY_LISTED := "LISTED"
const VISIBILITIES := [
	VISIBILITY_PUBLIC,
	VISIBILITY_OWNER,
	VISIBILITY_HIDDEN,
	VISIBILITY_LISTED,
]

const COUNT_PUBLIC := "PUBLIC"
const COUNT_IDENTITIES := "IDENTITIES"
const COUNT_VISIBILITIES := [COUNT_PUBLIC, COUNT_IDENTITIES]

const MAX_PUBLIC_REVEAL := 1024
const EXPECTED_KEYS := [
	"capacity",
	"count_visibility",
	"id",
	"metadata",
	"owner_id",
	"public_reveal_end",
	"public_reveal_start",
	"visibility",
	"visible_to",
]


static func create(
	zone_id: String,
	visibility: String,
	owner_id: int = -1,
	visible_to: Array = [],
	capacity: int = -1,
	metadata: Dictionary = {},
	count_visibility: String = COUNT_PUBLIC,
	public_reveal_start: int = 0,
	public_reveal_end: int = 0
) -> Dictionary:
	var value := {
		"id": zone_id,
		"visibility": visibility,
		"owner_id": owner_id,
		"visible_to": visible_to.duplicate(),
		"capacity": capacity,
		"metadata": metadata.duplicate(true),
		"count_visibility": count_visibility,
		"public_reveal_start": public_reveal_start,
		"public_reveal_end": public_reveal_end,
	}
	var check := validate(value)
	if not check["ok"]:
		return check
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("ZONE_DEFINITION_INVALID", "Zone definition must be a Dictionary.")
	var zone: Dictionary = value
	var keys: Array = zone.keys()
	keys.sort()
	if keys != EXPECTED_KEYS:
		return _error("ZONE_DEFINITION_KEYS_INVALID", "Zone definition has missing or unknown keys.")

	var id_check := CardDefinition._validate_id(zone["id"], "ZONE_ID")
	if not id_check["ok"]:
		return id_check
	if not zone["visibility"] is String or zone["visibility"] not in VISIBILITIES:
		return _error("ZONE_VISIBILITY_INVALID", "Zone visibility is not supported.")
	if not zone["count_visibility"] is String or zone["count_visibility"] not in COUNT_VISIBILITIES:
		return _error("ZONE_COUNT_VISIBILITY_INVALID", "Zone count visibility is not supported.")
	if not zone["owner_id"] is int or zone["owner_id"] < -1:
		return _error("ZONE_OWNER_INVALID", "Zone owner_id must be -1 or greater.")
	if zone["visibility"] == VISIBILITY_OWNER and zone["owner_id"] < 0:
		return _error("ZONE_OWNER_REQUIRED", "OWNER visibility requires a non-negative owner_id.")
	if not zone["visible_to"] is Array:
		return _error("ZONE_VISIBLE_TO_INVALID", "Zone visible_to must be an Array.")

	var seen := {}
	for raw_player_id in zone["visible_to"]:
		if not raw_player_id is int or raw_player_id < 0:
			return _error("ZONE_VISIBLE_TO_INVALID", "Zone visible_to contains an invalid player id.")
		if seen.has(raw_player_id):
			return _error("ZONE_VISIBLE_TO_DUPLICATE", "Zone visible_to contains a duplicate player id.")
		seen[raw_player_id] = true
	if zone["visibility"] == VISIBILITY_LISTED and zone["visible_to"].is_empty():
		return _error("ZONE_VISIBLE_TO_REQUIRED", "LISTED visibility requires at least one viewer.")
	if zone["visibility"] != VISIBILITY_LISTED and not zone["visible_to"].is_empty():
		return _error("ZONE_VISIBLE_TO_UNUSED", "visible_to is only valid for LISTED visibility.")

	if not zone["capacity"] is int or zone["capacity"] < -1:
		return _error("ZONE_CAPACITY_INVALID", "Zone capacity must be -1 or greater.")
	for reveal_key in ["public_reveal_start", "public_reveal_end"]:
		if not zone[reveal_key] is int or zone[reveal_key] < 0 or zone[reveal_key] > MAX_PUBLIC_REVEAL:
			return _error("ZONE_PUBLIC_REVEAL_INVALID", "%s must be between 0 and %d." % [reveal_key, MAX_PUBLIC_REVEAL])
	if zone["count_visibility"] != COUNT_PUBLIC and (
		zone["public_reveal_start"] > 0 or zone["public_reveal_end"] > 0
	):
		return _error("ZONE_REVEAL_REQUIRES_COUNT", "Public edge reveals require a publicly visible zone count.")

	if not zone["metadata"] is Dictionary:
		return _error("ZONE_METADATA_INVALID", "Zone metadata must be a Dictionary.")
	var data_check := PureDataValidator.validate(zone["metadata"], "$.zone.metadata")
	if not data_check["ok"]:
		return data_check
	return {"ok": true, "code": "OK", "message": ""}


static func can_view_identities(zone: Dictionary, viewer_id: int) -> bool:
	match zone["visibility"]:
		VISIBILITY_PUBLIC:
			return true
		VISIBILITY_OWNER:
			return viewer_id >= 0 and viewer_id == zone["owner_id"]
		VISIBILITY_LISTED:
			return viewer_id >= 0 and viewer_id in zone["visible_to"]
		_:
			return false


static func can_view_count(zone: Dictionary, viewer_id: int) -> bool:
	return can_view_identities(zone, viewer_id) or zone["count_visibility"] == COUNT_PUBLIC


static func visible_indices(zone: Dictionary, card_count: int, viewer_id: int) -> Array:
	if card_count <= 0:
		return []
	if can_view_identities(zone, viewer_id):
		return range(card_count)
	var visible: Dictionary = {}
	var start_count: int = mini(zone["public_reveal_start"], card_count)
	for index in range(start_count):
		visible[index] = true
	var end_count: int = mini(zone["public_reveal_end"], card_count)
	for offset in range(end_count):
		visible[card_count - 1 - offset] = true
	var result: Array = visible.keys()
	result.sort()
	return result


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
