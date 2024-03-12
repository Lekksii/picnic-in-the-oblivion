extends Control
class_name GUI
@onready var sv_effects_subviewport : SubViewportContainer = $"../../sv"
@onready var subviewport : SubViewport = $"../../sv/EffectDither"
@onready var frame : Control = $GAME/frame
@onready var hint: Label = $GAME/frame/screen_hint
@onready var ammo_clip : Label = $GAME/frame/ammo_frame/ammo_clip
@onready var ammo_all : Label = $GAME/frame/ammo_frame/ammo_all
@onready var belt_0_icon : TextureRect = $GAME/frame/ammo_frame/belt_0
@onready var belt_1_icon : TextureRect = $GAME/frame/ammo_frame/belt_1
@onready var belt_2_icon : TextureRect = $GAME/frame/ammo_frame/belt_2
@onready var belt_3_icon : TextureRect = $GAME/frame/ammo_frame/belt_3
@onready var weapon_icon : TextureRect = $GAME/frame/ammo_frame/weapon_icon
@onready var health_bar : TextureProgressBar = $GAME/frame/hp_bar
@onready var rad_bar : TextureProgressBar = $GAME/frame/rad_bar_frame/rad_bar
@onready var health_bar_inv : TextureProgressBar = $GAME/Inventory/hp_bar_inv
@onready var crosshair : TextureRect = $GAME/frame/cross
@onready var fps : Label = $GAME/frame/fps
@onready var pos : Label = $GAME/frame/pos
@onready var rot : Label = $GAME/frame/rot
@onready var camera_rotations : Label = $GAME/frame/rot2
@onready var pda_icon : TextureRect = $GAME/frame/pda_icon
@onready var rad_icon : TextureRect = $GAME/frame/radiation_icon
@onready var save_icon : TextureRect = $GAME/frame/save_icon
@onready var timers_text : Label = $GAME/frame/timers
@onready var message : Label = $GAME/frame/message
@export var loading_screen : Control
@onready var scope : TextureRect = $GAME/frame/lr_scope
@onready var main_menu : MainMenu = $GAME/MainMenu
@onready var damage_l : TextureRect = $GAME/frame/DamageLeft
@onready var damage_r : TextureRect = $GAME/frame/DamageRight
@onready var medkit_count : Label = $GAME/frame/medkit_icon/medkit_count
@onready var medkit_army_count : Label = $GAME/frame/medkit2_icon/medkit2_count
@onready var antirad_count : Label = $GAME/frame/antirad_icon/antirad_count
@onready var medkit_icon : TextureRect = $GAME/frame/medkit_icon
@onready var medkit_army_icon : TextureRect = $GAME/frame/medkit2_icon
@onready var antirad_icon : TextureRect = $GAME/frame/antirad_icon
@onready var weapon_hud : Sprite3D = $"../../sv/EffectDither/World/Player/Head/PlayerCamera/HUD"
@onready var casual_icon = $GAME/frame/casual_icon
@onready var press_f_text : Label = $GAME/frame/press_f
@onready var death_screen = $DeathScreen
@onready var final_image = $GAME/FinalImage

@onready var game_gui_root : Control = $GAME
@onready var vignette : TextureRect = $GAME/Vignette

@onready var InventoryWindow : Inventory = $GAME/Inventory as Inventory
@onready var InventoryMoney : Label = $GAME/Inventory/money
@onready var JournalWindow : Journal = $GAME/Journal as Journal
@onready var PauseWindow : PauseMenu = $GAME/Pause as PauseMenu
@onready var DialogueWindow : DialogueSystem = $GAME/Dialogue as DialogueSystem
@onready var TradingWindow : TradingSystem = $GAME/Trading as TradingSystem
@onready var MapWindow : Map = $GAME/Map as Map
@onready var ConsoleWindow : Console = $GAME/Console as Console
@onready var TipWindow : Control = $GAME/HelpMessage
@onready var SkillWindow : SkillSystem = $GAME/Statistic as SkillSystem
@onready var IntroWindow : Control = $GAME/IntroMessage
@onready var MainMenuWindow : MainMenu = $GAME/MainMenu as MainMenu
@onready var SpawnMenuWindow = $GAME/SpawnMenu

