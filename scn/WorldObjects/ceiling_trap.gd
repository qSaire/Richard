extends StaticBody2D

func _on_detector_body_entered(_body):
	$PressurePlate/PlateAnimPlayer.play("push")

func _on_detector_body_exited(_body):
	if $PressurePlate/PlateAnimPlayer.is_playing():
		await $PressurePlate/PlateAnimPlayer.animation_finished
	$PressurePlate/PlateAnimPlayer.play("pushOut")
