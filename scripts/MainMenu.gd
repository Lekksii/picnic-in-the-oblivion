extends ColorRect
class_name MainMenu
var load_btn = {"id": "mm_load", "text_id": "mm.continue"}
var mm_buttons = [
	{
		"id": "mm_new_game",
		"text_id": "mm.new.game"
	},
	{
		"id": "mm_options",
		"text_id": "mm.opt"
	},
	{
		"id": "mm_help",
		"text_id": "mm.help"
	},
	{
		"id": "mm_about",
		"text_id": "mm.about"
	},
	{
		"id": "mm_exit",
		"text_id": "mm.exit"
	},
]
var last_opt_chnanged = []
var languages = []
var credits_strings = []
var selected_index = 0
var pseudo_anim_btn_speed = 0.4
var sound_enabled = true

#region Variables of options buttons

@onready var version_title : RichTextLabel = $versionTitle
@onready var selected_button : Label = $ClickableTitle
@onready var left_button : Label = $NonClickableLeft
@onready var right_button : Label = $NonClickableRight
@onready var about_menu : Control = $MenuAbout
@onready var options_menu : Control = $Options
@onready var first_launch_menu : Control = $FirstLaunchWindow
@onready var logo : TextureRect = $Logo
@onready var background_color : ColorRect = self

@onready var opt_lang_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_lang
@onready var opt_sounds_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_snd
@onready var opt_aim_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_aim
@onready var opt_autoreload_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_autoreload
@onready var opt_fps_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_fps
@onready var opt_lang_first_launch : Button = $FirstLaunchWindow/VerticalContainer/opt_lang_fl
@onready var opt_difficulty_first_launch : Button = $FirstLaunchWindow/VerticalContainer/opt_difficulty_fl
@onready var opt_vsync_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_vsync
@onready var opt_mouse_smooth_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_smooth
@onready var opt_mouse_sens_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_sens
@onready var opt_vol_main_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volume_main
@onready var opt_vol_amb_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volume_amb
@onready var opt_vol_sfx_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volume_sfx
@onready var opt_vol_music_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volume_music
@onready var opt_vol_fx_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volume_fx1
@onready var opt_fps_lock_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_max_fps
@onready var opt_scale_3d_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_scale_3d
@onready var opt_difficulty_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_difficulty

@onready var opt_slider_main = $Options/ScrollContainer/VerticalContainer/slider_number_main
@onready var opt_slider_amb = $Options/ScrollContainer/VerticalContainer/slider_number_amb
@onready var opt_slider_sfx = $Options/ScrollContainer/VerticalContainer/slider_number_sfx
@onready var opt_slider_music = $Options/ScrollContainer/VerticalContainer/slider_number_music
@onready var opt_slider_fx = $Options/ScrollContainer/VerticalContainer/slider_number_fx
@onready var opt_slider_mouse_smooth = $Options/ScrollContainer/VerticalContainer/slider_number_smooth
@onready var opt_slider_mouse_sens = $Options/ScrollContainer/VerticalContainer/slider_number_sens
@onready var opt_slider_3d_scale = $Options/ScrollContainer/VerticalContainer/slider_number_3dscale

@onready var opt_ssao_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_ssao
@onready var opt_dithering_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_dithering
@onready var opt_glow_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_glow
@onready var opt_volumetric_fog_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_volumetric_fog
@onready var opt_moving_sky_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_moving_sky
@onready var opt_pixelation_btn : Button = $Options/ScrollContainer/VerticalContainer/opt_pixelation
@onready var opt_cam_sway : Button = $Options/ScrollContainer/VerticalContainer/opt_cam_sway
@onready var opt_corpses : Button = $Options/ScrollContainer/VerticalContainer/opt_corpses

@onready var splash_blocker = $"../../SplashBlocker"

@onready var about_scroll : ScrollContainer = $MenuAbout/ScrollContainer

var touch_start_position = Vector2()
var touch_end_position = Vector2()

#endregion

var about_autoscroll = false

var color_active = "ee9d31"
var color_disabled = "66625f"

var current_lang = 0

func _input(event):
	if OS.has_feature("mobile"):
		if visible and GameManager.main_menu:
			if event is InputEventScreenTouch and event.is_pressed():
				touch_start_position = event.position
			elif event is InputEventScreenTouch and not event.is_pressed():
				touch_end_position = event.position
				var swipe_vector = touch_end_position - touch_start_position
				#print("Swipe vector: %s" % str(swipe_vector))
				if swipe_vector.x > 100:
					PlusIndex()
				if swipe_vector.x < -100:
					MinusIndex()

