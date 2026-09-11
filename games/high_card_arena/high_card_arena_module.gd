extends RefCounted
## Complete example game for the universal engine.
##
## High Card Arena supports 2-4 players. Each player receives a private hand,
## plays one card per round, and the unique highest numeric card earns one point.
## Tied rounds award no point. The match ends when target score is reached,
## hands are exhausted, or a player concedes.

const CardState = preload("res://src/cards/card_state.gd")
const CardRandomizer = preload("res://src/cards/card_randomizer.gd")
const CardOperations = preload("res://src/cards/card_operations.gd")
const CardQuery = preload("res://src/cards/card_query.gd")
const DeckBuilder = preload("res://src/cards/deck_builder.gd")
const DealService = preload("res://src/cards/deal_service.gd")
const ZoneDefinition = preload("res://src/cards/zone_definition.gd")
const DeterministicRng = preload("res://src/random/deterministic_rng.gd")
const PlayerRegistry = preload("res://src/session/player_registry.gd")
const TurnState = preload("res://src/turns/turn_state.gd")
const PhaseMachine = preload("res://src/turns/phase_machine.gd")
const ScoreState = preload("res://src/scoring/score_state.gd")
const LegalAction = preload("res://src/core/legal_action.gd")

const PHASE_PLAY := "PLAY"
const PHASE_FINISHED := "FINISHED"
const ACTION_PLAY_CARD := "play_card"
const ACTION_CONCEDE := "concede"
const SUITS := ["clubs", "diamonds", "hearts", "spades"]
const STATE_KEYS := [
	"cards", "config", "finished_reason", "phase", "players", "rng", "round",
	"scores", "seed", "turn", "winner_ids",
]


func module_id() -> String:
	return "example.high_card_arena"


func module_version() -> String:
	return "2.0.0-hardened"


func validate_config(config: Dictionary) -> Dictionary:
	var normalized = _normalize_config(config)
	if not normalized["ok"]:
		return normalized
	return _success()


func create_initial_state(config: Dictionary, seed: int) -> Dictionary:
	var normalized: Dictionary = _normalize_config(config)
	if not normalized["ok"]:
		return _initialization_failure(normalized)
	var game_config: Dictionary = normalized["value"]
	var players: Array = []
	var player_ids: Array = []
	for index in range(game_config["player_names"].size()):
		players.append(PlayerRegistry.make_player(index, game_config["player_names"][index], index))
		player_ids.append(index)
	var registry_result: Dictionary = PlayerRegistry.create(players)
	if not registry_result["ok"]:
		return _initialization_failure(registry_result)

	var card_specs: Array = []
	for suit in SUITS:
		for rank in range(1, 14):
			card_specs.append({
				"id": "%s-%02d" % [suit, rank],
				"count": 1,
				"attributes": {"suit": suit, "rank": rank, "value": rank},
				"tags": ["standard", suit],
			})
	var deck_result: Dictionary = DeckBuilder.build(card_specs, "arena")
	if not deck_result["ok"]:
		return _initialization_failure(deck_result)

	var zones: Array = []
	var deck_zone: Dictionary = ZoneDefinition.create("deck", ZoneDefinition.VISIBILITY_HIDDEN)
	var table_zone: Dictionary = ZoneDefinition.create(
		"table",
		ZoneDefinition.VISIBILITY_PUBLIC,
		-1,
		[],
		game_config["player_names"].size()
	)
	var discard_zone: Dictionary = ZoneDefinition.create("discard", ZoneDefinition.VISIBILITY_PUBLIC)
	for zone_result in [deck_zone, table_zone, discard_zone]:
		if not zone_result["ok"]:
			return _initialization_failure(zone_result)
	zones.append(deck_zone["value"])
	zones.append(table_zone["value"])
	zones.append(discard_zone["value"])
	var placements: Dictionary = {
		"deck": deck_result["instance_ids"].duplicate(),
		"table": [],
		"discard": [],
	}
	var hand_zone_ids: Array = []
	for player_id in player_ids:
		var zone_id: String = "hand:%d" % player_id
		var hand_zone: Dictionary = ZoneDefinition.create(
			zone_id,
			ZoneDefinition.VISIBILITY_OWNER,
			player_id,
			[],
			game_config["hand_size"]
		)
		if not hand_zone["ok"]:
			return _initialization_failure(hand_zone)
		zones.append(hand_zone["value"])
		placements[zone_id] = []
		hand_zone_ids.append(zone_id)
	var cards_result: Dictionary = CardState.create(
		deck_result["definitions"],
		deck_result["instances"],
		zones,
		placements
	)
	if not cards_result["ok"]:
		return _initialization_failure(cards_result)
	var rng_result: Dictionary = DeterministicRng.create(seed)
	if not rng_result["ok"]:
		return _initialization_failure(rng_result)
	var shuffle_result: Dictionary = CardRandomizer.shuffle_zone(cards_result["value"], "deck", rng_result["value"])
	if not shuffle_result["ok"]:
		return _initialization_failure(shuffle_result)
	var deal_result: Dictionary = DealService.deal_round_robin(
		shuffle_result["value"],
		"deck",
		hand_zone_ids,
		game_config["hand_size"],
		DealService.TAKE_FROM_END
	)
	if not deal_result["ok"]:
		return _initialization_failure(deal_result)
	var turn_result: Dictionary = TurnState.create(player_ids, game_config["starting_player"])
	if not turn_result["ok"]:
		return _initialization_failure(turn_result)
	var phase_result: Dictionary = PhaseMachine.create({
		"initial": PHASE_PLAY,
		"terminal": [PHASE_FINISHED],
		"transitions": {PHASE_PLAY: [PHASE_FINISHED], PHASE_FINISHED: []},
	})
	if not phase_result["ok"]:
		return _initialization_failure(phase_result)
	var score_result: Dictionary = ScoreState.create(player_ids, 0, game_config["target_score"])
	if not score_result["ok"]:
		return _initialization_failure(score_result)
	return {
		"seed": seed,
		"config": game_config,
		"players": registry_result["value"],
		"cards": deal_result["value"],
		"rng": shuffle_result["rng_state"],
		"turn": turn_result["value"],
		"phase": phase_result["value"],
		"scores": score_result["value"],
		"round": {"number": 1, "plays_by_player": {}, "resolved": 0},
		"winner_ids": [],
		"finished_reason": "",
	}


