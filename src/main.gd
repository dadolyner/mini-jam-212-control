extends Node2D

@onready var _nav_region: NavigationRegion2D = $NavRegion
@onready var _dividing_wall: StaticBody2D = $DividingWall
@onready var _objective_label: Label = $Objective/ObjectiveLabel
@onready var _banner_label: Label = $Objective/BannerLabel

var _marches_started := false
var _won := false


func _enter_tree() -> void:
	GameManager.reset_run()


func _ready() -> void:
	_nav_region.bake_navigation_polygon(false)

	GameManager.castle_captured.connect(_on_castle_captured)
	_banner_label.visible = false
	_objective_label.text = "Objective: Capture the first castle (0/3)"
	GameManager.notify_state()


func _on_castle_captured(_old_team: int, _new_team: int) -> void:
	if not _marches_started and GameManager.bad_castles >= 1:
		_marches_started = true
		_drop_wall()

	_objective_label.text = "Objective: Capture the castles (%d/3)" % GameManager.bad_castles

	if not _won and GameManager.good_castles == 0:
		_win()


func _drop_wall() -> void:
	if is_instance_valid(_dividing_wall):
		_dividing_wall.queue_free()
	GameManager.marches_enabled = true
	await get_tree().physics_frame
	_nav_region.bake_navigation_polygon(false)


func _win() -> void:
	_won = true
	_objective_label.visible = false
	_banner_label.text = "Now press \"T\" to teleport to the boss fight."
	_banner_label.visible = true
	GameManager.boss_unlocked = true
