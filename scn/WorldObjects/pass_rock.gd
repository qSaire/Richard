extends Node2D

@onready var label = $Label
@onready var openSprite = $Area2D/OpenSprite

func _ready():
	label.text = InputMap.action_get_events("use")[0].as_text()[0] + " Активировать"
	label.visible = false

func _on_area_2d_body_entered(_body):
	if !openSprite.visible:
		label.visible = true
	else:
		label.visible = false

func _on_area_2d_body_exited(_body):
	label.visible = false
