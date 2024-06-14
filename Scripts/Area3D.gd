extends Area3D

# Store detected enemies
var detected_enemies = []

signal locked_enemy_visible
signal locked_enemy_invisible

func _ready():
	# Connect the body_entered and body_exited signals
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

##################
##    METHODS   ##
##################

func get_first_enemy():
	if detected_enemies.size() > 0:
		var enemy = detected_enemies[0]
		#detected_enemies.erase(enemy)
		return enemy
	else:
		return null

func get_closest_enemy_to_cursor():
	var closest_enemy = null
	var closest_distance = INF

	# Get the screen center position
	var screen_center = get_viewport().size / 2
	var screen_center_f = Vector2(screen_center.x, screen_center.y)

	# Get the camera node
	var camera = get_viewport().get_camera_3d()

	for enemy in detected_enemies:
		# Convert enemy's world position to screen position
		var screen_position = camera.unproject_position(enemy.global_transform.origin)

		# Calculate the distance to the center of the screen
		var distance = screen_center_f.distance_to(screen_position)

		if distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy

	return closest_enemy

func is_locked_enemy_visible(body):
	if body.is_outline:
		locked_enemy_visible.emit()

func is_locked_enemy_invisible(body):
	if body.is_outline:
		locked_enemy_invisible.emit()

##################
##    SIGNALS   ##
##################

func _on_body_entered(body):
	if body.is_in_group("enemies"):
		detected_enemies.append(body)
		is_locked_enemy_visible(body)

func _on_body_exited(body):
	if body.is_in_group("enemies"):
		detected_enemies.erase(body)
		is_locked_enemy_invisible(body)
