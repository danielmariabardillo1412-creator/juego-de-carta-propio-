extends Button
## Hitbox existente con recepción de drag; la legalidad viene de acciones UCE recibidas.

signal creature_dropped(instance_id: String, player_id: int, visual_slot: int)

var player_id := -1
var visual_slot := -1
var allowed_creature_ids: Array = []


func configure_drop(p_player_id: int, p_visual_slot: int, p_allowed_ids: Array) -> void:
	player_id = p_player_id
	visual_slot = p_visual_slot
	allowed_creature_ids = p_allowed_ids.duplicate()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "creature_from_hand" and data.get("instance_id", "") in allowed_creature_ids


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(at_position, data):
		creature_dropped.emit(data["instance_id"], player_id, visual_slot)
