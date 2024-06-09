extends CharacterBody2D

const SPEED = 1500.0

var is_nearPlayer = false
var is_picked = Global.is_axePicked
var gravity = 980
var direction
var is_hitTheWall = false
var damage = 60

@onready var animSprite = get_node("AnimatedSprite2D")
@onready var animPlayer = get_node("AnimationPlayer")

const soundHit = preload("res://assets/sounds/Sword Impact Hit 1.wav")
const soundLand = preload("res://assets/sounds/land in grass 10.wav")

func _ready():
	$EquipLabel.text = InputMap.action_get_events("use")[0].as_text()[0] + " Взять"
	if is_picked:
		queue_free()

func _physics_process(delta):
	direction = Global.throwDirection
	
	if is_on_floor():
		is_hitTheWall = false
		if animPlayer.is_playing() && animPlayer.current_animation != "default":
			var randStream = AudioStreamRandomizer.new()
			randStream.add_stream(0, soundLand)
			randStream.random_pitch = 2
			$Sounds.stream = randStream
			$Sounds.play()
		
		animPlayer.play("default")
		velocity.y = 0
		velocity.x = 0
		if is_nearPlayer:
			$EquipLabel.visible = true
			if Input.is_action_just_pressed("use"):
				Global.is_axeThrown = false
				Global.is_axePicked = true
				is_picked = true
				queue_free()
	
	if direction == 1 && !animSprite.is_flipped_h():
		animSprite.flip_h = true
	elif direction == -1 && animSprite.is_flipped_h():
		animSprite.flip_h = true
	
	if !is_on_floor() && !is_hitTheWall:
		animPlayer.play("flight")
		velocity.y += gravity * delta * 0.9
		velocity.x = direction * SPEED
	elif is_hitTheWall:
		animPlayer.play("fall")
	
	move_and_slide()

# calls when playing fall animation
func fall():
	velocity.y = gravity * 0.7
	velocity.x = 0

func _on_pick_area_body_entered(_body):
	is_nearPlayer = true

func _on_pick_area_body_exited(_body):
	is_nearPlayer = false
	$EquipLabel.visible = false

func _on_wall_detector_body_entered(_body):
	is_hitTheWall = true
	animPlayer.play("fall")

func _on_hit_area_area_entered(area):
	is_hitTheWall = true
	animPlayer.play("fall")
	var randStream = AudioStreamRandomizer.new()
	randStream.add_stream(0, soundHit)
	randStream.random_pitch = 2
	$Sounds.stream = randStream
	$Sounds.play()
	Events.emit_signal("playerAttack", damage, area)