@onready var GUI_ROOT : Control = $"."
@onready var GUI_GAME : Control = $GAME

@export var translation_labels : Array[Label] = []
@export var translation_buttons : Array[Button] = []
@export var textures_loader_elements = []

@onready var Loot : LootWindow = $GAME/Loot
@onready var TradingMessage = $GAME/TradingMessage

var is_tutorial_tip = false
var belt_ui : Array

# timer for message show
var message_showtime = 1.5
@onready var message_timer = Timer.new()
var intro_scroll_timer = 1.0
var messages_queue = []

var splash_timer = 3.0
var fade_time = 1.0

var viewport_init_size = Vector2()

var last_scale = 0
# templates of crosshair textures for quick changing
var crosshair_gun_texture
var crosshair_use_texture
var crosshair_lock_texture
var crosshair_hit_texture
var crosshair_headshot_texture

signal on_gui_init_finished

# Called when the node enters the scene tree for the first time.
func _ready():
	var dynamic_font_regular = FontFile.new()
	var dynamic_font_bold = FontFile.new()
	
	var regular_font : Theme = load("res://themes/regular_font.tres") as Theme
	var bold_font : Theme = load("res://themes/bold_font.tres") as Theme
	
	dynamic_font_regular.load_dynamic_font(GameManager.app_dir+"assets/fonts/SM3DRegular.ttf")
	dynamic_font_bold.load_dynamic_font(GameManager.app_dir+"assets/fonts/SM3DBold.ttf")
	
	dynamic_font_regular.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	dynamic_font_bold.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	
	dynamic_font_regular.oversampling = false
	dynamic_font_bold.oversampling = false
	
	regular_font.set_font("font","Label",dynamic_font_regular)
	regular_font.set_font("font","Button",dynamic_font_regular)
	regular_font.set_font("font","LineEdit",dynamic_font_regular)
	
	bold_font.set_font("font","Label",dynamic_font_bold)
	bold_font.set_font("font","Button",dynamic_font_bold)
	bold_font.set_font("font","LineEdit",dynamic_font_bold)
	bold_font.set_font("bold_font","RichTextLabel",dynamic_font_bold)
	bold_font.set_font("normal_font","RichTextLabel",dynamic_font_regular)
	#get_tree().root.content_scale_factor = 1.5
	message_timer.wait_time = message_showtime
	message_timer.name = "message_queue_timer"
	message_timer.timeout.connect(on_message_timer_timeout)
	add_child(message_timer)
	resize_cursor()
	get_tree().root.size_changed.connect(resize_cursor)
	await get_tree().create_timer(0.1).timeout
	belt_ui = [belt_0_icon, belt_1_icon, belt_2_icon, belt_3_icon]
	crosshair_gun_texture = Utility.load_external_texture("assets/ui/crosshair_weapon.png")
	crosshair_use_texture = Utility.load_external_texture("assets/ui/crosshair.png")
	crosshair_lock_texture = Utility.load_external_texture("assets/ui/lock.png")
	crosshair_hit_texture = Utility.load_external_texture("assets/ui/crosshair_weapon_hit.png")
	crosshair_headshot_texture = Utility.load_external_texture("assets/ui/crosshair_weapon_hit_headshot.png")
	rot.text = ""
	pos.text = ""
	
	search_ui_text_nodes(self)
	
	await get_tree().process_frame
	
	search_buttons_text_nodes(self)
	
	await get_tree().process_frame
	
	search_image_nodes(self)
	#print(textures_loader_elements.size())
	# textures reloading
	for texture in textures_loader_elements:
		if texture.texture != null and texture.texture.resource_path.contains("ui/"):
			var old_tex_name = texture.texture.resource_path.split('ui/',false)[1]
			#print("Reloaded texture for: %s" % old_tex_name)
			texture.texture = Utility.load_external_texture("assets/ui/"+old_tex_name)
	#self.reparent(get_node("root/Game/ViewPorts/MainGame/World/CanvasLayer"),true)
	
	if OS.has_feature("mobile"):
		medkit_icon.show()
		medkit_army_icon.show()
		antirad_icon.show()
		
	if OS.has_feature("windows"):
		medkit_icon.hide()
		medkit_army_icon.hide()
		antirad_icon.hide()

