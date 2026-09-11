extends RefCounted
## Hardened adapter between module legal-action enumeration and a bot policy.
##
## The adapter validates both sides of the trust boundary. The module must
## expose a canonical legal-action list and the policy must return one exact
## member of that list. Caller-owned request ids remain optional, but when
## supplied they are validated by GameAction and can be used for idempotency.

const GameAction = preload("res://src/core/game_action.gd")
const LegalAction = preload("res://src/core/legal_action.gd")
const ModuleProtocol = preload("res://src/core/module_protocol.gd")
const PureDataValidator = preload("res://src/core/pure_data_validator.gd")


static func choose(
	module: Object,
	state: Dictionary,
	actor_id: int,
	policy: Object,
	request_id: String = ""
) -> Dictionary:
	if actor_id < 0:
		return _error("BOT_ACTOR_INVALID", "Bot actor_id must be non-negative.")
	if module == null or not module.has_method("get_legal_actions"):
		return _error("BOT_MODULE_UNSUPPORTED", "Module does not enumerate legal actions.")
	if policy == null or not policy.has_method("choose_action"):
		return _error("BOT_POLICY_INVALID", "Policy must implement choose_action(actions, state, actor_id).")
	var state_check: Dictionary = PureDataValidator.validate(state, "$.bot_state")
	if not state_check["ok"]:
		return state_check

	var actions_value: Variant = module.call("get_legal_actions", state.duplicate(true), actor_id)
	var actions_check: Dictionary = ModuleProtocol.validate_legal_actions(actions_value, actor_id)
	if not actions_check["ok"]:
		return _error("BOT_LEGAL_ACTIONS_INVALID", "%s: %s" % [actions_check["code"], actions_check["message"]])
	var actions: Array = actions_value
	if actions.is_empty():
		return _error("BOT_NO_LEGAL_ACTION", "No legal action is available.")

	var policy_actions: Array = actions.duplicate(true)
	var policy_state: Dictionary = state.duplicate(true)
	var selected: Variant = policy.call("choose_action", policy_actions, policy_state, actor_id)
	var selected_check: Dictionary = LegalAction.validate(selected, actor_id)
	if not selected_check["ok"]:
		return _error("BOT_SELECTION_INVALID", "%s: %s" % [selected_check["code"], selected_check["message"]])
	var selected_action: Dictionary = selected
	var selected_index: int = actions.find(selected_action)
	if selected_index < 0:
		return _error("BOT_SELECTION_ILLEGAL", "Bot selected an action outside the canonical legal set.")

	var action = GameAction.new(
		selected_action["type"],
		actor_id,
		selected_action["payload"],
		request_id
	)
	var shape: Dictionary = action.validate_shape()
	if not shape["ok"]:
		return shape
	return {
		"ok": true,
		"code": "OK",
		"message": "",
		"value": action,
		"legal_index": selected_index,
	}


static func _error(code: String, message: String) -> Dictionary:
	return {"ok": false, "code": code, "message": message}
