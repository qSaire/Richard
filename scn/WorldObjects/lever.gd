extends Node2D

var is_inArea = false
var is_activated = false

@onready var label = $Label
@onready var animPlayer = $LeverAnimPlayer

func _ready():
	label.text = InputMap.action_get_events("use")[0].as_text()[0] + " Потянуть"
	label.visible = false
	if is_activated:
		animPlayer.play("halfRotate")

func _on_player_detector_body_entered(_body):
	is_inArea = true
	label.visible = true

func _on_player_detector_body_exited(_body):
	is_inArea = false
	label.visible = false

func _on_axe_detector_body_entered(_body):
	is_activated = true
	animPlayer.play("halfRotate")
