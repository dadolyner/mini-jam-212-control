class_name Npc
extends CharacterBody2D

const SPEED = 60.0

enum State { WANDERING, IDLE }
enum Team { GOOD, BAD }
enum UnitType { BASIC, HEALER, KNIGHT }

@export var team: Team = Team.GOOD
@export var unit_type: UnitType = UnitType.BASIC
@export var max_health: float = 60.0
@export var drain_rate: float = 10.0         
@export_file("*.tscn") var converts_to_path: String  
@export var convert_sound: String = ""         

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D

const RETREAT_FRAC := 0.3      # na 30% healtha gredo do castla se healat
const RECOVER_FRAC := 0.7      # na 70% healtha se nehajo healat pr castlu
const OBJECTIVE_REACH := 450.0 # da ne gredo direkt do castla, se prej ustavijo

const KNIGHT_HEALTH := 160.0   
const KNIGHT_DRAIN := 20.0     
const HEALER_HEAL := 14.0      
const FOLLOW_KEEP_DIST := 80.0

var health: float
var _state := State.IDLE
var _state_timer := 0.0
var _move_dir := Vector2.ZERO
var _targets: Array[Npc] = []
var _allies: Array[Npc] = []   # za healerja, kdo je in range
var _converting := false
var _objective: Node2D = null  # kam gredo uniti k jim je blo ukazano nekaj
var _retreating := false
var _march_label: Label


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("npc")
	GameManager.register_npc(team)

	_apply_unit_type()
	_apply_unit_color()

	health = max_health
	_health_bar.max_value = max_health
	_health_bar.value = health
	_health_bar.visible = false

	_create_march_label()

	$DetectionArea.body_entered.connect(_on_body_entered)
	$DetectionArea.body_exited.connect(_on_body_exited)

	_pick_next_state()
	queue_redraw()


func _exit_tree() -> void:
	GameManager.unregister_npc(team)


func _draw() -> void:
	var shape := _detection_shape.shape as CircleShape2D
	if shape == null:
		return
	var color := Color(0.3, 0.9, 0.4, 0.42) if team == Team.GOOD else Color(1.0, 0.3, 0.3, 0.42)
	draw_circle(Vector2.ZERO, shape.radius, color)


func _physics_process(delta: float) -> void:
	_prune_targets()
	_prune_allies()

	var target: Npc = null
	if unit_type == UnitType.HEALER:
		if not _move_to_destination():
			_wander(delta)
	else:
		target = _nearest_target()
		if target:
			_navigate_toward(target.global_position)
		elif _move_to_destination():
			pass
		else:
			_wander(delta)

	move_and_slide()

	if target == null and _state == State.WANDERING and get_slide_collision_count() > 0:
		_pick_next_state()

	if unit_type == UnitType.HEALER:
		_apply_heal(delta)
	else:
		_apply_drain(delta)
	_update_march_label()

	$Sprite2D.flip_h = velocity.x < 0.0



func _wander(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_next_state()

	if _state == State.WANDERING:
		velocity = _move_dir * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 10.0)


func _pick_next_state() -> void:
	if _state == State.WANDERING:
		_state = State.IDLE
		_state_timer = randf_range(1.0, 3.0)
		_move_dir = Vector2.ZERO
	else:
		_state = State.WANDERING
		_state_timer = randf_range(1.5, 4.0)
		var angle := randf() * TAU
		_move_dir = Vector2(cos(angle), sin(angle))



func _apply_drain(delta: float) -> void:
	var amount := drain_rate * delta
	for t in _targets:
		if is_instance_valid(t):
			t.take_drain(amount, self)


func _apply_heal(delta: float) -> void:
	var amount := HEALER_HEAL * delta
	for a in _allies:
		if is_instance_valid(a):
			a.heal(amount)


func take_drain(amount: float, _from: Npc = null) -> void:
	if _converting:
		return
	health -= amount
	_health_bar.value = health
	_health_bar.visible = health < max_health
	if health <= 0.0:
		_convert()


func heal(amount: float) -> void:
	if _converting:
		return
	health = min(health + amount, max_health)
	_health_bar.value = health
	_health_bar.visible = health < max_health


func _convert() -> void:
	if _converting or converts_to_path == "":
		return

	var scene := load(converts_to_path) as PackedScene
	if scene == null:
		return
	_converting = true

	if team == Team.GOOD:
		GameManager.gain_mana(1)

	if convert_sound != "":
		SoundManager.play(convert_sound)

	var pop := Color(1.0, 0.3, 0.3) if team == Team.GOOD else Color(0.3, 0.9, 0.4)
	Effects.burst(global_position, pop, 12)

	var replacement := scene.instantiate() as Npc
	replacement.unit_type = unit_type 
	replacement.position = global_position
	get_parent().call_deferred("add_child", replacement)
	queue_free()



