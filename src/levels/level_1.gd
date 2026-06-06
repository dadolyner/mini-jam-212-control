extends Node2D

const SANDBOX := "res://src/main.tscn"

const STEP_TITLES: Array[String] = [
	"Step 1/4 — Summon minions",
	"Step 2/4 — Corrupt the ground",
	"Step 3/4 — Corrupt a villager",
	"Step 4/4 — Empower a unit",
]
const STEP_HINTS: Array[String] = [
	"Press SPACE three times",
	"Press E to unleash corruption",
	"Summon minions around the villager, then press E",
	"Stand near a red unit and press 1 (Healer) or 2 (Knight)",
]

@onready var _demon: Demon = $Demon
@onready var _title: Label = $Tutorial/TaskTitle
@onready var _hint: Label = $Tutorial/TaskHint
@onready var _done_label: Label = $Tutorial/CompletedLabel
@onready var _intro_label: Label = $Tutorial/IntroLabel
@onready var _timer_label: Label = $Tutorial/CorruptionTimer
@onready var _corrupt_poly: Polygon2D = $CorruptionPolygon
@onready var _demo_good: Npc = $DemoGood
@onready var _demo_bad: Node = $DemoBad

var _step: int = 0
var _corruption_seen: bool = false
var _start_bad: int = 0
var _finished: bool = false
var _in_intro: bool = true
var _intro_post_timer: float = 0.0


func _ready() -> void:
	var bg := preload("res://src/background.gd").new()
	bg.z_index = -5
	add_child(bg)

	#freeza vse
	$BadNpc.set_physics_process(false)
	$GoodNpc.set_physics_process(false)
	$DemoBad.set_physics_process(false)

	_title.visible = false
	_hint.visible = false
	_done_label.visible = false
	_timer_label.visible = false
	_corrupt_poly.visible = false
	_intro_label.text = "Watch: a villager is converting a demon..."


func _process(delta: float) -> void:
	if _finished:
		return
	if _in_intro:
		_run_intro(delta)
		return
	_update_corruption_visuals()
	if _is_step_complete():
		_advance()


func _run_intro(delta: float) -> void:
	for node: Node in get_tree().get_nodes_in_group("npc"):
		if node != _demo_good:
			node.set_physics_process(false)

	if not is_instance_valid(_demo_bad):
		_intro_post_timer += delta
		_intro_label.text = "Now it's your turn!"
		if _intro_post_timer >= 1.5:
			_start_tutorial()


func _start_tutorial() -> void:
	_in_intro = false
	if is_instance_valid(_demo_good):
		_demo_good.set_physics_process(false)
	_intro_label.visible = false
	_start_bad = GameManager.bad_npcs
	_title.visible = true
	_hint.visible = true
	_show_step()


func _update_corruption_visuals() -> void:
	if _demon.corrupting:
		_corrupt_poly.visible = true
		_corrupt_poly.polygon = _demon.corruption_polygon
		_timer_label.visible = true
		_timer_label.text = "Corruption: %.1fs" % maxf(_demon.corruption_timer, 0.0)
	else:
		_corrupt_poly.visible = false
		_timer_label.visible = false


func _show_step() -> void:
	_title.text = STEP_TITLES[_step]
	_hint.text = STEP_HINTS[_step]


func _is_step_complete() -> bool:
	match _step:
		0:
			return _demon.minions.size() >= 3
		1:
			if _demon.corrupting:
				_corruption_seen = true
			return _corruption_seen
		2:
			return GameManager.bad_npcs >= _start_bad + 1
		3:
			return _any_upgraded()
	return false


func _any_upgraded() -> bool:
	for node: Node in get_tree().get_nodes_in_group("npc"):
		var npc: Npc = node as Npc
		if npc != null and npc.unit_type != Npc.UnitType.BASIC:
			return true
	return false


func _advance() -> void:
	_step += 1
	_corruption_seen = false
	if _step >= STEP_TITLES.size():
		_complete_tutorial()
	else:
		_show_step()


func _complete_tutorial() -> void:
	_finished = true
	_title.visible = false
	_hint.visible = false
	_timer_label.visible = false
	_corrupt_poly.visible = false
	_done_label.visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file(SANDBOX)