func on_message_timer_timeout():
	if messages_queue.size() > 0:
		var stringToPrint = messages_queue.pop_front() # Dequeue a string
		message.text = stringToPrint
		if message_timer.is_stopped():
			message_timer.start()
	else:
		print("String queue is empty.")
		message.text = ""
		# Stop the timer when the queue is empty
		message_timer.stop()
	
func resize_cursor():
	var cursor_compressed_image : Texture2D = Utility.load_external_texture("assets/ui/cursor.png")
	var original_cursor = cursor_compressed_image.get_image()
	var original_cursor_size = cursor_compressed_image.get_size()
	var original_width = ProjectSettings.get_setting("display/window/size/viewport_width") as int
	var screen_scale = int(float(DisplayServer.window_get_size().x)/float(original_width))
	var new_size = Vector2i(screen_scale*original_cursor_size)
	
	if last_scale != screen_scale:
		last_scale = screen_scale
		var cursor = Image.new()
		cursor.copy_from(original_cursor)
		#print(new_size)
		cursor.resize(new_size.x,new_size.y,Image.INTERPOLATE_NEAREST)
		Input.set_custom_mouse_cursor(ImageTexture.create_from_image(cursor))
	
func search_image_nodes(obj):
	var arr = []
	for texture_rect in obj.get_children():
		#print(texture_rect.name)
		if texture_rect is TextureRect and not arr.has(texture_rect):
			#xprint(texture_rect.name)
			arr.append(texture_rect)
		if texture_rect.get_child_count() > 0:
			search_image_nodes(texture_rect)
	for t in arr:
		textures_loader_elements.append(t)

func search_ui_text_nodes(obj):
	var arr = []
	for translation_label in obj.get_children():
		#print(texture_rect.name)
		if translation_label is UI_TEXT and translation_label is Label and not arr.has(translation_label):
			#print(translation_label.name)
			arr.append(translation_label)
		if translation_label.get_child_count() > 0:
			search_ui_text_nodes(translation_label)
	for t in arr:
		#print(t.name + " " + str(t.has_theme_font_override("font")))
		if not translation_labels.has(t):
			translation_labels.append(t)
			
func search_buttons_text_nodes(obj):
	var arr = []
	for translation_button in obj.get_children():
		if translation_button is UI_TEXT and translation_button is Button and not arr.has(translation_button):
			#print(translation_button.name)
			arr.append(translation_button)
		if translation_button.get_child_count() > 0:
			search_buttons_text_nodes(translation_button)
	for t in arr:
		if not translation_buttons.has(t):
			translation_buttons.append(t)

func SetWeaponHUD(state : bool):
	if state:
		weapon_hud.show()
	else:
		weapon_hud.hide()

func SetHUD(state : bool):
	if state:
		frame.show()
	else:
		frame.hide()

func SetCausalIcon(state : bool):
	casual_icon.visible = state

func UpdateHUDAmounts():
	medkit_count.text = str(InventoryWindow.GetItemsTypeAmount("medkit"))
	medkit_army_count.text = str(InventoryWindow.GetItemsTypeAmount("medkit_army"))
	antirad_count.text = str(InventoryWindow.GetItemsTypeAmount("antirad"))
	
