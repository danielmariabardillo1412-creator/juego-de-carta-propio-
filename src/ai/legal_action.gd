extends RefCounted
## Backward-compatible facade. The legal-action contract belongs to core; AI is
## only one consumer of it. New code should preload res://src/core/legal_action.gd.

const CoreLegalAction = preload("res://src/core/legal_action.gd")


static func create(
	action_type: String,
	actor_id: int,
	payload: Dictionary = {},
	label: String = "",
	metadata: Dictionary = {}
) -> Dictionary:
	return CoreLegalAction.create(action_type, actor_id, payload, label, metadata)


static func validate(value: Variant, expected_actor_id: int = -1) -> Dictionary:
	return CoreLegalAction.validate(value, expected_actor_id)
