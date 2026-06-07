extends Area2D
signal defeated

@export var base_health: float = 5000.0
@export var minion_dps_per_unit: float = 15.0
@export var click_damage: float = 10.0
@export var move_speed: float = 120.0
@export var minion_detect_radius: float = 200.0
@export var minion_kill_rate: float = 2.0

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var health_bar: ProgressBar = $HealthBar
@onready var label: Label = $Label
@onready var dps_label: Label = $DpsLabel

var health: float
var max_health: float
var is_defeated: bool = false
var is_mouse_held: bool = false

var target_position: Vector2
var is_moving: bool = false
var patrol_timer: Timer
var kill_timer: float = 0.0

func _ready() -> void:
	add_to_group("king")
	max_health = base_health
	health = max_health
	health_bar.max_value = 1.0
	health_bar.value = 1.0

	patrol_timer = Timer.new()
	patrol_timer.one_shot = true
	patrol_timer.timeout.connect(pick_new_target_position)
	add_child(patrol_timer)
	
	pick_new_target_position()


func pick_new_target_position() -> void:
	target_position = Vector2(randf_range(-600.0, 600.0), randf_range(-300.0, 300.0))
	is_moving = true

func _process(delta: float) -> void:
	if is_defeated:
		return

	var dps: float = GameManager.bad_npcs * minion_dps_per_unit
	health -= dps * delta
	health_bar.value = health / max_health

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		if not is_mouse_held:
			is_mouse_held = true
			var circle := $CollisionShape2D.shape as CircleShape2D
			if circle and global_position.distance_to(get_global_mouse_position()) <= circle.radius:
				take_damage(click_damage)
	else:
		is_mouse_held = false

	_patrol(delta)
	_kill_nearby_minions(delta)

	if GameManager.bad_npcs > 0:
		dps_label.text = str(GameManager.bad_npcs) + " minions | " + str(dps) + " DPS"
	else:
		dps_label.text = "Click for 10 damage"

	if health <= 0 and not is_defeated:
		is_defeated = true
		defeated.emit()


func _patrol(delta: float) -> void:
	if not is_moving:
		return

	var diff: Vector2 = target_position - position
	var dist: float = diff.length()
	if dist < 10.0:
		is_moving = false
		patrol_timer.start(randf_range(0.5, 2.0))
		return

	position += diff.normalized() * move_speed * delta


func _kill_nearby_minions(delta: float) -> void:
	if GameManager.bad_npcs <= 0:
		return

	kill_timer += delta
	var interval: float = 1.0 / minion_kill_rate
	if kill_timer < interval:
		return
	kill_timer = 0.0

	var demon: Demon = get_node_or_null("../Demon")
	if demon == null:
		return

	var to_kill: Array[Node2D] = []
	for minion in demon.minions:
		if not is_instance_valid(minion):
			continue
		if global_position.distance_to(minion.global_position) <= minion_detect_radius:
			to_kill.append(minion)

	for minion in to_kill:
		minion.queue_free()
		demon.minions.erase(minion)
		GameManager.unregister_npc(GameManager.TEAM_BAD)


func take_damage(amount: float) -> void:
	if is_defeated:
		return

	health -= amount
	health_bar.value = health / max_health

	if health <= 0 and not is_defeated:
		is_defeated = true
		defeated.emit()