func opt():
	return Utility.read_json("assets/options.json")

func credits():
	return Utility.read_json("assets/gameplay/credits.json")

func pseudo_btn_animation():
	await get_tree().create_timer(pseudo_anim_btn_speed).timeout
	left_button.text = "< "
	right_button.text = " >"
	await get_tree().create_timer(pseudo_anim_btn_speed).timeout
	left_button.text = "<"
	right_button.text = ">"
	pseudo_btn_animation()

func add_volume_bus(bus_name):
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)) < 0:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name),AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))+1.0)
	
func low_volume_bus(bus_name):
	if AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name)) >= -80:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(bus_name),AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))-1.0)

func change_volume_bus(bus_name:String,type:String="+"):
	if type == "+":
		add_volume_bus(bus_name)
	if type == "-": 
		low_volume_bus(bus_name)

func get_percent(value):
	var percentage = max(0.0, min(100.0, ((value - -80) / (0.0 - -80.0)) * 100.0))
	return round(percentage)
	
#region Ready() and intitialization of options buttons

func _ready():
	var _opt = opt()
	var sliders = [opt_slider_main,
	opt_slider_amb, opt_slider_music,
	opt_slider_sfx, opt_slider_fx,
	opt_slider_mouse_smooth,opt_slider_mouse_sens,
	opt_slider_3d_scale]
	
	opt_vsync_btn.pressed.connect(on_opt_any_btn_click.bind(opt_vsync_btn.name))
	opt_mouse_smooth_btn.pressed.connect(on_opt_any_btn_click.bind(opt_mouse_smooth_btn.name))
	opt_mouse_sens_btn.pressed.connect(on_opt_any_btn_click.bind(opt_mouse_sens_btn.name))
	opt_fps_lock_btn.pressed.connect(on_opt_any_btn_click.bind(opt_fps_lock_btn.name))
	opt_scale_3d_btn.pressed.connect(on_opt_any_btn_click.bind(opt_scale_3d_btn.name))
	opt_difficulty_btn.pressed.connect(on_opt_any_btn_click.bind(opt_difficulty_btn.name))
	opt_ssao_btn.pressed.connect(on_opt_any_btn_click.bind(opt_ssao_btn.name))
	opt_dithering_btn.pressed.connect(on_opt_any_btn_click.bind(opt_dithering_btn.name))
	opt_glow_btn.pressed.connect(on_opt_any_btn_click.bind(opt_glow_btn.name))
	opt_volumetric_fog_btn.pressed.connect(on_opt_any_btn_click.bind(opt_volumetric_fog_btn.name))
	opt_moving_sky_btn.pressed.connect(on_opt_any_btn_click.bind(opt_moving_sky_btn.name))
	opt_pixelation_btn.pressed.connect(on_opt_any_btn_click.bind(opt_pixelation_btn.name))
	opt_cam_sway.pressed.connect(on_opt_any_btn_click.bind(opt_cam_sway.name))
	opt_corpses.pressed.connect(on_opt_any_btn_click.bind(opt_corpses.name))
	
	
	for slider in sliders:
		slider.get_node("low_volume").pressed.connect(on_volume_low_slider_clicked.bind(slider.name))
		slider.get_node("rise_volume").pressed.connect(on_volume_add_slider_clicked.bind(slider.name))
		
		slider.get_node("low_volume").button_down.connect(on_volume_low_slider_clicked.bind(slider.name))
		slider.get_node("rise_volume").button_down.connect(on_volume_add_slider_clicked.bind(slider.name))
		
		if slider.name == opt_slider_main.name:
			slider.get_node("number").text = str(get_percent(_opt["volume_master"]))+"%"
		if slider.name == opt_slider_amb.name:
			slider.get_node("number").text = str(get_percent(_opt["volume_ambient"]))+"%"
		if slider.name == opt_slider_music.name:
			slider.get_node("number").text = str(get_percent(_opt["volume_music"]))+"%"
		if slider.name == opt_slider_sfx.name:
			slider.get_node("number").text = str(get_percent(_opt["volume_ambient_sfx"]))+"%"
		if slider.name == opt_slider_fx.name:
			slider.get_node("number").text = str(get_percent(_opt["volume_fx"]))+"%"
		if slider.name == opt_slider_mouse_smooth.name:
			slider.get_node("number").text = str(_opt["mouse_smooth"])
		if slider.name == opt_slider_mouse_sens.name:
			slider.get_node("number").text = str(_opt["mouse_sensitivity"]*100)
		if slider.name == opt_slider_3d_scale.name:
			slider.get_node("number").text = str(snapped(_opt["scale_3d_render"]*100.0,0))+"%"
			
	pseudo_btn_animation()
	
	version_title.text = "[b]build#%s ver. [color=ee9d31]%.1f[/color] %s [/b]" % [GameManager.game_build,GameManager.game_version, GameManager.game_version_suffix]
	
	if "input_map" in opt():
		var controls = {}
		for input in opt()["input_map"]:
			controls[input["action_id"]] = input["key_code"] if typeof(input["key_code"]) == TYPE_ARRAY else [input["key_code"]]
		add_inputs_options(controls)
		
	# if we have languages already - clear list
	if languages.size() > 0:
		languages.clear()
	
	# append languages to the list from opions
	for lang in opt()["languages"].keys():
		languages.append(lang)
	
	# set current language index to real current language from options
	current_lang = opt()["languages"].keys().find(opt()["current_language"]) as int
	
	# update options text to current language
	if languages.size() > 0:
		_update_options()
		
	# update main buttons selector
	UpdateSelector()
	# run our outside script
	GameAPI.RunOutsideScript("p_mm")._menu_init(self)
	
	# connect method to signal when game will be ready and fully loaded
	GameManager.on_game_ready.connect(on_game_ready)
	
