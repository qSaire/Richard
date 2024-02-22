extends Node

signal healthChanged(currentHealth)
var isGamePaused = false
@onready var pauseMenu = $"../CanvasLayer/PauseMenu"

func _process(_delta):
	if Input.is_action_just_pressed("ui_cancel"):
		isGamePaused = !isGamePaused
	
	if isGamePaused == true:
		get_tree().paused = true
		pauseMenu.show()
	else:
		get_tree().paused = false
		pauseMenu.hide()

func _on_continue_pressed():
	isGamePaused = !isGamePaused

func _on_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scn/MainMenu/menu.tscn")

func _on_save_pressed():
	save_game()
	isGamePaused = !isGamePaused

func save_game():
	var saveFile = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	for node in saveNodes:
		if node.scene_file_path.is_empty():
			print("сохраняемый узел '%s' не является экземпляром сцены, пропущен" % node.name)
			continue
		
		if !node.has_method("saveData"):
			print("'%s' не имеет функции saveData(), пропущен" % node.name)
			continue
		
		var nodeData = node.call("saveData")
		var jsonString = JSON.stringify(nodeData)
		saveFile.store_line(jsonString)

func _on_load_pressed():
	load_game()
	isGamePaused = !isGamePaused

func load_game():
	if !FileAccess.file_exists("user://savegame.save"):
		return
	
	var saveFile = FileAccess.open("user://savegame.save", FileAccess.READ)
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	for numOfNode in range(saveNodes.size()):
		var jsonString = saveFile.get_line()
		var json = JSON.new()
		var parseResult = json.parse(jsonString)
		if not parseResult == OK:
			print("Ошибка парсинга JSON файла: ", json.get_error_message(), " в " + jsonString + " на строчке №", numOfNode)
			continue
		
		var nodeData = json.get_data()
		saveNodes[numOfNode].position = Vector2(nodeData["pos_x"], nodeData["pos_y"])
		for i in nodeData.keys():
			if i == "playerHealth":
				emit_signal("healthChanged", int(nodeData[i]))
			
			saveNodes[numOfNode].set(i, nodeData[i])
