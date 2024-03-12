extends Node3D
class_name NPC
var id : String
var keys : Dictionary
var profile : Dictionary
@export var skeleton : Skeleton3D
@export var animation : AnimationPlayer
@export var npc_model : MeshInstance3D
@export var l_hand : BoneAttachment3D
@export var r_hand : BoneAttachment3D
@export var head : BoneAttachment3D
@export var backpack : BoneAttachment3D
@export var hit_blood : Sprite3D
@export var sparkle : Sprite3D
@export var head_mesh: MeshInstance3D
@export var lookat_fake : Node3D
@export var sound_3d: AudioStreamPlayer
var head_temp_rot
var hostile_eyezone
var attack_animations = []
var start_animation = "shoot_stand_start"
var current_animation = ""
var attack_left = false
var attack_right = false
var attack_up = false

var walking = false
var waypoints = []
var walking_loop = false

var weapon_place = null
var is_hostile = false
var is_dead = false
var is_player_look = false
var can_attack = false
var can_play_anim = true

signal is_attacked

var is_attack = false

var health = 1.0
var damage = 0.0
var delay = 0.0
var can_talk = true
var hit_blood_torso_pos = Vector3(-0.088,0.747,0.721)

var delay_timer = 0
var _temp_old_delay = 0
var loot : Dictionary = {
	"money": 0,
	"items": []
}

