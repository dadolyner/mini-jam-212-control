extends Node2D

@onready var win_screen: CanvasLayer = $WinScreen
@onready var continue_button: Button = $WinScreen/Container/ContinueButton
@onready var demon: Demon = $Demon
@onready var king: Area2D = $King

func _ready() -> void:
	king.defeated.connect(_on_king_defeated)
	continue_button.pressed.connect(_on_continue_pressed)

func _on_king_defeated() -> void:
	demon.queue_free()
	king.queue_free()
	win_screen.show()

func _on_continue_pressed() -> void:
	get_tree().change_scene_to_file("res://src/main.tscn")
