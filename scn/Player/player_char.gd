extends CharacterBody2D

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
	TAKEHIT,
	CLIMB,
	THROW
}
const SPEED = 400.0
const JUMP_VELOCITY_STEP = -25
const gravity = 980

var jumpPower = 0
var jumpTimer = 0.0
var jumpTimerMax = 0.2
var is_jumping = false
var is_climbing = false
var speedCoef = 1
var maxHealth = 80
var currentHealth = maxHealth
var damage = 50
var currentState = STATE.IDLE
var is_cooldown = false
var numOfAttacksInAir = 0
var oneWayLayer = 10
var posBeforeFall = 0

const standingCollShape = preload("res://resources/player_standingCollisionShape.tres")
const crouchingCollShape = preload("res://resources/player_crouchingCollisionShape.tres")
const standingHurtBox = preload("res://resources/player_hurtBoxStanding.tres")
const crouchingHurtBox = preload("res://resources/player_hurtBoxCrouching.tres")

const soundJump0 = preload("res://assets/sounds/Stone Jump.wav")
const soundJump1 = preload("res://assets/sounds/Stone Chain Jump.wav")
const soundLand = preload("res://assets/sounds/land in grass 10.wav")
const soundSwing = preload("res://assets/sounds/swordswing.wav")
const swordHit = preload("res://assets/sounds/Sword Impact Hit 3.wav")
const soundHurt = preload("res://assets/sounds/ArmorSound.wav")
const soundHealing = preload("res://assets/sounds/HealPotion.wav")
const soundMaxHealth = preload("res://assets/sounds/MaxHealthPotion.wav")

@onready var collShape = $CollisionShape2D
@onready var hurtBox = $AttackDirection/DamageBox/HurtBox/CollisionShape2D
@onready var animSprite = $AnimatedSprite2D
@onready var animPlayer = $AnimationPlayer
@onready var crouchingRayCasts = $CrouchingRayCasts
@onready var groundRayCast = $AttackDirection/GroundRayCast

func _ready():
	add_to_group("Persist")
	position = Global.playerCurrentPosition
	maxHealth = Global.playerMaxHealth
	currentHealth = Global.playerCurrentHealth
	changeHorizontalPos(Global.playerDirection)
	Events.connect("enemyAttack", Callable(self, "_on_take_hit"))
	Events.connect("healthPotionPicked", Callable(self, "_on_pick_health_potion"))
	Events.connect("maxHealthPotionPicked", Callable(self, "_on_pick_max_health_potion"))

# delta - moment of time
func _physics_process(delta):
	var direction = Input.get_axis("left", "right")
	match int(currentState):
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
		STATE.CLIMB:
			climb()
		STATE.THROW:
			throw()
	
	move_and_slide()

func idle():
	if !is_on_floor() && !groundRayCast.is_colliding():
		posBeforeFall = position.y
		currentState = STATE.FALL
	else:
		if collShape.shape != standingCollShape:
			changeCollision()
		
		animPlayer.play("idle")
		jumpTimer = 0
		is_jumping = false
		velocity.x = move_toward(velocity.x, 0, SPEED)
		numOfAttacksInAir = 1
		if (Input.is_anything_pressed() 
			|| (Input.is_anything_pressed() && !Input.is_action_pressed("left") && !Input.is_action_pressed("right"))):
			currentState = STATE.MOVE
		
		if Input.is_action_just_pressed("jump"):
			currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("throw") && Global.is_axePicked && !is_cooldown:
			currentState = STATE.THROW
		
		if Input.is_action_just_pressed("crouch"):
			animPlayer.play("startCrouch")
			currentState = STATE.CROUCH
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.ATTACK1
		
		if is_climbing && Input.is_action_just_pressed("jump"):
			currentState = STATE.CLIMB

func move(direction):
	if is_on_floor():
		velocity.y = 0
	
	if !is_on_floor() && !groundRayCast.is_colliding():
		posBeforeFall = position.y
		currentState = STATE.FALL
	else:
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("jump"):
			currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("crouch"):
			currentState = STATE.CROUCH
		
		if Input.is_action_just_pressed("throw") && Global.is_axePicked && !is_cooldown:
			currentState = STATE.THROW
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			if $Sounds.playing == false:
				$Sounds.playing = false
			currentState = STATE.ATTACK1
		
		if is_climbing && Input.is_action_just_pressed("jump"):
			currentState = STATE.CLIMB

