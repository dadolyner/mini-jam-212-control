extends Control

const _MAP_L := -3000.0
const _MAP_R :=  4000.0
const _MAP_T := -2500.0
const _MAP_B :=  3500.0

const _BG_COLOR     := Color(0.05, 0.05, 0.07, 0.88)
const _BORDER_COLOR := Color(0.4,  0.4,  0.45, 1.0)
const _GOOD_COLOR   := Color(0.25, 0.55, 1.0,  1.0)
const _BAD_COLOR    := Color(1.0,  0.25, 0.25, 1.0)
const _PLAYER_COLOR := Color(1.0,  0.95, 0.2,  1.0)
const _CASTLE_SIZE   := 14.0
const _CASTLE_BORDER := 2.0
const _UNIT_RADIUS   := 2.5
const _PLAYER_RADIUS := 4.5


func _process(_delta: float) -> void:
	queue_redraw()


func _world_to_map(world: Vector2) -> Vector2:
	var nx := (world.x - _MAP_L) / (_MAP_R - _MAP_L)
	var ny := (world.y - _MAP_T) / (_MAP_B - _MAP_T)
	return Vector2(nx * size.x, ny * size.y)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), _BG_COLOR)
	draw_rect(Rect2(Vector2.ZERO, size), _BORDER_COLOR, false, 1.5)

	for c in get_tree().get_nodes_in_group("castle"):
		var castle := c as Castle
		if castle == null:
			continue
		var mp := _world_to_map(castle.global_position)
		var half := _CASTLE_SIZE * 0.5
		var col := _GOOD_COLOR if castle.team == Castle.Team.GOOD else _BAD_COLOR
		draw_rect(Rect2(mp - Vector2(half, half), Vector2(_CASTLE_SIZE, _CASTLE_SIZE)), col)
		draw_rect(Rect2(mp - Vector2(half, half), Vector2(_CASTLE_SIZE, _CASTLE_SIZE)), Color.WHITE, false, _CASTLE_BORDER)

	for n in get_tree().get_nodes_in_group("npc"):
		var npc := n as Npc
		if npc == null:
			continue
		var mp := _world_to_map(npc.global_position)
		var col := _GOOD_COLOR if npc.team == Npc.Team.GOOD else _BAD_COLOR
		draw_circle(mp, _UNIT_RADIUS, col)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player := players[0] as Node2D
		if player != null:
			draw_circle(_world_to_map(player.global_position), _PLAYER_RADIUS, _PLAYER_COLOR)