#endregion

func OnSplashFinishedAll():
	GameManager.player.PlayMusic("assets/sounds/mm_music.wav")

func _update_options():
	opt_lang_btn.text = Lang.translate("mm.opt.lang.selector") + " %s" % Lang.translate("lang.%s" % Lang.current_lang)
	opt_lang_first_launch.text = Lang.translate("mm.opt.lang.selector") + " %s" % Lang.translate("lang.%s" % Lang.current_lang)
	_set_ui_opt_text(opt_difficulty_first_launch,opt()["casual_gameplay"],"mm.opt.difficulty","mm.opt.difficulty.easy","mm.opt.difficulty.normal")
	_set_ui_opt_text(opt_corpses,opt()["corpses"],"mm.opt.corpses","opt.yes","opt.no")
	
	opt_sounds_btn.text = Lang.translate("mm.opt.sounds") + " %s" % Lang.translate("opt.yes" if sound_enabled else "opt.no")
	opt_aim_btn.text = Lang.translate("mm.opt.aim") + " %s" % Lang.translate("opt.yes" if GameManager.aim_assist else "opt.no")
	if GameManager.is_game_ready:
		opt_autoreload_btn.text = Lang.translate("mm.opt.autoreload") + " %s" % Lang.translate("opt.yes" if GameManager.weapon_system.autoreloading else "opt.no")
		opt_fps_btn.text = Lang.translate("mm.opt.fps") + " %s" % Lang.translate("opt.yes" if GameManager.show_fps else "opt.no")
		_set_ui_opt_text(opt_vsync_btn,opt()["vsync"],"mm.opt.vsync","opt.yes","opt.no")
		#_set_ui_opt_text(opt_fps_lock_btn,opt()["lock_60_fps"],"mm.opt.max.fps","opt.yes","opt.no")
		_set_ui_opt_text(opt_difficulty_btn,opt()["casual_gameplay"],"mm.opt.difficulty","mm.opt.difficulty.easy","mm.opt.difficulty.normal")
		_set_ui_opt_text(opt_ssao_btn,opt()["ssao"],"mm.opt.ssao","opt.yes","opt.no")
		_set_ui_opt_text(opt_glow_btn,opt()["glow"],"mm.opt.glow","opt.yes","opt.no")
		_set_ui_opt_text(opt_dithering_btn,opt()["dithering"],"mm.opt.dithering","opt.yes","opt.no")
		_set_ui_opt_text(opt_volumetric_fog_btn,opt()["volumetric_fog"],"mm.opt.volumetric.fog","opt.yes","opt.no")
		_set_ui_opt_text(opt_moving_sky_btn,opt()["sky_shader"],"mm.opt.moving.sky","opt.yes","opt.no")
		_set_ui_opt_text(opt_pixelation_btn,opt()["pixelation"],"mm.opt.pixelation","opt.yes","opt.no")
		_set_ui_opt_text(opt_cam_sway,opt()["camera_sway"],"mm.opt.camera.sway","opt.yes","opt.no")
		
func _set_ui_opt_text(ui_opt : Button,parameter,text_key: String,yes_key: String,no_key: String):
	ui_opt.text = Lang.translate(text_key) + " %s" % Lang.translate(yes_key if parameter else no_key)

#region Process() function

