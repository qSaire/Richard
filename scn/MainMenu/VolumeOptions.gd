extends VBoxContainer

func _ready(): # при заходе всегда готов - исправить на обновление после глав меню
	%MasterSlider.value = Configurator.config.get_value("Audio", '0')
	AudioServer.set_bus_volume_db(0, linear_to_db(%MasterSlider.value))
	
	%MusicSlider.value = Configurator.config.get_value("Audio", '1')
	AudioServer.set_bus_volume_db(1, linear_to_db(%MusicSlider.value))
	
	%SfxSlider.value = Configurator.config.get_value("Audio", '2')
	AudioServer.set_bus_volume_db(2, linear_to_db(%SfxSlider.value))

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		%MasterSlider.value = Configurator.config.get_value("Audio", '0')
		%MusicSlider.value = Configurator.config.get_value("Audio", '1')
		%SfxSlider.value = Configurator.config.get_value("Audio", '2')

func _on_master_slider_value_changed(value):
	set_volume(0,value)

func _on_music_slider_value_changed(value):
	set_volume(1,value)

func _on_sfx_slider_value_changed(value):
	set_volume(2,value)

func set_volume(idx, value):
	AudioServer.set_bus_volume_db(idx, linear_to_db(value))
	Configurator.config.set_value("Audio",str(idx),value)
	Configurator.save_data()
