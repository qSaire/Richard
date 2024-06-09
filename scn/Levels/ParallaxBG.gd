extends Node2D

var currentPos
var camera

func _ready():
	position = Vector2(0, 0)
	if get_parent().find_child("Player").get_child(-1) != null:
		camera = get_parent().find_child("Player").get_child(-1).find_child("Camera2D")
		currentPos = camera.get_target_position()

func _physics_process(_delta):
	camera = get_parent().find_child("Player").get_child(-1).find_child("Camera2D")
	if currentPos == null:
		currentPos = camera.get_target_position()
	
	if camera.get_target_position() != currentPos:
		var dist = currentPos - camera.get_target_position()
		currentPos = camera.get_target_position()
		for layer in get_children():
			layer.position.x += dist.x * layer.speed * 0.5
