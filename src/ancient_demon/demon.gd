class_name Demon
extends CharacterBody2D

enum {IDLE, RUN}

var player_state = IDLE

@export var player_speed: float = 400.0
@export var player_acceleration: float = 4000.0
@export var player_friction: float = 5000.0
@export var animated_sprite: AnimatedSprite2D = null
@export var player_sprite: Sprite2D = null
@export var corruption_area: Area2D = null

var input: Vector2

var minions: Array[Node2D] = []
var corrupting: bool = false
var corruption_polygon: PackedVector2Array
var corruption_drain_rate: float = 11.0
var corruption_timer: float = 0.0
@export var corruption_duration: float = 5.0

const UPGRADE_RADIUS := 250.0 

@onready var _camera: Camera2D = $Camera2D
var _shake_amount: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Effects.shake_requested.connect(_on_shake_requested)

	if get_tree().get_first_node_in_group("king"):
		_summon_army()

func _on_shake_requested(amount: float) -> void:
	_shake_amount = max(_shake_amount, amount)

func _update_shake(delta: float) -> void:
	if _shake_amount <= 0.1:
		_shake_amount = 0.0
		_camera.offset = Vector2.ZERO
		return
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_amount
	_shake_amount = max(_shake_amount - 40.0 * delta, 0.0)

func _try_upgrade(type: Npc.UnitType, cost: int) -> void:
	var unit := _nearest_bad_unit(type)
	if unit == null:
		return
	if not GameManager.try_spend_mana(cost):
		return
	unit.upgrade_to(type)
	SoundManager.play("convert_bad")

func _nearest_bad_unit(skip_type: Npc.UnitType) -> Npc:
	var best: Npc = null
	var best_dist := UPGRADE_RADIUS * UPGRADE_RADIUS
	for n in get_tree().get_nodes_in_group("npc"):
		var npc := n as Npc
		if npc == null or npc.team != Npc.Team.BAD or npc.unit_type == skip_type:
			continue
		var d := global_position.distance_squared_to(npc.global_position)
		if d < best_dist:
			best_dist = d
			best = npc
	return best

#za kvadrat okol, da vidš koga boš upgradal
func get_upgrade_target(skip_type: Npc.UnitType) -> Npc:
	return _nearest_bad_unit(skip_type)

func _physics_process(delta: float) -> void:
	move(delta)
	_update_shake(delta)

	if not corrupting:
		if Input.is_action_just_pressed("summon"):
			spawn_minion()

		if Input.is_action_just_pressed("corrupt") and minions.size() >= 3:
			start_corruption()

		if Input.is_action_just_pressed("upgrade_healer"):
			_try_upgrade(Npc.UnitType.HEALER, GameManager.COST_HEALER)
		if Input.is_action_just_pressed("upgrade_knight"):
			_try_upgrade(Npc.UnitType.KNIGHT, GameManager.COST_KNIGHT)

		if Input.is_action_just_pressed("to_king"):
			_teleport_to_king()

	if corrupting:
		corruption_timer -= delta
		if corruption_timer <= 0.0:
			end_corruption()
			return

		if corruption_polygon.size() >= 3:
			for child in get_parent().get_children():
				var npc: Npc = child as Npc
				if npc and npc.team == 0 and Geometry2D.is_point_in_polygon(npc.position, corruption_polygon):
					npc.take_drain(corruption_drain_rate * delta)
	
func move(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction == Vector2.ZERO:
		player_state = IDLE
		apply_friction(player_friction * delta)
		animated_sprite.play("idle")
	else:
		player_state = RUN
		apply_movement(direction * player_acceleration * delta)
		animated_sprite.play("run")
		animated_sprite.flip_h = direction.x < 0
		player_sprite.flip_h = direction.x < 0

	move_and_slide()
	
func apply_friction(ammount: float) -> void:
	if velocity.length() > ammount:
		velocity -= velocity.normalized() * ammount
	else:
		velocity = Vector2.ZERO
		
func apply_movement(ammount: Vector2) -> void:
	velocity += ammount
	velocity = velocity.limit_length(player_speed)

func start_corruption() -> void:
	corrupting = true
	corruption_timer = corruption_duration

	corruption_polygon = PackedVector2Array()
	for i in range(minions.size()):
		var minion: Node2D = minions[i]
		minion.set("circle_color", Color.RED)
		minion.queue_redraw()
		corruption_polygon.append(minion.position)

func end_corruption() -> void:
	corrupting = false
	corruption_polygon = PackedVector2Array()

	for m in minions:
		if is_instance_valid(m):
			m.queue_free()
	minions.clear()

func _teleport_to_king() -> void:
	if not GameManager.try_spend_mana(10):
		return

	Effects.burst(global_position, Color.MAGENTA, 12)
	Effects.shake(4.0)
	SoundManager.play("castle_purify")

	get_tree().change_scene_to_file("res://src/levels/boss_arena.tscn")


func _summon_army() -> void:
	var count := GameManager.bad_npcs
	for i in count:
		var offset := Vector2(randf_range(-120.0, 120.0), randf_range(-120.0, 120.0))
		spawn_minion_at(global_position + offset)


func spawn_minion_at(pos: Vector2) -> void:
	var minion: Node2D = Node2D.new()
	minion.name = "Minion"
	minion.global_position = pos

	var script: Script = preload("res://src/ancient_demon/minion.gd")
	minion.set_script(script)

	var shape: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = 8.0
	shape.shape = circle
	minion.add_child(shape)

	var parent: Node2D = get_parent()
	if parent:
		parent.add_child(minion)

	minions.append(minion)


func spawn_minion() -> void:
	spawn_minion_at(global_position)
