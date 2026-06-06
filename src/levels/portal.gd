extends Area2D

@export_file("*.tscn") var next_scene: String = "res://src/main.tscn"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and next_scene != "":
		get_tree().change_scene_to_file(next_scene)
