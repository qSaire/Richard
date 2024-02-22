extends CharacterBody2D

enum STATE {
	IDLE,
	CHASE,
	ATTACK,
	FALL,
	TAKEHIT,
	RECOVER,
	DEATH
}
var currentState: int = STATE.IDLE:
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
			STATE.TAKEHIT:
				takeHit()
			STATE.RECOVER:
				recover()
			STATE.DEATH:
				death()

var gravity = 980
var speed = 150
var health = 100
var damage = 20
var is_alive = true
var is_inChaseArea = false
var direction
@onready var animPlayer = $AnimationPlayer
@onready var animSprite = $AnimatedSprite2D
@onready var player = $"../../Player/PlayerChar"

func _ready():
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
	
	move_and_slide()

func idle():
	velocity.x = 0
	animPlayer.play("idle")

func chase():
	direction = (player.position - self.position).normalized()
	velocity.x = direction.x * speed
	animPlayer.play("run")
	if direction.x > 0:
		animSprite.flip_h = false
		$AttackDirection.rotation_degrees = 0
	elif direction.x < 0:
		animSprite.flip_h = true
		$AttackDirection.rotation_degrees = 180

func attack():
	velocity.x = 0
	speed = 0
	animPlayer.play("attack")
	await animPlayer.animation_finished
	speed = 150
	currentState = STATE.RECOVER

func fall():
	animPlayer.play("fall")

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
	animPlayer.play("death")
	await animPlayer.animation_finished
	queue_free();

func _on_attack_range_body_entered(_body):
	if is_alive:
		currentState = STATE.ATTACK

func saveData():
	var saveDict = {
		"pos_x" : position.x,
		"pos_y" : position.y,
		"health" : health,
		"is_inChaseArea": is_inChaseArea,
		"is_alive" : is_alive
	}
	return saveDict

func _on_hit_box_area_entered(_area):
	Events.emit_signal("enemyAttack", damage)

func _on_take_hit(playerDamage):
	health -= playerDamage
	if health <= 0:
		currentState = STATE.DEATH
	else:
		currentState = STATE.IDLE
		currentState = STATE.TAKEHIT
