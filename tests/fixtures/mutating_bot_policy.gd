extends RefCounted
## Mutates its private arguments to prove the adapter isolates caller/module data.


func choose_action(actions: Array, state: Dictionary, _actor_id: int) -> Dictionary:
	var selected: Dictionary = actions[0].duplicate(true)
	actions[0]["type"] = "tampered_inside_policy"
	state["policy_tamper"] = true
	return selected
