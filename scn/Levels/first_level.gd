extends Node2D

@onready var healthBar = $CanvasLayer/HealthBar
@onready var player = $Player/PlayerChar

func _ready():
	healthBar.max_value = player.playerHealth
	healthBar.value = player.playerHealth

func _on_player_char_health_changed(currentHealth):
	healthBar.value = currentHealth

func _on_manager_health_changed(currentHealth):
	healthBar.value = currentHealth
