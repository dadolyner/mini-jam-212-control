extends Node

signal balance_changed(good_ratio: float, bad_ratio: float)

const TEAM_GOOD := 0
const TEAM_BAD := 1

const CASTLE_WEIGHT := 5   # 1 grad = 5 minionov

var good_npcs := 0
var bad_npcs := 0
var good_castles := 0
var bad_castles := 0


func register_npc(team: int) -> void:
	if team == TEAM_GOOD:
		good_npcs += 1
	else:
		bad_npcs += 1
	_emit()


func unregister_npc(team: int) -> void:
	if team == TEAM_GOOD:
		good_npcs = max(good_npcs - 1, 0)
	else:
		bad_npcs = max(bad_npcs - 1, 0)
	_emit()


func register_castle(team: int) -> void:
	if team == TEAM_GOOD:
		good_castles += 1
	else:
		bad_castles += 1
	_emit()


func castle_changed_team(old_team: int, new_team: int) -> void:
	if old_team == TEAM_GOOD:
		good_castles = max(good_castles - 1, 0)
	else:
		bad_castles = max(bad_castles - 1, 0)
	if new_team == TEAM_GOOD:
		good_castles += 1
	else:
		bad_castles += 1
	_emit()


func _good_score() -> int:
	return good_npcs + good_castles * CASTLE_WEIGHT


func _bad_score() -> int:
	return bad_npcs + bad_castles * CASTLE_WEIGHT


func _emit() -> void:
	var total := _good_score() + _bad_score()
	if total <= 0:
		balance_changed.emit(0.5, 0.5)
		return
	var good_ratio := float(_good_score()) / float(total)
	balance_changed.emit(good_ratio, 1.0 - good_ratio)
