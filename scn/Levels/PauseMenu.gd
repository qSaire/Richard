extends Control

func _process(_delta):
	if Configurator.config.get_value("Video", "fullscreen") == DisplayServer.WINDOW_MODE_FULLSCREEN:
		$"../Options/VBoxContainer/HBoxContainer2/FullscreenCheckBtn".button_pressed = true
	else:
		$"../Options/VBoxContainer/HBoxContainer2/FullscreenCheckBtn".button_pressed = false
	
	if $"../Options".visible == true && Input.is_action_just_pressed("ui_cancel"):
		$"../Options".visible = false
		$".".visible = true

func _on_continue_pressed():
	$"../Sounds".play()
	Events.emit_signal("continuePressed")

func _on_options_pressed():
	$"../Sounds".play()
	$".".visible = false
	$"../Options".visible = true

func _on_fullscreen_check_btn_toggled(toggled_on):
	if toggled_on:
		$"../Sounds".play()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		Configurator.config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		$"../Sounds".play()
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		Configurator.config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
 
	Configurator.save_data()

func _on_back_btn_pressed():
	$"../Sounds".play()
	$"../Options".visible = false
	$".".visible = true

func _on_save_pressed():
	$"../Sounds".play()
	Events.emit_signal("savePressed")

func _on_load_pressed():
	$"../Sounds".play()
	Events.emit_signal("loadPressed")

func _on_quit_pressed():
	$"../Sounds".play()
	Events.emit_signal("quitPressed")