func applyJumpForce(power):
	if power >= -540:
		velocity.y = power

func jump(direction, delta):
	changeHorizontalPos(direction)
	if is_on_floor() && !is_jumping:
		jumpPower = -300
		jumpTimer = 0.0
		is_jumping = true
		animPlayer.play("jump")
		var randStream = AudioStreamRandomizer.new()
		randStream.add_stream(0, soundJump0)
		randStream.add_stream(1, soundJump1)
		$Sounds.stream = randStream
		$Sounds.play()
	elif is_on_floor() || groundRayCast.is_colliding():
		currentState = STATE.IDLE
	
	if Input.is_action_pressed("jump") && is_jumping && jumpTimer < jumpTimerMax:
		jumpPower += JUMP_VELOCITY_STEP
		applyJumpForce(jumpPower)
	
	if is_climbing && Input.is_action_just_pressed("jump"):
		currentState = STATE.CLIMB
	
	if !is_on_floor() && !groundRayCast.is_colliding():
		jumpTimer += delta
	
	if !is_on_floor() && !groundRayCast.is_colliding() && jumpTimer >= jumpTimerMax:
		velocity.y += gravity * delta * 2
	
	if Input.is_action_just_pressed("attack") && !is_cooldown:
		numOfAttacksInAir -= 1
		currentState = STATE.ATTACK1
	
	if velocity.y > 0:
		posBeforeFall = position.y
		currentState = STATE.FALL

func fall(direction, delta):
	if !is_on_floor() && !groundRayCast.is_colliding():
		animPlayer.play("fall")
		velocity.y += gravity * delta * 1.5
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			numOfAttacksInAir -= 1
			currentState = STATE.ATTACK1
		
		if is_climbing && Input.is_action_just_pressed("jump"):
			currentState = STATE.CLIMB
	else:
		if posBeforeFall - position.y < -500:
			var fallDamage = 10
			if posBeforeFall - position.y < -750:
				fallDamage = 20
			if posBeforeFall - position.y < -1000:
				fallDamage = 100
			
			_on_take_hit(fallDamage)
		else:
			var randStream = AudioStreamRandomizer.new()
			randStream.add_stream(0, soundLand)
			randStream.random_pitch = 2
			$Sounds.stream = randStream
			$Sounds.play()
			currentState = STATE.IDLE

func crouch():
	if collShape.shape != crouchingCollShape:
		changeCollision()
	
	speedCoef = 0.5
	if !is_on_floor():
		speedCoef = 1
		posBeforeFall = position.y
		currentState = STATE.FALL
	else:
		if (!Input.is_anything_pressed() || (Input.is_action_pressed("left") && Input.is_action_pressed("right")) 
			|| (Input.is_anything_pressed() && !Input.is_action_pressed("left") && !Input.is_action_pressed("right"))):
			animPlayer.play("crouch")
		else:
			currentState = STATE.CROUCHWALK
		
		if Input.is_action_just_pressed("crouch"):
			if checkForUpCollision() == false:
				animPlayer.play("endCrouch")
				speedCoef = 1
				currentState = STATE.IDLE
		
		if Input.is_action_just_pressed("jump"):
			if checkForUpCollision() == false:
				animPlayer.play("endCrouch")
				speedCoef = 1
				currentState = STATE.IDLE
		
		if Input.is_action_just_pressed("left") || Input.is_action_just_pressed("right"):
			currentState = STATE.CROUCHWALK
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.CROUCHATTACK

func crouchWalk(direction):
	if !is_on_floor():
		speedCoef = 1
		changeCollision()
		posBeforeFall = position.y
		currentState = STATE.FALL
	else:
		changeHorizontalPos(direction)
		if Input.is_action_just_pressed("jump"):
			if checkForUpCollision() == false:
				speedCoef = 1
				changeCollision()
				currentState = STATE.JUMP
		
		if Input.is_action_just_pressed("crouch"):
			if checkForUpCollision() == false:
				animPlayer.play("endCrouch")
				speedCoef = 1
				changeCollision()
				currentState = STATE.MOVE
		
		if Input.is_action_just_pressed("attack") && !is_cooldown:
			currentState = STATE.CROUCHATTACK

