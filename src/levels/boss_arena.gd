extends Node2D
const BAD_NPC = preload("uid://bnwdtmq2vpmvo")

@onready var win_screen: CanvasLayer = $WinScreen
@onready var continue_button: Button = $WinScreen/Container/ContinueButton
@onready var demon: Demon = $Demon
@onready var king: Area2D = $King
@onready var bad_npcs: Node2D = $BadNpcs

func _ready() -> void:
	king.defeated.connect(_on_king_defeated)
	continue_button.pressed.connect(_on_continue_pressed)
	
	for n in GameManager.bad_npcs_saved:
		var bad_npc: Npc = BAD_NPC.instantiate()
		bad_npc.global_position.x = demon.global_position.x + randf_range(-10.0, 10.0)
		bad_npc.global_position.y = demon.global_position.y + randf_range(-10.0, 10.0)
		bad_npcs.add_child(bad_npc)

func _on_king_defeated() -> void:
	demon.queue_free()
	king.queue_free()
	win_screen.show()

func _on_continue_pressed() -> void:
	GameManager.bad_npcs = 0
	get_tree().change_scene_to_file("res://src/main.tscn")
