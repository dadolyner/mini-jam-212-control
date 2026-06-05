extends CharacterBody2D
enum {IDLE, RUN}
var player_state = IDLE

@export var player_speed: float = 400.0
@export var player_acceleration: float = 4000.0
@export var player_friction: float = 5000.0
@export var animated_sprite: AnimatedSprite2D = null
@export var player_sprite: Sprite2D = null


var input: Vector2

func _physics_process(delta: float) -> void:
	move(delta)
	
func move(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if direction == Vector2.ZERO:
		player_state = IDLE
		apply_friction(player_friction * delta)
		animated_sprite.play("idle")
	else:
		player_state = RUN
		apply_movement(direction * player_acceleration * delta)
		animated_sprite.play("run")
		animated_sprite.flip_h = direction.x < 0
		player_sprite.flip_h = direction.x < 0

	move_and_slide()
	
func apply_friction(ammount: Variant) -> void:
	if velocity.length() > ammount:
		velocity -= velocity.normalized() * ammount
	else:
		velocity = Vector2.ZERO
		
func apply_movement(ammount: Variant) -> void:
	velocity += ammount
	velocity = velocity.limit_length(player_speed)