func crouchAttack():
	if animPlayer.current_animation != "crouchAttack":
		var randStream = AudioStreamRandomizer.new()
		randStream.add_stream(0, soundSwing)
		randStream.random_pitch = 2
		$Sounds.stream = randStream
		$Sounds.play()
		
	animPlayer.play("crouchAttack")
	velocity.x = 0
	await animPlayer.animation_finished
	setOnCooldown()
	if Input.is_action_pressed("left") || Input.is_action_pressed("right"):
		currentState = STATE.CROUCHWALK
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		currentState = STATE.CROUCH

func attack():
	if !is_on_floor() && numOfAttacksInAir >= 0:
		if animPlayer.current_animation != "attack1":
			var randStream = AudioStreamRandomizer.new()
			randStream.add_stream(0, soundSwing)
			randStream.random_pitch = 2
			$Sounds.stream = randStream
			$Sounds.play()
		
		animPlayer.play("attack1")
		velocity.y = -40
		velocity.x = 0
		await animPlayer.animation_finished
		currentState = STATE.FALL
	elif !is_on_floor() && numOfAttacksInAir < 0:
		currentState = STATE.FALL
	else:
		if animPlayer.current_animation != "attack1":
			var randStream = AudioStreamRandomizer.new()
			randStream.add_stream(0, soundSwing)
			randStream.random_pitch = 2
			$ParallelSFX.stream = randStream
			$ParallelSFX.play()
		
		animPlayer.play("attack1")
		velocity.x = 0
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
	if animPlayer.current_animation != "hit":
		var randStream = AudioStreamRandomizer.new()
		randStream.add_stream(0, soundHurt)
		randStream.random_pitch = 1.5
		$ParallelSFX.stream = randStream
		$ParallelSFX.play()
	
	velocity.x = 0
	velocity.y = 0
	if checkForUpCollision() == false:
		animPlayer.play("hit")
		await animPlayer.animation_finished
		currentState = STATE.IDLE
	else:
		currentState = STATE.CROUCH

func death():
	if animPlayer.current_animation != "death":
		var randStream = AudioStreamRandomizer.new()
		randStream.add_stream(0, soundHurt)
		randStream.random_pitch = 1.5
		$ParallelSFX.stream = randStream
		$ParallelSFX.play()
		velocity.x = 0
		velocity.y = 100
		animPlayer.play("death")
		await animPlayer.animation_finished
		Events.emit_signal("playerDeath")
		set_physics_process(false)

func changeHorizontalPos(direction):
	if direction:
		velocity.x = direction * SPEED * speedCoef
		if velocity.y == 0 && Input.is_action_just_pressed("crouch"):
			velocity.x = move_toward(velocity.x, 0, SPEED)
			currentState = STATE.CROUCH
		elif (velocity.y == 0 && Input.is_action_just_pressed("crouch") && 
			(Input.is_action_pressed("left") || Input.is_action_pressed("right"))):
			currentState = STATE.CROUCHWALK
		
		if  groundRayCast.is_colliding() || (currentState == STATE.MOVE && velocity.y == 0):
			animPlayer.play("run")
		
		if currentState == STATE.CROUCHWALK && velocity.y == 0:
			animPlayer.play("crouchWalk")
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		if currentState == STATE.MOVE && velocity.y == 0:
			currentState = STATE.IDLE
			
		if currentState == STATE.CROUCHWALK && velocity.y == 0:
			currentState = STATE.CROUCH
	
	# mirroring character sprite horisontal in different direction
	if direction == 1 && animSprite.is_flipped_h():
		animSprite.flip_h = false
		$AttackDirection.scale.x = 1
	elif direction == -1 && !animSprite.is_flipped_h():
		animSprite.flip_h = true
		$AttackDirection.scale.x = -1

func climb():
	animPlayer.play("idle")
	if !is_on_floor():
		animPlayer.play("hang")
	
	if is_climbing:
		velocity.y = 0
		velocity.x = 0
		if Input.is_action_pressed("jump"):
			velocity.y = -SPEED
		elif Input.is_action_pressed("crouch"):
			velocity.y = SPEED
		elif Input.is_action_pressed("left") || Input.is_action_pressed("right"):
			is_climbing = false
			$AttackDirection/LadderDetector/CollisionShape2D.disabled = true
			await get_tree().create_timer(0.2).timeout
			$AttackDirection/LadderDetector/CollisionShape2D.disabled = false
	elif !is_on_floor():
		posBeforeFall = position.y
		currentState = STATE.FALL
	
	if is_climbing && is_on_floor() && Input.is_anything_pressed() && !Input.is_action_pressed("jump"):
		currentState = STATE.IDLE

