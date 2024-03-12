# ALWAYS extend script from Node, else game will crash, cause script handler error.
extends Node

var mainmenu : MainMenu = null

# Calls ONLY when main menu loaded.
func _menu_init(mm):
	# set reference of MainMenu script to our variable
	mainmenu = mm as MainMenu
	
	# Register all our new scripts here, before gameplay actually starts.
	# GameAPI.RunOutsideScript("script_name1")
	# GameAPI.RunOutsideScript("script_name2")
	# # # # # # # # # # # # # # # # #
	
	# now we can do other things...
	#mainmenu.version_title.text += " (Mod by ... ver. 0.1)"
	#mainmenu.selected_button.position.y -= 64
	
	# also we can separate different code for different game builds, like 
	# for Windows and Android. You can do it very easy!
	# just use if statement with OS.has_feature("windows") or OS.has_feature("mobile")
	
	if OS.has_feature("mobile"):
		mainmenu.logo.scale = mainmenu.logo.scale * 1.5  # make mainmenu logo bigger for mobile
		mainmenu.version_title.add_theme_font_size_override("normal_font_size",32) # make version text bigger
# Called every frame in main menu
func _menu_process(delta):
	pass
