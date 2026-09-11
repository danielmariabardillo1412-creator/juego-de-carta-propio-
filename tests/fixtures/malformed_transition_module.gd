extends "res://tests/fixtures/minimal_turn_module.gd"
## Hostile fixture that returns an unknown field in a successful transition.


func reduce(state: Dictionary, action: Object) -> Dictionary:
	var base: Dictionary = super.reduce(state, action)
	base["unexpected"] = true
	return base