func _on_body_entered(body: Node) -> void:
	var other := body as Npc
	if other == null:
		return
	if other.team != team:
		if not _targets.has(other):
			_targets.append(other)
	elif not _allies.has(other):
		_allies.append(other)


func _on_body_exited(body: Node) -> void:
	var other := body as Npc
	if other:
		_targets.erase(other)
		_allies.erase(other)


func _prune_targets() -> void:
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)


func _prune_allies() -> void:
	for i in range(_allies.size() - 1, -1, -1):
		if not is_instance_valid(_allies[i]):
			_allies.remove_at(i)


func _nearest_target() -> Npc:
	var best: Npc = null
	var best_dist := INF
	for t in _targets:
		var d := global_position.distance_squared_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	return best


func _nearest_ally() -> Npc:
	var best: Npc = null
	var best_dist := INF
	for a in _allies:
		if not is_instance_valid(a):
			continue
		var d := global_position.distance_squared_to(a.global_position)
		if d < best_dist:
			best_dist = d
			best = a
	if best:
		return best
	

	for n in get_tree().get_nodes_in_group("npc"):
		var ally := n as Npc
		if ally == null or ally == self or ally.team != team:
			continue
		var ad := global_position.distance_squared_to(ally.global_position)
		if ad < best_dist:
			best_dist = ad
			best = ally
	return best


func _follow_ally(delta: float) -> bool:
	var ally := _nearest_ally()
	if ally == null:
		return false
	var to_ally := ally.global_position - global_position
	if to_ally.length() > FOLLOW_KEEP_DIST:
		velocity = to_ally.normalized() * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 10.0)
	return true


func set_objective(node: Node2D) -> void:
	_objective = node


func _apply_unit_type() -> void:
	match unit_type:
		UnitType.KNIGHT:
			max_health = KNIGHT_HEALTH
			drain_rate = KNIGHT_DRAIN
		UnitType.HEALER:
			drain_rate = 0.0


func _type_color() -> Color:
	if unit_type == UnitType.HEALER:
		return Color(0.6, 0.3, 0.95) if team == Team.BAD else Color(1.5, 1.5, 1.6)
	if unit_type == UnitType.KNIGHT:
		return Color(0.5, 0.12, 0.12) if team == Team.BAD else Color(0.15, 0.2, 0.6)
	return Color.WHITE


func _apply_unit_color() -> void:
	$Sprite2D.modulate = _type_color()


func upgrade_to(t: UnitType) -> void:
	unit_type = t
	_apply_unit_type()
	_health_bar.max_value = max_health
	health = max_health
	_health_bar.value = health
	_health_bar.visible = false
	_apply_unit_color()
	Effects.burst(global_position, _type_color(), 14)


func _create_march_label() -> void:
	_march_label = Label.new()
	_march_label.text = "Charging!"
	_march_label.visible = false
	_march_label.size = Vector2(100, 18)
	_march_label.position = Vector2(-50, -52)
	_march_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_march_label.add_theme_font_size_override("font_size", 14)
	_march_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35))
	_march_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_march_label.add_theme_constant_override("outline_size", 4)
	add_child(_march_label)


func _update_march_label() -> void:
	var marching := _objective != null and is_instance_valid(_objective) and not _retreating
	if _march_label.visible != marching:
		_march_label.visible = marching


func _move_to_destination() -> bool:
	if team == Team.GOOD:
		if _retreating and health >= RECOVER_FRAC * max_health:
			_retreating = false
		elif not _retreating and health <= RETREAT_FRAC * max_health:
			_retreating = true
		if _retreating:
			var refuge := _nearest_castle(team)
			if refuge:
				_navigate_toward(refuge.global_position)
				return true

	if _objective != null and is_instance_valid(_objective):
		var to_obj := _objective.global_position - global_position
		if to_obj.length() <= OBJECTIVE_REACH:
			_objective = null
			return false
		_navigate_toward(_objective.global_position)
		return true
	return false


func _navigate_toward(target: Vector2) -> void:
	_nav_agent.target_position = target
	var next_pos: Vector2 = _nav_agent.get_next_path_position()
	var dir := next_pos - global_position
	if dir.length_squared() > 1.0:
		velocity = dir.normalized() * SPEED
	else:
		velocity = Vector2.ZERO


func _nearest_castle(of_team: int) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for c in get_tree().get_nodes_in_group("castle"):
		var castle := c as Node2D
		if castle == null or castle.get("team") != of_team:
			continue
		var d := global_position.distance_squared_to(castle.global_position)
		if d < best_dist:
			best_dist = d
			best = castle
	return best
