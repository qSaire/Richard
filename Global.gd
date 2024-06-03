extends Node

signal sendNotification(notificationText)

var loadedLevel = preload("res://scn/Levels/first_level.tscn")
var levels = [loadedLevel,
	preload("res://scn/Levels/dungeon_level.tscn")]
var savedLevels = [null, null, null]
var is_axePicked = false
var is_axeThrown = false
var throwDirection = 0
var is_dungeonGateOpen = false
var playerMaxHealth = 80
var playerCurrentHealth = 80
var playerTransitionHP = 80
var playerDirection = 1
var playerCurrentPosition = Vector2(2100, 595)

#начало - 2100, 595      у пещеры - 609, 1454     528, 595
#в пещере - 8008, 462
