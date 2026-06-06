class_name Castle
extends Node2D

enum Team { GOOD, BAD }

const GoodNPC = preload("res://src/goodNPC/goodNPC.tscn")
const BadNPC = preload("res://src/badNPC/badNPC.tscn")

const CORRUPT_TINT := Color(0.45, 0.3, 0.6) 

@export var team: Team = Team.GOOD
@export var max_health := 1000.0   
@export var aura_radius := 650.0   
@export var corrupt_rate := 40.0  
@export var regen_rate := 30.0     
@export var decay_rate := 20.0     
@export var turret_drain := 8.0    
@export var heal_rate := 12.0
@export var spawn_interval := 30.0
@export var order_interval := 20.0  #Kok pogosto pošilja unite v rangu v nasprotn grad

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _health_bar: ProgressBar = $HealthBar
@onready var _health_label: Label = $HealthLabel
@onready var _detection_shape: CollisionShape2D = $DetectionArea/CollisionShape2D

var health: float
var _npcs: Array[Npc] = []    #za trackanje kolk je NPCjev okol
var _spawn_timer := 0.0
var _order_timer := 0.0
var _spawn_label: Label


func _ready() -> void:
	var shape := _detection_shape.shape as CircleShape2D
	if shape:
		shape.radius = aura_radius

	health = max_health
	_health_bar.max_value = max_health
	_update_health_display()

	add_to_group("castle")
	GameManager.register_castle(team)

	$DetectionArea.body_entered.connect(_on_body_entered)
	$DetectionArea.body_exited.connect(_on_body_exited)

	_spawn_timer = spawn_interval
	_order_timer = order_interval
	_refresh_visuals()
	_create_spawn_label()
	queue_redraw()


func _draw() -> void:
	var color := Color(0.3, 0.9, 0.4, 0.12) if team == Team.GOOD else Color(0.6, 0.3, 0.8, 0.14)
	draw_circle(Vector2.ZERO, aura_radius, color)


func _physics_process(delta: float) -> void:
	_prune_npcs()

	var good := _count_team(Team.GOOD)
	var bad := _count_team(Team.BAD)

	if team == Team.GOOD:
		var net_enemy := bad - good
		if net_enemy > 0:
			health -= corrupt_rate * net_enemy * delta
		else:
			health = min(health + regen_rate * delta, max_health)
		if health <= 0.0:
			_flip_to(Team.BAD)
	else:
		var net_purifier := good - bad
		if net_purifier > 0:
			health -= corrupt_rate * net_purifier * delta
		elif bad > 0:
			health = min(health + regen_rate * delta, max_health)
		else:
			health -= decay_rate * delta
		if health <= 0.0:
			_flip_to(Team.GOOD)

	_update_health_display()
	_spawn_label.text = "%.1f" % maxf(_spawn_timer, 0.0)

	_run_turret(delta)
	_run_aura(delta)
	_tick_spawn(delta)
	_tick_orders(delta)


func _flip_to(new_team: Team) -> void:
	var old_team := team
	team = new_team
	health = max_health
	GameManager.castle_changed_team(old_team, new_team)
	_refresh_visuals()
	queue_redraw()

	if new_team == Team.BAD:
		Effects.burst(global_position, Color(0.6, 0.25, 0.8), 48)
		Effects.shake(14.0)
		SoundManager.play("castle_corrupt")
	else:
		Effects.burst(global_position, Color(0.3, 0.9, 0.4), 48)
		Effects.shake(8.0)
		SoundManager.play("castle_purify")


#za grad spawn timer
func _create_spawn_label() -> void:
	_spawn_label = Label.new()
	_spawn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_spawn_label.position = Vector2(-60.0, -220.0)
	_spawn_label.size = Vector2(120.0, 28.0)
	_spawn_label.add_theme_font_size_override("font_size", 18)
	_spawn_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4, 1.0))
	_spawn_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_spawn_label.add_theme_constant_override("outline_size", 4)
	add_child(_spawn_label)


func _update_health_display() -> void:
	_health_bar.value = health
	_health_label.text = "%d / %d" % [round(health), round(max_health)]


func _refresh_visuals() -> void:
	_sprite.modulate = CORRUPT_TINT if team == Team.BAD else Color.WHITE
	var fill := _health_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if fill:
		fill.bg_color = Color(0.6, 0.25, 0.8) if team == Team.BAD else Color(0.2, 0.8, 0.25)

func _run_turret(delta: float) -> void:
	var enemy_team := Team.BAD if team == Team.GOOD else Team.GOOD
	var target := _nearest_of_team(enemy_team)
	if target:
		target.take_drain(turret_drain * delta)


func _run_aura(delta: float) -> void:
	var amount := heal_rate * delta
	for n in _npcs:
		if is_instance_valid(n) and n.team == team:
			n.heal(amount)


func _tick_spawn(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer > 0.0:
		return
	_spawn_timer = spawn_interval

	var scene: PackedScene = GoodNPC if team == Team.GOOD else BadNPC
	var npc = scene.instantiate()
	var angle := randf() * TAU
	npc.position = global_position + Vector2(cos(angle), sin(angle)) * 120.0
	get_parent().add_child(npc)


func _tick_orders(delta: float) -> void:
	_order_timer -= delta
	if _order_timer > 0.0:
		return
	_order_timer = order_interval

	var enemy_castle := _nearest_enemy_castle()
	if enemy_castle == null:
		return
	# Send the friendly units currently defending this castle to assault the enemy stronghold.
	for n in _npcs:
		if is_instance_valid(n) and n.team == team:
			n.set_objective(enemy_castle)


func _nearest_enemy_castle() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for c in get_tree().get_nodes_in_group("castle"):
		var castle := c as Castle
		if castle == null or castle == self or castle.team == team:
			continue
		var d := global_position.distance_squared_to(castle.global_position)
		if d < best_dist:
			best_dist = d
			best = castle
	return best

func _on_body_entered(body: Node) -> void:
	var npc := body as Npc
	if npc and not _npcs.has(npc):
		_npcs.append(npc)


func _on_body_exited(body: Node) -> void:
	var npc := body as Npc
	if npc:
		_npcs.erase(npc)


func _prune_npcs() -> void:
	for i in range(_npcs.size() - 1, -1, -1):
		if not is_instance_valid(_npcs[i]):
			_npcs.remove_at(i)


func _count_team(t: int) -> int:
	var count := 0
	for n in _npcs:
		if is_instance_valid(n) and n.team == t:
			count += 1
	return count


func _nearest_of_team(t: int) -> Npc:
	var best: Npc = null
	var best_dist := INF
	for n in _npcs:
		if not is_instance_valid(n) or n.team != t:
			continue
		var d := global_position.distance_squared_to(n.global_position)
		if d < best_dist:
			best_dist = d
			best = n
	return best
