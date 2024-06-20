extends Node2D

var is_gateOpen = Global.is_dungeonGateOpen
var is_inPassRockArea = false
var is_nearEntrance = false
var throwableAxe = preload("res://scn/Items/throwable_axe.tscn")
var maxHealthSpawn = Global.playerMaxHealth
var is_leverActivated = false
var is_nearLever = false
var is_nearCastle = false

@onready var player = find_child("Player").find_child("PlayerChar")
@onready var healthBar = get_node(^"/root/SceneTransition/PlayerUI/HealthBar")

func _ready():
	add_to_group("Persist")
	Events.connect("mobDeath", Callable(self, "_on_mob_death"))
	Events.connect("playerDeath", Callable(self, "_on_player_death"))
	Events.connect("throwAxe", Callable(self, "_on_throw_axe"))
	Events.connect("healthChanged", Callable(self, "_on_player_char_health_changed"))
	Events.connect("maxHealthChanged", Callable(self, "_on_player_char_max_health_changed"))
	
	if is_gateOpen:
		$LevelObjectsFront/DungeonGate/GateBody/Sprite2D2.visible = false
		$LevelObjectsFront/DungeonGate/GateBody/CollisionShape2D.disabled = true
		$LevelObjectsBehind/PassRock/Area2D/OpenSprite.visible = true
	
	healthBar.max_value = Global.playerMaxHealth
	healthBar.value = Global.playerCurrentHealth
	
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
	# enter in dungeon level
	if (is_nearEntrance && Input.is_anything_pressed()) || (is_nearCastle && Input.is_action_just_pressed("use")):
		var scene = PackedScene.new()
		scene.pack(self)
		Global.savedLevels[0] = scene
		var nextScene
		if is_nearEntrance:
			Global.playerCurrentPosition = $TriggerAreas/TransitionToDungeon.playerSpawnPosition
			Global.playerDirection = $TriggerAreas/TransitionToDungeon.playerDirection
			if Global.savedLevels[1] != null:
				nextScene = Global.savedLevels[1]
			else:
				# on first enter in level
				nextScene = preload("res://scn/Levels/dungeon_level.tscn")
		elif is_nearCastle:
			Global.playerCurrentPosition = $TriggerAreas/CastleGate.playerSpawnPosition
			Global.playerDirection = $TriggerAreas/CastleGate.playerDirection
			if Global.savedLevels[2] != null:
				nextScene = Global.savedLevels[2]
			else:
				nextScene = preload("res://scn/Levels/castle_level.tscn")
		
		queue_free()
		Global.playerTransitionHP = Global.playerCurrentHealth
		SceneTransition.change_scene_to_packed(nextScene)
	
	if is_inPassRockArea && Input.is_action_pressed("use") && !is_gateOpen:
		Global.is_dungeonGateOpen = true
		$LevelObjectsBehind/PassRock/Area2D/OpenSprite.visible = true
		$LevelObjectsFront/DungeonGate/AnimationPlayer.play("opening")
		$LevelObjectsBehind/PassRock/Label.visible = false
		is_gateOpen = true
	
	if is_nearLever && Input.is_action_just_pressed("use") && !$LevelObjectsBehind/Lever/LeverAnimPlayer.is_playing():
		if is_leverActivated:
			is_leverActivated = false
			$LevelObjectsBehind/Drawbridge/StaticBody2D/DrawbridgeAnimPlayer.play_backwards("open")
			$LevelObjectsBehind/Lever/LeverAnimPlayer.play_backwards("fullRotate")
		else:
			is_leverActivated = true
			$LevelObjectsBehind/Drawbridge/StaticBody2D/DrawbridgeAnimPlayer.play("open")
			$LevelObjectsBehind/Lever/LeverAnimPlayer.play("fullRotate")

func _on_player_char_health_changed(health):
	healthBar.value = health
	Global.playerCurrentHealth = health

func _on_player_char_max_health_changed(health):
	healthBar.max_value = health
	Global.playerMaxHealth = health

func _on_area_2d_body_entered(_body):
	is_inPassRockArea = true

func _on_area_2d_body_exited(_body):
	is_inPassRockArea = false

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

func _on_waterwell_body_entered(_body):
	$TriggerAreas/Waterwell/WaterwellAnimPlayer.play("hide")
	await $TriggerAreas/Waterwell/WaterwellAnimPlayer.animation_finished
	$TriggerAreas/Waterwell/UnderWaterwellTiles.visible = false

func _on_player_detector_body_entered(_body):
	is_nearLever = true

func _on_player_detector_body_exited(_body):
	is_nearLever = false

func _on_axe_detector_body_entered(_body):
	is_leverActivated = true
	$LevelObjectsBehind/Drawbridge/StaticBody2D/DrawbridgeAnimPlayer.play("open")

func _on_under_bridge_body_entered(_body):
	var axe = get_node("Items/ThrowableAxe")
	axe.velocity.x = 0
	Global.throwDirection = -1
	var tween = create_tween()
	tween.tween_property(axe, "position", Vector2(10150, 590), 1.5)
	tween.tween_property(axe, "position", Vector2(9918, 635), 0.4)

func _on_under_bridge_area_entered(area):
	if area.get_collision_layer_value(5) == true:
		Events.emit_signal("playerAttack", 1000, area)

func _on_castle_gate_body_entered(_body):
	is_nearCastle = true
	$TriggerAreas/CastleGate/GateSounds.play()
	$TriggerAreas/CastleGate/CastleGate.visible = true
	$TriggerAreas/CastleGate/Label.visible = true

func _on_castle_gate_body_exited(_body):
	is_nearCastle = false
	$TriggerAreas/CastleGate/CastleGate.visible = false
	$TriggerAreas/CastleGate/Label.visible = false

func saveData():
	var saveDict = {
		"filename" : get_scene_file_path(),
		"nodeName" : "FirstLevel",
		"parent" : get_parent().get_path(),
		"pos_x" : position.x,
		"pos_y" : position.y,
		"is_gateOpen" : is_gateOpen,
		"is_leverActivated" : is_leverActivated,
		"is_inPassRockArea" : is_inPassRockArea
	}
	return saveDict