func validate_state(state: Dictionary) -> Dictionary:
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _failure("ARENA_STATE_KEYS_INVALID", "High Card Arena state keys are invalid.")
	if not state["seed"] is int or state["seed"] < 0:
		return _failure("ARENA_SEED_INVALID", "seed must be a non-negative integer.")
	if not state["config"] is Dictionary:
		return _failure("ARENA_CONFIG_INVALID", "config must be a Dictionary.")
	var normalized_config: Dictionary = _normalize_config(state["config"])
	if not normalized_config["ok"] or normalized_config["value"] != state["config"]:
		return _failure("ARENA_CONFIG_INVALID", "Stored config is invalid or not normalized.")

	var registry_check: Dictionary = PlayerRegistry.validate(state["players"])
	if not registry_check["ok"]:
		return registry_check
	var card_check: Dictionary = CardState.validate(state["cards"])
	if not card_check["ok"]:
		return card_check
	var rng_check: Dictionary = DeterministicRng.validate(state["rng"])
	if not rng_check["ok"]:
		return rng_check
	var turn_check: Dictionary = TurnState.validate(state["turn"])
	if not turn_check["ok"]:
		return turn_check
	var phase_check: Dictionary = PhaseMachine.validate(state["phase"])
	if not phase_check["ok"]:
		return phase_check
	var score_check: Dictionary = ScoreState.validate(state["scores"])
	if not score_check["ok"]:
		return score_check

	if not state["round"] is Dictionary:
		return _failure("ARENA_ROUND_INVALID", "round must be a Dictionary.")
	var round_state: Dictionary = state["round"]
	var round_keys: Array = round_state.keys()
	round_keys.sort()
	if round_keys != ["number", "plays_by_player", "resolved"]:
		return _failure("ARENA_ROUND_KEYS_INVALID", "round has missing or unknown keys.")
	if not round_state["number"] is int or round_state["number"] < 1:
		return _failure("ARENA_ROUND_NUMBER_INVALID", "round number must be positive.")
	if not round_state["resolved"] is int or round_state["resolved"] < 0:
		return _failure("ARENA_ROUND_RESOLVED_INVALID", "resolved round count must be non-negative.")
	if round_state["number"] != round_state["resolved"] + 1:
		return _failure("ARENA_ROUND_COUNTER_MISMATCH", "round number must equal resolved + 1.")
	if state["turn"]["round_number"] != round_state["number"]:
		return _failure("ARENA_TURN_ROUND_MISMATCH", "Turn cursor round must match arena round number.")
	if not round_state["plays_by_player"] is Dictionary:
		return _failure("ARENA_PLAYS_INVALID", "plays_by_player must be a Dictionary.")
	if not state["winner_ids"] is Array or not state["finished_reason"] is String:
		return _failure("ARENA_FINISH_DATA_INVALID", "Winner/final reason data is invalid.")

	var player_ids: Array = PlayerRegistry.player_ids(state["players"])
	if state["turn"]["order"] != player_ids:
		return _failure("ARENA_TURN_ORDER_MISMATCH", "Turn order must match player registry order.")
	var score_ids: Array = []
	for score_key in state["scores"]["scores"].keys():
		score_ids.append(int(score_key))
	score_ids.sort()
	if score_ids != player_ids:
		return _failure("ARENA_SCORE_PLAYERS_MISMATCH", "Score participants must match player ids.")

	var required_zones: Array = ["deck", "table", "discard"]
	for player_id in player_ids:
		required_zones.append("hand:%d" % player_id)
	for zone_id in required_zones:
		if not state["cards"]["zones"].has(zone_id):
			return _failure("ARENA_ZONE_MISSING", "Required zone is missing: %s" % zone_id)
	if state["cards"]["zones"].size() != required_zones.size():
		return _failure("ARENA_ZONE_EXTRA", "High Card Arena state contains an undeclared zone.")
	if state["cards"]["definitions"].size() != 52 or state["cards"]["instances"].size() != 52:
		return _failure("ARENA_DECK_SHAPE_INVALID", "High Card Arena requires exactly 52 definitions and instances.")
	var copies_by_definition: Dictionary = {}
	for instance in state["cards"]["instances"].values():
		copies_by_definition[instance["definition_id"]] = int(copies_by_definition.get(instance["definition_id"], 0)) + 1
	for suit in SUITS:
		for rank in range(1, 14):
			var expected_definition_id: String = "%s-%02d" % [suit, rank]
			if not state["cards"]["definitions"].has(expected_definition_id):
				return _failure("ARENA_CARD_DEFINITION_MISSING", "Standard card definition is missing: %s" % expected_definition_id)
			var standard_definition: Dictionary = state["cards"]["definitions"][expected_definition_id]
			if standard_definition["attributes"] != {"suit": suit, "rank": rank, "value": rank}:
				return _failure("ARENA_CARD_ATTRIBUTES_INVALID", "Standard card attributes are invalid: %s" % expected_definition_id)
			if standard_definition["tags"] != ["standard", suit]:
				return _failure("ARENA_CARD_TAGS_INVALID", "Standard card tags are invalid: %s" % expected_definition_id)
			if int(copies_by_definition.get(expected_definition_id, 0)) != 1:
				return _failure("ARENA_CARD_COPY_COUNT_INVALID", "Every standard card definition requires exactly one physical instance.")
	var deck_definition: Dictionary = state["cards"]["zones"]["deck"]["definition"]
	var table_definition: Dictionary = state["cards"]["zones"]["table"]["definition"]
	var discard_definition: Dictionary = state["cards"]["zones"]["discard"]["definition"]
	if deck_definition["visibility"] != ZoneDefinition.VISIBILITY_HIDDEN or deck_definition["public_reveal_start"] != 0 or deck_definition["public_reveal_end"] != 0:
		return _failure("ARENA_DECK_VISIBILITY_INVALID", "Deck identities must remain fully hidden.")
	if table_definition["visibility"] != ZoneDefinition.VISIBILITY_PUBLIC or table_definition["capacity"] != player_ids.size():
		return _failure("ARENA_TABLE_DEFINITION_INVALID", "Table must be public and sized to player count.")
	if discard_definition["visibility"] != ZoneDefinition.VISIBILITY_PUBLIC:
		return _failure("ARENA_DISCARD_VISIBILITY_INVALID", "Discard identities must be public.")
	for player_id in player_ids:
		var hand_definition: Dictionary = state["cards"]["zones"]["hand:%d" % player_id]["definition"]
		if hand_definition["visibility"] != ZoneDefinition.VISIBILITY_OWNER or hand_definition["owner_id"] != player_id or hand_definition["count_visibility"] != ZoneDefinition.COUNT_PUBLIC:
			return _failure("ARENA_HAND_PRIVACY_INVALID", "Each hand must be visible only to its owner.")
		if hand_definition["capacity"] != state["config"]["hand_size"]:
			return _failure("ARENA_HAND_CAPACITY_INVALID", "Hand capacity must match configured hand_size.")

	var seen_play_cards: Dictionary = {}
	for player_key in round_state["plays_by_player"].keys():
		if not player_key is String or not player_key.is_valid_int() or int(player_key) not in player_ids:
			return _failure("ARENA_PLAY_OWNER_INVALID", "Round contains an unknown player.")
		var instance_id: Variant = round_state["plays_by_player"][player_key]
		if not instance_id is String or seen_play_cards.has(instance_id):
			return _failure("ARENA_PLAY_CARD_INVALID", "Round play cards must be unique String ids.")
		seen_play_cards[instance_id] = true
		var location: Dictionary = CardState.locate_card(state["cards"], instance_id)
		if not location["ok"] or location["zone_id"] != "table":
			return _failure("ARENA_PLAY_LOCATION_INVALID", "Played card must be on the table.")
	var table_cards: Array = state["cards"]["zones"]["table"]["cards"]
	if table_cards.size() != seen_play_cards.size():
		return _failure("ARENA_TABLE_PLAY_MISMATCH", "Table cards must exactly match current round plays.")
	for table_card in table_cards:
		if not seen_play_cards.has(table_card):
			return _failure("ARENA_TABLE_PLAY_MISMATCH", "Table contains a card absent from round plays.")
	if round_state["plays_by_player"].size() >= player_ids.size():
		return _failure("ARENA_ROUND_OVERFULL", "Committed state cannot retain a fully played unresolved round.")
	var turn_order: Array = state["turn"]["order"]
	var anchor_index: int = state["turn"]["round_anchor_index"]
	var direction: int = state["turn"]["direction"]
	for play_offset in range(round_state["plays_by_player"].size()):
		var expected_player: int = turn_order[posmod(anchor_index + play_offset * direction, turn_order.size())]
		if not round_state["plays_by_player"].has(str(expected_player)):
			return _failure("ARENA_PLAY_ORDER_INVALID", "Round plays do not match turn order from the round anchor.")
	var expected_active: int = turn_order[posmod(
		anchor_index + round_state["plays_by_player"].size() * direction,
		turn_order.size()
	)]
	if TurnState.active_player(state["turn"]) != expected_active:
		return _failure("ARENA_ACTIVE_PLAYER_INVALID", "Active player does not follow committed round plays.")

	var seen_winners: Dictionary = {}
	for winner_id in state["winner_ids"]:
		if not winner_id is int or winner_id not in player_ids or seen_winners.has(winner_id):
			return _failure("ARENA_WINNER_INVALID", "winner_ids contains an invalid or duplicate player.")
		seen_winners[winner_id] = true
	var terminal: bool = PhaseMachine.is_terminal(state["phase"])
	var allowed_reasons: Array = ["", "TARGET_REACHED", "HANDS_EXHAUSTED", "CONCEDE"]
	if state["finished_reason"] not in allowed_reasons:
		return _failure("ARENA_FINISH_REASON_INVALID", "finished_reason is unknown.")
	if terminal and (state["finished_reason"].is_empty() or state["winner_ids"].is_empty()):
		return _failure("ARENA_TERMINAL_DATA_MISSING", "Terminal state requires finish reason and winners.")
	if not terminal and (not state["finished_reason"].is_empty() or not state["winner_ids"].is_empty()):
		return _failure("ARENA_PREMATURE_FINISH_DATA", "Running state cannot already contain final winners/reason.")
	var all_hands_empty: bool = true
	for player_id in player_ids:
		if not state["cards"]["zones"]["hand:%d" % player_id]["cards"].is_empty():
			all_hands_empty = false
			break
	match state["finished_reason"]:
		"":
			if ScoreState.target_reached(state["scores"]) or all_hands_empty:
				return _failure("ARENA_FINISH_CONDITION_IGNORED", "Running state already satisfies a finish condition.")
		"TARGET_REACHED":
			if not ScoreState.target_reached(state["scores"]) or state["winner_ids"] != ScoreState.leader_ids(state["scores"]):
				return _failure("ARENA_TARGET_FINISH_INVALID", "Target finish winners/score condition are inconsistent.")
		"HANDS_EXHAUSTED":
			if not all_hands_empty or ScoreState.target_reached(state["scores"]) or state["winner_ids"] != ScoreState.leader_ids(state["scores"]):
				return _failure("ARENA_HANDS_FINISH_INVALID", "Hands-exhausted finish is inconsistent.")
		"CONCEDE":
			var expected_winners: Array = []
			var conceding_player: int = TurnState.active_player(state["turn"])
			for player_id in PlayerRegistry.player_ids(state["players"], true):
				if player_id != conceding_player:
					expected_winners.append(player_id)
			if state["winner_ids"] != expected_winners:
				return _failure("ARENA_CONCEDE_WINNERS_INVALID", "Concede winners must be every other active player.")
	return _success()


