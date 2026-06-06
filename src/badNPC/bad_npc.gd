extends "res://src/goodNPC/good_npc.gd"

const FLEE_SPEED := SPEED * 1.6
const FLEE_DURATION := 1.5
const FLEE_REACTION_DELAY := 0.2
const RALLY_RADIUS := 100.0
const RALLY_DURATION := 3.0

var _flee_from: Npc = null
var _flee_timer := 0.0
var _react_timer := 0.0
var _pending_drainer: Npc = null
var _rally_target: Npc = null
var _rally_timer := 0.0
var _committed := false

func _count_allies() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("npc"):
		if node == self or not is_instance_valid(node):
			continue
		if not node.has_method("rally"):
			continue
		if node.get("_committed") and node.get("_rally_target") == _rally_target:
			count += 1
	return count

func take_drain(amount: float, from: Npc = null) -> void:
	super.take_drain(amount, from)
	if from and is_instance_valid(from):
		_pending_drainer = from


func rally(target: Npc) -> void:
	if _converting:
		return
	_committed = true
	_flee_timer = 0.0
	_flee_from = null
	_rally_target = target
	_rally_timer = RALLY_DURATION


func _call_for_help(threat: Npc) -> void:
	var allies_rallied := 0
	for node in get_tree().get_nodes_in_group("npc"):
		if node == self or not is_instance_valid(node):
			continue
		if not node.has_method("rally"):
			continue
		if (node as Node2D).global_position.distance_squared_to(global_position) > RALLY_RADIUS * RALLY_RADIUS:
			continue
		node.call("rally", threat)
		allies_rallied += 1

	if allies_rallied > 0:
		_committed = true
		_flee_timer = 0.0
		_flee_from = null
		_rally_target = threat
		_rally_timer = RALLY_DURATION
	else:
		_flee_from = threat
		_flee_timer = FLEE_DURATION


func _check_flee_reaction(delta: float) -> void:
	if _committed:
		_pending_drainer = null
		return
	if _pending_drainer != null and is_instance_valid(_pending_drainer):
		_react_timer += delta
		if _react_timer >= FLEE_REACTION_DELAY:
			_react_timer = 0.0
			_call_for_help(_pending_drainer)
	else:
		_react_timer = 0.0
	_pending_drainer = null


func _physics_process(delta: float) -> void:
	if _flee_timer > 0.0 and is_instance_valid(_flee_from):
		_flee_timer -= delta
		_prune_targets()
		velocity = global_position.direction_to(_flee_from.global_position) * -FLEE_SPEED
		move_and_slide()
		$Sprite2D.flip_h = velocity.x < 0.0
		_pending_drainer = null
	elif _rally_timer > 0.0 and is_instance_valid(_rally_target):
		_rally_timer -= delta
		_prune_targets()
		if not _targets.is_empty():
			_rally_timer = 0.0
			_rally_target = null
			super._physics_process(delta)
		else:
			_navigate_toward(_rally_target.global_position)
			move_and_slide()
			$Sprite2D.flip_h = velocity.x < 0.0
		_check_flee_reaction(delta)
	else:
		_committed = false
		_flee_from = null
		_rally_timer = 0.0
		_rally_target = null
		super._physics_process(delta)
		_check_flee_reaction(delta)
