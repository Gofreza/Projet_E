extends SubViewportContainer

var planet_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	planet_scene = preload("res://Scenes/Menu/Planet.tscn")
	
	var instance = planet_scene.instantiate()
	$SubViewport.add_child(instance)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
