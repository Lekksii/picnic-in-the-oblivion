extends ColorRect
class_name SkillSystem

@export var ui_exp_bar : TextureProgressBar
@export var ui_skillpoints : Label
@export var ui_level : Label
@export var ui_weight : Label

@export var ui_health_data : Label
@export var ui_accuracy_data : Label
@export var ui_armor_data : Label
@export var ui_rad_data : Label
@export var ui_anomaly_data : Label
@export var ui_str_data : Label
var is_open_from_pause = false

var level: int = 1
var level_max : int = 10
var current_exp: int = 0
var next_level_exp: int = 15
var skill_point: int = 1

var accuracy: float = 0.35
var health_max: float = 50.0
var strenght: float = 0.0
var armor: float = 0.0
var radiation_resistance: float = 0.0
var anomaly_resistance: float = 0.0

var color_red = "e80000"
var color_green = "28be38"
var is_handling_input : bool = false

func _set_color_if(ui_obj,if_skill):
	if if_skill <= 0:
		ui_obj.add_theme_color_override("font_color",Color(color_red))
	else:
		ui_obj.add_theme_color_override("font_color",Color(color_green))
# Called when the node enters the scene tree for the first time.
func _ready():
	_ResetSkills()
	#await GameManager.on_game_ready
	#FixLostArtifactEffects("af_battery")

func UpgradeSkill(skill:String):
	GameManager.PlaySFXLoaded(GameManager.sfx_manager_json["on_skill_click"])
	if skill_point > 0:
		match skill:
			"armor": armor += 5
			"accuracy": accuracy += 0.05
			"resistance": 
				radiation_resistance += 5
				anomaly_resistance += 5
			"health": 
				GameManager.player.SetMaxHp(GameManager.player.health_max + 10)
				health_max = GameManager.player.health_max
			"strenght":
				strenght += 1
				GameManager.Gui.InventoryWindow.weight_max += snappedf(10.0,0.01)
		skill_point -= 1
	_update_skills()

func FixLostArtifactEffects(art_id : String):
	var art = null
	var effects = null
	if GameManager.items_json[art_id]["slot"] == "belt":
		art = GameManager.items_json[art_id]
		effects = art["on_use"]
	else:
		return
	for effect in effects:
		if effect == "max_hp":
			GameManager.player.LowMaxHp(effects[effect])
		if effect == "accuracy":
			GameManager.Gui.SkillWindow.accuracy -= effects[effect] / 100
		if effect == "strength":
			GameManager.Gui.SkillWindow.strenght -= effects[effect] / 100
		if effect == "weight":
			GameManager.Gui.InventoryWindow.weight_max -= effects[effect]
			GameManager.Gui.InventoryWindow.UpdateWeight()
		if effect == "armor":
			GameManager.Gui.SkillWindow.armor -= effects[effect]
		if effect == "rad_resist":
			GameManager.Gui.SkillWindow.radiation_resistance -= effects[effect]
		if effect == "anomaly_resist":
			GameManager.Gui.SkillWindow.anomaly_resistance -= effects[effect]

func AddExp(value:int, with_message : bool = false):
	var lvl_up_exp = 0
	current_exp += value
	print("Received exp: %d" % value)
	if with_message:
		GameManager.Gui.ShowMessage("%d EXP" % value)
	if current_exp >= next_level_exp:
		print("Current exp is more than need for level up! It's: %d/%d" % [current_exp, next_level_exp])
		lvl_up_exp = (current_exp - next_level_exp)
		print("Calculate next exp that we add after leveling up. It's: %d" % lvl_up_exp)
		current_exp = 0
		next_level_exp += randi_range(10,30)
		skill_point += 1
		level += 1
		GameManager.Gui.ShowMessage("+ %s!" % Lang.translate("pause.skills.level"))
	_update_skills()
	if lvl_up_exp != 0:
		AddExp(lvl_up_exp)

func AddSkillPoint(p : int = 1):
	skill_point += p

func _ResetSkills():
	level = 1
	level_max = 10
	current_exp = 0
	next_level_exp = 10
	skill_point = 1

	accuracy = 0.55
	health_max = 50.0
	strenght = 2.0
	armor = 0.0
	radiation_resistance = 0.0
	anomaly_resistance = 0.0

func _update_skills():
	if GameManager.player:
		health_max = GameManager.player.health_max
	ui_health_data.text = ("%.0f" % health_max)+"%" if health_max <= 0.0 else ("+%.0f" % health_max)+"%"
	ui_accuracy_data.text = ("%.0f" % float(accuracy * 100.0))+"%" if accuracy <= 0.0 else ("+%.0f" % float(accuracy * 100.0))+"%"
	ui_armor_data.text = ("%.0f" % float(armor))+"%" if armor <= 0.0 else ("+%.0f" % armor)+"%"
	ui_rad_data.text = ("%.0f" % float(radiation_resistance))+"%" if radiation_resistance <= 0.0 else ("+%.0f" % radiation_resistance)+"%"
	ui_anomaly_data.text = ("%.0f" % float(anomaly_resistance))+"%" if anomaly_resistance <= 0.0 else ("+%.0f" % anomaly_resistance)+"%"
	ui_str_data.text = ("%.0f" % float(strenght))+"%" if strenght <= 0.0 else ("+%.0f" % strenght)+"%"
	ui_exp_bar.value = current_exp
	ui_exp_bar.max_value = next_level_exp
	ui_skillpoints.text = "%s %s" % [Lang.translate("pause.skills.points"), str(skill_point)]
	ui_level.text = "%s %d" % [Lang.translate("pause.skills.level"), level]
	if GameManager.Gui.InventoryWindow:
		ui_weight.text = Lang.translate("ui.statistic.weight") + " " + str(GameManager.Gui.InventoryWindow.weight_max) + " %s" % Lang.translate("kg")
	_set_color_if(ui_rad_data,radiation_resistance)
	_set_color_if(ui_str_data,strenght)
	_set_color_if(ui_anomaly_data,anomaly_resistance)
	_set_color_if(ui_armor_data, armor)			

func Open():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_update_skills()
	self.show()
	return

# Check if is opened
func IsOpened():
	if self.visible:
		return true
	else:
		return false

func Close():
	for skill_btn in $VerticalContainerSkills.get_children():
		if skill_btn is UI_TEXT:
			skill_btn.SetIconAnimation(false)
			
	if not is_open_from_pause:
		
		if not GameManager.Gui.death_screen.visible and IsOpened():
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		GameManager.pause = false
		hide()
	else:
		GameManager.Gui.PauseWindow.show()
		hide()
		is_open_from_pause = false
	if GameManager.level_is_safe:
		GameManager.SaveGame()

func _on_visibility_changed():
	pass


func _on_accuracy_pressed():
	UpgradeSkill("accuracy")


func _on_health_pressed():
	UpgradeSkill("health")


func _on_strenght_pressed():
	UpgradeSkill("strenght")


func _on_resistance_pressed():
	UpgradeSkill("resistance")


func _on_skills_info_pressed():
	GameManager.Gui.ShowTradingMessage(Lang.translate("skills.help"))
