extends RefCounted
## Estado pequeño de intención visual. No modifica el duelo ni decide legalidad.

enum Phase { IDLE, SOURCE_SELECTED, TARGET_SELECTION, MODE_SELECTION }

var phase: Phase = Phase.IDLE
var source_id := ""
var candidate_actions: Array = []
var legal_destinations: Array = []
var target_slot := -1
var pending_mode := ""
var cancellable := false


func begin_source(instance_id: String, actions: Array) -> void:
	reset()
	source_id = instance_id
	candidate_actions = actions.duplicate(true)
	phase = Phase.SOURCE_SELECTED
	cancellable = true


func set_destinations(slots: Array) -> void:
	legal_destinations = slots.duplicate()
	phase = Phase.TARGET_SELECTION if not slots.is_empty() else Phase.SOURCE_SELECTED


func choose_target(slot: int, actions: Array) -> void:
	target_slot = slot
	candidate_actions = actions.duplicate(true)
	phase = Phase.MODE_SELECTION


func reset() -> void:
	phase = Phase.IDLE
	source_id = ""
	candidate_actions = []
	legal_destinations = []
	target_slot = -1
	pending_mode = ""
	cancellable = false


func snapshot() -> Dictionary:
	return {
		"phase": Phase.keys()[phase],
		"source_id": source_id,
		"candidate_count": candidate_actions.size(),
		"legal_destinations": legal_destinations.duplicate(),
		"target_slot": target_slot,
		"pending_mode": pending_mode,
		"cancellable": cancellable,
	}