func _process(_delta):
	if first_launch_menu.visible:
		if splash_blocker == null:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if about_autoscroll:
		#print("autoscroll")
		about_scroll.scroll_vertical += 1
	
	if visible:
		if splash_blocker == null:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	if GameManager.main_menu and (splash_blocker == null or not GameManager.show_splash):
		if (not GameManager.Gui.TradingMessage.visible and
			not options_menu.visible and not about_menu.visible and
			not GameManager.Gui.IntroWindow.visible and not GameManager.Gui.death_screen.visible):		

			if Input.is_action_just_pressed("menu_left"):
				MinusIndex()
				
			if Input.is_action_just_pressed("menu_right"):
				PlusIndex()

			if Input.is_action_just_pressed("menu_enter"):
				#print(selected_button.get_theme_color("font_color").to_html(false))
				if selected_button.get_theme_color("font_color").to_html(false) == color_active:
					if mm_buttons[selected_index]["id"] == "mm_new_game": # New Game
						await get_tree().create_timer(0.2).timeout
						#Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
						if GameManager.player.music.playing:
							GameManager.player.music.stop()
						GameManager.main_menu = false
						GameManager.Gui.loading_screen.show()
						GameManager.player.LoadPlayerProfile()
						
						await GameManager.player.player_loaded
						# SET GAME INIT
						#Gui.ShowMessage("Hello world!")
						GameManager.Gui.InventoryWindow._game_ready_inventory()
						GameManager.weapon_system._game_ready()
						GameManager.weapon_system.UpdateAmmo()
						self.hide()
						Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
						GameManager.LoadGameLevel(GameManager.player_json["start_level"])
				
					if mm_buttons[selected_index]["id"] == "mm_load": # Load
						await get_tree().create_timer(0.3).timeout
						Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
						if GameManager.player.music.playing:
							GameManager.player.music.stop()
						GameManager.main_menu = false
						GameManager.Gui.loading_screen.show()
						GameManager.LoadGame()
						return
						
					if mm_buttons[selected_index]["id"] == "mm_options": # Options
						if not options_menu.visible:
							options_menu.show()
							_update_options()
							
					if mm_buttons[selected_index]["id"] == "mm_help": # About
						if OS.has_feature("windows"):
							GameManager.Gui.ShowIntroMessageCustom("mm.help.text")
						if OS.has_feature("mobile"):
							GameManager.Gui.ShowIntroMessageCustom("mm.help.text.mobile")
						
					if mm_buttons[selected_index]["id"] == "mm_about": # Credits
						if not about_menu.visible:
							load_credits()
							about_menu.show()
							about_scroll.scroll_vertical = 0
							about_autoscroll = true
					if mm_buttons[selected_index]["id"] == "mm_exit": # Exit
						get_tree().quit()
			
		if Input.is_action_just_pressed("pause"):
			if about_menu.visible:
				about_autoscroll = false
				about_menu.hide()
				
			if options_menu.visible:
				options_menu.hide()
				
			if GameManager.Gui.IntroWindow.visible:
				GameManager.Gui.IntroWindow.get_node("ButtonIntroOk").pressed.emit()
				
		GameAPI.RunOutsideScript("p_mm")._menu_process(_delta)

func UpdateSelector():
	if FileAccess.file_exists(GameManager.app_dir+"progress.save"):
		var ids = []
		for btn in mm_buttons:
			ids.append(btn["id"])
				
		if not ids.has("mm_load"):
			mm_buttons.insert(1,load_btn)
	else:
		for btn in mm_buttons:
			if btn["id"] == "mm_load":
				mm_buttons.erase(btn)
				break
	#if selected_index == 1:
	#	if FileAccess.file_exists(GameManager.app_dir+"progress.save"):
	#		selected_button.add_theme_color_override("font_color",Color(color_active))
	#	else:
	#		selected_button.add_theme_color_override("font_color",Color(color_disabled))
	#else:
	#	selected_button.add_theme_color_override("font_color",Color(color_active))
	selected_button.text = Lang.translate(mm_buttons[selected_index]["text_id"])
	#if selected_index == 0:
		#left_button.text = Lang.translate(mm_buttons[len(mm_buttons)-1]["text_id"])
	#	selected_button.text = Lang.translate(mm_buttons[selected_index]["text_id"])
		#right_button.text = Lang.translate(mm_buttons[selected_index+1]["text_id"])
	#elif selected_index == len(mm_buttons)-1:
		#left_button.text = Lang.translate(mm_buttons[selected_index-1]["text_id"])
	#	selected_button.text = Lang.translate(mm_buttons[selected_index]["text_id"])
		#right_button.text = Lang.translate(mm_buttons[0]["text_id"])
	#else:
		#left_button.text = Lang.translate(mm_buttons[selected_index-1]["text_id"])
	#	selected_button.text = Lang.translate(mm_buttons[selected_index]["text_id"])
		#right_button.text = Lang.translate(mm_buttons[selected_index+1]["text_id"])
		
