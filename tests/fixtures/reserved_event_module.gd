extends "res://tests/fixtures/minimal_turn_module.gd"
## Hostile fixture that attempts to emit an event in the engine_ namespace.


func reduce(state: Dictionary, action: Object) -> Dictionary:
	var base: Dictionary = super.reduce(state, action)
	if base.get("ok", false):
		base["events"] = [{"type": "engine_closed", "payload": {}}]
	return base