func validate_viewer(state: Dictionary, viewer_id: int) -> Dictionary:
	if not state.has("players") or not state["players"] is Dictionary:
		return _failure("ARENA_PLAYERS_INVALID", "Player registry is unavailable.")
	var player_result: Dictionary = PlayerRegistry.get_player(state["players"], viewer_id)
	if not player_result["ok"]:
		return _failure("VIEWER_UNKNOWN", "Viewer is not a player in this match.")
	return _success()


func validate_action(state: Dictionary, action: Object) -> Dictionary:
	if PhaseMachine.is_terminal(state["phase"]):
		return _failure("ARENA_FINISHED", "The match is already finished.")
	var active_player: int = TurnState.active_player(state["turn"])
	if action.actor_id != active_player:
		return _failure("WRONG_ACTOR", "Only the active player may act.")
	if action.type == ACTION_CONCEDE:
		if not action.payload.is_empty():
			return _failure("CONCEDE_PAYLOAD_INVALID", "Concede requires an empty payload.")
		return _success()
	if action.type != ACTION_PLAY_CARD:
		return _failure("ACTION_UNKNOWN", "Unsupported High Card Arena action.")
	var payload_keys: Array = action.payload.keys()
	payload_keys.sort()
	if payload_keys != ["instance_id"] or not action.payload["instance_id"] is String:
		return _failure("PLAY_PAYLOAD_INVALID", "play_card requires exactly a String instance_id.")
	var location = CardState.locate_card(state["cards"], action.payload["instance_id"])
	if not location["ok"]:
		return location
	if location["zone_id"] != "hand:%d" % action.actor_id:
		return _failure("CARD_NOT_IN_HAND", "Player can only play a card from their own hand.")
	if state["round"]["plays_by_player"].has(str(action.actor_id)):
		return _failure("PLAYER_ALREADY_PLAYED", "Player already played in this round.")
	return _success()


