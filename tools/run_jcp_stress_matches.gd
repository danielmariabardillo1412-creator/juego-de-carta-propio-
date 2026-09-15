extends SceneTree
## Simulador adversarial reproducible del juego de cartas propio.
##
## Ejecutar, por ejemplo:
##   godot --headless --path . --script res://tools/run_jcp_stress_matches.gd -- --games=2000
##
## Cada semilla usa una politica determinista distinta. Ante un fallo se conserva
## la semilla, el paso, la accion y el snapshot completo para poder reproducirlo.

const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameAction = preload("res://src/core/game_action.gd")
const ReplayService = preload("res://src/persistence/replay_service.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")

const SUMMARY_BASE := "res://diagnostic_logs/jcp_stress"
const DEFAULT_GAMES := 2000
const DEFAULT_MAX_ACTIONS := 900
const REPLAY_SAMPLE_INTERVAL := 500
const READ_SAMPLE_INTERVAL := 101

const FORCED_ACTIONS := [
	"choose_fusion_combat_bonus",
	"decline_redirect",
	"redirect_attack",
]

var _games_target := DEFAULT_GAMES
var _max_actions := DEFAULT_MAX_ACTIONS
var _start_seed := 0
var _report_tag := "latest"
var _total_actions := 0
var _max_actions_seen := 0
var _replays_checked := 0
var _finish_reasons: Dictionary = {}
var _action_counts: Dictionary = {}
var _policy_counts: Dictionary = {}
var _life_profile_counts: Dictionary = {}
var _tied_matches := 0
var _failure: Dictionary = {}
var _started_at_msec := 0
var _balance_mode := false
var _balance_cards: Dictionary = {}
var _balance_wins_by_seat := {"0": 0, "1": 0}
var _balance_first_player_wins := 0
var _balance_decided_matches := 0
var _balance_turns_total := 0
var _balance_openings_without_creature := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	_parse_arguments()
	_started_at_msec = Time.get_ticks_msec()
	for game_index in range(_games_target):
		var seed := _start_seed + game_index
		var result: Dictionary = _run_match(seed, game_index)
		if not result["ok"]:
			_failure = result
			_write_json(_failure_path(), result)
			_finish(game_index)
			return
		if _balance_mode and (game_index + 1) % 2 == 0:
			_write_json(_summary_path(), _summary(game_index + 1, "RUNNING"))
			print("JCP-BALANCE progreso: %d/%d partidas" % [game_index + 1, _games_target])
		if (game_index + 1) % 100 == 0:
			print("JCP-STRESS progreso: %d/%d partidas" % [game_index + 1, _games_target])
	_finish(_games_target)


