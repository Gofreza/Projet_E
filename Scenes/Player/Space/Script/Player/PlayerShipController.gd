extends ShipController

@onready var cam = $CameraRoot/CameraYaw/CameraPitch/Camera3D
@onready var birdcam = $CameraRoot/CameraYaw/CameraPitch/BirdCamera3D

func _ready() -> void:
	super._ready()
	cam.current = true
	birdcam.current = false

func _physics_process(delta: float):
	if Input.is_action_just_pressed("stop_moving"):
		desired_speed_forward = 0.0
		desired_speed_strafe = 0.0
		desired_speed_vertical = 0.0
		
	# Handle rolling input
	if Input.is_action_pressed("rotate_left"):
		apply_roll(roll_speed * delta)
	elif Input.is_action_pressed("rotate_right"):
		apply_roll(-roll_speed * delta)
	
	if Input.is_action_just_pressed("lock"):
		lock_enemy()
	
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		fire_cannons()
		
	if Input.is_action_just_pressed("spawn"):
		if cam.current:
			cam.current = false
			birdcam.current = true
		else:
			cam.current = true
			birdcam.current = false

	# Player-specific movement handling
	var input_dir = Input.get_vector("strafe_left", "strafe_right", "throttle_up", "throttle_down")
	var input_dir_y = Input.get_action_strength("pitch_up") - Input.get_action_strength("pitch_down")

	if input_dir.y < 0 and desired_speed_forward < MAX_SPEED:
		desired_speed_forward += desired_speed_acceleration * delta * MAX_SPEED
	elif input_dir.y > 0 and desired_speed_forward > MIN_SPEED:
		desired_speed_forward -= desired_speed_acceleration * delta * MAX_SPEED

	if input_dir.x != 0:
		desired_speed_strafe += input_dir.x * desired_speed_acceleration * delta * MAX_SPEED
		desired_speed_strafe = clamp(desired_speed_strafe, -MAX_SPEED, MAX_SPEED)
	else:
		desired_speed_strafe = lerp(desired_speed_strafe, 0.0, decceleration * delta)

	if input_dir_y != 0:
		desired_speed_vertical += input_dir_y * desired_speed_acceleration * delta * MAX_SPEED
		desired_speed_vertical = clamp(desired_speed_vertical, -MAX_SPEED, MAX_SPEED)
	else:
		desired_speed_vertical = lerp(desired_speed_vertical, 0.0, decceleration * delta)

	super._physics_process(delta)

func _on_mouse_analog_input_analog_input(analog: Vector2) -> void:
	turn_input = analog
