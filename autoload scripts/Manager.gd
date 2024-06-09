extends Node

var isGamePaused = false

@onready var pauseMenu = get_node(^"/root/SceneTransition/PlayerUI/PauseMenu")
@onready var healthBar = get_node(^"/root/SceneTransition/PlayerUI/HealthBar")
@onready var optionsNode = get_node(^"/root/SceneTransition/PlayerUI//Options")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	Events.connect("continuePressed", Callable(self, "_on_continue_pressed"))
	Events.connect("quitPressed", Callable(self, "_on_quit_pressed"))
	Events.connect("savePressed", Callable(self, "_on_save_pressed"))
	Events.connect("loadPressed", Callable(self, "_on_load_pressed"))

func _process(_delta):
	if get_parent().has_node("Menu"):
		healthBar.visible = false
	else:
		healthBar.visible = true
	
	if (Input.is_action_just_pressed("ui_cancel") && !get_parent().has_node("Menu") 
	&& optionsNode != null && optionsNode.visible != true):
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
	isGamePaused = false
	get_tree().get_first_node_in_group("Persist").queue_free()
	SceneTransition.change_scene_to_file("res://scn/MainMenu/menu.tscn")

func _on_save_pressed():
	save_game()
	isGamePaused = !isGamePaused

func _on_load_pressed():
	load_game()
	isGamePaused = !isGamePaused

func save_game():
	var saveFile = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	var levelNode = get_tree().get_first_node_in_group("Persist")
	var scene = PackedScene.new()
	scene.pack(levelNode)
	match levelNode.get_name():
		"FirstLevel":
			Global.savedLevels[0] = scene
		"DungeonLevel":
			Global.savedLevels[1] = scene
	
	var playerNode = levelNode.find_child("Player").get_child(0)
	
	# firstly saving level and player nodes
	saveFile.store_line(JSON.stringify(saveNodes[saveNodes.find(levelNode)].call("saveData")))
	saveFile.store_line(JSON.stringify(saveNodes[saveNodes.find(playerNode)].call("saveData")))
	for node in saveNodes:
		if node.scene_file_path.is_empty():
			print("сохраняемый узел '%s' не является экземпляром сцены, пропущен" % node.name)
			continue
		
		if !node.has_method("saveData"):
			print("'%s' не имеет функции saveData(), пропущен" % node.name)
			continue
		
		if node == playerNode || node == levelNode:
			continue
		
		var nodeData = node.call("saveData")
		var jsonString = JSON.stringify(nodeData)
		saveFile.store_line(jsonString)

func load_game(): # not safe
	if !FileAccess.file_exists("user://savegame.save"):
		return 
	
	var saveNodes = get_tree().get_nodes_in_group("Persist")
	# delete current level node
	if saveNodes.size() != 0:
		saveNodes[0].free()
	
	var saveFile = FileAccess.open("user://savegame.save", FileAccess.READ)
	# load level and delete old nodes in it
	loadLevel(saveFile)
	# get new nodes from loaded level
	saveNodes = get_tree().get_nodes_in_group("Persist")
	for i in saveNodes:
		if i == saveNodes[0]:
			continue
		i.queue_free()
	
	while saveFile.get_position() + 1 < saveFile.get_length():
		var jsonString = saveFile.get_line()
		var json = JSON.new()
		var parseResult = json.parse(jsonString)
		if parseResult != OK:
			print("JSON Parse Error: ", json.get_error_message(), " in ", jsonString, " at line ", json.get_error_line())
			continue
		
		var nodeData = json.get_data()
		var newObject = load(nodeData["filename"]).instantiate()
		get_node(nodeData["parent"]).add_child(newObject)
		newObject.position = Vector2(nodeData["pos_x"], nodeData["pos_y"])
		newObject.add_to_group("Persist")
		for i in nodeData.keys():
			if i == "currentHealth":
				Events.emit_signal("healthChanged", int(nodeData[i]))
			
			if i == "filename" || i == "parent" || i == "pos_x" || i == "pos_y":
				continue
			
			newObject.set(i, nodeData[i])

func loadLevel(saveFile):
	var jsonString = saveFile.get_line()
	var json = JSON.new()
	json.parse(jsonString)
	var nodeData = json.get_data()
	
	var newObject
	if nodeData["filename"] == "" && Global.savedLevels[0] != null:
		match nodeData["nodeName"]:
			"FirstLevel":
				newObject = Global.savedLevels[0].instantiate()
			"DungeonLevel":
				newObject = Global.savedLevels[1].instantiate()
	else:
		newObject = load(nodeData["filename"]).instantiate()
	
	get_node(nodeData["parent"]).add_child(newObject)
	newObject.position = Vector2(nodeData["pos_x"], nodeData["pos_y"])
	newObject.add_to_group("Persist")
	for i in nodeData.keys():
		if i == "filename" || i == "parent" || i == "pos_x" || i == "pos_y":
			continue
		
		newObject.set(i, nodeData[i])