#endregion

func MinusIndex():
	var next_index = 0
	if selected_index > 0:
		selected_index -= 1
	else:
		selected_index = len(mm_buttons)-1
	UpdateSelector()
	
func PlusIndex():
	if selected_index != len(mm_buttons)-1:
		selected_index += 1
	else:
		selected_index = 0
	UpdateSelector()

func add_inputs_options(controls):
	var event
	#print(controls)
	for action in controls:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			
		for key in controls[action]:
			event = InputEventKey.new()
			#print(OS.find_keycode_from_string(key))
			event.keycode = OS.find_keycode_from_string(key)
			InputMap.action_add_event(action, event)

func load_credits():
	var credits_json = credits()
	var ref_main_title = $MenuAbout/ScrollContainer/VBoxContainer/CreditMainTitle
	var ref_main_subtitle = $MenuAbout/ScrollContainer/VBoxContainer/CrerditMainSubTitleText
	var credits_container = $MenuAbout/ScrollContainer/VBoxContainer
	var ref_copyright = $MenuAbout/ScrollContainer/VBoxContainer/Copyright
	
	if credits_strings.size() > 0:
		for credit in credits_strings:
			credit.queue_free()
	credits_strings.clear()
	
	if credits_json == null : return
	
	for credit in credits_json:
		var new_main_title = ref_main_title.duplicate()
		new_main_title.text_id = credit["title"]
		new_main_title.UpdateLanguage()
		credits_container.add_child(new_main_title)
		credits_strings.append(new_main_title)
		new_main_title.show()
		for author in credit["authors"]:
			var new_main_subtitle = ref_main_subtitle.duplicate()
			# RegEx for searching patterns in string, for now it's [lang][/lang] bbcode
			var new_regex = RegEx.new()
			var edited_text = new_regex.compile("\\[lang\\](.*?)\\[/lang\\]")
			# after compiling expression in search we'll get two strings:
			# original [lang]test.text[/lang] and only inside text in brackets test.text
			for reg_result in new_regex.search_all(author):
				author = author.replace(reg_result.strings[0],Lang.translate(reg_result.strings[1]))
			# after replacement we can apply our text to object
			new_main_subtitle.text = author
			credits_container.add_child(new_main_subtitle)
			credits_strings.append(new_main_subtitle)
			new_main_subtitle.show()
		
		
	credits_container.move_child(ref_copyright,credits_container.get_child_count()-1)
	
#region Options buttons logic

func _on_non_clickable_right_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			PlusIndex()


func _on_non_clickable_left_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			MinusIndex()


func _on_clickable_title_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("clicked")
			Input.action_press("menu_enter")
			Input.action_release("menu_enter")


func _on_opt_lang_pressed():
	var opt_edited = opt().duplicate()
	var result = ""
	for l in opt_edited["languages"].keys():
		if current_lang < opt_edited["languages"].keys().size()-1:
			current_lang += 1
			break
		else:
			current_lang = 0
			break
			
	opt_edited["current_language"] = languages[current_lang]

	result = Utility.beautify_json(str(opt_edited))
	#print(current_lang)
	#print(result)
	Lang.current_lang = opt_edited["current_language"]
	Lang._change_lang(Lang.current_lang)
	
	if first_launch_menu.visible:
		$FirstLaunchWindow/ScrollContainer/VBoxContainer/Warning.UpdateLanguage()
	
	# Saving in options file
	save_to_options(result)
	
	#await get_tree().process_frame
	GameManager.Gui.UpdateTexts()
	await get_tree().process_frame
	UpdateSelector()
	_update_options()

# Store data to options!
func save_to_options(data : String):
	if data == null or data.is_empty(): return
	if FileAccess.file_exists(GameManager.app_dir+"assets/options.json"):
		var f = FileAccess.open(GameManager.app_dir+"assets/options.json",FileAccess.WRITE)
		f.store_string(data)
		f.close()
	print("Saved to options.json")

func _on_opt_snd_pressed():
	var master_sound = AudioServer.get_bus_index("Master")
	
	match sound_enabled:
		true:
			AudioServer.set_bus_mute(master_sound,true)
		false:
			AudioServer.set_bus_mute(master_sound,false)
	
	sound_enabled = !sound_enabled
	
	save_to_options(Utility.json_edit(opt().duplicate(),"music_and_sound",sound_enabled))
	
	_update_options()


