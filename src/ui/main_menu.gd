extends Control

const LEVEL_1 := "res://src/levels/level_1.tscn"


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(LEVEL_1)


func _on_quit_pressed() -> void:
	get_tree().quit()