func _ready():
	
	# lit feature for daylight and unlit for dark
	if GameManager.World.get_node("SceneLight").visible:
		var orig_mat_0 : StandardMaterial3D = npc_model.get_surface_override_material(0)
		var orig_mat_1 : StandardMaterial3D = npc_model.get_surface_override_material(1)
		var orig_mat_head : StandardMaterial3D = head_mesh.get_surface_override_material(0)
		orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		orig_mat_head.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		npc_model.set_surface_override_material(0,orig_mat_0)
		npc_model.set_surface_override_material(1,orig_mat_1)
		head_mesh.set_surface_override_material(0,orig_mat_head)
		
	else:
		var orig_mat_0 : StandardMaterial3D = npc_model.get_surface_override_material(0)
		var orig_mat_1 : StandardMaterial3D = npc_model.get_surface_override_material(1)
		var orig_mat_head : StandardMaterial3D = head_mesh.get_surface_override_material(0)
		
		orig_mat_0.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
		orig_mat_1.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
		orig_mat_head.shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
		
		npc_model.set_surface_override_material(0,orig_mat_0)
		npc_model.set_surface_override_material(1,orig_mat_1)
		head_mesh.set_surface_override_material(0,orig_mat_head)

	if not is_hostile:
		get_node("npc/npc2/Skeleton3D/BoneTorsoCollider/BoneTorsoHostileBody").hide()
		get_node("npc/npc2/Skeleton3D/BoneTorsoCollider/BoneTorsoStaticBody").show()
		var antigas = head.get_node("AttachNode/NpcHead/Antigas")
		if "weapon" in profile and profile["weapon"]:
			var wpn_hand_model = Utility.load_model("assets/models/"+profile["weapon"]+".obj","assets/textures/texobj2.png",position,Vector3(0,0,0),Vector3(2,2,2),false,true)
			weapon_place = wpn_hand_model
			if "weapon_hold" in profile and profile["weapon_hold"]:
				if profile["weapon_hold"] == "l_hand":
					l_hand.get_child(0).add_child(wpn_hand_model)
				if profile["weapon_hold"] == "r_hand":
					r_hand.get_child(0).add_child(wpn_hand_model)
				if profile["weapon_hold"] == "backpack":
					backpack.get_child(0).add_child(wpn_hand_model)
			else:
				if profile["weapon_hold"] == "backpack":
					backpack.get_child(0).add_child(wpn_hand_model)
			wpn_hand_model.position = Vector3.ZERO
			if npc_model.get_surface_override_material(0).shading_mode == StandardMaterial3D.SHADING_MODE_UNSHADED:
				#print("Set NPC's weapon unshaded!")
				wpn_hand_model.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
		
		if "idle_animation" in profile and profile["idle_animation"]:
			PlayAnim(profile["idle_animation"])
			
		
		if "texture" in profile and profile["texture"]:
			ChangeTexture(Utility.load_external_texture("assets/textures/"+profile["texture"]+".png"))
			
		if "gasmask" in profile and profile["gasmask"]:
			if "gasmask_type" in profile and profile["gasmask_type"]:
				antigas.get_surface_override_material(0).set("albedo_texture",Utility.load_external_texture("assets/textures/"+profile["gasmask_type"]+".png"))
				if npc_model.get_surface_override_material(0).shading_mode == StandardMaterial3D.SHADING_MODE_UNSHADED:
					antigas.get_surface_override_material(0).shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
				else:
					antigas.get_surface_override_material(0).shading_mode = StandardMaterial3D.SHADING_MODE_PER_PIXEL
					
			antigas.show()
		else:
			antigas.hide()
	else:
		is_attacked.connect(on_attacked)
		
		get_node("npc/npc2/Skeleton3D/BoneTorsoCollider/BoneTorsoHostileBody").show()
		get_node("npc/npc2/Skeleton3D/BoneTorsoCollider/BoneTorsoStaticBody").hide()
		# checks if level has eyezone
		for nodes in GameManager.current_level.get_children():
			if nodes is EYEZONE and nodes.id == keys["zone_id"]:
				hostile_eyezone = nodes
				hostile_eyezone.enemies.append(self)
				#print("ENEMY found eyezone")
				break
		
		#if hostile_eyezone:
		#	hostile_eyezone.enemies.pick_random().can_attack = true
		
		delay = randf_range(profile["attack_delay"][0],profile["attack_delay"][1])
		_temp_old_delay = delay
		delay_timer = _temp_old_delay 
		
		PlayAnim(start_animation)
		current_animation = start_animation
		
		if "attack_sound" in profile:
			var audio_loader = AudioLoader.new()
			sound_3d.set_stream(audio_loader.loadfile(GameManager.app_dir+"assets/sounds/"+profile["attack_sound"]))
		
		if "damage" in profile:
			damage = randf_range(profile["damage"][0],profile["damage"][1])
		
		if "money" in profile:
			var money_amount = randi_range(profile["money"][0],profile["money"][1])
			loot["money"] = money_amount if not GameManager.casual_gameplay else money_amount*2
			
		if "health" in profile:
			health = randf_range(profile["health"][0],profile["health"][1])
		# if this npc are enemy
		if "weapons" in profile and profile["weapons"]:
			var wpn_hand_model = Utility.load_model("assets/models/"+profile["weapons"].pick_random()+".obj","assets/textures/texobj2.png",position,Vector3(0,0,0),Vector3(2,2,2),false,true)
			r_hand.get_child(0).add_child(wpn_hand_model)
			wpn_hand_model.position = Vector3.ZERO
			if npc_model.get_surface_override_material(0).shading_mode == StandardMaterial3D.SHADING_MODE_UNSHADED:
				#print("Set NPC's weapon unshaded!")
				wpn_hand_model.material_override.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
			
			
		if "texture" in profile and profile["texture"]:
			ChangeTexture(Utility.load_external_texture("assets/textures/"+profile["texture"].pick_random()+".png"))
		
	
func ChangeWeaponPosition(bone_name : String):
	match bone_name:
		"l_hand": weapon_place.reparent(l_hand.get_child(0))
		"r_hand": weapon_place.reparent(r_hand.get_child(0))
		"backpack": weapon_place.reparent(backpack.get_child(0))
	weapon_place.position = Vector3.ZERO
	weapon_place.rotation = Vector3.ZERO