func _on_back_pressed():
	var _opt = opt()
	save_to_options(Utility.json_edit(_opt,"volume_master",snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")),2)))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"volume_ambient",snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("AMBIENT")),2)))
	await get_tree().process_frame	
	save_to_options(Utility.json_edit(_opt,"volume_ambient_sfx",snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("AMBIENT_SFX")),2)))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"volume_music",snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("MUSIC")),2)))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"volume_fx",snappedf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("FX1")),2)))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"mouse_sensitivity",GameManager.player.SENSITIVITY))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"mouse_smooth",GameManager.player.SMOOTHNESS))
	await get_tree().process_frame
	save_to_options(Utility.json_edit(_opt,"scale_3d_render",get_tree().root.scaling_3d_scale))
	
	if last_opt_chnanged.has("opt_max_fps"):
		GameManager.Gui.ShowTradingMessage(Lang.translate("mm.opt.restart.msg"))
		last_opt_chnanged.erase("opt_max_fps")
	
	_opt = null
	if options_menu.visible:
		options_menu.hide()


func _on_opt_aim_pressed():
	GameManager.aim_assist = !GameManager.aim_assist
	save_to_options(Utility.json_edit(opt().duplicate(),"aim_assist",GameManager.aim_assist))
	_update_options()


func _on_opt_autoreload_pressed():
	GameManager.weapon_system.autoreloading = !GameManager.weapon_system.autoreloading
	save_to_options(Utility.json_edit(opt().duplicate(),"autoreload",GameManager.weapon_system.autoreloading))
	_update_options()


func _on_opt_fps_pressed():
	GameManager.show_fps = !GameManager.show_fps
	save_to_options(Utility.json_edit(opt().duplicate(),"show_fps",GameManager.show_fps))	
	_update_options()


func on_volume_add_slider_clicked(btn_id):
	match btn_id:
		opt_slider_main.name:
			change_volume_bus("Master","+")
			opt_slider_main.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("Master")))))+"%"
		opt_slider_amb.name:
			change_volume_bus("AMBIENT","+")
			opt_slider_amb.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("AMBIENT")))))+"%"
			
		opt_slider_sfx.name:
			change_volume_bus("AMBIENT_SFX","+")
			opt_slider_sfx.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("AMBIENT_SFX")))))+"%"
			
		opt_slider_music.name:
			change_volume_bus("MUSIC","+")
			opt_slider_music.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("MUSIC")))))+"%"
			
		opt_slider_fx.name:
			change_volume_bus("FX1","+")
			change_volume_bus("FX2","+")
			opt_slider_fx.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("FX1")))))+"%"
		opt_slider_mouse_sens.name:
			if GameManager.player.SENSITIVITY < 0.99:
				GameManager.player.SENSITIVITY += 0.01
				print("Sensitivity: %.2f" % GameManager.player.SENSITIVITY)
				opt_slider_mouse_sens.get_node("number").text = str(snappedf(GameManager.player.SENSITIVITY*100,0))
		opt_slider_mouse_smooth.name:
			if GameManager.player.SMOOTHNESS < 100:
				GameManager.player.SMOOTHNESS += 1
				opt_slider_mouse_smooth.get_node("number").text = str(GameManager.player.SMOOTHNESS)
		opt_slider_3d_scale.name:
			if get_tree().root.scaling_3d_scale < 1.0:
				get_tree().root.scaling_3d_scale += 0.1
				print("3D Scale: %.2f" % get_tree().root.scaling_3d_scale)
				opt_slider_3d_scale.get_node("number").text = str(round(get_tree().root.scaling_3d_scale*100))+"%"
	
