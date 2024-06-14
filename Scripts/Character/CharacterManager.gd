extends CharacterBody3D

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
const MOUSE_SENSITIVITY = 0.002  # turning speed
const ZOOM_SENSITIVITY = 1.0  # zooming speed
const MIN_ZOOM_DISTANCE = 2.0  # minimum distance from the character
const MAX_ZOOM_DISTANCE = 20.0  # maximum distance from the character

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

# Reference to the camera and pivot
@export var camera: Camera3D
@export var pivot: Node3D

func _ready():
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		# Rotate the pivot (and hence the camera) around the character
		pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		# Rotate the camera up and down
		#var camera_rotation = camera.rotation_degrees
		#camera_rotation.x -= event.relative.y * MOUSE_SENSITIVITY
		#camera_rotation.x = clamp(camera_rotation.x, -89, 89)
		#camera.rotation_degrees = camera_rotation
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-ZOOM_SENSITIVITY)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(ZOOM_SENSITIVITY)

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("strafe_left", "strafe_right", "move_forward", "move_backward")
	var direction = (pivot.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction:	
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

func zoom_camera(amount):
	var new_position = camera.transform.origin + camera.transform.basis.z * amount
	var distance = (new_position - pivot.transform.origin).length()

	if distance > MIN_ZOOM_DISTANCE and distance < MAX_ZOOM_DISTANCE:
		camera.translate(Vector3(0, 0, amount))