func reduce(state: Dictionary, action: Object) -> Dictionary:
	if action.type == ACTION_CONCEDE:
		return _reduce_concede(state, action.actor_id)
	return _reduce_play_card(state, action.actor_id, action.payload["instance_id"])


func get_public_state(state: Dictionary) -> Dictionary:
	var card_view = CardState.view_for(state["cards"], -1)
	return {
		"players": state["players"].duplicate(true),
		"phase": state["phase"]["current"],
		"active_player": TurnState.active_player(state["turn"]),
		"round": state["round"].duplicate(true),
		"scores": state["scores"].duplicate(true),
		"winner_ids": state["winner_ids"].duplicate(),
		"finished_reason": state["finished_reason"],
		"card_table": card_view["value"],
	}


func get_player_state(state: Dictionary, viewer_id: int) -> Dictionary:
	var view = get_public_state(state)
	var card_view = CardState.view_for(state["cards"], viewer_id)
	view["card_table"] = card_view["value"]
	view["viewer_id"] = viewer_id
	view["legal_actions"] = get_legal_actions(state, viewer_id)
	return view


func get_legal_actions(state: Dictionary, viewer_id: int) -> Array:
	if PhaseMachine.is_terminal(state["phase"]) or TurnState.active_player(state["turn"]) != viewer_id:
		return []
	var result: Array = []
	var hand_result = CardState.zone_card_ids(state["cards"], "hand:%d" % viewer_id)
	if hand_result["ok"]:
		for instance_id in hand_result["value"]:
			var definition_id: String = state["cards"]["instances"][instance_id]["definition_id"]
			var definition: Dictionary = state["cards"]["definitions"][definition_id]
			var action_result = LegalAction.create(
				ACTION_PLAY_CARD,
				viewer_id,
				{"instance_id": instance_id},
				"Play %s" % definition_id,
				{"value": definition["attributes"]["value"]}
			)
			result.append(action_result["value"])
	var concede_result = LegalAction.create(ACTION_CONCEDE, viewer_id, {}, "Concede")
	result.append(concede_result["value"])
	return result


