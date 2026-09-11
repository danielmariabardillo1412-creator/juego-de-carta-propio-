extends RefCounted
## Pure-data player/team registry used by game modules.
##
## `metadata` is explicitly public session metadata. Secrets belong in the game
## module's private state/view, never in this registry.

const PureDataValidator = preload("res://src/core/pure_data_validator.gd")

const STATE_KEYS := ["players", "teams"]
const PLAYER_KEYS := ["active", "id", "metadata", "name", "seat", "team_id"]
const TEAM_KEYS := ["id", "metadata", "name"]
const MAX_PLAYERS := 1024
const MAX_TEAMS := 1024
const MAX_NAME_LENGTH := 128


static func create(players: Array, teams: Array = []) -> Dictionary:
	var state := {"players": players.duplicate(true), "teams": teams.duplicate(true)}
	var check := validate(state)
	if not check["ok"]:
		return check
	return _success(state)


static func make_player(
	player_id: int,
	name: String,
	seat: int,
	team_id: int = -1,
	metadata: Dictionary = {},
	active: bool = true
) -> Dictionary:
	return {
		"id": player_id,
		"name": name,
		"seat": seat,
		"team_id": team_id,
		"metadata": metadata.duplicate(true),
		"active": active,
	}


static func make_team(team_id: int, name: String, metadata: Dictionary = {}) -> Dictionary:
	return {"id": team_id, "name": name, "metadata": metadata.duplicate(true)}


static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _error("PLAYER_REGISTRY_INVALID", "Player registry must be a Dictionary.")
	var state: Dictionary = value
	var pure_check: Dictionary = PureDataValidator.validate(state, "$.player_registry")
	if not pure_check["ok"]:
		return pure_check
	var keys: Array = state.keys()
	keys.sort()
	if keys != STATE_KEYS:
		return _error("PLAYER_REGISTRY_KEYS_INVALID", "Registry requires exactly players and teams.")
	if not state["players"] is Array or state["players"].is_empty() or state["players"].size() > MAX_PLAYERS:
		return _error("PLAYERS_INVALID", "players must be a non-empty bounded Array.")
	if not state["teams"] is Array or state["teams"].size() > MAX_TEAMS:
		return _error("TEAMS_INVALID", "teams must be a bounded Array.")

	var team_ids: Dictionary = {}
	for raw_team in state["teams"]:
		if not raw_team is Dictionary:
			return _error("TEAM_INVALID", "Each team must be a Dictionary.")
		var team: Dictionary = raw_team
		var team_keys: Array = team.keys()
		team_keys.sort()
		if team_keys != TEAM_KEYS:
			return _error("TEAM_KEYS_INVALID", "Team requires exactly id, metadata and name.")
		if not team["id"] is int or team["id"] < 0:
			return _error("TEAM_ID_INVALID", "Team id must be a non-negative integer.")
		if team_ids.has(team["id"]):
			return _error("TEAM_ID_DUPLICATE", "Team ids must be unique.")
		var team_name_check: Dictionary = _validate_name(team["name"], "TEAM_NAME_INVALID")
		if not team_name_check["ok"]:
			return team_name_check
		if not team["metadata"] is Dictionary:
			return _error("TEAM_METADATA_INVALID", "Team metadata must be a Dictionary.")
		team_ids[team["id"]] = true

	var player_ids: Dictionary = {}
	var seats: Dictionary = {}
	for raw_player in state["players"]:
		if not raw_player is Dictionary:
			return _error("PLAYER_INVALID", "Each player must be a Dictionary.")
		var player: Dictionary = raw_player
		var player_keys: Array = player.keys()
		player_keys.sort()
		if player_keys != PLAYER_KEYS:
			return _error("PLAYER_KEYS_INVALID", "Player requires exactly active, id, metadata, name, seat and team_id.")
		if not player["id"] is int or player["id"] < 0:
			return _error("PLAYER_ID_INVALID", "Player id must be a non-negative integer.")
		if player_ids.has(player["id"]):
			return _error("PLAYER_ID_DUPLICATE", "Player ids must be unique.")
		var player_name_check: Dictionary = _validate_name(player["name"], "PLAYER_NAME_INVALID")
		if not player_name_check["ok"]:
			return player_name_check
		if not player["seat"] is int or player["seat"] < 0:
			return _error("PLAYER_SEAT_INVALID", "Player seat must be non-negative.")
		if seats.has(player["seat"]):
			return _error("PLAYER_SEAT_DUPLICATE", "Player seats must be unique.")
		if not player["team_id"] is int or player["team_id"] < -1:
			return _error("PLAYER_TEAM_INVALID", "team_id must be -1 or a known non-negative team id.")
		if player["team_id"] >= 0 and not team_ids.has(player["team_id"]):
			return _error("PLAYER_TEAM_UNKNOWN", "Player references an unknown team.")
		if not player["metadata"] is Dictionary or not player["active"] is bool:
			return _error("PLAYER_DATA_INVALID", "Player metadata/active fields are invalid.")
		player_ids[player["id"]] = true
		seats[player["seat"]] = true
	return _ok()


