extends Node

## Central juice API. Call from anywhere:
##   Effects.burst(global_position, color)
##   Effects.shake(amount)

signal shake_requested(amount: float)


func burst(world_pos: Vector2, color: Color, amount := 16) -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return

	var p := CPUParticles2D.new()
	p.global_position = world_pos
	p.z_index = 50
	p.one_shot = true
	p.emitting = true
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 160.0
	p.gravity = Vector2.ZERO
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = color

	scene.add_child(p)
	p.finished.connect(p.queue_free)


func shake(amount: float) -> void:
	shake_requested.emit(amount)
