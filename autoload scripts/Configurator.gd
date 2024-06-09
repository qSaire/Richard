extends Node

const PATH = "user://settings.cfg"
var config = ConfigFile.new()

func _ready():
	config.set_value("Video", "fullscreen", DisplayServer.WINDOW_MODE_WINDOWED)
	
	for i in range(3):
		config.set_value("Audio", str(i), 0.5)
	
	load_data()

func save_data():
	config.save(PATH)

func load_data():
	if config.load("user://settings.cfg") != OK:
		save_data()
		return
	
	load_video_settings()

func load_video_settings():
	var screen_type = config.get_value("Video","fullscreen")
	DisplayServer.window_set_mode(screen_type)