func ChangeTexture(texture : Texture):
	var backpack_tex : StandardMaterial3D = npc_model.get_surface_override_material(0).duplicate() as StandardMaterial3D
	var npc_tex : StandardMaterial3D = npc_model.get_surface_override_material(1).duplicate() as StandardMaterial3D
	
	npc_tex.albedo_texture = texture
	
	npc_model.set_surface_override_material(0,backpack_tex)
	npc_model.set_surface_override_material(1,npc_tex)
	head_mesh.set_surface_override_material(0,npc_tex)

# emits when npc attack player
func on_attacked(_npc):
	#print("emit reset for hostile")
	if hostile_eyezone.enemies.size() > 0:
		var random_ai = hostile_eyezone.enemies.pick_random()
		random_ai.can_attack = true
		#print("Picked random AI [%s]" % random_ai.name)
	'''
	print("\n")
	if hostile_eyezone.enemies.size() > 1:
		print("eyezone has more than 1 ai %s" % str(hostile_eyezone.enemies))
		for ai in hostile_eyezone.enemies:
			print("check ai [%s] if it can attack..." % ai.name)
			if ai != npc:
				print("Not self, check it for [can_attack] boolean")
				if not ai.can_attack:
					print("[%s] can attack is false, add permission" % ai.name)
					ai.can_attack = true
					break
				else:
					print("AI already shot, pass...")
			else:
				print("this is ourself ai, pass...")
	'''
func PlayAnim(a_name):
	current_animation = a_name
	#print(current_animation)
	animation.play(a_name)

func PlaySound(sound):
	GameManager.PlaySFXLoaded(sound)

func Hit(value : float):
	if is_hostile:
		if not is_dead:
			hit_blood.show()
			#hit_blood.position.x = backpack.position.x
			#hit_blood.position.y = backpack.position.y
			hit_blood.pixel_size = randf_range(0.005,0.02)
			hit_blood.rotate_z(randf_range(0,45))
			
			health -= value
			await get_tree().create_timer(0.1).timeout
			hit_blood.hide()
			if health <= 0:
				is_dead = true
				if "exp" in profile:
					var rand_exp = randi_range(profile["exp"][0],profile["exp"][1])
					GameManager.Gui.SkillWindow.AddExp(rand_exp if not GameManager.casual_gameplay else rand_exp*2)
				health = 0
				emit_signal("is_attacked",self)
				GameManager.emit_signal("on_npc_kill",hostile_eyezone,id,loot)	
				
			
	if is_dead:
		animation.speed_scale = 1
		#print("AI is dead!")
		#print(current_animation.split('_'))
		if current_animation != "" and can_play_anim:
			if current_animation.split('_').has("left"):
				if current_animation.split('_').has("sit"):
					PlayAnim("death_sit_left")
					
			if current_animation.split('_').has("right"):
				if current_animation.split('_').has("sit"):
					PlayAnim("death_sit_right")
					
			if current_animation.split('_').has("stand") and current_animation.split('_').has("right"):
				PlayAnim("death_sit_right")
			elif current_animation.split('_').has("stand") and current_animation.split('_').has("left"):
				PlayAnim("death_sit_left")
			
				
			if current_animation.split('_').has("sit") and current_animation.split('_').has("up") or \
			current_animation.split('_').has("stand") and current_animation.split('_').has("idle"):
				PlayAnim("death_stand")
					
				
		GameManager.Gui.ShowMessage("$%s" % str(loot["money"]))
		GameManager.player.AddMoney(loot["money"])
		if "loot" in profile and profile["loot"]:
			for dead_loot in profile["loot"]:
				#print("Chance of [%s] drop is -> %s" % [dead_loot["item"],str(chance)])
				var chance = randf()
				#print("Current [%s] chance is %.2f / %.2f" % [dead_loot["item"],chance, dead_loot["chance"]])
				if chance < float(dead_loot["chance"] if not GameManager.casual_gameplay else dead_loot["chance"]*2):
					
					for amount in range(int(dead_loot["amount"])):
						GameManager.Gui.InventoryWindow.AddItem(dead_loot["item"])
				else:
					continue
		
		for h in hostile_eyezone.enemies:
			h.can_attack = false
		
		hostile_eyezone.enemies.erase(self)		
		await get_tree().create_timer(2.0).timeout
		if hostile_eyezone.enemies.size() > 0:
			var ai = hostile_eyezone.enemies.pick_random()
			ai.delay_timer = 0.5
			ai.can_attack = true
			
		if GameManager.corpse_cleaner:
			queue_free()

