extends Node2D

const _TILESET    = preload("res://assets/sprites/tileset.png")
const _TILE_FLOOR = Rect2(1156, 145, 260, 258)
const _TILE_SMALL = Rect2(1652, 148, 248, 245)
const _TILE_EDGE  = Rect2(634,  30,  266, 384)

# ~18 px world — slightly smaller than NPC bodies (~24 px wide capsule)
# 3 px overlap between tiles eliminates the black seams
const _TILE_SCALE = 0.20
const _FLOOR_STEP = 44.0
const _EDGE_STEP  = 44.0

const _MAP_L = -3000.0
const _MAP_R =  4000.0
const _MAP_T = -2500.0
const _MAP_B =  3500.0

# Corridor walls — must match StaticBody2D shapes in main.tscn
const _WALL_COLOR := Color(0.28, 0.28, 0.32)
const _WALLS: Array = [
	Rect2(  400, -930, 1000, 60),   # WallA — upper horizontal
	Rect2(-1100, 1370,  800, 60),   # WallB — mid-left horizontal
	Rect2( 1770, -400,   60, 1000), # WallC — center-right vertical
	Rect2( 1850, 1770,  700, 60),   # WallD — lower-right horizontal
	Rect2(-1030, -800,   60, 800),  # WallE — upper-left vertical
	Rect2(  950, 2370,  900, 60),   # WallF — lower horizontal
	Rect2( 2770, -700,   60, 600),  # WallG — upper-right vertical
	Rect2( -150, -830,  500, 60),   # WallH — upper-center horizontal
]

var _floor_dest: Array[Rect2] = []
var _floor_src:  Array[Rect2] = []
var _edges: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	# Floor tiles — 85 % main stone, 15 % cracked variant
	var x := _MAP_L + _FLOOR_STEP * 0.5
	while x < _MAP_R + _FLOOR_STEP:
		var y := _MAP_T + _FLOOR_STEP * 0.5
		while y < _MAP_B + _FLOOR_STEP:
			var src := _TILE_FLOOR if rng.randf() > 0.15 else _TILE_SMALL
			var w   := src.size.x * _TILE_SCALE
			var h   := src.size.y * _TILE_SCALE
			_floor_dest.append(Rect2(x - w * 0.5, y - h * 0.5, w, h))
			_floor_src.append(src)
			y += _FLOOR_STEP
		x += _FLOOR_STEP

	# Edge tiles — jagged side faces outward into the void
	x = _MAP_L + _EDGE_STEP * 0.5
	while x < _MAP_R + _EDGE_STEP:
		_edges.append([Vector2(x, _MAP_B), 0.0])          # bottom — jagged down
		_edges.append([Vector2(x, _MAP_T), PI])            # top    — jagged up
		x += _EDGE_STEP

	var y := _MAP_T + _EDGE_STEP * 0.5
	while y < _MAP_B + _EDGE_STEP:
		_edges.append([Vector2(_MAP_L, y), -PI * 0.5])    # left   — jagged left
		_edges.append([Vector2(_MAP_R, y),  PI * 0.5])    # right  — jagged right
		y += _EDGE_STEP

	queue_redraw()


func _draw() -> void:
	# Dark void outside the playable area
	draw_rect(
		Rect2(_MAP_L - 600, _MAP_T - 600, _MAP_R - _MAP_L + 1200, _MAP_B - _MAP_T + 1200),
		Color(0.05, 0.05, 0.07)
	)

	# Floor — all unrotated, drawn in one contiguous batch
	for i in _floor_dest.size():
		draw_texture_rect_region(_TILESET, _floor_dest[i], _floor_src[i])

	# Edge tiles — each needs its own rotation transform
	var ew := _TILE_EDGE.size.x * _TILE_SCALE
	var eh := _TILE_EDGE.size.y * _TILE_SCALE
	var half_dest := Rect2(-ew * 0.5, -eh * 0.5, ew, eh)
	for e in _edges:
		draw_set_transform(e[0], e[1], Vector2.ONE)
		draw_texture_rect_region(_TILESET, half_dest, _TILE_EDGE)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Corridor walls — dark stone bands matching StaticBody2D shapes in main.tscn
	for wall in _WALLS:
		draw_rect(wall, _WALL_COLOR)
