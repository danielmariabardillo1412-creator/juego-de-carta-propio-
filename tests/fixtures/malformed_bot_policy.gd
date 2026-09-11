extends RefCounted
## Returns an incomplete legal-action envelope.


func choose_action(_actions: Array, _state: Dictionary, actor_id: int) -> Dictionary:
	return {"type": "pass", "actor_id": actor_id}
