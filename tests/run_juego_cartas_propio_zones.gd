extends SceneTree
## Verifica barajas, manos, zonas, robo, privacidad y conservacion de 80 cartas.

const GameAction = preload("res://src/core/game_action.gd")
const UniversalCardEngine = preload("res://src/core/universal_card_engine.gd")
const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const CardState = preload("res://src/cards/card_state.gd")

var _checks := 0
var _failures: Array = []


func _init() -> void:
	_run_suite()
	if _failures.is_empty():
		print("JCP-ZONES PASS: %d checks" % _checks)
		quit(0)
		return
	printerr("JCP-ZONES FAIL: %d failure(s) across %d checks" % [_failures.size(), _checks])
	for failure in _failures:
		printerr(" - %s" % failure)
	quit(1)


func _run_suite() -> void:
	var engine = UniversalCardEngine.new(GameModule.new(), {"player_names": ["Lucia", "Alex"]})
	_expect(engine.is_ready(), "el modulo acepta la configuracion minima")
	var start = engine.start(20260908)
	_expect(start.success, "la partida con cartas arranca")
	if not start.success:
		_failures.append("arranque rechazado: %s — %s" % [start.code, start.message])
		return
	var state: Dictionary = engine.export_module_state()
	_expect_equal(state["cards"]["definitions"].size(), 40, "hay 40 cartas diferentes")
	_expect_equal(state["cards"]["instances"].size(), 80, "cada jugador recibe su copia fisica del mazo")
	_expect_equal(state["cards"]["zones"].size(), 16, "hay ocho zonas por jugador")
	for player_id in [0, 1]:
		_expect_zone_count(state, "deck:%d" % player_id, 35)
		_expect_zone_count(state, "hand:%d" % player_id, 5)
		_expect_zone_count(state, "creatures:%d" % player_id, 0)
		_expect_zone_count(state, "fusion_materials:%d" % player_id, 0)
		_expect_zone_count(state, "support:%d" % player_id, 0)
		_expect_zone_count(state, "attachments:%d" % player_id, 0)
		_expect_zone_count(state, "terrain:%d" % player_id, 0)
		_expect_zone_count(state, "graveyard:%d" % player_id, 0)

	var public_view: Dictionary = engine.get_public_state()["game"]["card_table"]
	_expect_equal(public_view["zones"]["hand:0"]["count"], 5, "el numero de cartas de la mano es publico")
	_expect_equal(public_view["zones"]["hand:0"]["cards"].size(), 0, "el publico no conoce la mano")
	_expect_equal(public_view["zones"]["deck:0"]["cards"].size(), 0, "el publico no conoce el orden de la baraja")
	var player_zero_view: Dictionary = engine.get_player_state(0)["game"]["card_table"]
	var player_one_view: Dictionary = engine.get_player_state(1)["game"]["card_table"]
	_expect_equal(player_zero_view["zones"]["hand:0"]["cards"].size(), 5, "cada jugador ve su propia mano")
	_expect_equal(player_zero_view["zones"]["hand:1"]["cards"].size(), 0, "un jugador no ve la mano rival")
	_expect_equal(player_one_view["zones"]["hand:1"]["cards"].size(), 5, "el segundo jugador ve su propia mano")

	# El primer jugador no roba durante su primer turno.
	var advance = engine.perform_action(GameAction.new("advance_phase", 0, {}, "p0-draw"))
	_expect(advance.success, "el jugador inicial entra en Robo")
	state = engine.export_module_state()
	_expect_zone_count(state, "deck:0", 35)
	_expect_zone_count(state, "hand:0", 5)

	# Se completa el turno y el segundo jugador si roba al entrar en su fase de Robo.
	for index in range(5):
		var result = engine.perform_action(GameAction.new("advance_phase", 0, {}, "p0-rest-%d" % index))
		_expect(result.success, "el jugador inicial completa la fase %d" % index)
	var draw_second = engine.perform_action(GameAction.new("advance_phase", 1, {}, "p1-draw"))
	_expect(draw_second.success, "el segundo jugador entra en Robo")
	state = engine.export_module_state()
	_expect_zone_count(state, "deck:1", 34)
	_expect_zone_count(state, "hand:1", 6)
	_expect(CardState.validate(state["cards"])["ok"], "las cartas siguen conservadas despues del robo")
	_expect(engine.validate_internal_consistency()["ok"], "el motor conserva un estado integro")

	var public_events: Array = engine.get_events(0, -1)
	var private_events: Array = engine.get_events(0, 1)
	var public_private_draws := 0
	var owner_private_draws := 0
	for event in public_events:
		if event["type"] == "private_card_drawn":
			public_private_draws += 1
	for event in private_events:
		if event["type"] == "private_card_drawn":
			owner_private_draws += 1
	_expect_equal(public_private_draws, 0, "el identificador robado no aparece en eventos publicos")
	_expect_equal(owner_private_draws, 1, "solo el propietario recibe el identificador de su carta robada")


func _expect_zone_count(state: Dictionary, zone_id: String, expected: int) -> void:
	var result: Dictionary = CardState.zone_card_ids(state["cards"], zone_id)
	_expect(result["ok"], "la zona %s existe" % zone_id)
	if result["ok"]:
		_expect_equal(result["value"].size(), expected, "cantidad correcta en %s" % zone_id)


func _expect(condition: bool, description: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(description)


func _expect_equal(actual: Variant, expected: Variant, description: String) -> void:
	_checks += 1
	if actual != expected:
		_failures.append("%s — esperado=%s actual=%s" % [description, str(expected), str(actual)])