func on_volume_low_slider_clicked(btn_id):
	match btn_id:
		opt_slider_main.name:
			change_volume_bus("Master","-")
			opt_slider_main.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("Master")))))+"%"
		opt_slider_amb.name:
			change_volume_bus("AMBIENT","-")
			opt_slider_amb.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("AMBIENT")))))+"%"
		opt_slider_sfx.name:
			change_volume_bus("AMBIENT_SFX","-")
			opt_slider_sfx.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("AMBIENT_SFX")))))+"%"
		opt_slider_music.name:
			change_volume_bus("MUSIC","-")
			opt_slider_music.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("MUSIC")))))+"%"
		opt_slider_fx.name:
			change_volume_bus("FX1","-")
			change_volume_bus("FX2","-")
			opt_slider_fx.get_node("number").text = str(get_percent(AudioServer.get_bus_volume_db((AudioServer.get_bus_index("FX1")))))+"%"
		opt_slider_mouse_sens.name:
			if GameManager.player.SENSITIVITY > 0.01:
				GameManager.player.SENSITIVITY -= 0.01
				opt_slider_mouse_sens.get_node("number").text = str(snappedf(GameManager.player.SENSITIVITY*100,0))
		opt_slider_mouse_smooth.name:
			if GameManager.player.SMOOTHNESS > 1:
				GameManager.player.SMOOTHNESS -= 1
				opt_slider_mouse_smooth.get_node("number").text = str(GameManager.player.SMOOTHNESS)
		opt_slider_3d_scale.name:
			if get_tree().root.scaling_3d_scale > 0.1:
				get_tree().root.scaling_3d_scale -= 0.1
				opt_slider_3d_scale.get_node("number").text = str(round(get_tree().root.scaling_3d_scale*100.0))+"%"

