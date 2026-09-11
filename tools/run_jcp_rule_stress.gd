extends SceneTree
## Fuzzing rapido de partidas completas contra el modulo de reglas.
## UCE conserva una segunda puerta, mas lenta, en run_jcp_stress_matches.gd.

const GameAction = preload("res://src/core/game_action.gd")
const ModuleProtocol = preload("res://src/core/module_protocol.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")
const StateDigest = preload("res://src/state/state_digest.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

const SUMMARY_BASE := "res://diagnostic_logs/jcp_rule_stress"
const DEFAULT_GAMES := 5000
const DEFAULT_MAX_ACTIONS := 900

var _games_target := DEFAULT_GAMES
var _start_seed := 0
var _max_actions := DEFAULT_MAX_ACTIONS
var _report_tag := "latest"
var _actions_total := 0
var _actions_max := 0
var _finish_reasons: Dictionary = {}
var _action_counts: Dictionary = {}
var _ties := 0
var _failure: Dictionary = {}
var _started_at := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_parse_arguments()
	_started_at = Time.get_ticks_msec()
	for index in range(_games_target):
		var result := _run_match(_start_seed + index, index)
		if not result["ok"]:
			_failure = result
			_write_json(_failure_path(), result)
			_finish(index)
			return
		if (index + 1) % 50 == 0:
			print("JCP-RULE-STRESS progreso: %d/%d" % [index + 1, _games_target])
	_finish(_games_target)


func _run_match(seed: int, game_index: int) -> Dictionary:
	var life_profiles := [1, 1, 1, 1, 1, 1, 1, 1, 3, 8]
	var config := {
		"player_names": ["Bot A", "Bot B"],
		"starting_player": seed % 2,
		"starting_life": life_profiles[game_index % life_profiles.size()],
	}
	var module = GameModule.new()
	var state: Dictionary = module.create_initial_state(config, seed)
	var initial_check: Dictionary = module.validate_state(state)
	if not initial_check["ok"]:
		return _fail("initial_state", seed, 0, {}, initial_check, state, [])
	var rng_create: Dictionary = DeterministicRng.create(seed + 1000003)
	if not rng_create["ok"]:
		return _fail("rng", seed, 0, {}, rng_create, state, [])
	var rng_state: Dictionary = rng_create["value"]
	var action_log: Array = []
	var step := 0

	while not module.is_finished(state) and step < _max_actions:
		var first: Array = module.get_legal_actions(state.duplicate(true), 0)
		var second: Array = module.get_legal_actions(state.duplicate(true), 1)
		var first_check := ModuleProtocol.validate_legal_actions(first, 0)
		var second_check := ModuleProtocol.validate_legal_actions(second, 1)
		if not first_check["ok"] or not second_check["ok"]:
			return _fail("legal_action_shape", seed, step, {}, first_check if not first_check["ok"] else second_check, state, action_log)
		if first.is_empty() == second.is_empty():
			return _fail("legal_action_deadlock", seed, step, {}, {"player_0": first.size(), "player_1": second.size()}, state, action_log)
		var actor_id := 0 if not first.is_empty() else 1
		var legal: Array = first if actor_id == 0 else second
		var picked := _pick_action(legal, seed % 8, rng_state)
		if not picked["ok"]:
			return _fail("selection", seed, step, {}, picked, state, action_log)
		rng_state = picked["rng_state"]
		var selected: Dictionary = picked["action"]
		var action = GameAction.new(selected["type"], actor_id, selected["payload"], "rule-%d-%d" % [seed, step])
		var validation: Dictionary = module.validate_action(state.duplicate(true), action)
		if not validation["ok"]:
			return _fail("advertised_action_rejected", seed, step, selected, validation, state, action_log)
		var transition: Dictionary = module.reduce(state.duplicate(true), action)
		var transition_check: Dictionary = ModuleProtocol.validate_transition(transition)
		if not transition_check["ok"] or not transition.get("ok", false):
			return _fail("transition", seed, step, selected, transition_check if not transition_check["ok"] else transition, state, action_log)
		# validate_action() valida profundamente el estado al comienzo del siguiente
		# paso; validate_transition() ya valida todos los eventos. Evitar repetirlos
		# aqui mantiene la misma cobertura y reduce a la mitad el coste del lote.
		var next_state: Dictionary = transition["state"]
		action_log.append(action.to_dict())
		state = next_state
		_increment(_action_counts, selected["type"])
		step += 1

	if not module.is_finished(state):
		return _fail("action_limit", seed, step, {}, {"max_actions": _max_actions}, state, action_log)
	var final_state_check: Dictionary = module.validate_state(state)
	if not final_state_check["ok"]:
		return _fail("final_state", seed, step, {}, final_state_check, state, action_log)
	var reason: String = state.get("finished_reason", "")
	if reason not in ["life_zero", "deck_empty"]:
		return _fail("finish_reason", seed, step, {}, {"actual": reason}, state, action_log)
	var winners: Array = state.get("winner_ids", [])
	if winners.is_empty():
		if reason != "life_zero" or state["life"].values().count(0) != 2:
			return _fail("winner_count", seed, step, {}, {"winners": winners, "life": state["life"]}, state, action_log)
		_ties += 1
	elif winners.size() != 1:
		return _fail("winner_count", seed, step, {}, {"winners": winners}, state, action_log)
	var digest: Dictionary = StateDigest.sha256(state)
	if not digest["ok"]:
		return _fail("final_digest", seed, step, {}, digest, state, action_log)
	_actions_total += step
	_actions_max = maxi(_actions_max, step)
	_increment(_finish_reasons, reason)
	return {"ok": true}


func _pick_action(actions: Array, policy_id: int, rng_state: Dictionary) -> Dictionary:
	var weighted: Array = []
	for action in actions:
		if action["type"] == "concede":
			continue
		var weight := _weight(action["type"], policy_id)
		for _copy in range(weight):
			weighted.append(action)
	if weighted.is_empty():
		return {"ok": false, "message": "Solo queda rendicion."}
	var draw: Dictionary = DeterministicRng.next_int(rng_state, weighted.size())
	if not draw["ok"]:
		return draw
	return {"ok": true, "action": weighted[draw["value"]], "rng_state": draw["state"]}


func _weight(action_type: String, policy_id: int) -> int:
	# Las decisiones obligatorias no deben competir con acciones ordinarias.
	if action_type in ["choose_fusion_combat_bonus", "decline_redirect", "redirect_attack"]:
		return 30
	var common := {
		"advance_phase": 5, "summon_creature": 12, "set_creature": 5,
		"set_support": 9, "play_terrain": 8, "equip_item": 8,
		"play_persistent": 8, "play_main_spell": 9, "fuse_creatures": 11,
		"activate_creature_ability": 8, "activate_fusion_ability": 9,
		"relocate_equipment": 7, "change_position": 6, "attack": 18,
		"activate_reaction": 12, "pass_reaction": 4,
	}
	var weight: int = common.get(action_type, 5)
	if policy_id == 1 and action_type in ["set_support", "play_terrain", "equip_item", "play_persistent", "fuse_creatures"]:
		weight += 10
	elif policy_id == 2 and action_type in ["summon_creature", "change_position", "attack"]:
		weight += 12
	elif policy_id == 3 and action_type in ["set_support", "activate_reaction", "play_main_spell"]:
		weight += 14
	elif policy_id == 4:
		# Fuerza partidas anormalmente pasivas para recorrer agotamiento de baraja.
		weight = 35 if action_type == "advance_phase" else 1
	elif policy_id == 5:
		weight = {
			"summon_creature": 24, "fuse_creatures": 40,
			"activate_fusion_ability": 30, "advance_phase": 5, "attack": 12,
		}.get(action_type, 3)
	elif policy_id == 6:
		weight = {
			"summon_creature": 18, "equip_item": 35, "relocate_equipment": 40,
			"play_persistent": 22, "advance_phase": 5, "attack": 10,
		}.get(action_type, 4)
	elif policy_id == 7:
		weight = {
			"set_creature": 24, "set_support": 35, "change_position": 20,
			"activate_reaction": 35, "pass_reaction": 2,
			"advance_phase": 5, "attack": 12,
		}.get(action_type, 4)
	return weight


func _fail(stage: String, seed: int, step: int, action: Dictionary, detail: Dictionary, state: Dictionary, actions: Array) -> Dictionary:
	return {"ok": false, "stage": stage, "seed": seed, "step": step, "action": action, "detail": detail, "state": state, "actions": actions}


func _increment(counts: Dictionary, key: String) -> void:
	counts[key] = counts.get(key, 0) + 1


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			_games_target = maxi(1, int(argument.trim_prefix("--games=")))
		elif argument.begins_with("--start-seed="):
			_start_seed = maxi(0, int(argument.trim_prefix("--start-seed=")))
		elif argument.begins_with("--max-actions="):
			_max_actions = maxi(1, int(argument.trim_prefix("--max-actions=")))
		elif argument.begins_with("--report-tag="):
			var candidate := argument.trim_prefix("--report-tag=")
			if candidate.is_valid_identifier():
				_report_tag = candidate


func _finish(games_completed: int) -> void:
	var summary := {
		"status": "PASS" if _failure.is_empty() else "FAIL",
		"games_requested": _games_target,
		"games_completed": games_completed,
		"start_seed": _start_seed,
		"last_seed": _start_seed + maxi(0, games_completed - 1),
		"total_actions": _actions_total,
		"maximum_actions_in_match": _actions_max,
		"finish_reasons": _finish_reasons,
		"tied_matches": _ties,
		"action_counts": _action_counts,
		"elapsed_msec": Time.get_ticks_msec() - _started_at,
	}
	if not _failure.is_empty():
		summary["failure_seed"] = _failure["seed"]
		summary["failure_stage"] = _failure["stage"]
	_write_json(_summary_path(), summary)
	if _failure.is_empty():
		print("JCP-RULE-STRESS PASS: %d games, %d actions, %d ms" % [games_completed, _actions_total, summary["elapsed_msec"]])
		print(JSON.stringify(summary, "\t"))
		quit(0)
		return
	printerr("JCP-RULE-STRESS FAIL: seed=%s step=%s stage=%s" % [_failure["seed"], _failure["step"], _failure["stage"]])
	quit(1)


func _summary_path() -> String:
	return "%s_%s.json" % [SUMMARY_BASE, _report_tag]


func _failure_path() -> String:
	return "%s_failure_%s.json" % [SUMMARY_BASE, _report_tag]


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(value, "\t") + "\n")