func _process(_delta):
	
	if vignette.material.get_shader_parameter("vignette_opacity") > 0.15:
		var opacity = vignette.material.get_shader_parameter("vignette_opacity")
		vignette.material.set_shader_parameter("vignette_opacity",opacity - _delta * 3)
	
	UpdateHUDAmounts()
			
	if IntroWindow.visible:
		intro_scroll_timer -= _delta * 1
		if intro_scroll_timer <= 0:
			intro_scroll_timer = 0
			$GAME/IntroMessage/ScrollContainer.scroll_vertical += 8
			intro_scroll_timer = 1.0
	
	if GameManager.player and GameManager.player.debug_info:
		$GAME/frame/debug_panel.visible = true
		var pos_x = "%.2f" % GameManager.player.position.x
		var pos_y = "%.2f" % GameManager.player.position.y
		var pos_z = "%.2f" % GameManager.player.position.z
		var rot_x = "%.2f" % GameManager.player.rotation_degrees.x
		var rot_y = "%.2f" % GameManager.player.rotation_degrees.y
		var rot_z = "%.2f" % GameManager.player.rotation_degrees.z
		pos.text = "X: %s\nY: %s\nZ: %s" % [pos_x,pos_y,pos_z]
		rot.text = "(%s, %s, %s)" % [rot_x, rot_y, rot_z]
		$GAME/editor_mode/camera_pos.text = "(%s, %s, %s)" % [pos_x,pos_y,pos_z]
		
		camera_rotations.text = "PlayerCamera: %s\nPlayerHead: %s\nFakeHead: %s" % [str(GameManager.player.PlayerCamera.rotation_degrees),str(GameManager.player.PlayerHead.rotation_degrees),str(GameManager.player.FakeHead.rotation_degrees)]

func PressF(state : bool):
	if state:
		if OS.has_feature("windows"):
			press_f_text.text = "%s (%s)" % [Lang.translate("press"), Lang.translate_string("[key_action]use[/key_action]")]
		if OS.has_feature("mobile"):
			press_f_text.text = "%s" % Lang.translate("press.mobile")
	else:
		press_f_text.text = ""
func ShowMessage(text):
	messages_queue.push_back(text)
	if messages_queue.size() == 1:
		message.text = text
		if message_timer.is_stopped():
			message_timer.start()

func ShowTradingMessage(text,type = "classic"):
	match type:
		"classic":
			$GAME/TradingMessage/BG2.show()
			$GAME/TradingMessage/BGBlack.show()
			TradingMessage.show()
			
			if TradingWindow.visible:
				TradingWindow._update_bags()
		"hint":
			$GAME/TradingMessage/BG2.hide()
			$GAME/TradingMessage/BGBlack.hide()
			$GAME/TradingMessage/BG3.show()
			TradingMessage.show()
	$GAME/TradingMessage/infoText.text = text

# Find UI element in GUI/GAME node
func GetUIElement(node):
	return get_node("GAME/"+node)

# Find UI element in editor node
func GetEditorElement(node):
	return get_node("GAME/editor_mode/"+node)

func _on_bug_button_ok_pressed():
	get_tree().quit()

# show crosshair hint
func show_hint(text):
	hint.text = text
# clear crosshair hint
func clear_hint():
	hint.text = ""

func UpdateTexts():
	for lang_label in translation_labels:
		if lang_label != null and lang_label.text != "":
			if lang_label.get("text_id"):
				lang_label.UpdateLanguage()
	# translation for buttons
	for lang_button in translation_buttons:
		if lang_button != null and lang_button.text != "":
			if lang_button.get("text_id"):
				lang_button.text = Lang.translate(lang_button.text_id)
			
func ShowIntroMessage():
	IntroWindow.show()
	GameManager.pause = true
	if GameManager.main_menu == false:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
func HideIntroMessage():
	if GameManager.current_level != null:
		if not death_screen.visible and not MainMenuWindow.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.pause = false
	IntroWindow.hide()
	
func ShowIntroMessageCustom(text : String):
	IntroWindow.get_node("ScrollContainer/title").text = Lang.translate(text)
	ShowIntroMessage()

func LoadHelpTipJson(id : String):
	var tips = Utility.read_json("assets/gameplay/help_tips.json")
	for tip in tips:
		if tip["id"] == id:
			_ShowHelpTipMessage(tip["topic_img"],tip["text"],tip["topic_img_size"] if "topic_img_size" in tip else 256)
			break
	
func _ShowHelpTipMessage(topic_img_path : String, text : String,img_size=256):
	if not GameManager.pause:
		GameManager.pause = true
		is_tutorial_tip = true
		ShowTradingMessage("[center][img=%d]assets/ui/%s[/img][/center]\n \n \n%s" % [img_size,topic_img_path, Lang.translate(text)],"hint")
		#$GAME/HelpMessage/infoText.text = "[center][img=%d]assets/ui/%s[/img][/center]\n \n \n%s" % [img_size,topic_img_path, Lang.translate(text)]
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		#$GAME/HelpMessage.show()
	
