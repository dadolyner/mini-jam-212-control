extends Control

const _RING_COLOR := Color(0.9, 0.15, 0.15, 0.9)
const _BG_COLOR   := Color(0.15, 0.05, 0.05, 0.6)
const _RING_WIDTH := 10.0
const _MARGIN     := 6.0

var _progress: float = 0.0


func set_progress(t: float) -> void:
	_progress = clampf(t, 0.0, 1.0)
	visible = _progress > 0.0
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - _MARGIN

	draw_arc(center, radius, 0.0, TAU, 64, _BG_COLOR, _RING_WIDTH, true)

	if _progress > 0.0:
		var sweep := TAU * _progress
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + sweep, 64, _RING_COLOR, _RING_WIDTH, true)
