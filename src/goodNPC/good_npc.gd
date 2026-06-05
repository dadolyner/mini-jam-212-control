extends CharacterBody2D

const SPEED = 60.0

enum State { WANDERING, IDLE }

var _state := State.IDLE
var _state_timer := 0.0
var _move_dir := 1.0


func _ready() -> void:
	_pick_next_state()


func _physics_process(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_next_state()

	if _state == State.WANDERING:
		velocity.x = _move_dir * SPEED
		if is_on_wall():
			_move_dir *= -1.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)

	$Sprite2D.flip_h = velocity.x < 0.0

	move_and_slide()


func _pick_next_state() -> void:
	if _state == State.WANDERING:
		_state = State.IDLE
		_state_timer = randf_range(1.0, 3.0)
	else:
		_state = State.WANDERING
		_state_timer = randf_range(1.5, 4.0)
		_move_dir = 1.0 if randf() > 0.5 else -1.0