func is_finished(state: Dictionary) -> bool:
	return PhaseMachine.is_terminal(state["phase"])


func _reduce_play_card(state: Dictionary, actor_id: int, instance_id: String) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var moved = CardState.move_card(next_state["cards"], instance_id, "hand:%d" % actor_id, "table")
	if not moved["ok"]:
		return moved
	next_state["cards"] = moved["value"]
	next_state["round"]["plays_by_player"][str(actor_id)] = instance_id
	var definition_id: String = next_state["cards"]["instances"][instance_id]["definition_id"]
	var definition: Dictionary = next_state["cards"]["definitions"][definition_id]
	var events: Array = [{
		"type": "card_played",
		"payload": {
			"player_id": actor_id,
			"instance_id": instance_id,
			"definition_id": definition_id,
			"value": definition["attributes"]["value"],
		},
		"visible_to": [],
	}]
	var player_count: int = PlayerRegistry.player_ids(next_state["players"]).size()
	if next_state["round"]["plays_by_player"].size() < player_count:
		var advanced: Dictionary = TurnState.advance(next_state["turn"])
		if not advanced["ok"]:
			return advanced
		next_state["turn"] = advanced["value"]
		events.append({
			"type": "turn_started",
			"payload": {"player_id": TurnState.active_player(next_state["turn"])},
			"visible_to": [],
		})
		return {"ok": true, "state": next_state, "events": events}
	return _resolve_round(next_state, events)


