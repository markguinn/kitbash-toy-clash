extends Node

signal enemy_died(enemy, hit_box)
signal player_died(enemy, hit_box)

var confirm_dlg: AcceptDialog
var pick_dlg

func _ready() -> void:
	enemy_died.connect(_on_enemy_died)
	player_died.connect(_on_player_died)


func _on_enemy_died(enemy, _hit_box) -> void:
	var dc = enemy.get("loot_parts_dc")
	if dc and randf() <= dc:
		pass


var last_enemy
func _on_player_died(enemy, _hit_box) -> void:
	var dlg: AcceptDialog = get_tree().get_first_node_in_group("confirm_dlg")
	dlg.show()
	last_enemy = enemy
	get_tree().paused = true
	dlg.confirmed.connect(_on_continue, ConnectFlags.CONNECT_ONE_SHOT)
	dlg.canceled.connect(_on_reset, ConnectFlags.CONNECT_ONE_SHOT)


func _on_reset() -> void:
	prints("reseting")
	get_tree().paused = false
	get_tree().reload_current_scene()
	
func _on_continue() -> void:
	prints("continuing")
	get_tree().paused = false
	var player = get_tree().get_first_node_in_group("player")
	var phb = player.get_node("HurtBox")
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
		elif hurtbox.armor < phb.armor:
			phb.armor = hurtbox.armor
			pb.mesh.material.albedo_color = body.mesh.material.albedo_color
	for n in get_tree().get_nodes_in_group("enemies"):
		# TODO: probably by distance?
		n.queue_free()
	phb.hp = phb.starting_hp
	get_tree().get_first_node_in_group("confirm_dlg").hide()
