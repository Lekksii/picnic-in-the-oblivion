extends Node
class_name WeaponSystem 
var current_weapon : Weapon
var pslot : Weapon
var rslot : Weapon
var infinite_ammo = false
var no_reload = false
var ammo_in_inv = 0
var last_magazine_wpn : Dictionary
var hide_weapon = false
var can_shoot = true
var is_reloading : bool = false
var is_scoping : bool = false
var can_scope : bool = false
var autoreloading : bool = true
var wm_origin_pos : Vector3
var _dt = 0
var l = null
signal shot

func _game_ready():
	pass
	#CheckWeaponsInInventorySlots()

func CheckWeaponsInInventorySlots():
	var pistol_slot : item = GameManager.Gui.InventoryWindow._GetItemInSlot("pistol")
	var rifle_slot :item = GameManager.Gui.InventoryWindow._GetItemInSlot("rifle")
	if pistol_slot:
		var profile = _get_profile(pistol_slot)
		pslot = NewWeapon(pistol_slot.keys["profile"],profile,profile["clip_ammo_max"],profile["speed"],profile["damage"],profile["accuracy"])
		pslot.wm_pos = Vector3(profile["sparkle_position"][0],profile["sparkle_position"][1],profile["sparkle_position"][2])
		pslot.hud_pos = Vector3(profile["hud_position"][0],profile["hud_position"][1],profile["hud_position"][2])
		pslot.item_data = pistol_slot
	if rifle_slot:
		var profile = _get_profile(rifle_slot)
		rslot = NewWeapon(rifle_slot.keys["profile"],profile,profile["clip_ammo_max"],profile["speed"],profile["damage"],profile["accuracy"])
		rslot.wm_pos = Vector3(profile["sparkle_position"][0],profile["sparkle_position"][1],profile["sparkle_position"][2])
		rslot.hud_pos = Vector3(profile["hud_position"][0],profile["hud_position"][1],profile["hud_position"][2])
		rslot.item_data = rifle_slot
		
func _get_profile(slot):
	return GameManager.weapons_json[slot.keys["profile"]]

func NewWeapon(id, data, ammo, speed, damage, accuracy):
	var wpn = Weapon.new()
	wpn.id = id
	wpn.data = data
	wpn.ammo_mag = ammo
	wpn.speed = speed
	wpn.damage = damage
	wpn.accuracy = accuracy
	return wpn

func Scope(b : bool):
	if b:
		is_scoping = true
		GameManager.Gui.scope.show()
		GameManager.Gui.crosshair.hide()
		GameManager.player.ChangeFov(25)
	else:
		is_scoping = false
		GameManager.Gui.scope.hide()
		GameManager.Gui.crosshair.show()
		GameManager.player.ChangeFov(GameManager.player.basic_fov)

func UpdateWeapons():
	if current_weapon == null:
		GameManager.player.hud.hide()
		GameManager.Gui.ammo_clip.text = ""
		GameManager.Gui.ammo_all.text = ""
	if hide_weapon:
		GameManager.player.hud.hide()
		
