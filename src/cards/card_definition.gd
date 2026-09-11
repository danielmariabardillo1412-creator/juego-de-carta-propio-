extends RefCounted
## Portable definition of a card type.
##
## A definition describes what a card is. It is not a physical copy in a
## match. Games are free to encode suit, rank, cost, text, artwork keys or any
## other rule data inside `attributes`.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const MAX_ID_LENGTH := 128
const MAX_TAG_LENGTH := 64
const EXPECTED_KEYS := ["attributes", "id", "tags"]


static func create(
	definition_id: String,
	attributes: Dictionary = {},
	tags: Array = []
) -> Dictionary:
	var value := {
		"id": definition_id,
		"attributes": attributes.duplicate(true),
		"tags": tags.duplicate(),
	}
	var check := validate(value)
	if not check["ok"]:
		return check
	return _success(value)


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("CARD_DEFINITION_INVALID", "Card definition must be a Dictionary.")
	var definition: Dictionary = value
	var keys: Array = definition.keys()
	keys.sort()
	if keys != EXPECTED_KEYS:
		return _error(
			"CARD_DEFINITION_KEYS_INVALID",
			"Card definition requires exactly: attributes, id and tags."
		)

	var id_check := _validate_id(definition["id"], "CARD_DEFINITION_ID")
	if not id_check["ok"]:
		return id_check
	if not definition["attributes"] is Dictionary:
		return _error("CARD_ATTRIBUTES_INVALID", "Card attributes must be a Dictionary.")
	var data_check := PureDataValidator.validate(definition["attributes"], "$.card.attributes")
	if not data_check["ok"]:
		return data_check
	if not definition["tags"] is Array:
		return _error("CARD_TAGS_INVALID", "Card tags must be an Array.")

	var seen := {}
	for raw_tag in definition["tags"]:
		if not raw_tag is String:
			return _error("CARD_TAG_INVALID", "Every card tag must be a String.")
		var tag: String = raw_tag
		if tag.is_empty() or tag.strip_edges() != tag or tag.length() > MAX_TAG_LENGTH:
			return _error("CARD_TAG_INVALID", "Card tags must be trimmed, non-empty and at most 64 characters.")
		if seen.has(tag):
			return _error("CARD_TAG_DUPLICATE", "Card definition contains a duplicate tag: %s" % tag)
		seen[tag] = true

	return _ok()


static func _validate_id(value: Variant, code_prefix: String) -> Dictionary:
	if not value is String:
		return _error("%s_INVALID" % code_prefix, "Identifier must be a String.")
	var identifier: String = value
	if identifier.is_empty() or identifier.strip_edges() != identifier:
		return _error("%s_INVALID" % code_prefix, "Identifier must be trimmed and non-empty.")
	if identifier.length() > MAX_ID_LENGTH:
		return _error("%s_TOO_LONG" % code_prefix, "Identifier exceeds 128 characters.")
	for index in range(identifier.length()):
		if identifier.unicode_at(index) <= 32 or identifier.unicode_at(index) == 127:
			return _error("%s_INVALID" % code_prefix, "Identifier cannot contain whitespace or control characters.")
	return _ok()


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
