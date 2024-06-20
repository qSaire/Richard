extends Node2D

var throwableAxe = preload("res://scn/Items/throwable_axe.tscn")
var maxHealthSpawn = Global.playerMaxHealth
var is_nearExit = false
var is_nearLever = false
var is_leverActivated = false

@onready var player = find_child("Player").find_child("PlayerChar")
@onready var healthBar = get_node(^"/root/SceneTransition/PlayerUI/HealthBar")
@onready var playerDirection = $TriggerAreas/Gate.playerDirection
@onready var playerSpawnPosition = $TriggerAreas/Gate.playerSpawnPosition

const soundDoorClose = preload("res://assets/sounds/Door Close 1.wav")
const soundDoorOpen = preload("res://assets/sounds/Door Open 1.wav")

func _ready():
	add_to_group("Persist")
	Events.connect("mobDeath", Callable(self, "_on_mob_death"))
	Events.connect("playerDeath", Callable(self, "_on_player_death"))
	Events.connect("throwAxe", Callable(self, "_on_throw_axe"))
	Events.connect("healthChanged", Callable(self, "_on_player_char_health_changed"))
	Events.connect("maxHealthChanged", Callable(self, "_on_player_char_max_health_changed"))
	
	healthBar.max_value = Global.playerMaxHealth
	healthBar.value = Global.playerCurrentHealth
	Global.is_axePicked = true
	
	# save scene for checkpoint
	# transition after death to mainmenu and to this level
	var scene = PackedScene.new()
	scene.pack(self)
	maxHealthSpawn = Global.playerMaxHealth
	Global.loadedLevel = scene

func _process(_delta):
	if has_node("/root/Menu"):
		queue_free()
	
	player = find_child("Player").get_child(-1)
	# back in first level
	if is_nearExit && Input.is_action_just_pressed("use"):		
		var scene = PackedScene.new()
		scene.pack(self)
		Global.savedLevels[2] = scene
		var nextScene = Global.savedLevels[0]
		queue_free()
		Global.playerCurrentPosition = playerSpawnPosition
		Global.playerDirection = playerDirection
		Global.playerTransitionHP = Global.playerCurrentHealth
		SceneTransition.change_scene_to_packed(nextScene)
	
	if is_nearLever && Input.is_action_just_pressed("use") && !$ObjectsBehind/DoorToBoss/Lever/LeverAnimPlayer.is_playing():
		if is_leverActivated:
			is_leverActivated = false
			$ObjectsBehind/DoorToBoss/ClosedDoor.visible = true
			$ObjectsBehind/DoorToBoss/OpenedDoor.visible = false
			$ObjectsBehind/DoorToBoss/CollisionShape2D.disabled = false
			$ObjectsBehind/DoorToBoss/Lever/LeverSounds.play()
			$ObjectsBehind/DoorToBoss/DoorSounds.stream = soundDoorClose
			$ObjectsBehind/DoorToBoss/DoorSounds.play()
			$ObjectsBehind/DoorToBoss/Lever/LeverAnimPlayer.play_backwards("fullRotate")
		else:
			is_leverActivated = true
			$ObjectsBehind/DoorToBoss/ClosedDoor.visible = false
			$ObjectsBehind/DoorToBoss/OpenedDoor.visible = true
			$ObjectsBehind/DoorToBoss/CollisionShape2D.disabled = true
			$ObjectsBehind/DoorToBoss/Lever/LeverSounds.play()
			$ObjectsBehind/DoorToBoss/DoorSounds.stream = soundDoorOpen
			$ObjectsBehind/DoorToBoss/DoorSounds.play()
			$ObjectsBehind/DoorToBoss/Lever/LeverAnimPlayer.play("fullRotate")

func _on_player_char_health_changed(health):
	healthBar.value = health
	Global.playerCurrentHealth = health

func _on_player_char_max_health_changed(health):
	healthBar.max_value = health
	Global.playerMaxHealth = health

func _on_mob_death(nodeName):
	nodeName.queue_free()

func _on_player_death():
	healthBar.value = Global.playerTransitionHP
	Global.playerCurrentHealth = Global.playerTransitionHP
	Global.playerMaxHealth = maxHealthSpawn
	SceneTransition.change_scene_to_file("res://scn/MainMenu/menu.tscn")

func _on_throw_axe(direction):
	var axe = throwableAxe.instantiate()
	find_child("Items").add_child(axe)
	axe.position.x = player.position.x
	axe.position.y = player.position.y - 35
	Global.throwDirection = direction

func _on_gate_body_entered(_body):
	is_nearExit = true
	$TriggerAreas/Gate/Sounds.play()
	$TriggerAreas/Gate/CastleGateInsideOpen.visible = true
	$TriggerAreas/Gate/Label.visible = true

func _on_gate_body_exited(_body):
	is_nearExit = false
	$TriggerAreas/Gate/CastleGateInsideOpen.visible = false
	$TriggerAreas/Gate/Label.visible = false

func _on_hidden_path_body_entered(_body):
	$TriggerAreas/HiddenPath/HiddentPathAnim.play("show")
	await $TriggerAreas/HiddenPath/HiddentPathAnim.animation_finished
	$TriggerAreas/HiddenPath/HiddenPathTiles.visible = false

func _on_player_detector_body_entered(_body):
	is_nearLever = true

func _on_player_detector_body_exited(_body):
	is_nearLever = false

func saveData():
	var saveDict = {
		"filename" : get_scene_file_path(),
		"nodeName" : "CastleLevel",
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y
	}
	return saveDict

