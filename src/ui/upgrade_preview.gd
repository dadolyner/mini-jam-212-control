extends Node2D

const _BOX_HALF   := 28.0
const _LINE_WIDTH := 2.0

const _COLOR_AFFORDABLE := Color(0.3, 1.0, 0.4, 0.9)
const _COLOR_EXPENSIVE  := Color(0.55, 0.55, 0.55, 0.7)

const _CORRUPT_FILL   := Color(1.0, 0.1, 0.1, 0.22)
const _CORRUPT_BORDER := Color(1.0, 0.2, 0.2, 0.85)
const _TIMER_FONT_SIZE := 90


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var demon := players[0] as Demon
	if demon == null:
		return

	_draw_corruption(demon)
	_draw_upgrade_previews(demon)


func _draw_corruption(demon: Demon) -> void:
	if not demon.corrupting:
		return
	var poly := demon.corruption_polygon
	if poly.size() < 3:
		return

	draw_colored_polygon(poly, _CORRUPT_FILL)

	var closed: PackedVector2Array = PackedVector2Array(poly)
	closed.append(poly[0])
	draw_polyline(closed, _CORRUPT_BORDER, 2.0)

	var centroid := Vector2.ZERO
	for p in poly:
		centroid += p
	centroid /= float(poly.size())

	var font := ThemeDB.fallback_font
	var fs := _TIMER_FONT_SIZE
	var txt := "%.1f" % maxf(demon.corruption_timer, 0.0)
	var text_pos := Vector2(centroid.x - 100.0, centroid.y + float(fs) * 0.35)
	draw_string(font, text_pos + Vector2(3.0, 3.0), txt, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, Color(0.0, 0.0, 0.0, 0.8))
	draw_string(font, text_pos, txt, HORIZONTAL_ALIGNMENT_CENTER, 200, fs, Color(1.0, 1.0, 1.0, 0.95))


func _draw_upgrade_previews(demon: Demon) -> void:
	var healer_target := demon.get_upgrade_target(Npc.UnitType.HEALER)
	var knight_target := demon.get_upgrade_target(Npc.UnitType.KNIGHT)

	if healer_target != null and healer_target == knight_target:
		_draw_box(healer_target.global_position, [GameManager.COST_HEALER, GameManager.COST_KNIGHT])
		return

	if healer_target != null:
		_draw_box(healer_target.global_position, [GameManager.COST_HEALER])
	if knight_target != null:
		_draw_box(knight_target.global_position, [GameManager.COST_KNIGHT])


func _draw_box(world_pos: Vector2, costs: Array) -> void:
	var all_affordable: bool = true
	for i in costs.size():
		if GameManager.mana < int(costs[i]):
			all_affordable = false
			break

	var box_col := _COLOR_AFFORDABLE if all_affordable else _COLOR_EXPENSIVE
	var fill_col := Color(box_col.r, box_col.g, box_col.b, 0.12)
	var rect := Rect2(world_pos - Vector2(_BOX_HALF, _BOX_HALF), Vector2(_BOX_HALF * 2.0, _BOX_HALF * 2.0))
	draw_rect(rect, fill_col)
	draw_rect(rect, box_col, false, _LINE_WIDTH)
