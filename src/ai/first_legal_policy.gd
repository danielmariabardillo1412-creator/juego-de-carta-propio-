extends RefCounted
## Deterministic baseline bot: selects the first legal action.


func choose_action(actions: Array, _state: Dictionary, _actor_id: int) -> Dictionary:
	return actions[0].duplicate(true)