func _run_match(seed: int, game_index: int) -> Dictionary:
	# La mayoria de partidas usa vida abreviada para multiplicar recorridos de
	# combate; una de cada diez conserva los 30 puntos reglamentarios completos.
	var life_profiles := [1, 1, 1, 1, 1, 1, 1, 3, 8, 30]
	var starting_life: int = 30 if _balance_mode else life_profiles[game_index % life_profiles.size()]
	var config := {
		"player_names": ["Bot A", "Bot B"],
		"starting_player": seed % 2,
		"starting_life": starting_life,
	}
	_increment(_life_profile_counts, str(starting_life))
	var engine = UniversalCardEngine.new(GameModule.new(), config)
	if not engine.is_ready():
		return _failure_result("construction", seed, 0, {}, engine.construction_error(), engine)
	var started = engine.start(seed)
	if not started.success:
		return _failure_result("start", seed, 0, {}, _engine_error(started), engine)
	var initial_state: Dictionary = engine.export_module_state() if _balance_mode else {}
	var played_by_player := {"0": {}, "1": {}}
	if _balance_mode:
		for player_id in [0, 1]:
			var hand: Array = initial_state["cards"]["zones"]["hand:%d" % player_id]["cards"]
			var has_creature := false
			for instance_id in hand:
				var definition_id: String = initial_state["cards"]["instances"][instance_id]["definition_id"]
				if definition_id.begins_with("M"):
					has_creature = true
			if not has_creature:
				_balance_openings_without_creature += 1

	# Emparejar cada politica con ambos jugadores iniciales en semillas consecutivas.
	var policy_id := (int(seed / 2) % 4) if _balance_mode else seed % 4
	var policy_name: String = ["uniform", "development", "aggressive", "reactive"][policy_id]
	_increment(_policy_counts, policy_name)
	var rng_result: Dictionary = DeterministicRng.create(seed + 1000003)
	if not rng_result["ok"]:
		return _failure_result("rng", seed, 0, {}, rng_result, engine)
	var rng_state: Dictionary = rng_result["value"]
	var step := 0

	while engine.lifecycle_name() == "RUNNING" and step < _max_actions:
		if step == 0 or step % READ_SAMPLE_INTERVAL == 0:
			var read_check: Dictionary = _check_read_boundaries(engine)
			if not read_check["ok"]:
				return _failure_result("read_boundary", seed, step, {}, read_check, engine)
		var actor_actions: Dictionary = _acting_player_and_actions(engine)
		if not actor_actions["ok"]:
			return _failure_result("legal_action_deadlock", seed, step, {}, actor_actions, engine)
		var pick: Dictionary = _pick_action(actor_actions["actions"], policy_id, rng_state)
		if not pick["ok"]:
			return _failure_result("action_selection", seed, step, {}, pick, engine)
		rng_state = pick["rng_state"]
		var selected: Dictionary = pick["action"]
		if _balance_mode and selected["type"] in ["summon_creature", "set_creature", "set_support", "play_persistent", "equip_item", "play_main_spell", "play_terrain", "activate_reaction"]:
			var instance_id: String = selected["payload"].get("instance_id", "")
			if not instance_id.is_empty():
				var pre_state: Dictionary = engine.export_module_state()
				var instance: Dictionary = pre_state["cards"]["instances"].get(instance_id, {})
				if not instance.is_empty():
					played_by_player[str(actor_actions["actor_id"])][instance["definition_id"]] = true
		var request_id := "stress-%d-%d" % [seed, step]
		var before_version: int = engine.state_version()
		var action = GameAction.new(selected["type"], actor_actions["actor_id"], selected["payload"], request_id)
		var applied = engine.perform_action(action)
		if not applied.success:
			return _failure_result("advertised_action_rejected", seed, step, selected, _engine_error(applied), engine)
		if engine.state_version() != before_version + 1:
			return _failure_result("version_not_incremented_once", seed, step, selected, {
				"expected": before_version + 1,
				"actual": engine.state_version(),
			}, engine)
		_increment(_action_counts, selected["type"])
		step += 1

	if engine.lifecycle_name() != "FINISHED":
		return _failure_result("action_limit", seed, step, {}, {
			"message": "La partida no termino dentro del limite.",
			"max_actions": _max_actions,
		}, engine)
	var final_consistency: Dictionary = engine.validate_internal_consistency()
	if not final_consistency["ok"]:
		return _failure_result("final_consistency", seed, step, {}, final_consistency, engine)
	if not engine.get_legal_actions(0).is_empty() or not engine.get_legal_actions(1).is_empty():
		return _failure_result("terminal_actions", seed, step, {}, {"message": "El estado final aun anuncia acciones."}, engine)
	var state: Dictionary = engine.export_module_state()
	var reason: String = state.get("finished_reason", "")
	if reason not in ["life_zero", "deck_empty"]:
		return _failure_result("finish_reason", seed, step, {}, {"actual": reason}, engine)
	var winners: Array = state.get("winner_ids", [])
	if winners.is_empty():
		if reason != "life_zero" or state["life"].values().count(0) != 2:
			return _failure_result("winner_count", seed, step, {}, {"actual": winners, "life": state["life"]}, engine)
		_tied_matches += 1
	elif winners.size() != 1:
		return _failure_result("winner_count", seed, step, {}, {"actual": winners}, engine)
	if _balance_mode:
		_balance_turns_total += state["turn"]["turn_number"]
		if winners.size() == 1:
			_balance_decided_matches += 1
			_increment(_balance_wins_by_seat, str(winners[0]))
			if winners[0] == config["starting_player"]:
				_balance_first_player_wins += 1
		for player_id in [0, 1]:
			var deck: Array = state["cards"]["zones"]["deck:%d" % player_id]["cards"]
			var seen: Dictionary = {}
			for instance_id in initial_state["cards"]["instances"]:
				var instance: Dictionary = initial_state["cards"]["instances"][instance_id]
				if instance["metadata"]["owner_id"] == player_id and not deck.has(instance_id):
					seen[instance["definition_id"]] = true
			for definition_id in seen:
				var metric: Dictionary = _balance_card_metric(definition_id)
				metric["seen"] += 1
				if winners.has(player_id):
					metric["won_when_seen"] += 1
				_balance_cards[definition_id] = metric
			for definition_id in played_by_player[str(player_id)]:
				var metric: Dictionary = _balance_card_metric(definition_id)
				metric["played"] += 1
				if winners.has(player_id):
					metric["won_when_played"] += 1
				_balance_cards[definition_id] = metric

	# El primer lote y una muestra regular reconstruyen el snapshot completo.
	if game_index < 2 or game_index % REPLAY_SAMPLE_INTERVAL == 0:
		var replay: Dictionary = ReplayService.replay(GameModule.new(), config, engine.export_runtime_snapshot())
		if not replay["ok"]:
			return _failure_result("replay", seed, step, {}, replay, engine)
		_replays_checked += 1

	_total_actions += step
	_max_actions_seen = maxi(_max_actions_seen, step)
	_increment(_finish_reasons, reason)
	return {"ok": true}


