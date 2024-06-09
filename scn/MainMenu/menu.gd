extends Node2D

var levelScene = Global.loadedLevel

func _ready():
	levelScene = Global.loadedLevel
	if Configurator.config.get_value("Video", "fullscreen") == DisplayServer.WINDOW_MODE_FULLSCREEN:
		$Main/Options/HBoxContainer3/HBoxContainer2/FullscreenCheckBtn.button_pressed = true
	else:
		$Main/Options/HBoxContainer3/HBoxContainer2/FullscreenCheckBtn.button_pressed = false

func _on_quit_btn_pressed():
	$Sounds.play()
	get_tree().quit()

func _on_play_btn_pressed():
	$Sounds.play()
	SceneTransition.change_scene_to_packed(levelScene)

func _on_options_btn_pressed():
	$Sounds.play()
	$Main/VBoxContainer.visible = false
	$Main/Options.visible = true

func _on_back_btn_pressed():
	$Sounds.play()
	$Main/VBoxContainer.visible = true
	$Main/Options.visible = false

func _on_fullscreen_check_btn_toggled(toggled_on):
	if toggled_on:
		$Sounds.play()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Configurator.config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		$Sounds.play()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Configurator.config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
	
	Configurator.save_data()
