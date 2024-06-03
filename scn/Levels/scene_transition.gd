extends Node

@onready var animPlayer = $AnimationPlayer

func _ready():
	Global.connect("sendNotification", Callable(self, "_on_send_notification"))

func change_scene_to_file(path : String):
	animPlayer.play("fadeIn")
	await on_animation_finished()
	change(path)
	animPlayer.play("fadeOut")

func change_scene_to_packed(scene):
	animPlayer.play("fadeIn")
	await on_animation_finished()
	get_tree().change_scene_to_packed(scene)
	animPlayer.play("fadeOut")

func change(path):
	get_tree().change_scene_to_file(path)

func on_animation_finished():
	await animPlayer.animation_finished

func _on_send_notification(notificationText):
	$PlayerUI/NotificationLabel.text = notificationText
	$PlayerUI/AnimationPlayer.play("fadeText")
