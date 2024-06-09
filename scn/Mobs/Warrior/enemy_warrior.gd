extends CharacterBody2D

enum STATE {
	IDLE,
	CHASE,
	ATTACK,
	FALL,
	JUMP,
	TAKEHIT,
	RECOVER,
	DEATH
}
var currentState : int = STATE.IDLE:
	set(value):
		currentState = value
		match currentState:
			STATE.IDLE:
				idle()
			STATE.CHASE:
				chase()
			STATE.ATTACK:
				attack()
			STATE.FALL:
				fall()
			STATE.JUMP:
				jump()
			STATE.TAKEHIT:
				takeHit()
			STATE.RECOVER:
				recover()
			STATE.DEATH:
				death()

const SPEED = 175
const JUMP_VELOCITY = -470

var speed = SPEED
var gravity = 980
var health = 90
var damage = 20
var is_alive = true
var is_inChaseArea = false
var direction
var player

@onready var animPlayer = $AnimationPlayer
@onready var animSprite = $AnimatedSprite2D
@onready var groundDetector = $AttackDirection/GrounDetector
@onready var jumpBlock = $AttackDirection/JumpBlockDetector

const soundHurt0 = preload("res://assets/sounds/HurtSound0.wav")
const soundHurt1 = preload("res://assets/sounds/HurtSound1.wav")
const soundSword0 = preload("res://assets/sounds/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 1.wav")
const soundSword1 = preload("res://assets/sounds/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 2.wav")
const soundSword2 = preload("res://assets/sounds/SFX/Attacks/Sword Attacks Hits and Blocks/Sword Attack 3.wav")

func _ready():
	add_to_group("Persist")
	player = get_parent().get_parent().find_child("Player").get_child(-1)
	if !is_alive:
		queue_free()
	
	Events.connect("playerAttack", Callable(self, "_on_take_hit"))

func _physics_process(delta):
	if is_alive:
		if !is_on_floor() && currentState != STATE.ATTACK:
			velocity.y += gravity * delta
			currentState = STATE.FALL
		elif (is_inChaseArea && currentState != STATE.ATTACK && currentState != STATE.FALL 
		&& currentState != STATE.TAKEHIT && currentState != STATE.RECOVER):
			currentState = STATE.CHASE
		elif !is_inChaseArea || (is_inChaseArea && currentState == STATE.FALL):
			currentState = STATE.IDLE
	else:
		await animPlayer.animation_finished
		Events.emit_signal("mobDeath", $".")
	
	move_and_slide()

func idle():
	velocity.x = 0
	speed = SPEED
	animPlayer.play("idle")

func chase():
	direction = (player.position - self.position).normalized()
	velocity.x = direction.x * speed
	animPlayer.play("run")
	if direction.x > 0 && animSprite.is_flipped_h():
		animSprite.flip_h = false
		$AttackDirection.scale.x = 1
	elif direction.x < 0 && !animSprite.is_flipped_h():
		animSprite.flip_h = true
		$AttackDirection.scale.x = -1
	
	if !groundDetector.has_overlapping_bodies() || is_on_wall():
		if !jumpBlock.has_overlapping_bodies():
			currentState = STATE.JUMP

func attack():
	if !is_on_floor():
		velocity.y = -30
	
	velocity.x = 0
	speed = 0
	animPlayer.play("attack")
	var randStream = AudioStreamRandomizer.new()
	randStream.add_stream(0, soundSword0)
	randStream.add_stream(1, soundSword1)
	randStream.add_stream(2, soundSword2)
	randStream.random_pitch = 1.2
	$Sounds.stream = randStream
	$Sounds.play()
	await animPlayer.animation_finished
	speed = SPEED
	currentState = STATE.RECOVER

func fall():
	animPlayer.play("fall")
	if is_inChaseArea:
		velocity.x = direction.x * speed

func jump():
	velocity.y += JUMP_VELOCITY
	animPlayer.play("jump")

func hpCheckSubtract(receivedDamage):
	health -= receivedDamage
	if health <= 0:
		currentState = STATE.DEATH
	else:
		currentState = STATE.IDLE
		currentState = STATE.TAKEHIT

func _on_detector_body_entered(_body):
	is_inChaseArea = true

func _on_detector_body_exited(_body):
	is_inChaseArea = false

func takeHit():
	velocity.x = 0
	animPlayer.play("hit")
	await animPlayer.animation_finished
	await get_tree().create_timer(0.5).timeout
	currentState = STATE.RECOVER

func recover():
	if is_alive:
		animPlayer.play("recover")
		await animPlayer.animation_finished
		currentState = STATE.IDLE

func death():
	is_alive = false
	var randStream = AudioStreamRandomizer.new()
	randStream.add_stream(0, soundHurt0)
	randStream.add_stream(1, soundHurt1)
	randStream.random_pitch = 1.2
	$Sounds.stream = randStream
	$Sounds.play()
	animPlayer.play("death")

func _on_attack_range_body_entered(_body):
	currentState = STATE.ATTACK

func _on_hurt_box_body_entered(_body):
	hpCheckSubtract(25)

func _on_hit_box_area_entered(_area):
	Events.emit_signal("enemyAttack", damage)

func _on_take_hit(playerDamage, area):
	if area == $AttackDirection/DamageBox/HurtBox:
		hpCheckSubtract(playerDamage)

func saveData():
	var saveDict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"health" : health,
		"is_inChaseArea": is_inChaseArea,
		"direction": direction,
		"is_alive" : is_alive
	}
	return saveDict