func DrawWeapon(slot):
	if slot == "pistol" and GameManager.Gui.InventoryWindow._GetItemInSlot("pistol"):
		GameManager.player.hud_anim_player.stop()
		GameManager.player.PlayHudAnimation("wpn_draw")
		GameManager.Gui.crosshair.texture = GameManager.Gui.crosshair_gun_texture
		current_weapon = pslot
		if "inf_ammo" in current_weapon.data and current_weapon.data["inf_ammo"]:
			infinite_ammo = true
		if "ammo_type" in current_weapon.data and current_weapon.data["ammo_type"] != null:
			infinite_ammo = false
		
		if "no_reload" in current_weapon.data and current_weapon.data["no_reload"]:
			no_reload = true
		else:
			no_reload = false
		
		if pslot.id in last_magazine_wpn:
			current_weapon.ammo_mag = last_magazine_wpn[pslot.id]
		else:
			current_weapon.ammo_mag = pslot.ammo_mag
		if not GameManager.player.hud.visible:
			GameManager.player.hud.show()
			
		if "scope" in current_weapon.data and current_weapon.data["scope"]:
			can_scope = true
		else:
			can_scope = false
		#GameManager.player.hud.get_node("AnimationPlayer").speed_scale = 0.4
		GameManager.player.hud.position = current_weapon.hud_pos
		GameManager.player.SHOOT_DELAY = current_weapon.speed
		GameManager.player.shoot_delay_timer = current_weapon.speed
		GameManager.player.hud.texture = Utility.load_external_texture(current_weapon.data["hud"])
		#print(GameManager.player.hud.material_override.albedo_texture.resource_path)
		var mat = GameManager.player.hud.material_override.duplicate() as StandardMaterial3D
		mat.albedo_texture = Utility.load_external_texture(current_weapon.data["hud"])
		if FileAccess.file_exists("assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png"):
			mat.normal_texture = Utility.load_external_texture("assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png")
			#print("found normalmap for %s" % GameManager.app_dir+"assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png")
		#print(GameManager.player.hud.material_override.albedo_texture.resource_path)
		GameManager.player.hud.material_override = mat
		GameManager.player.timer.start(0.1)
		await GameManager.player.timer.timeout
		GameManager.Gui.weapon_icon.texture = current_weapon.item_data.icon.texture
		UpdateAmmo()
		
	if slot == "rifle" and GameManager.Gui.InventoryWindow._GetItemInSlot("rifle"):
		GameManager.player.hud_anim_player.stop()
		GameManager.player.PlayHudAnimation("wpn_draw")
		GameManager.Gui.crosshair.texture = GameManager.Gui.crosshair_gun_texture
		current_weapon = rslot
		ammo_in_inv = 0
		if "inf_ammo" in current_weapon.data and current_weapon.data["inf_ammo"]:
			infinite_ammo = true
		else:
			infinite_ammo = false
		
		if "no_reload" in current_weapon.data and current_weapon.data["no_reload"]:
			no_reload = true
		else:
			no_reload = false
			
		if rslot.id in last_magazine_wpn:
			current_weapon.ammo_mag = last_magazine_wpn[rslot.id]
		else:
			current_weapon.ammo_mag = rslot.ammo_mag
		if not GameManager.player.hud.visible:
			GameManager.player.hud.show()
			GameManager.player.hud.position = rslot.hud_pos
			
		GameManager.player.hud.texture = Utility.load_external_texture(current_weapon.data["hud"])
		var mat = GameManager.player.hud.material_override.duplicate() as StandardMaterial3D
		mat.albedo_texture = Utility.load_external_texture(current_weapon.data["hud"])
		if FileAccess.file_exists(GameManager.app_dir+"assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png"):
			mat.normal_texture = Utility.load_external_texture("assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png")
			#print("found normalmap for %s" % GameManager.app_dir+"assets/ui/"+current_weapon.data["hud"].split('.png')[0].split('ui/')[1]+"_nm.png")
		#print(GameManager.player.hud.material_override.albedo_texture.resource_path)
		
		GameManager.player.hud.material_override = mat
		
		if infinite_ammo:
			UpdateAmmo()
		else:
			UpdateAmmo()
		GameManager.player.SHOOT_DELAY = current_weapon.speed
		GameManager.player.shoot_delay_timer = current_weapon.speed
		if "scope" in current_weapon.data and current_weapon.data["scope"]:
			can_scope = true
		else:
			can_scope = false
		
		GameManager.player.hud.position = current_weapon.hud_pos
		
		GameManager.player.timer.start(0.1)
		await GameManager.player.timer.timeout
		#
		#GameManager.Gui.weapon_icon.texture = current_weapon.item_data.texture
	#print("+ Значок зброї в руках на екрані змінено! Item ID: %s\n\n" % [current_weapon.item_data.ID])
	GameManager.player.hud_orig_wm_pos = current_weapon.wm_pos
	GameManager.player.hud_orig_pos = current_weapon.hud_pos
	UpdateWeapons()
	
	
func UpdateAmmo():
	if current_weapon:
		
		if infinite_ammo:
			GameManager.Gui.ammo_clip.text = str(current_weapon.ammo_mag)
			GameManager.Gui.ammo_all.text = str(current_weapon.data["clip_ammo_max"])
		else:
			ammo_in_inv = 0
			for ammo in GameManager.Gui.InventoryWindow.items_list:
				if is_instance_valid(ammo):
					if ammo.ID == current_weapon.data["ammo_type"]:
						ammo_in_inv += 1
			GameManager.Gui.ammo_clip.text = str(current_weapon.ammo_mag)
			GameManager.Gui.ammo_all.text = str(ammo_in_inv)
	else:
		#GameManager.Gui.crosshair.texture = GameManager.Gui.crosshair_use_texture
		GameManager.Gui.ammo_clip.text = ""
		GameManager.Gui.ammo_all.text = ""

