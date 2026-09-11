extends "res://tests/fixtures/minimal_turn_module.gd"
## Hostile fixture whose advertised version changes after construction.

var _version_calls: int = 0


func module_version() -> String:
	_version_calls += 1
	return "1.%d" % _version_calls
