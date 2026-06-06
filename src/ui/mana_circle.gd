extends Control

const _BG_COLOR := Color(0.05, 0.05, 0.22, 0.92)
const _FILL_COLOR := Color(0.28, 0.18, 0.82, 0.95)
const _TEXT_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const _RING_WIDTH := 12.0
const _MARGIN := 8.0

var _current: int = 20
var _maximum: int = 20

@onready var _label: Label = $Label


func _ready() -> void:
	_label.text = "%d/%d" % [_current, _maximum]


func set_mana(current_val: int, max_val: int) -> void:
	_current = current_val
	_maximum = max_val
	_label.text = "%d/%d" % [_current, _maximum]
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - _MARGIN

	draw_arc(center, radius, 0.0, TAU, 64, _BG_COLOR, _RING_WIDTH, true)

	if _maximum > 0:
		var fill_angle := TAU * (float(_current) / float(_maximum))
		draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + fill_angle, 64, _FILL_COLOR, _RING_WIDTH, true)
