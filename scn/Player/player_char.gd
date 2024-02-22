extends CharacterBody2D

signal healthChanged(currentHealth)

enum STATE {
	IDLE,
	MOVE,
	DEATH,
	CROUCH,
	CROUCHWALK,
	CROUCHATTACK,
	JUMP,
	FALL,
	ATTACK1,
	ATTACK2,
	TAKEHIT
}
const SPEED = 350.0
const JUMP_VELOCITY = -400.0
var speedCoef = 1
var gravity = 980
var playerHealth = 100
var damage = 50
var currentState = STATE.IDLE
var is_cooldown = false
var numOfAttacksInAir = 0
@onready var animSprite = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer

func _ready():
	Events.connect("enemyAttack", Callable(self, "_on_take_hit"))

# delta = moment of time
func _physics_process(delta):
	var direction = Input.get_axis("left", "right")
	match currentState:
		STATE.IDLE:
			idle()
		STATE.MOVE:
			move(direction)
		STATE.DEATH:
			death()
		STATE.CROUCH:
			crouch()
		STATE.CROUCHWALK:
			crouchWalk(direction)
		STATE.CROUCHATTACK:
			crouchAttack()
		STATE.JUMP:
			jump(direction, delta)
		STATE.FALL:
			fall(direction, delta)
		STATE.ATTACK1:
			attack()
		STATE.ATTACK2:
			#print("State: " + STATE.keys()[currentState])
			pass
		STATE.TAKEHIT:
			takeHit()
	
	move_and_slide()

func idle():
	if !is_on_floor():
		currentState = STATE.FALL
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		numOfAttacksInAir = 1
		if (!Input.is_anything_pressed() || (Input.is_action_pressed("left") && Input.is_action_pressed("right")) 
			|| (Input.is_anything_pressed() && !Input.is_action_pressed("left") && !Input.is_action_pressed("right"))):
			animPlayer.play("idle")
		else:
			currentState = STATE.MOVE
		
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("crouch"):
			animPlayer.play("startCrouch")
			currentState = STATE.CROUCH
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.ATTACK1

func move(direction):
	if !is_on_floor():
		currentState = STATE.FALL
	else:
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("crouch"):
			currentState = STATE.CROUCH
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.ATTACK1

func jump(direction, delta):
	animPlayer.play("jump")
	velocity.y += gravity * delta
	changeHorizontalPos(direction)
	if Input.is_action_just_pressed("attack") && !is_cooldown:
		currentState = STATE.ATTACK1
	
	if velocity.y > 0:
		currentState = STATE.FALL

func fall(direction, delta):
	if !is_on_floor():
		animPlayer.play("fall")
		velocity.y += gravity * delta
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.ATTACK1
	else:
		currentState = STATE.IDLE

func crouch():
	speedCoef = 0.5
	if !is_on_floor():
		speedCoef = 1
		currentState = STATE.FALL
	else:
		if (!Input.is_anything_pressed() || (Input.is_action_pressed("left") && Input.is_action_pressed("right")) 
			|| (Input.is_anything_pressed() && !Input.is_action_pressed("left") && !Input.is_action_pressed("right"))):
			animPlayer.play("crouch")
		else:
			currentState = STATE.CROUCHWALK
		
		if Input.is_action_just_pressed("crouch"):
			animPlayer.play("endCrouch")
			speedCoef = 1
			currentState = STATE.IDLE
		
		if Input.is_action_just_pressed("jump"):
			animPlayer.play("endCrouch")
			speedCoef = 1
			currentState = STATE.IDLE
		
		if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("right"):
			currentState = STATE.CROUCHWALK
		
		if Input.is_action_just_pressed("attack"):
			currentState = STATE.CROUCHATTACK

func crouchWalk(direction):
	if !is_on_floor():
		speedCoef = 1
		currentState = STATE.FALL
	else:
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			speedCoef = 1
			currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("crouch"):
			animPlayer.play("endCrouch")
			speedCoef = 1
			currentState = STATE.MOVE
		
		if Input.is_action_just_pressed("attack"):
			currentState = STATE.CROUCHATTACK

func crouchAttack():
	animPlayer.play("crouchAttack")
	await animPlayer.animation_finished
	if Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		currentState = STATE.CROUCHWALK
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		currentState = STATE.CROUCH

func attack():
	if !is_on_floor() && numOfAttacksInAir > 0:
		numOfAttacksInAir -= 1
		animPlayer.play("attack1")
		await animPlayer.animation_finished
		currentState = STATE.FALL
	elif !is_on_floor() && numOfAttacksInAir == 0:
		await get_tree().create_timer(0.2).timeout
		numOfAttacksInAir -= 1
		currentState = STATE.FALL
	elif !is_on_floor() && numOfAttacksInAir < 0:
		currentState = STATE.FALL
	else:
		animPlayer.play("attack1")
		await animPlayer.animation_finished
		setOnCooldown()
		if Input.is_action_pressed("left") || Input.is_action_pressed("right"):
			currentState = STATE.MOVE
		elif !is_on_floor():
			currentState = STATE.FALL
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			currentState = STATE.IDLE

func takeHit():
	animPlayer.play("hit")
	await animPlayer.animation_finished
	currentState = STATE.IDLE

func death():
	animPlayer.play("death")
	await animPlayer.animation_finished
	queue_free()
	if is_inside_tree():
		get_tree().change_scene_to_file("res://scn/MainMenu/menu.tscn")

func setOnCooldown():
	is_cooldown = true
	await get_tree().create_timer(0.5).timeout
	is_cooldown = false

func changeHorizontalPos(direction):
	if direction:
		velocity.x = direction * SPEED * speedCoef
		if velocity.y == 0 && Input.is_action_just_pressed("crouch"):
			velocity.x = move_toward(velocity.x, 0, SPEED)
			currentState = STATE.CROUCH
		elif (velocity.y == 0 && Input.is_action_just_pressed("crouch") && 
			(Input.is_action_pressed("left") || Input.is_action_pressed("right"))):
			currentState = STATE.CROUCHWALK
		
		if currentState == STATE.MOVE && velocity.y == 0:
			animPlayer.play("run")
			
		if currentState == STATE.CROUCHWALK && velocity.y == 0:
			animPlayer.play("crouchWalk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if currentState == STATE.MOVE && velocity.y == 0:
			currentState = STATE.IDLE
			
		if currentState == STATE.CROUCHWALK && velocity.y == 0:
			currentState = STATE.CROUCH
	
	# Mirroring character sprite horisontal in different direction
	if direction == 1:
		animSprite.flip_h = false
		$AttackDirection.rotation_degrees = 0
	elif direction == -1:
		animSprite.flip_h = true
		$AttackDirection.rotation_degrees = 180

func _on_hit_box_area_entered(_area):
	Events.emit_signal("playerAttack", damage)

func _on_take_hit(enemyDamage):
	velocity.x = 0
	speedCoef = 1
	playerHealth -= enemyDamage
	if playerHealth <= 0:
		playerHealth = 0
		emit_signal("healthChanged", playerHealth)
		currentState = STATE.DEATH
	else:
		currentState = STATE.TAKEHIT
		emit_signal("healthChanged", playerHealth)

func saveData():
	var saveDict = {
		"pos_x" : position.x,
		"pos_y" : position.y,
		"playerHealth" : playerHealth,
		#"currentState" : currentState,
		"is_cooldown" : is_cooldown,
		"velocity.x" : velocity.x,
		"velocity.y" : velocity.y,
		"numOfAttacksInAir" : numOfAttacksInAir
	}
	return saveDict