func on_game_ready():
	var _opt_ready = opt()
	var player : Player = GameManager.player as Player
	# options load music/sound bus state
	
	if "music_and_sound" in _opt_ready and _opt_ready["music_and_sound"] != null:
		var master_sound = AudioServer.get_bus_index("Master")
	
		if _opt_ready["music_and_sound"]: AudioServer.set_bus_mute(master_sound,false)
		else: AudioServer.set_bus_mute(master_sound,true)
		
		sound_enabled = _opt_ready["music_and_sound"]
		
	# options load aim assist
	if "aim_assist" in _opt_ready and _opt_ready["aim_assist"] != null:
		GameManager.aim_assist = _opt_ready["aim_assist"]
	
	# options load autoreload
	if "autoreload" in _opt_ready and _opt_ready["autoreload"] != null:
		GameManager.weapon_system.autoreloading = _opt_ready["autoreload"]
	
	# options load fps
	if "show_fps" in _opt_ready and _opt_ready["show_fps"] != null:
		GameManager.show_fps = _opt_ready["show_fps"]
		
	if _opt_ready["first_launch"] and self.visible:
		first_launch_menu.show()
		_update_options()
	
	if _opt_ready["mouse_sensitivity"] != 0:
		player.SENSITIVITY = _opt_ready["mouse_sensitivity"]
	else:
		player.SENSITIVITY = 0.19
	
	if _opt_ready["mouse_smooth"] != 0:
		player.SMOOTHNESS = _opt_ready["mouse_smooth"]
	else:
		player.SMOOTHNESS = 12
	
	if _opt_ready["vsync"]:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	if _opt_ready["camera_sway"]:
		player.camera_sway_option = true
	else:
		player.camera_sway_option = false
		
	#if _opt_ready["lock_60_fps"]:
	#	Engine.max_fps = 60
	#else:
	#	Engine.max_fps = 0
	
	if _opt_ready["volumetric_fog"]:
		GameManager.volumetric_fog = _opt_ready["volumetric_fog"]
	
	if _opt_ready["corpses"]:
		GameManager.corpse_cleaner = _opt_ready["corpses"]
	
	if _opt_ready["casual_gameplay"]:
		GameManager.casual_gameplay = true
		GameManager.Gui.SetCausalIcon(true)
	else:
		GameManager.Gui.SetCausalIcon(false)
		GameManager.casual_gameplay = false
	
	if _opt_ready["scale_3d_render"] <= 1.0 and _opt_ready["scale_3d_render"] != 0.25:
		GameManager.Gui.sv_effects_subviewport.get_node("EffectDither").scaling_3d_scale = _opt_ready["scale_3d_render"]
		
	if _opt_ready["scale_3d_render"] == 0:
		GameManager.Gui.sv_effects_subviewport.get_node("EffectDither").scaling_3d_scale = 1.0
		
	player.PlayerCamera.environment.ssao_enabled = _opt_ready["ssao"]
	player.PlayerCamera.environment.glow_enabled = _opt_ready["glow"]
	GameManager.moving_sky_shader = _opt_ready["sky_shader"]
	GameManager.Gui.set_dithering(_opt_ready["dithering"])
	
	if _opt_ready["pixelation"]:
		GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("resolution_scale",3)
		GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("color_depth",5)
		
	else:
		GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("resolution_scale",1)
		GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("color_depth",8)
		
	
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),_opt_ready["volume_master"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("FX1"),_opt_ready["volume_fx"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("FX2"),_opt_ready["volume_fx"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("MUSIC"),_opt_ready["volume_music"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("AMBIENT"),_opt_ready["volume_ambient"])
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("AMBIENT_SFX"),_opt_ready["volume_ambient_sfx"])
	
	_opt_ready = null

func _on_ok_first_launch_pressed():
	if first_launch_menu.visible:
		save_to_options(Utility.json_edit(opt().duplicate(),"first_launch",false))
		first_launch_menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func on_opt_any_btn_click(btn_name):
	print("%s was clicked" % btn_name)
	match btn_name:
		"opt_vsync":
			var vsync_status = opt()["vsync"]
			save_to_options(Utility.json_edit(opt().duplicate(),"vsync",!vsync_status))
			if vsync_status:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"opt_max_fps":
			var lock_status = opt()["lock_60_fps"]
			save_to_options(Utility.json_edit(opt().duplicate(),"lock_60_fps",!lock_status))
			if lock_status:
				Engine.max_fps = 60
			else:
				Engine.max_fps = 0
			last_opt_chnanged.append("opt_max_fps")
		"opt_difficulty":
			var casual = GameManager.casual_gameplay
			save_to_options(Utility.json_edit(opt().duplicate(),"casual_gameplay",!casual))
			GameManager.Gui.SetCausalIcon(!GameManager.casual_gameplay)
			GameManager.casual_gameplay = !GameManager.casual_gameplay
		"opt_ssao":
			var ssao = GameManager.player.PlayerCamera.environment.ssao_enabled
			save_to_options(Utility.json_edit(opt().duplicate(),"ssao",!ssao))
			GameManager.player.PlayerCamera.environment.ssao_enabled = !ssao
		"opt_volumetric_fog": 
			var vfog = GameManager.volumetric_fog
			save_to_options(Utility.json_edit(opt().duplicate(),"volumetric_fog",!vfog))
			GameManager.volumetric_fog = !vfog
		"opt_glow":
			var glow = GameManager.player.PlayerCamera.environment.glow_enabled
			save_to_options(Utility.json_edit(opt().duplicate(),"glow",!glow))
			GameManager.player.PlayerCamera.environment.glow_enabled = !glow
		"opt_dithering":
			var dithering = GameManager.Gui.sv_effects_subviewport.material.get_shader_parameter("dithering")
			save_to_options(Utility.json_edit(opt().duplicate(),"dithering",!dithering))
			GameManager.Gui.set_dithering(!dithering)
		"opt_moving_sky":
			var moving_sky = GameManager.moving_sky_shader
			save_to_options(Utility.json_edit(opt().duplicate(),"sky_shader",!moving_sky))
			GameManager.moving_sky_shader = !moving_sky
		"opt_cam_sway":
			var cam_sway = GameManager.player.camera_sway_option
			save_to_options(Utility.json_edit(opt().duplicate(),"camera_sway",!cam_sway))
			GameManager.player.camera_sway_option = !cam_sway
		"opt_corpses":
			var corpses = GameManager.corpse_cleaner
			save_to_options(Utility.json_edit(opt().duplicate(),"corpses",!corpses))
			GameManager.corpse_cleaner = !corpses
			
		"opt_pixelation":
			var pixelation = GameManager.Gui.sv_effects_subviewport.material.get_shader_parameter("resolution_scale")
			
			if pixelation >= 3:
				GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("resolution_scale",1)
				GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("color_depth",8)
				save_to_options(Utility.json_edit(opt().duplicate(),"pixelation",false))
			else:
				GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("resolution_scale",3)
				GameManager.Gui.sv_effects_subviewport.material.set_shader_parameter("color_depth",5)
				save_to_options(Utility.json_edit(opt().duplicate(),"pixelation",true))
	_update_options()

#endregion

func _on_non_clickable_right_mouse_entered():
	right_button.add_theme_color_override("font_color",Color("ee9d31"))


func _on_non_clickable_left_mouse_entered():
	left_button.add_theme_color_override("font_color",Color("ee9d31"))


func _on_non_clickable_left_mouse_exited():
	left_button.add_theme_color_override("font_color",Color("66625f"))


func _on_non_clickable_right_mouse_exited():
	right_button.add_theme_color_override("font_color",Color("66625f"))


func _on_opt_difficulty_fl_pressed():
	var casual = GameManager.casual_gameplay
	save_to_options(Utility.json_edit(opt().duplicate(),"casual_gameplay",!casual))
	GameManager.Gui.SetCausalIcon(!GameManager.casual_gameplay)
	GameManager.casual_gameplay = !GameManager.casual_gameplay
	_update_options()


func _on_visibility_changed():
	pass