func _resolve_round(state: Dictionary, events: Array) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var played_ids: Array = next_state["round"]["plays_by_player"].values()
	var highest = CardQuery.highest_by_attribute(next_state["cards"], played_ids, "value")
	if not highest["ok"]:
		return highest
	var winning_cards: Array = highest["value"]["instance_ids"]
	var round_winner_ids: Array = []
	for player_key in next_state["round"]["plays_by_player"].keys():
		if next_state["round"]["plays_by_player"][player_key] in winning_cards:
			round_winner_ids.append(int(player_key))
	round_winner_ids.sort()
	if round_winner_ids.size() == 1:
		var score_result: Dictionary = ScoreState.add(next_state["scores"], round_winner_ids[0], 1)
		if not score_result["ok"]:
			return score_result
		next_state["scores"] = score_result["value"]
		events.append({
			"type": "round_won",
			"payload": {
				"round": next_state["round"]["number"],
				"player_id": round_winner_ids[0],
				"value": highest["value"]["best"],
			},
			"visible_to": [],
		})
	else:
		events.append({
			"type": "round_tied",
			"payload": {
				"round": next_state["round"]["number"],
				"player_ids": round_winner_ids,
				"value": highest["value"]["best"],
			},
			"visible_to": [],
		})
	var discarded = CardOperations.transfer_all(next_state["cards"], "table", "discard")
	if not discarded["ok"]:
		return discarded
	next_state["cards"] = discarded["value"]
	next_state["round"]["resolved"] += 1
	next_state["round"]["number"] += 1
	next_state["round"]["plays_by_player"] = {}

	var hands_empty = true
	for player_id in PlayerRegistry.player_ids(next_state["players"]):
		if not next_state["cards"]["zones"]["hand:%d" % player_id]["cards"].is_empty():
			hands_empty = false
			break

	# Advance the generic turn cursor to the next round even when the match will
	# finish now. This keeps arena.round and turn.round_number coherent in every
	# persisted terminal snapshot.
	if round_winner_ids.size() == 1:
		var set_turn: Dictionary = TurnState.set_active_player(next_state["turn"], round_winner_ids[0], true, true)
		if not set_turn["ok"]:
			return set_turn
		next_state["turn"] = set_turn["value"]
	else:
		var advanced: Dictionary = TurnState.advance(next_state["turn"])
		if not advanced["ok"]:
			return advanced
		var reanchored: Dictionary = TurnState.set_round_anchor(
			advanced["value"],
			TurnState.active_player(advanced["value"]),
			false
		)
		if not reanchored["ok"]:
			return reanchored
		next_state["turn"] = reanchored["value"]

	if ScoreState.target_reached(next_state["scores"]) or hands_empty:
		next_state["winner_ids"] = ScoreState.leader_ids(next_state["scores"])
		next_state["finished_reason"] = "TARGET_REACHED" if ScoreState.target_reached(next_state["scores"]) else "HANDS_EXHAUSTED"
		var phase_result: Dictionary = PhaseMachine.transition(next_state["phase"], PHASE_FINISHED)
		if not phase_result["ok"]:
			return phase_result
		next_state["phase"] = phase_result["value"]
		events.append({
			"type": "match_finished",
			"payload": {
				"winner_ids": next_state["winner_ids"],
				"reason": next_state["finished_reason"],
				"scores": next_state["scores"]["scores"].duplicate(true),
			},
			"visible_to": [],
		})
		return {"ok": true, "state": next_state, "events": events}

	events.append({
		"type": "round_started",
		"payload": {
			"round": next_state["round"]["number"],
			"player_id": TurnState.active_player(next_state["turn"]),
		},
		"visible_to": [],
	})
	return {"ok": true, "state": next_state, "events": events}


