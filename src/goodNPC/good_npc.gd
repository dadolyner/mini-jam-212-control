class_name Npc
extends CharacterBody2D

const SPEED = 60.0

enum State { WANDERING, IDLE }
enum Team { GOOD, BAD }

@export var team: Team = Team.GOOD
@export var max_health: float = 60.0
@export var drain_rate: float = 10.0         
@export_file("*.tscn") var converts_to_path: String  
@export var convert_sound: String = ""         

@onready var _health_bar: ProgressBar = $HealthBar
@onready var _detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

const RETREAT_FRAC := 0.1      # na 10% healtha gredo do castla se healat
const RECOVER_FRAC := 0.7      # na 70% healtha se nehajo healat pr castlu
const OBJECTIVE_REACH := 450.0 # da ne gredo direkt do castla, se prej ustavijo

var health: float
var _state := State.IDLE
var _state_timer := 0.0
var _move_dir := Vector2.ZERO
var _targets: Array[Npc] = []
var _converting := false
var _objective: Node2D = null  # kam gredo uniti k jim je blo ukazano nekaj
var _retreating := false
var _march_label: Label


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("npc")
	GameManager.register_npc(team)

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
	var target := _nearest_target()

	if target:
		velocity = (target.global_position - global_position).normalized() * SPEED
	elif _move_to_destination():
		pass
	else:
		_wander(delta)

	move_and_slide()

	if target == null and _state == State.WANDERING and get_slide_collision_count() > 0:
		_pick_next_state()

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

	if convert_sound != "":
		SoundManager.play(convert_sound)

	var pop := Color(1.0, 0.3, 0.3) if team == Team.GOOD else Color(0.3, 0.9, 0.4)
	Effects.burst(global_position, pop, 12)

	var replacement := scene.instantiate()
	replacement.position = global_position
	get_parent().call_deferred("add_child", replacement)
	queue_free()



func _on_body_entered(body: Node) -> void:
	var other := body as Npc
	if other and other.team != team and not _targets.has(other):
		_targets.append(other)


func _on_body_exited(body: Node) -> void:
	var other := body as Npc
	if other:
		_targets.erase(other)


func _prune_targets() -> void:
	for i in range(_targets.size() - 1, -1, -1):
		if not is_instance_valid(_targets[i]):
			_targets.remove_at(i)


func _nearest_target() -> Npc:
	var best: Npc = null
	var best_dist := INF
	for t in _targets:
		var d := global_position.distance_squared_to(t.global_position)
		if d < best_dist:
			best_dist = d
			best = t
	return best


func set_objective(node: Node2D) -> void:
	_objective = node


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
				velocity = (refuge.global_position - global_position).normalized() * SPEED
				return true

	if _objective != null and is_instance_valid(_objective):
		var to_obj := _objective.global_position - global_position
		if to_obj.length() <= OBJECTIVE_REACH:
			_objective = null
		else:
			velocity = to_obj.normalized() * SPEED
			return true
	return false


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
