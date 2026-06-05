extends Node2D

const GoodNPC = preload("res://src/goodNPC/goodNPC.tscn")
const BadNPC = preload("res://src/badNPC/badNPC.tscn")
const SPAWN_RADIUS = 250.0


func _ready() -> void:
	for marker in $GoodGuySpawns.get_children():
		_spawn_npcs(GoodNPC, marker.global_position, 10)

	for marker in $BadGuySpawns.get_children():
		_spawn_npcs(BadNPC, marker.global_position, 10)


func _spawn_npcs(scene: PackedScene, center: Vector2, count: int) -> void:
	for i in count:
		var angle := randf() * TAU
		var dist := randf_range(50.0, SPAWN_RADIUS)
		var npc = scene.instantiate()
		npc.position = center + Vector2(cos(angle), sin(angle)) * dist
		add_child(npc)