func _reduce_concede(state: Dictionary, actor_id: int) -> Dictionary:
	var next_state: Dictionary = state.duplicate(true)
	var winners: Array = []
	for player_id in PlayerRegistry.player_ids(next_state["players"], true):
		if player_id != actor_id:
			winners.append(player_id)
	next_state["winner_ids"] = winners
	next_state["finished_reason"] = "CONCEDE"
	var phase_result: Dictionary = PhaseMachine.transition(next_state["phase"], PHASE_FINISHED)
	if not phase_result["ok"]:
		return phase_result
	next_state["phase"] = phase_result["value"]
	return {
		"ok": true,
		"state": next_state,
		"events": [{
			"type": "player_conceded",
			"payload": {"player_id": actor_id, "winner_ids": winners},
			"visible_to": [],
		}],
	}


func _normalize_config(config: Dictionary) -> Dictionary:
	var allowed_keys: Array = ["hand_size", "player_names", "starting_player", "target_score"]
	for key in config.keys():
		if not key is String or key not in allowed_keys:
			return _failure("CONFIG_KEY_UNKNOWN", "Unknown High Card Arena config key: %s" % str(key))
	var names: Variant = config.get("player_names", ["Player 1", "Player 2"])
	var hand_size: Variant = config.get("hand_size", 5)
	var target_score: Variant = config.get("target_score", 3)
	var starting_player: Variant = config.get("starting_player", 0)
	if not names is Array or names.size() < 2 or names.size() > 4:
		return _failure("CONFIG_PLAYERS_INVALID", "High Card Arena requires 2-4 players.")
	var normalized_names: Array = []
	var seen_names: Dictionary = {}
	for raw_name in names:
		if not raw_name is String:
			return _failure("CONFIG_PLAYER_NAME_INVALID", "Player names must be Strings.")
		var name: String = raw_name.strip_edges()
		if name.is_empty() or seen_names.has(name):
			return _failure("CONFIG_PLAYER_NAME_INVALID", "Player names must be unique non-empty Strings.")
		seen_names[name] = true
		normalized_names.append(name)
	if not hand_size is int or hand_size < 1 or hand_size > 10:
		return _failure("CONFIG_HAND_SIZE_INVALID", "hand_size must be between 1 and 10.")
	if normalized_names.size() * hand_size > 52:
		return _failure("CONFIG_DECK_TOO_SMALL", "Standard deck cannot satisfy requested hand sizes.")
	if not target_score is int or target_score < 1 or target_score > hand_size:
		return _failure("CONFIG_TARGET_INVALID", "target_score must be between 1 and hand_size.")
	if not starting_player is int or starting_player < 0 or starting_player >= normalized_names.size():
		return _failure("CONFIG_START_PLAYER_INVALID", "starting_player is outside player range.")
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": {
			"player_names": normalized_names,
			"hand_size": hand_size,
			"target_score": target_score,
			"starting_player": starting_player,
		},
	}


func _initialization_failure(result: Variant) -> Dictionary:
	if result is Dictionary:
		return {
			"initialization_error": {
				"ok": false,
				"code": result.get("code", "ARENA_INITIALIZATION_FAILED"),
				"message": result.get("message", "High Card Arena initialization failed."),
			}
		}
	return {
		"initialization_error": {
			"ok": false,
			"code": "ARENA_INITIALIZATION_FAILED",
			"message": "High Card Arena initialization returned an invalid result.",
		}
	}


func _success() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


func _failure(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