func HideWeapon():
	if current_weapon:
		GameManager.player.hud_anim_player.stop()
		GameManager.player.PlayHudAnimation("wpn_hide")
		GameManager.Gui.crosshair.texture = GameManager.Gui.crosshair_use_texture
		#await GameManager.player.hud_anim_player.animation_finished
		GameManager.player.hud.hide()
		GameManager.Gui.ammo_clip.text = ""
		GameManager.Gui.ammo_all.text = ""
		if current_weapon.id == pslot.id:
			pslot.ammo_mag = current_weapon.ammo_mag
		if current_weapon.id == rslot.id:
			rslot.ammo_mag = current_weapon.ammo_mag
		#hide_weapon = true
		GameManager.player.hud_anim_player.stop()
		
		
func ReloadWeapon():
	if current_weapon.ammo_mag < current_weapon.data["clip_ammo_max"] and not hide_weapon:
		
		if infinite_ammo:
			current_weapon.ammo_mag = current_weapon.data["clip_ammo_max"]
		else:
			for ammo in GameManager.Gui.InventoryWindow.items_list:
				if is_instance_valid(ammo):
					if ammo.ID == current_weapon.data["ammo_type"]:
						current_weapon.ammo_mag = current_weapon.data["clip_ammo_max"]
						ammo.SelfDestroy()
						ammo_in_inv -= 1
						UpdateAmmo()
						break
		#await get_tree().create_timer(0.1).timeout
		is_reloading = false
		UpdateAmmo()
		can_shoot = true

func _show_wm_sarkle(b:bool):
	
	var wm = GameManager.player.shoot_fire
	if b:
		#print(l)
		var light = Utility.add_point_light(Color(Color.ORANGE,0.1),5,false,0.095,Vector3(GameManager.player.PlayerCamera.position.x,GameManager.player.PlayerCamera.position.y,GameManager.player.PlayerCamera.position.z-0.5),GameManager.player.PlayerCamera.rotation)
		l = light
		#print(l)
		wm_origin_pos = current_weapon.wm_pos
		wm.show()
		GameManager.player.add_child(light)
		wm.rotate_z(randf_range(0,180.0))
		wm.position.x = randf_range(current_weapon.wm_pos.x,current_weapon.wm_pos.x+0.002)
		wm.position.y = randf_range(current_weapon.wm_pos.y-0.001, current_weapon.wm_pos.y+0.002)
		can_shoot = false
	else:
		#print(l)
		if l:
			l.queue_free()
		#print(l)
		wm.hide()
		wm.position = wm_origin_pos
		can_shoot = true

func Shoot():
	if current_weapon and GameManager.player.ready_to_shoot and can_shoot:
		if current_weapon.ammo_mag >= 1:
			#f not infinite_ammo:
			if "shoot_count" in current_weapon.data:
				current_weapon.ammo_mag -= current_weapon.data["shoot_count"]
			else:
				current_weapon.ammo_mag -= 1
			
			
			GameManager.player.shoot_cam_anim()
			#if GameManager.player.anima
			#if GameManager.player.hud_anim_player.current_animation != "idle":
			GameManager.player.hud_anim_player.stop()
			GameManager.player.PlayHudAnimation("shoot")
			GameManager.PlaySFXLoaded(current_weapon.data["fire_sound"])
			
			if not GameManager.player.one_hit_kill:	
				emit_signal("shot",current_weapon.damage + GameManager.Gui.SkillWindow.strenght,current_weapon.accuracy)
			else:
				#GameManager.Gui.SkillSystem.accuracy = 
				emit_signal("shot",999,1)
				
			UpdateAmmo()
		else:
			if autoreloading:
				if ammo_in_inv != 0 or infinite_ammo:
					can_shoot = false
					is_reloading = true
					GameManager.player.PlayHudAnimation(current_weapon.data["reload_anim"])

func DeleteWeapon(slot,silent = false):
	if slot == "rifle":
		current_weapon = null
		last_magazine_wpn[rslot.id] = rslot.ammo_mag
		GameManager.Gui.weapon_icon.texture = null
		rslot = null
		UpdateAmmo()
		UpdateWeapons()
		if pslot and not silent:
			DrawWeapon("pistol")
	if slot == "pistol":
		current_weapon = null
		last_magazine_wpn[pslot.id] = pslot.ammo_mag
		GameManager.Gui.weapon_icon.texture = null
		pslot = null
		UpdateAmmo()
		UpdateWeapons()
		if rslot and not silent:
			DrawWeapon("rifle")

func _process(delta):
	_dt += 1 * delta