func _acting_player_and_actions(engine: Object) -> Dictionary:
	var first: Array = engine.get_legal_actions(0)
	var second: Array = engine.get_legal_actions(1)
	if first.is_empty() == second.is_empty():
		return {
			"ok": false,
			"message": "Debe existir exactamente un jugador con prioridad.",
			"player_0_actions": first.size(),
			"player_1_actions": second.size(),
		}
	return {
		"ok": true,
		"actor_id": 0 if not first.is_empty() else 1,
		"actions": first if not first.is_empty() else second,
	}


func _check_read_boundaries(engine: Object) -> Dictionary:
	var digest_before: Dictionary = engine.state_digest()
	if not digest_before["ok"]:
		return digest_before
	var public_view: Dictionary = engine.get_public_state()
	var player_zero: Dictionary = engine.get_player_state(0)
	var player_one: Dictionary = engine.get_player_state(1)
	for view in [public_view, player_zero, player_one]:
		if view.get("game", {}).has("view_error"):
			return {"ok": false, "message": "Una vista valida devolvio view_error.", "view_error": view["game"]["view_error"]}
	var digest_after: Dictionary = engine.state_digest()
	if not digest_after["ok"] or digest_after["value"] != digest_before["value"]:
		return {"ok": false, "message": "Consultar vistas o acciones muto el estado."}
	return {"ok": true}


func _pick_action(actions: Array, policy_id: int, rng_state: Dictionary) -> Dictionary:
	var candidates: Array = []
	for action in actions:
		if action["type"] != "concede":
			candidates.append(action)
	if candidates.is_empty():
		return {"ok": false, "message": "Solo se anuncio la rendicion en una partida activa."}
	for forced_type in FORCED_ACTIONS:
		var forced: Array = candidates.filter(func(action: Dictionary) -> bool: return action["type"] == forced_type)
		if not forced.is_empty():
			return _random_member(forced, rng_state)

	var weighted: Array = []
	for candidate in candidates:
		var weight := _action_weight(candidate["type"], policy_id)
		for _copy in range(weight):
			weighted.append(candidate)
	return _random_member(weighted, rng_state)


func _action_weight(action_type: String, policy_id: int) -> int:
	if policy_id == 0:
		return {
			"advance_phase": 5, "summon_creature": 12, "set_creature": 4,
			"fuse_creatures": 9, "change_position": 6, "attack": 18,
			"activate_reaction": 8, "pass_reaction": 4,
		}.get(action_type, 5)
	if policy_id == 1:
		return {
			"advance_phase": 2, "summon_creature": 12, "set_creature": 7,
			"set_support": 10, "play_terrain": 10, "equip_item": 10,
			"play_persistent": 10, "play_main_spell": 10, "fuse_creatures": 14,
			"activate_creature_ability": 8, "activate_fusion_ability": 8,
			"relocate_equipment": 7, "change_position": 4, "attack": 8,
			"activate_reaction": 8, "pass_reaction": 3,
		}.get(action_type, 2)
	if policy_id == 2:
		return {
			"advance_phase": 5, "summon_creature": 12, "set_creature": 2,
			"fuse_creatures": 10, "change_position": 8, "attack": 20,
			"activate_creature_ability": 7, "activate_fusion_ability": 9,
			"activate_reaction": 7, "pass_reaction": 4,
		}.get(action_type, 4)
	return {
		"advance_phase": 4, "summon_creature": 7, "set_creature": 10,
		"set_support": 16, "play_persistent": 12, "play_main_spell": 8,
		"equip_item": 9, "fuse_creatures": 7, "attack": 10,
		"activate_reaction": 20, "pass_reaction": 2,
	}.get(action_type, 5)


