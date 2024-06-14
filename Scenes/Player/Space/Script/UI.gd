extends CanvasLayer

@export var target:Node
@export var speedControl: Control
var gauge:ProgressBar
var label:Label
var desiredgauge:ProgressBar
var desiredlabel:Label

@export var healthShieldControl: Control
var healthBar: ProgressBar
var shieldBar: ProgressBar

func _ready():
	gauge = speedControl.get_child(0)
	label = gauge.get_child(0)
	desiredgauge = speedControl.get_child(1)
	desiredlabel = desiredgauge.get_child(0)
	healthBar = healthShieldControl.get_child(0)
	shieldBar = healthShieldControl.get_child(1)
	on_update_health()

func _process(_delta):
	update_speed()

func update_speed():
	var speed = abs(target.current_speed_vertical) + abs(target.current_speed_forward) + abs(target.current_speed_strafe)
	var desiredSpeed = abs(target.desired_speed_vertical) + abs(target.desired_speed_forward) + abs(target.desired_speed_strafe)
	var max_speed = target.MAX_SPEED
	
	gauge.value = (speed/max_speed) * 100
	label.text = str(round(speed)) + "m/s"
	
	desiredgauge.value = (desiredSpeed/max_speed) * 100
	desiredlabel.text = str(round(desiredSpeed)) + "m/s"

func on_update_health():
	healthBar.max_value = target.health
	healthBar.value = target.health
	shieldBar.max_value = target.shield
	shieldBar.value = target.shield
	pass
