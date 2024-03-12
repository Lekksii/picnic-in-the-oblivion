extends Node

var bug_trap = preload("res://bug_trap.tscn")
var bug
#var bug_server : TCPServer = TCPServer.new()
#var bug_server_peers = []
var error_messages = []
#var has_connection = false

func _ready():
	self.process_mode = Node.PROCESS_MODE_ALWAYS
	#bug_server.listen(9999,"127.0.0.1")	
	
func _process(_delta):
	if bug != null:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	#UDP()
	#if bug_server.is_connection_available() and not has_connection:
	#	print("Connection available!")
	#	bug_server.take_connection().put_string(str(error_message))
	#	has_connection = true
	#if not bug_server.is_connection_available() and has_connection:
	#	has_connection = false
	#	print("BugTrap disconnected!")

func Crash(caption : String,console_secription=""):
	#var file = FileAccess.open(OS.get_executable_path().replace("picnic.exe","")+"logs.txt",FileAccess.WRITE)
	#var time = Time
	#var t = time.get_datetime_dict_from_system()
	if not GameManager.Gui.has_node("BugTrap"):
		#print("First crash! - %s" % caption)
		#get_tree().paused = true
		#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		bug = bug_trap.instantiate() as Control
		GameManager.Gui.add_child.call_deferred(bug)		
		error_messages.append(caption)
		GameManager.Gui.get_node("GAME").hide()
		printerr(caption)
		
		#get_node("/root/Game/sv").queue_free()
		#Gui.get_node("GAME").hide()
		#get_node("/root/Game").queue_free()
		#get_window().mode = Window.MODE_WINDOWED
		get_window().title = "Game crashed..."
		#get_window().size = Vector2i(640,480)
		bug.set_anchors_preset(Control.PRESET_FULL_RECT)
		Input.set_custom_mouse_cursor(null)
		get_window().grab_focus()
		get_window().position = Vector2(get_window().content_scale_size.x/2.0-get_window().size.x/2.0,get_window().content_scale_size.y/2.0-get_window().size.y/2.0)
		#Gui.get_node("Bug").show()
		bug.set_size(get_window().size)
		
		bug.get_node("OK").pressed.connect(on_ok_bug_pressed)
		bug.get_node("Copy").pressed.connect(on_copy_bug_pressed)	
		bug.get_node("Panel/Group/ErrorRichLabel").text = "[center][img=256]IconBug.png[/img][/center]\n \n"
		for cap in error_messages:
			bug.get_node("Panel/Group/ErrorRichLabel").add_text(cap+"\n")
		#get_tree().paused = true
	else:
		#print("Another crash!")
		GameManager.Gui.get_node("BugTrap/Panel/Group/ErrorRichLabel").text += "\n"+caption
	
	#for line in bug.get_node("Panel/Group/ErrorRichLabel").text.get_line_count():	
	#file.store_line(("[%d/%d/%d %d:%d:%d]: %s" % [t.day,t.month,t.year,t.hour,t.minute,t.second,"BugTrap.Crash() -> "]) + " %s" % console_secription if console_secription != "" else ("[%d/%d/%d %d:%d:%d]: %s" % [t.day,t.month,t.year,t.hour,t.minute,t.second, "BugTrap.Crash():"]))
	#file.close()
	await get_tree().create_timer(0.1).timeout
	get_tree().paused = true
func on_ok_bug_pressed():
	get_tree().quit()
	
func on_copy_bug_pressed():
	DisplayServer.clipboard_set(bug.get_node("Panel/Group/ErrorRichLabel").text)
	get_tree().quit()
