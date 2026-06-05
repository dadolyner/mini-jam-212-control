extends Node2D

const GoodNPC = preload("res://src/goodNPC/goodNPC.tscn")
const SPAWN_RADIUS = 250.0


func _ready() -> void:
	var center = $Marker2D.position
	for i in 30:
		var angle = randf() * TAU
		var dist = randf_range(50.0, SPAWN_RADIUS)
		var npc = GoodNPC.instantiate()
		npc.position = center + Vector2(cos(angle), sin(angle)) * dist
		add_child(npc)
