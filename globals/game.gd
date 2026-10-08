extends Node

signal enemy_died(enemy, hit_box)
signal player_died(enemy, hit_box)

var confirm_dlg: AcceptDialog
var pick_dlg

var config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	config.load("res://config.ini")
	if FileAccess.file_exists("res://config.local.ini"):
		config.load("res://config.local.ini")

	enemy_died.connect(_on_enemy_died)
	player_died.connect(_on_player_died)
	Log.debug.call_deferred(self, "ready")

func _on_enemy_died(enemy, _hit_box) -> void:
	var dc = enemy.get("loot_parts_dc")
	if dc and randf() <= dc:
		pass

func is_dev_mode() -> bool:
	return OS.is_debug_build()

var last_enemy
func _on_player_died(enemy, _hit_box) -> void:
	var dlg: AcceptDialog = get_tree().get_first_node_in_group("confirm_dlg")
	dlg.show()
	last_enemy = enemy
	get_tree().paused = true
	dlg.confirmed.connect(_on_continue, ConnectFlags.CONNECT_ONE_SHOT)
	dlg.canceled.connect(_on_reset, ConnectFlags.CONNECT_ONE_SHOT)


func _on_reset() -> void:
	Log.debug(self, "reseting")
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_continue() -> void:
	Log.debug(self, "continuing")
	get_tree().paused = false
	var player = get_tree().get_first_node_in_group("player")
	if last_enemy:
		var pb = player.get_node("Body")
		var hurtbox = last_enemy.get_node("HurtBox")
		var body = last_enemy.get_node("Body")
		if last_enemy.speed < player.speed:
			player.speed = last_enemy.speed
			player.get_node("Body/Leg_L").mesh.material.albedo_color = body.mesh.material.albedo_color
			player.get_node("Body/Leg_L").scale *= 2.0
			player.get_node("Body/Leg_R").scale *= 2.0
			#player.get_node("Body/Leg_R").mesh.material.albedo_color = body.mesh.material.albedo_color
		elif hurtbox.armor < player.life.armor:
			player.life.armor = player.life.armor
			pb.mesh.material.albedo_color = body.mesh.material.albedo_color
	for n in get_tree().get_nodes_in_group("enemies"):
		# TODO: probably by distance?
		n.queue_free()
	player.life.hp = player.life.starting_hp
	get_tree().get_first_node_in_group("confirm_dlg").hide()


# this will be true when in a stage and false otherwise (title screen, credits, etc)
# it will remain true when paused though
var is_in_game := false


## Returns the parent node for the active screen or stage
#func get_container() -> Node2D:
#	return get_tree().get_first_node_in_group("scene_container")


## Returns the root of the current active scene
#func get_active_scene() -> Node:
#	return get_container().get_child(0)


## Returns the currently active player
#func get_player() -> Player:
#	return get_tree().get_first_node_in_group("player")


#var is_changing := false
#func change_scene(new_scene_path: String, params = {}) -> void:
	#if is_changing:
		#Log.warn(self, "asked to change to", new_scene_path, "but in the middle of another change")
		#return
	#is_changing = true
	#Log.info(self, "changing to ", new_scene_path, params)
	#var fade_in: bool = params.get("fade_in", true)
	#var fade_out: bool = params.get("fade_out", true)
	#var container := get_container()
	#var cur_scene := get_active_scene()
#
	## start the fade early so we load while it's fading
	#var fade_out_tween: Tween
	#if fade_out:
		#AudioManager.fade_out()
		#fade_out_tween = VFX.white_out()
		#await fade_out_tween.finished
#
	#var new_scene: Resource = load(new_scene_path)
	#if not new_scene:
		#new_scene = load(TITLE_SCREEN)
	#var new_instance: Node = new_scene.instantiate()
	#if new_instance.get("persist_as_current"):
		#StateManager.set_keys.call_deferred({ "path": new_scene_path, "params": params }, "cur_scene")
	#
	##if fade_out:
		##await fade_out_tween.finished
	#
	#container.remove_child(cur_scene)
	#container.add_child(new_instance)
	#cur_scene.queue_free()
	#var t = get_tree()
	#if t:
		#await get_tree().physics_frame
	#StateManager.manage_scene.call_deferred(new_instance, new_scene_path, params)
	#scene_changed.emit.call_deferred()
#
	#if fade_in:
		#VFX.white_in()
#
	#is_changing = false
#
#
#func quit_to_title() -> void:
	#change_scene(TITLE_SCREEN)
	