func _random_member(values: Array, rng_state: Dictionary) -> Dictionary:
	var draw: Dictionary = DeterministicRng.next_int(rng_state, values.size())
	if not draw["ok"]:
		return draw
	return {
		"ok": true,
		"action": values[draw["value"]],
		"rng_state": draw["state"],
	}


func _failure_result(stage: String, seed: int, step: int, action: Dictionary, detail: Dictionary, engine: Object) -> Dictionary:
	return {
		"ok": false,
		"stage": stage,
		"seed": seed,
		"step": step,
		"action": action.duplicate(true),
		"detail": detail.duplicate(true),
		"snapshot": engine.export_runtime_snapshot() if engine != null else {},
	}


func _engine_error(result: Object) -> Dictionary:
	return {"code": result.code, "message": result.message}


func _parse_arguments() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--games="):
			_games_target = maxi(1, int(argument.trim_prefix("--games=")))
		elif argument.begins_with("--max-actions="):
			_max_actions = maxi(1, int(argument.trim_prefix("--max-actions=")))
		elif argument.begins_with("--start-seed="):
			_start_seed = maxi(0, int(argument.trim_prefix("--start-seed=")))
		elif argument.begins_with("--report-tag="):
			var candidate := argument.trim_prefix("--report-tag=")
			if candidate.is_valid_identifier():
				_report_tag = candidate
		elif argument == "--balance":
			_balance_mode = true


func _increment(counts: Dictionary, key: String) -> void:
	counts[key] = counts.get(key, 0) + 1


func _finish(games_completed: int) -> void:
	var summary := _summary(games_completed, "PASS" if _failure.is_empty() else "FAIL")
	_write_json(_summary_path(), summary)
	if _failure.is_empty():
		print("JCP-STRESS PASS: %d games, %d actions, %d replays, %d ms" % [games_completed, _total_actions, _replays_checked, summary["elapsed_msec"]])
		print(JSON.stringify(summary, "\t"))
		quit(0)
		return
	printerr("JCP-STRESS FAIL: seed=%s step=%s stage=%s" % [_failure.get("seed"), _failure.get("step"), _failure.get("stage")])
	printerr("Failure report: %s" % ProjectSettings.globalize_path(_failure_path()))
	quit(1)


func _summary(games_completed: int, status: String) -> Dictionary:
	var elapsed_msec := Time.get_ticks_msec() - _started_at_msec
	var summary := {
		"status": status,
		"games_requested": _games_target,
		"games_completed": games_completed,
		"start_seed": _start_seed,
		"last_seed": _start_seed + maxi(0, games_completed - 1),
		"total_actions": _total_actions,
		"maximum_actions_in_match": _max_actions_seen,
		"replays_checked": _replays_checked,
		"finish_reasons": _finish_reasons,
		"policy_counts": _policy_counts,
		"starting_life_counts": _life_profile_counts,
		"tied_matches": _tied_matches,
		"action_counts": _action_counts,
		"elapsed_msec": elapsed_msec,
	}
	if _balance_mode:
		summary["balance_observation"] = {
			"method": "full_life_30_mirrored_decks_paired_starting_seats_weighted_policies",
			"warning": "Bot-vs-bot correlations are not causal card power or human play data.",
			"decided_matches": _balance_decided_matches,
			"wins_by_seat": _balance_wins_by_seat,
			"first_player_wins": _balance_first_player_wins,
			"turns_total": _balance_turns_total,
			"openings_without_creature": _balance_openings_without_creature,
			"cards": _balance_cards,
		}
	if not _failure.is_empty():
		summary["failure_stage"] = _failure.get("stage", "unknown")
		summary["failure_seed"] = _failure.get("seed", -1)
	return summary


func _summary_path() -> String:
	return "%s_%s.json" % [SUMMARY_BASE, _report_tag]


func _failure_path() -> String:
	return "%s_failure_%s.json" % [SUMMARY_BASE, _report_tag]


func _write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("No se pudo escribir %s" % path)
		return
	file.store_string(JSON.stringify(value, "\t") + "\n")


func _balance_card_metric(definition_id: String) -> Dictionary:
	return _balance_cards.get(definition_id, {"seen": 0, "played": 0, "won_when_seen": 0, "won_when_played": 0}).duplicate()
