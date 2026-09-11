extends "res://tests/fixtures/minimal_turn_module.gd"
## Hostile fixture that leaks a non-portable Object in its public view.


func get_public_state(_state: Dictionary) -> Dictionary:
	return {"leaked_object": RefCounted.new()}
