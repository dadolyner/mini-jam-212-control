extends Node2D

var circle_radius := 8.0
var circle_color := Color.WHITE

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, circle_radius, circle_color)