func ShowRad():
	$GAME/frame/rad_bar_frame.show()
	
func HideRad():
	$GAME/frame/rad_bar_frame.hide()

# Show object list on level (for editor mode)
func show_editor_object_list(list):
	var obj_list = $GAME/editor_mode/lvl_objects_selector/ScrollContainer/ObjectList
	var obj = preload("res://engine_objects/editor_list_object.tscn")
	obj_list.get_children().clear()
	
	for ed_obj in list:
		var new_obj = obj.instantiate()
		new_obj.text = str(ed_obj.name)
		obj_list.add_child(new_obj)
	$GAME/editor_mode/lvl_objects_selector.show()

func _on_close_selector_pressed():
	$GAME/editor_mode/lvl_objects_selector.hide()

func _on_light_mode_pressed():
	GameManager.World.get_node("SceneLight").visible = !GameManager.World.get_node("SceneLight").visible

func _on_button_ok_pressed():
	$GAME/HelpMessage/infoText.text = ""
	$GAME/HelpMessage.hide()
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_msg_btn_click"])
	if not death_screen.visible and not MainMenuWindow.visible:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.pause = false
	await get_tree().create_timer(0.1).timeout
	# randomly pick enemy and allow him permission to attack player
	if GameManager.player.current_eyezone != null and GameManager.player.current_eyezone.enemies.size() > 0:
		for hostile in GameManager.player.current_eyezone.enemies:
			if hostile.can_attack:
				return
		
		var ai = GameManager.player.current_eyezone.enemies.pick_random()
		ai.delay_timer = 0.5
		ai.can_attack = true

func set_dithering(state:bool = true):
	sv_effects_subviewport.material.set_shader_parameter("dithering", state)

func _on_ready():
	# translation for labels
	for lang_label in translation_labels:
		if lang_label != null and lang_label.text != "":
			if lang_label.get("text_id"):
				lang_label.text = Lang.translate(lang_label.text_id)
				lang_label.uppercase = true
	# translation for buttons
	for lang_button in translation_buttons:
		if lang_button != null and lang_button.text != "":
			if lang_button.get("text_id"):
				lang_button.text = Lang.translate(lang_button.text_id)
				lang_button.text = lang_button.text.to_upper()
	await get_tree().process_frame
	on_gui_init_finished.emit()

func _on_button_intro_ok_pressed():
	HideIntroMessage()
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_msg_btn_click"])


func _on_button_trading_msg_ok_pressed():
	TradingMessage.hide()
	GameManager.on_trading_message_ok.emit()
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_msg_btn_click"])
	if is_tutorial_tip:
		GameManager.pause = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		is_tutorial_tip = false


func _on_help_message_visibility_changed():
	if MainMenuWindow.visible:
		if $GAME/HelpMessage.visible:
			$GAME/HelpMessage/infoText.text = ""
			$GAME/HelpMessage.hide()
			GameManager.pause = false



func _on_pda_icon_gui_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed() and GameManager.pda_enabled:
			GameManager.pause = true
			MapWindow.Open()
			MapWindow.is_open_from_pause = false
			return


func _on_radiation_icon_gui_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			#print("rad tapped")
			var rad = InventoryWindow.Find("antirad") as item
			if rad:
				rad.UseItem()
				return


func _on_medkit_icon_gui_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			#print("rad tapped")
			var med = InventoryWindow.Find("medkit") as item
			if med:
				med.UseItem()
				return


func _on_medkit_2_icon_gui_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			#print("rad tapped")
			var med = InventoryWindow.Find("medkit_army") as item
			if med:
				med.UseItem()
				return


func _on_antirad_icon_gui_input(event):
	if event is InputEventScreenTouch:
		if event.is_pressed():
			#print("rad tapped")
			var rad = InventoryWindow.Find("antirad") as item
			if rad:
				rad.UseItem()
				return
