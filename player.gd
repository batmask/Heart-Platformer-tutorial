extends CharacterBody2D


@export var movement_data : PlayerMovementData

const JUMP_VELOCITY_RELEASE_MOD = 2
enum JUMP_ENV_STATE { FLOOR, WALL, AIR, COYOTE }
enum JUMP_STATE { NONE, JUMP, WALL_JUMP}

@export var max_jump = 2

var jump_count = max_jump
var previous_jump_env_state = JUMP_ENV_STATE.FLOOR
var jump_env_state = JUMP_ENV_STATE.FLOOR
var previous_jump_state = JUMP_STATE.NONE
var jump_state = JUMP_STATE.NONE

var previous_physics_delta = 0.0
var coyote_timer_mod_delta = 0.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var coyote_jump_timer = $CoyoteJumpTimer
@onready var starting_position = global_position

func _physics_process(delta):
	apply_gravity(delta)
	
	check_jump_state(delta)
#	handle_wall_jump()
	handle_jump()
	
	var input_axis = Input.get_axis("ui_left", "ui_right")
	
	handle_acceleration(input_axis, delta)	
	handle_air_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	apply_air_resistance(input_axis, delta)
	update_animations(input_axis)
	
#	var was_on_floor = (jump_state == JUMP_STATE.FLOOR)
	move_and_slide()
#	var just_left_ledge = was_on_floor and not (jump_state != JUMP_STATE.FLOOR) and velocity.y >= 0
#	if just_left_ledge:
#		coyote_jump_timer.start()
	
	previous_physics_delta = delta
	previous_jump_env_state = jump_env_state
	previous_jump_state = jump_state
	
	
func apply_gravity(delta):
	if not is_on_floor():
		velocity.y += gravity * movement_data.gravity_scale * delta	

func check_jump_state(delta):
	if is_on_wall_only():
		jump_env_state = JUMP_ENV_STATE.WALL
		jump_state = JUMP_STATE.NONE	
	elif is_on_floor():
		jump_env_state = JUMP_ENV_STATE.FLOOR
		jump_state = JUMP_STATE.NONE
		jump_count = max_jump
	elif jump_env_state == JUMP_ENV_STATE.COYOTE:
		if coyote_jump_timer.time_left < coyote_timer_mod_delta:
			jump_env_state = JUMP_ENV_STATE.AIR			
	else:
		if jump_env_state == JUMP_ENV_STATE.FLOOR and velocity.y >= 0: # just left floor
			jump_env_state = JUMP_ENV_STATE.COYOTE
			coyote_jump_timer.start()
			coyote_timer_mod_delta = previous_physics_delta
		else:			
			jump_env_state = JUMP_ENV_STATE.AIR	
	
	if jump_env_state != previous_jump_env_state:
		print("jump env state: ", JUMP_ENV_STATE.keys()[jump_env_state])
	
	if jump_state != previous_jump_state:
		print("jump state: ", JUMP_STATE.keys()[jump_state])

func handle_jump():
	if Input.is_action_just_pressed("jump"):
		if jump_env_state == JUMP_ENV_STATE.WALL:
			var wall_normal = get_wall_normal()	
			velocity.x = wall_normal.x * movement_data.speed
			velocity.y = movement_data.jump_velocity
			jump_state = JUMP_STATE.WALL_JUMP
			
		if (jump_env_state == JUMP_ENV_STATE.FLOOR or jump_env_state == JUMP_ENV_STATE.COYOTE) and jump_count > 0:
			velocity.y = movement_data.jump_velocity
			jump_state = JUMP_STATE.JUMP
			jump_count -= 1
			print("jump started")
		
		# multi jump
		if jump_env_state == JUMP_ENV_STATE.AIR and jump_count > 0:
			velocity.y = movement_data.jump_velocity * 0.8
			jump_state = JUMP_STATE.JUMP
			jump_count -= 1
			print("double jump")
	
	if Input.is_action_just_released("jump") and jump_env_state == JUMP_ENV_STATE.AIR and velocity.y < 0:
		velocity.y = velocity.y/JUMP_VELOCITY_RELEASE_MOD
		print("short jump")
	
		print("jump state: ", JUMP_STATE.keys()[jump_state])

#func handle_wall_jump():
#	if jump_env_state != JUMP_ENV_STATE.WALL: return
#
#	var wall_normal = get_wall_normal()	
#	if Input.is_action_just_pressed("jump"):
#		velocity.x = wall_normal.x * movement_data.speed
#		velocity.y = movement_data.jump_velocity
#		jump_state = JUMP_STATE.WALL_JUMP
	
func handle_acceleration(input_axis, delta):
	if not is_on_floor(): return 
	
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.acceleration * delta)

func handle_air_acceleration(input_axis, delta):
	if is_on_floor(): return
	
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, movement_data.speed * input_axis, movement_data.air_acceleration * delta)
	
func apply_friction(input_axis, delta):
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.friction * delta)
		
func apply_air_resistance(input_axis, delta):
	if input_axis == 0 and not is_on_floor():
		velocity.x = move_toward(velocity.x, 0, movement_data.air_resistance * delta)

func update_animations(input_axis):
	if input_axis != 0:
		animated_sprite_2d.flip_h = (input_axis < 0)
		animated_sprite_2d.play("run")
	else:
		animated_sprite_2d.play("idle")
	
	if not is_on_floor():
		animated_sprite_2d.play("jump")

func damage():
	print("damage")
	global_position = starting_position
