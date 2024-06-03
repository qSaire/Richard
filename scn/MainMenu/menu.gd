extends Node2D

# level after main menu
var levelScene = Global.loadedLevel

func _ready():
	levelScene = Global.loadedLevel

func _on_quit_btn_pressed():
	get_tree().quit()

func _on_play_btn_pressed():
	SceneTransition.change_scene_to_packed(levelScene)

func _on_options_btn_pressed():
	$Main/VBoxContainer.visible = false
	$Main/Options.visible = true

func _on_back_btn_pressed():
	$Main/VBoxContainer.visible = true
	$Main/Options.visible = false

func _on_fullscreen_check_btn_toggled(toggled_on):
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
