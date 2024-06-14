extends Node3D

signal set_cam_rotation(_cam_rotation : float)

const ZOOM_SENSITIVITY = 1.0  # zooming speed
const MIN_ZOOM_DISTANCE = 2.0  # minimum distance from the character
const MAX_ZOOM_DISTANCE = 20.0  # maximum distance from the character

@onready var yaw_node = $CameraYaw
@onready var pitch_node = $CameraYaw/CameraPitch
@onready var camera = $CameraYaw/CameraPitch/Camera3D
var yaw : float = 0
var pitch : float = 0
var yaw_sensitivity : float = 0.07
var pitch_sensitivity : float = 0.07
var yaw_acceleration : float = 15
var pitch_acceleration : float = 15
var pitch_max : float = 75
var pitch_min : float = -55
var tween : Tween

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(-ZOOM_SENSITIVITY)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(ZOOM_SENSITIVITY)
	elif event is InputEventPanGesture:
		# Zoom using trackpad pinch gesture
		zoom_camera(event.delta.y * ZOOM_SENSITIVITY)

func _input(event):
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += -event.relative.y * pitch_sensitivity

func _physics_process(delta):
	pitch = clamp(pitch, pitch_min, pitch_max)
	
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(pitch_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	
	set_cam_rotation.emit(yaw_node.rotation.y)

func zoom_camera(amount):
	var new_position = camera.transform.origin + camera.transform.basis.z * amount
	var distance = (new_position - yaw_node.transform.origin).length()

	if distance > MIN_ZOOM_DISTANCE and distance < MAX_ZOOM_DISTANCE:
		camera.translate(Vector3(0, 0, amount))
		
func _on_set_movement_state(_movement_state: MovementState):
	if tween:
		tween.kill()
		
	tween = create_tween()
	tween.tween_property(camera, "fov", _movement_state.camera_fov, 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
