extends Control

func _on_continue_pressed():
	Events.emit_signal("continuePressed")

func _on_save_pressed():
	Events.emit_signal("savePressed")

func _on_load_pressed():
	Events.emit_signal("loadPressed")

func _on_quit_pressed():
	Events.emit_signal("quitPressed")