func attack(timer):
	delay_timer -= timer
	if delay_timer <= 0:
		is_attack = true
		animation.speed_scale = randf_range(0.4,0.75)
		if npc_model.get_surface_override_material(0).shading_mode == StandardMaterial3D.SHADING_MODE_UNSHADED:
			$sparkle/sparkle_light.hide()
		else:
			$sparkle/sparkle_light.show()
		#if not animation.is_playing():
		PlayAnim(attack_animations.pick_random())
		delay_timer = _temp_old_delay
		can_attack = false
		emit_signal("is_attacked",self)
		#process_mode = Node.PROCESS_MODE_INHERIT

func MoveTo(_waypoints_id : String, _loop : bool = false):
	pass

func hit_player():
	
	if sound_3d.stream != null:
		#print("play enemy shoot sound!")
		sound_3d.playing = true
	#await get_tree().process_frame
	if hostile_eyezone.player:
		var chance = profile["accuracy"]
		var rand = randf_range(0,1)
		
		if GameManager.enemy_accuracy_always:
			chance = 1.0
		
		if rand <= chance:
			var skills = GameManager.Gui.SkillWindow as SkillSystem
			damage = randf_range(profile["damage"][0],profile["damage"][1])
			var final_damage = damage * (100.0 - skills.armor)/100.0
			#if not GameManager.pause:
			hostile_eyezone.player.Hit(final_damage,self)
		else:
			var miss_sounds = profile["miss_sounds"]
			GameManager.PlaySFXLoaded(miss_sounds.pick_random(),-30)
			GameManager.Gui.vignette.material.set_shader_parameter("vignette_opacity",0.5)
			GameManager.player.shoot_cam_anim(true,randf_range(-0.2,0.8),0,randf_range(-0.3,0.4))
		#print("AI damage player by: %.2f HP\nPlayer's armor: %d" % [final_damage,skills.armor])

func _process(delta):
	if not is_hostile and GameManager.looked_npc != null and self.name == GameManager.looked_npc.name:
		# if player look at this npc - npc look at player
		if GameManager.look_at_npc and not GameManager.player.is_cutscene:
			lookat_fake.look_at(GameManager.player.global_position,Vector3.UP,true)
			head_mesh.rotation.y = lerp(GameManager.looked_npc.head_mesh.rotation.y,lookat_fake.rotation.y,delta*2)
			
	if not is_hostile:
		lookat_fake.rotation = Vector3.ZERO
		head_mesh.rotation.y = lerp(head_mesh.rotation.y,0.0,delta)
			
	if is_hostile and hostile_eyezone and not is_dead and not GameManager.pause and not GameManager.ai_ignore:
		# if npc is enemy and alive
		if hostile_eyezone.player and can_attack or hostile_eyezone.player and \
		hostile_eyezone.enemies.size() == 1 and hostile_eyezone.enemies.has(self):
			#print("can_attack")
			attack(delta)
	
	#if is_hostile and is_dead:
	#	if GameManager.corpse_cleaner:
	#		queue_free()

func _on_animation_player_animation_finished(anim_name):
	GameManager.emit_signal("on_npc_animation_finished",self,anim_name)
	if is_hostile:
		if anim_name.contains("shoot"):
			is_attack = false


func _on_animation_player_animation_started(anim_name):
	if anim_name.contains("death"):
		#print("%s can't play anims no more!" % name)
		can_play_anim = false
