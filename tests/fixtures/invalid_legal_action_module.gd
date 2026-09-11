extends "res://tests/fixtures/minimal_turn_module.gd"
## Hostile fixture that advertises an action for a different actor.


func get_legal_actions(_state: Dictionary, viewer_id: int) -> Array:
	return [{
		"type": "pass",
		"actor_id": viewer_id + 1,
		"payload": {},
		"label": "Invalid actor",
		"metadata": {},
	}]
