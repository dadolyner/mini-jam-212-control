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

var health: float
var _state := State.IDLE
var _state_timer := 0.0
var _move_dir := Vector2.ZERO
var _targets: Array[Npc] = []                  
var _converting := false


func _ready() -> void:
	motion_mode = MOTION_MODE_FLOATING
	add_to_group("npc")

	health = max_health
	_health_bar.max_value = max_health
	_health_bar.value = health
	_health_bar.visible = false

	$DetectionArea.body_entered.connect(_on_body_entered)
	$DetectionArea.body_exited.connect(_on_body_exited)

	_pick_next_state()


func _physics_process(delta: float) -> void:
	_prune_targets()
	var target := _nearest_target()

	if target:
		velocity = (target.global_position - global_position).normalized() * SPEED
	else:
		_wander(delta)

	move_and_slide()

	if target == null and _state == State.WANDERING and get_slide_collision_count() > 0:
		_pick_next_state()

	_apply_drain(delta)

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
			t.take_drain(amount)


func take_drain(amount: float) -> void:
	if _converting:
		return
	health -= amount
	_health_bar.value = health
	_health_bar.visible = health < max_health
	if health <= 0.0:
		_convert()


func _convert() -> void:
	if _converting or converts_to_path == "":
		return

	var scene := load(converts_to_path) as PackedScene
	if scene == null:
		return
	_converting = true

	if convert_sound != "":
		SoundManager.play(convert_sound)

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
