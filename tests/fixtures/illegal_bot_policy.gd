extends RefCounted
## Returns a structurally valid action that was not actually advertised.


func choose_action(actions: Array, _state: Dictionary, _actor_id: int) -> Dictionary:
	var selected: Dictionary = actions[0].duplicate(true)
	selected["label"] = "%s (forged)" % selected["label"]
	return selected