static func player_ids(state: Dictionary, active_only: bool = false) -> Array:
	if not validate(state)["ok"]:
		return []
	var result: Array = []
	for player in state["players"]:
		if not active_only or player["active"]:
			result.append(player["id"])
	return result


static func seat_order(state: Dictionary, active_only: bool = false) -> Array:
	if not validate(state)["ok"]:
		return []
	var players: Array = []
	for player in state["players"]:
		if not active_only or player["active"]:
			players.append(player.duplicate(true))
	for left_index in range(players.size()):
		for right_index in range(left_index + 1, players.size()):
			if players[right_index]["seat"] < players[left_index]["seat"]:
				var temporary: Variant = players[left_index]
				players[left_index] = players[right_index]
				players[right_index] = temporary
	var result: Array = []
	for player in players:
		result.append(player["id"])
	return result


static func team_members(state: Dictionary, team_id: int, active_only: bool = false) -> Array:
	if not validate(state)["ok"]:
		return []
	var known_team: bool = false
	for team in state["teams"]:
		if team["id"] == team_id:
			known_team = true
			break
	if not known_team:
		return []
	var result: Array = []
	for player in state["players"]:
		if player["team_id"] == team_id and (not active_only or player["active"]):
			result.append(player["id"])
	result.sort()
	return result


static func get_player(state: Dictionary, player_id: int) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	for player in state["players"]:
		if player["id"] == player_id:
			return _success(player)
	return _error("PLAYER_UNKNOWN", "Unknown player id.")


static func set_active(state: Dictionary, player_id: int, active: bool) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	var next_state: Dictionary = state.duplicate(true)
	for player in next_state["players"]:
		if player["id"] == player_id:
			player["active"] = active
			var next_check: Dictionary = validate(next_state)
			if not next_check["ok"]:
				return next_check
			return _success(next_state)
	return _error("PLAYER_UNKNOWN", "Unknown player id.")


static func public_view(state: Dictionary) -> Dictionary:
	var check := validate(state)
	if not check["ok"]:
		return check
	return _success(state)


static func _validate_name(value: Variant, code: String) -> Dictionary:
	if not value is String:
		return _error(code, "Name must be a String.")
	var name: String = value
	if name.is_empty() or name.strip_edges() != name or name.length() > MAX_NAME_LENGTH:
		return _error(code, "Name must be trimmed, non-empty and at most %d characters." % MAX_NAME_LENGTH)
	for index in range(name.length()):
		var codepoint: int = name.unicode_at(index)
		if codepoint < 32 or codepoint == 127:
			return _error(code, "Name cannot contain control characters.")
	return _ok()


static func _success(value: Dictionary) -> Dictionary:
	return {"ok": true, "code": "OK", "message": "", "value": value.duplicate(true)}


static func _ok() -> Dictionary:
	return {"ok": true, "code": "OK", "message": ""}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