func throw():
	if !is_on_floor():
		posBeforeFall = position.y
		currentState = STATE.FALL
	else:
		animPlayer.play("throwAxe")
		velocity.x = 0
		await animPlayer.animation_finished
		setOnCooldown()
		currentState = STATE.IDLE

func changeCollision():
	if collShape.shape == crouchingCollShape:
		collShape.shape = standingCollShape
		collShape.position.y = 0
		hurtBox.shape = standingHurtBox
		hurtBox.position.y = 0
	else:
		collShape.shape = crouchingCollShape
		collShape.position.y = 5.5
		hurtBox.shape = crouchingHurtBox
		hurtBox.position.y = 5.333
	
	return

# calls when playing throw animation
func emitThrowSignal():
	var direction
	if animSprite.is_flipped_h():
		direction = -1
	else:
		direction = 1
	
	Global.is_axePicked = false
	Global.is_axeThrown = true
	Events.emit_signal("throwAxe", direction)

# cooldown between attacks
func setOnCooldown():
	is_cooldown = true
	await get_tree().create_timer(0.5).timeout
	is_cooldown = false

# invulnerability after take damage
func getInvulnerable():
	$"AttackDirection/DamageBox/HurtBox/CollisionShape2D".disabled = true
	await get_tree().create_timer(1.5).timeout
	$"AttackDirection/DamageBox/HurtBox/CollisionShape2D".disabled = false

func hpCheckSubtract(enemyDamage):
	currentHealth -= enemyDamage
	if currentHealth <= 0:
		currentHealth = 0
		Events.emit_signal("healthChanged", currentHealth)
		currentState = STATE.DEATH
	else:
		Events.emit_signal("healthChanged", currentHealth)
		currentState = STATE.TAKEHIT

func checkForUpCollision():
	for rayCast in crouchingRayCasts.get_children():
		if rayCast.is_colliding():
			return true
	
	return false

func _on_hit_box_area_entered(area):
	var randStream = AudioStreamRandomizer.new()
	randStream.add_stream(0, swordHit)
	randStream.random_pitch = 2
	$Sounds.stream = randStream
	$Sounds.play()
	Events.emit_signal("playerAttack", damage, area)

func _on_crouch_hit_box_area_entered(area):
	var randStream = AudioStreamRandomizer.new()
	randStream.add_stream(0, swordHit)
	randStream.random_pitch = 2
	$Sounds.stream = randStream
	$Sounds.play()
	Events.emit_signal("playerAttack", damage, area)

func _on_ladder_detector_body_entered(_body):
	if is_climbing == false:
		is_climbing = true

func _on_ladder_detector_body_exited(_body):
	if is_climbing == true:
		is_climbing = false

# damage from traps
func _on_hurt_box_body_entered(_body):
	hpCheckSubtract(20)

# damage from mobs
func _on_take_hit(enemyDamage):
	velocity.x = 0
	speedCoef = 1
	hpCheckSubtract(enemyDamage)

# heal
func _on_pick_health_potion(healPoints):
	$ParallelSFX.stream = soundHealing
	$ParallelSFX.play()
	currentHealth += healPoints
	if currentHealth > maxHealth:
		currentHealth = maxHealth
	
	Events.emit_signal("healthChanged", currentHealth)

func _on_pick_max_health_potion(healPoints):
	$ParallelSFX.stream = soundMaxHealth
	$ParallelSFX.play()
	maxHealth += healPoints
	Events.emit_signal("maxHealthChanged", maxHealth)

func _on_one_way_detector_body_entered(_body):
	set_collision_mask_value(oneWayLayer, true)

func _on_one_way_detector_body_exited(_body):
	set_collision_mask_value(oneWayLayer, false)

func _input(event):
	if event.is_action_released("jump") && is_jumping:
		jumpTimer = jumpTimerMax
	
	if (event.is_action_pressed("crouch") && is_on_floor() 
	&& (currentState == STATE.CROUCH || currentState == STATE.MOVE)):
		set_collision_mask_value(oneWayLayer, false)

func saveData():
	Global.playerDirection = -1 if animSprite.is_flipped_h() else 1
	var saveDict = {
		"filename" : get_scene_file_path(),
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"currentHealth" : currentHealth,
		"currentState" : currentState,
		"is_cooldown" : is_cooldown,
		"velocity.x" : velocity.x,
		"velocity.y" : velocity.y,
		"numOfAttacksInAir" : numOfAttacksInAir
	}
	return saveDict
