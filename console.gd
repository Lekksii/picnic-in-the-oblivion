extends Panel
class_name Console
@onready var console_line = $console_command_line
@onready var console_text = $text_lines

var player : Player

signal command_entered

# Called when the node enters the scene tree for the first time.
func _ready():
	command_entered.connect(on_command_entered)


func on_command_entered(cmd : String):
	if GameManager.player != null and player == null:
		player = GameManager.player
		
	var cmd_code = cmd.to_lower().split('(')[0]
	var cmd_arguments = cmd.to_lower().split('(',false)[1].split(')',false)[0] if cmd.contains('(') and cmd.contains(')') else null
	
	if cmd_arguments and cmd_arguments.contains(','): cmd_arguments = cmd_arguments.split(',',false)
	
	match cmd_code:
		"exit": Close()
		"cls": Close()
		"close": Close()
		"heal": player.Heal(player.health_max)
		"exp": 
			var amount : int = int(cmd_arguments) if cmd_arguments != null else 0
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,str(cmd_arguments)])
			if typeof(amount) == TYPE_INT:
				GameManager.Gui.SkillWindow.AddExp(amount)
			else:
				console_text.append_text("\n>>> %s : [color=red]Wrong type, it's must be integer![/color]" % cmd_code)
				
		"god": 
			GameManager.godmode = !GameManager.godmode
			console_text.append_text("\nGodmode is %s" % ["Enabled" if GameManager.godmode else "Disabled"])
		"ai_ignore": 
			GameManager.ai_ignore = !GameManager.ai_ignore
			console_text.append_text("\nAI Ignore is %s" % ["Enabled" if GameManager.ai_ignore else "Disabled"])
		"money": player.AddMoney(9999)
		"help": 
			console_text.append_text("\n>>> %s:\n\n" % cmd_code)
			console_text.append_text("1. exit, cls, close -> Close console window\n")
			console_text.append_text("2. help -> Show available commands\n")
			console_text.append_text("3. level(lvl_id: [color=orange]String[/color]) -> load level by id\n")
			console_text.append_text("4. add_key(key: [color=orange]String[/color] or keys: [color=orange]Array[/color]) -> add event keys to player\n")
			console_text.append_text("5. give_item(id: [color=orange]String[/color] or ids: [color=orange]Array[/color]) -> add item/items to player\n")
			console_text.append_text("6. player_debug_fly(state: [color=orange]bool[/color]) -> set player debug fly mode (1) - fly, (0) - not fly\n")
			console_text.append_text("7. hide_hud(state: [color=orange]bool[/color]) -> show (0)/(1) hide HUD\n")
			console_text.append_text("8. hide_wpn(state: [color=orange]bool[/color]) -> show (0)/(1) hide weapons\n")
			console_text.append_text("9. photo_mode(state: [color=orange]bool[/color]) -> show/hide UI and weapons HUD\n")
			console_text.append_text("10. heal -> Heal player\n")
			console_text.append_text("11. god -> Make player immortal\n")
			console_text.append_text("12. ai_ignore -> Make AI to ignore player (help for debugging doors/transitions)\n")
			console_text.append_text("13. money -> Add 9999$ to player\n")
			
			
		"photo_mode":
			var state : bool = bool(int(cmd_arguments))
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])
			if typeof(state) == TYPE_BOOL:			
				GameManager.Gui.SetHUD(state)
				GameManager.Gui.SetWeaponHUD(state)
			else:
				console_text.append_text("\n>>> %s : [color=red]Wrong type, it's must be bool![/color]" % cmd_code)
			
		"hide_wpn":
			var state : bool = bool(int(cmd_arguments))
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])
			if typeof(state) == TYPE_BOOL:			
				GameManager.Gui.SetWeaponHUD(state)
			else:
				console_text.append_text("\n>>> %s : [color=red]Wrong type, it's must be bool![/color]" % cmd_code)
		
		"hide_hud":
			var state : bool = bool(int(cmd_arguments))
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])
			if typeof(state) == TYPE_BOOL:			
				GameManager.Gui.SetHUD(state)
			else:
				console_text.append_text("\n>>> %s : [color=red]Wrong type, it's must be bool![/color]" % cmd_code)
		
		"player_debug_fly":
			var state : bool = bool(int(cmd_arguments))
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])
			if typeof(state) == TYPE_BOOL:			
				GameManager.player.DebugFly = bool(state)
			else:
				console_text.append_text("\n>>> %s : [color=red]Wrong type, it's must be bool![/color]" % cmd_code)
				
		
		"give_item":
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])			
			
			if cmd_arguments is PackedStringArray:
				for arg in cmd_arguments:
					console_text.append_text("\n>>> item [%s] added!" % arg)	
					GameManager.Gui.InventoryWindow.AddItem(arg)
			else:
				console_text.append_text("\n>>> item [%s] added!" % cmd_arguments)
				GameManager.Gui.InventoryWindow.AddItem(cmd_arguments)
		"level":
			if cmd_arguments:
				console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])
				await get_tree().create_timer(0.1).timeout
				Close()
				GameManager.change_level(cmd_arguments)
		"add_key":
			console_text.append_text("\n>>> %s (%s)" % [cmd_code,cmd_arguments])			
			if cmd_arguments is PackedStringArray:
				for arg in cmd_arguments:
					console_text.append_text("\n>>> \"%s\" key added!" % arg)	
					GameManager.AddEventKey(arg)
			else:
				console_text.append_text("\n>>> \"%s\" key added!" % cmd_arguments)
				GameManager.AddEventKey(cmd_arguments)
			Close()
		_: console_text.append_text("\n>>> %s : [color=red]Unknow command![/color]" % cmd_code)
			
	
	#"Entered [%s] cmd with (%s) args" % [cmd_code, cmd_arguments])


func _on_console_command_line_text_submitted(new_text):
	console_line.text = ""
	emit_signal("command_entered",new_text)

func _input(event):
	
	
	if Input.is_action_just_pressed("console") or Input.is_action_just_pressed("pause"):
		if GameManager.pause and visible:
			#print("console pressed esc")
			if not GameManager.Gui.InventoryWindow.IsOpened() and \
				not GameManager.Gui.JournalWindow.IsOpened() and not GameManager.Gui.MapWindow.IsOpened() and not GameManager.Gui.SkillWindow.IsOpened():
						Close()

func all_pause_windows_closed() -> bool:
	return (not GameManager.Gui.InventoryWindow.IsOpened() and
			not GameManager.Gui.JournalWindow.IsOpened() and
			not GameManager.Gui.MapWindow.IsOpened() and
			not GameManager.Gui.SkillWindow.IsOpened())

func Close():
	#print("Console close")
	if GameManager.pause:
		self.hide()
		if not GameManager.Gui.death_screen.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		await get_tree().create_timer(0.1).timeout
		GameManager.pause = false

func Open():
	if not GameManager.pause:
		GameManager.pause = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		self.show()
