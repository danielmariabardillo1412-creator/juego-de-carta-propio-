extends RefCounted
## Builds immutable card definitions and uniquely identified physical instances.

const CardDefinition = preload("res://src/cards/card_definition.gd")
const CardInstance = preload("res://src/cards/card_instance.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const ALLOWED_SPEC_KEYS := ["attributes", "count", "id", "instance_metadata", "tags"]
const MAX_INSTANCES := 100000
const RESERVED_INSTANCE_METADATA_KEYS := ["copy_index", "serial"]


static func build(card_specs: Array, id_prefix: String = "card", starting_serial: int = 1) -> Dictionary:
	if card_specs.is_empty():
		return _error("DECK_SPECS_EMPTY", "At least one card specification is required.")
	var prefix_check: Dictionary = CardDefinition._validate_id(id_prefix, "DECK_PREFIX")
	if not prefix_check["ok"]:
		return prefix_check
	if starting_serial < 1:
		return _error("DECK_SERIAL_INVALID", "starting_serial must be a positive integer.")

	var definitions: Array = []
	var instances: Array = []
	var definition_ids: Dictionary = {}
	var serial: int = starting_serial
	var total_requested: int = 0
	for raw_spec in card_specs:
		if not raw_spec is Dictionary:
			return _error("DECK_SPEC_INVALID", "Each card specification must be a Dictionary.")
		var spec: Dictionary = raw_spec
		for raw_key in spec.keys():
			if not raw_key is String or raw_key not in ALLOWED_SPEC_KEYS:
				return _error("DECK_SPEC_KEYS_INVALID", "Card specification contains an unknown key.")
		var definition_id: Variant = spec.get("id", "")
		var count: Variant = spec.get("count", 1)
		var attributes: Variant = spec.get("attributes", {})
		var tags: Variant = spec.get("tags", [])
		var instance_metadata: Variant = spec.get("instance_metadata", {})
		if not definition_id is String:
			return _error("DECK_DEFINITION_ID_INVALID", "Card specification id must be a String.")
		var definition_id_check: Dictionary = CardDefinition._validate_id(definition_id, "DECK_DEFINITION_ID")
		if not definition_id_check["ok"]:
			return definition_id_check
		if not count is int or count <= 0:
			return _error("DECK_COUNT_INVALID", "Card specification count must be positive.")
		if definition_ids.has(definition_id):
			return _error("DECK_DEFINITION_DUPLICATE", "Card definition ids must be unique.")
		if not attributes is Dictionary or not tags is Array or not instance_metadata is Dictionary:
			return _error("DECK_SPEC_DATA_INVALID", "attributes, tags and instance_metadata fields are invalid.")
		var metadata_check: Dictionary = PureDataValidator.validate(instance_metadata, "$.deck.instance_metadata")
		if not metadata_check["ok"]:
			return metadata_check
		for reserved_key in RESERVED_INSTANCE_METADATA_KEYS:
			if instance_metadata.has(reserved_key):
				return _error("DECK_INSTANCE_METADATA_RESERVED", "instance_metadata cannot define reserved key: %s" % reserved_key)
		total_requested += count
		if total_requested > MAX_INSTANCES:
			return _error("DECK_TOO_LARGE", "Deck exceeds the maximum instance count of %d." % MAX_INSTANCES)

		var definition_result: Dictionary = CardDefinition.create(definition_id, attributes, tags)
		if not definition_result["ok"]:
			return definition_result
		definitions.append(definition_result["value"])
		definition_ids[definition_id] = true
		for copy_index in range(count):
			var instance_id: String = "%s-%05d" % [id_prefix, serial]
			var instance_id_check: Dictionary = CardDefinition._validate_id(instance_id, "CARD_INSTANCE_ID")
			if not instance_id_check["ok"]:
				return instance_id_check
			var metadata: Dictionary = instance_metadata.duplicate(true)
			metadata["copy_index"] = copy_index
			metadata["serial"] = serial
			var instance_result: Dictionary = CardInstance.create(instance_id, definition_id, metadata)
			if not instance_result["ok"]:
				return instance_result
			instances.append(instance_result["value"])
			serial += 1

	var instance_ids: Array = []
	for instance in instances:
		instance_ids.append(instance["id"])
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"definitions": definitions,
		"instances": instances,
		"instance_ids": instance_ids,
		"next_serial": serial,
	}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
