extends Node

signal balance_changed(good_ratio: float, bad_ratio: float)
signal mana_changed(current: int, maximum: int)
signal castle_captured(old_team: int, new_team: int)

const TEAM_GOOD := 0
const TEAM_BAD := 1

const MAX_MANA := 100
const COST_HEALER := 8
const COST_KNIGHT := 12

const CASTLE_WEIGHT := 5   # 1 grad = 5 minionov

var good_npcs := 0
var bad_npcs := 0
var good_castles := 0
var bad_castles := 0

var mana := MAX_MANA

var marches_enabled := false


func _ready() -> void:
	_emit_mana()

func reset_run() -> void:
	good_npcs = 0
	bad_npcs = 0
	good_castles = 0
	bad_castles = 0
	mana = MAX_MANA
	marches_enabled = false
	_emit()
	_emit_mana()

func try_spend_mana(amount: int) -> bool:
	if mana < amount:
		return false
	mana -= amount
	_emit_mana()
	return true


func gain_mana(amount: int) -> void:
	mana = mini(mana + amount, MAX_MANA)
	_emit_mana()


func _emit_mana() -> void:
	mana_changed.emit(mana, MAX_MANA)

func notify_state() -> void:
	_emit()
	_emit_mana()


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
	castle_captured.emit(old_team, new_team)


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
