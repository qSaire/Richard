extends Node2D

var is_nearEntrance = false
var is_visitedLever = false
var throwableAxe = preload("res://scn/Items/throwable_axe.tscn")
var maxHealthSpawn = Global.playerMaxHealth
var is_nearLever = false
var is_leverActivated = false

@onready var player = find_child("Player").find_child("PlayerChar")
@onready var healthBar = get_node(^"/root/SceneTransition").find_child("PlayerUI").find_child("HealthBar")
@onready var playerDirection = $TransitionToFirstLvl.playerDirection
@onready var playerSpawnPosition = $TransitionToFirstLvl.playerSpawnPosition

func _ready():
	add_to_group("Persist")
	Events.connect("mobDeath", Callable(self, "_on_mob_death"))
	Events.connect("playerDeath", Callable(self, "_on_player_death"))
	Events.connect("throwAxe", Callable(self, "_on_throw_axe"))
	Events.connect("healthChanged", Callable(self, "_on_player_char_health_changed"))
	Events.connect("maxHealthChanged", Callable(self, "_on_player_char_max_health_changed"))
	healthBar.max_value = Global.playerMaxHealth
	healthBar.value = Global.playerCurrentHealth
	
	# save scene for checkpoint
	# transition after death to mainmenu and to this level
	var scene = PackedScene.new()
	scene.pack(self)
	maxHealthSpawn = Global.playerMaxHealth
	Global.loadedLevel = scene

func _process(_delta):
	if is_nearEntrance && Input.is_anything_pressed():
		var scene = PackedScene.new()
		scene.pack(self)
		Global.savedLevels[1] = scene
		var nextScene = Global.savedLevels[0]
		queue_free()
		Global.playerCurrentPosition = playerSpawnPosition
		Global.playerDirection = playerDirection
		Global.playerTransitionHP = Global.playerCurrentHealth
		SceneTransition.change_scene_to_packed(nextScene)
	
	if is_nearLever && Input.is_action_just_pressed("use") && !$LevelObjectsBehind/Lever/LeverAnimPlayer.is_playing():
		if !$LevelObjectsBehind/Lever/LeverAnimSprite.is_flipped_h():
			$LevelObjectsBehind/Lever/LeverAnimSprite.flip_h = !$LevelObjectsBehind/Lever/LeverAnimSprite.flip_h
			$LevelObjectsBehind/Lever/LeverAnimPlayer.play("fullRotate")
		else:
			$LevelObjectsBehind/Lever/LeverAnimSprite.flip_h = !$LevelObjectsBehind/Lever/LeverAnimSprite.flip_h
			$LevelObjectsBehind/Lever/LeverAnimPlayer.play("fullRotate")

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

func _on_transition_area_body_entered(_body):
	is_nearEntrance = true

func _on_transition_area_body_exited(_body):
	is_nearEntrance = false

func _on_notif_trigger_body_entered(_body):
	if Global.is_axePicked && !is_visitedLever:
		is_visitedLever = true
		Global.emit_signal("sendNotification", "Вы можете кидать топор на правую кнопку мыши либо на X")
		$NotifTrigger/LeverAnimPlayer.play("cameraMove")

func _on_axe_detector_body_entered(_body):
	is_leverActivated = true
	$LevelObjectsBehind/Rope/RopeAnimPlayer.play("activ")

func _on_player_detector_body_entered(_body):
	is_nearLever = true

func _on_player_detector_body_exited(_body):
	is_nearLever = false

func _on_hiden_area_body_entered(_body):
	$HidenArea/HidenAreaAnimPlayer.play("hide")
	await $HidenArea/HidenAreaAnimPlayer.animation_finished
	$HidenArea/HidingRect.visible = false

func _on_hiden_descent_body_entered(_body):
	$HidenDescent/DescentAnimPlayer.play("hide")
	await $HidenDescent/DescentAnimPlayer.animation_finished
	$HidenDescent/HidingTileMap.visible = false

func saveData():
	var saveDict = {
		"filename" : get_scene_file_path(),
		"nodeName" : "DungeonLevel",
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y
	}
	return saveDict

