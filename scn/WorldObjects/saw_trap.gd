extends Path2D

@export var is_looped = true
@export var speed = 0.05
@export var speedScale = 1.0

@onready var path = $PathFollow2D
@onready var animPlayer = $AnimationPlayer

func _ready():
	# if curve ended in the start
	if !is_looped:
		animPlayer.play("move")
		animPlayer.speed_scale = speedScale
		set_process(false)

func _process(_delta):
	path.progress += speed
