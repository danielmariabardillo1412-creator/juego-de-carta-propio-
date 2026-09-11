extends RefCounted
## Portable physical card instance.
##
## Several instances may reference the same definition. This distinction is
## required for duplicate cards, multiple decks and collectible-card games.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const EXPECTED_KEYS := ["definition_id", "id", "metadata"]


static func create(
	instance_id: String,
	definition_id: String,
	metadata: Dictionary = {}
) -> Dictionary:
	var value := {
		"id": instance_id,
		"definition_id": definition_id,
		"metadata": metadata.duplicate(true),
	}
	var check := validate(value)
	if not check["ok"]:
		return check
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("CARD_INSTANCE_INVALID", "Card instance must be a Dictionary.")
	var instance: Dictionary = value
	var keys: Array = instance.keys()
	keys.sort()
	if keys != EXPECTED_KEYS:
		return _error(
			"CARD_INSTANCE_KEYS_INVALID",
			"Card instance requires exactly: definition_id, id and metadata."
		)

	var instance_id_check := CardDefinition._validate_id(instance["id"], "CARD_INSTANCE_ID")
	if not instance_id_check["ok"]:
		return instance_id_check
	var definition_id_check := CardDefinition._validate_id(instance["definition_id"], "CARD_REFERENCE_ID")
	if not definition_id_check["ok"]:
		return definition_id_check
	if not instance["metadata"] is Dictionary:
		return _error("CARD_INSTANCE_METADATA_INVALID", "Card instance metadata must be a Dictionary.")
	var data_check := PureDataValidator.validate(instance["metadata"], "$.card_instance.metadata")
	if not data_check["ok"]:
		return data_check
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
