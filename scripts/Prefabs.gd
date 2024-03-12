extends Node

#spawn prefab in node
func create_prefab(prefab,pos,rot):
	prefab.position = pos
	prefab.rotation = rot
	#where.add_child(prefab)

# campfire barrel with animated fire sprite and light
func campfire_barrel():
	var barrel = Utility.load_model("assets/models/barrel_1.obj","assets/textures/texobj1.png",Vector3(0,0,0),Vector3(0,0,0),Vector3(1,1,1),false,true)
	var light = preload("../assets/object_editor/point_light.tscn").instantiate()
	var fire_anim = preload("../assets/object_editor/animated_sprite.tscn").instantiate()
	fire_anim.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	for f in range(4):
		fire_anim.sprite_frames.add_frame("default",Utility.load_external_texture("assets/textures/fire_000"+str(f)+".png"))
	fire_anim.speed_scale = 2
	fire_anim.autoplay = "default"
	fire_anim.pixel_size = 0.025
	fire_anim.position = Vector3(0,1.312,0)
	light.light_color = Color.ORANGE
	light.position = Vector3(0,1.605,0)
	
	barrel.add_child(light)
	barrel.add_child(fire_anim)
	return barrel
