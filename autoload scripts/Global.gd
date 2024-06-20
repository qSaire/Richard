extends Node

signal sendNotification(notificationText)

# level after main menu
var loadedLevel = preload("res://scn/Levels/first_level.tscn")
var savedLevels = [load("res://scn/Levels/first_level.tscn"), 
	load("res://scn/Levels/dungeon_level.tscn"), 
	load("res://scn/Levels/castle_level.tscn")]
var is_axePicked = false
var is_axeThrown = false
var throwDirection = 0
var is_dungeonGateOpen = false
var playerMaxHealth = 80
var playerCurrentHealth = 80
var playerTransitionHP = 80
var playerDirection = 1
var playerCurrentPosition = Vector2(2100, 596)
