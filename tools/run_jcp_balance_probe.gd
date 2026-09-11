extends SceneTree
## Sonda reproducible de cifras impresas. No sustituye partidas ni ejecuta efectos contextuales.

const GameModule = preload("res://games/juego_cartas_propio/juego_cartas_propio_module.gd")
const FusionCatalog = preload("res://games/juego_cartas_propio/fusion_catalog.gd")


func _init() -> void:
	var creatures: Array = []
	for spec in GameModule.new().call("_card_specs"):
		if spec["attributes"]["card_type"] == "creature":
			creatures.append(_unit(spec["id"], spec["attributes"]))
	var fusions: Array = []
	for recipe in FusionCatalog.recipes():
		fusions.append(_unit(recipe["result"]["identity_id"], recipe["result"]))
	var f001: Dictionary = _find_unit(fusions, "fusion.f001_nature_alpha")
	var f067: Dictionary = _find_unit(fusions, "fusion.f067_water_major")
	var report := {
		"scope": "printed_stats_only",
		"creature_count": creatures.size(),
		"fusion_count": fusions.size(),
		"f001": {
			"printed": f001,
			"leadership_kill_thresholds_vs_creatures": _leadership_thresholds(creatures, creatures),
			"leadership_kill_thresholds_vs_fusions": _leadership_thresholds(creatures, fusions),
		},
		"f067": {
			"printed": f067,
			"attack_choice_vs_creatures": _outcome_counts(f067["attack"] + 1, f067["defense"], creatures),
			"defense_choice_vs_creatures": _outcome_counts(f067["attack"], f067["defense"] + 1, creatures),
			"attack_choice_vs_fusions": _outcome_counts(f067["attack"] + 1, f067["defense"], fusions),
			"defense_choice_vs_fusions": _outcome_counts(f067["attack"], f067["defense"] + 1, fusions),
		},
	}
	print(JSON.stringify(report, "\t"))
	quit(0)


func _unit(id: String, attributes: Dictionary) -> Dictionary:
	return {
		"id": id,
		"name": attributes["display_name"],
		"cost": attributes["cost"],
		"attack": attributes["attack"],
		"defense": attributes["defense"],
	}


func _find_unit(units: Array, id: String) -> Dictionary:
	for unit in units:
		if unit["id"] == id:
			return unit
	return {}


func _outcome_counts(attack: int, defense: int, opponents: Array) -> Dictionary:
	var counts := {"wins": 0, "trades": 0, "losses": 0, "stalls": 0}
	for opponent in opponents:
		var destroys: bool = attack > opponent["defense"]
		var is_destroyed: bool = opponent["attack"] > defense
		if destroys and not is_destroyed:
			counts["wins"] += 1
		elif destroys and is_destroyed:
			counts["trades"] += 1
		elif not destroys and is_destroyed:
			counts["losses"] += 1
		else:
			counts["stalls"] += 1
	return counts


func _leadership_thresholds(allies: Array, opponents: Array) -> Dictionary:
	var improved_pairs := 0
	var total_pairs: int = allies.size() * opponents.size()
	var allies_helped: Dictionary = {}
	for ally in allies:
		for opponent in opponents:
			if ally["attack"] == opponent["defense"]:
				improved_pairs += 1
				allies_helped[ally["id"]] = true
	return {
		"improved_pairs": improved_pairs,
		"total_pairs": total_pairs,
		"percent": snappedf(100.0 * improved_pairs / total_pairs, 0.01),
		"distinct_allies_helped": allies_helped.size(),
	}
