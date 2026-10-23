class_name BodyPart
extends Node3D

@export var extra_tracks: Array[String] = []

# how do these stack?
# should they be 0-based and a percentage of the base stat?
# should they be absolute and we take the max of all parts?
# should each multiply by whatever was before?
@export var move_speed: float = 1.0
@export var attack_power: float = 1.0
@export var armor: float = 1.0
# what else? luck?

# this should be absolute seconds i think
@export var attack_cooldown: float = 0.5
@export var special_attack_cooldown: float = 5.0
@export var min_collider_height: float = 3.0

# optional?
# should it respond to input directly?
# i think we want it to come down from a parent node
func attack() -> void:
	pass

# called from animation? or just a timer? do we even need this?
# this would be the point where a projectile would fire
# e.g. the arrow is released in the animation etc
func attack_peak() -> void:
	pass

func special_attack() -> void:
	pass


func _get_animation_player() -> AnimationPlayer:
	var p: Node3D = get_parent()
	while p:
		var ap = p.get_node_or_null("AnimationPlayer")
		if ap:
			return ap
		p = p.get_parent()
	return null


func _get_primary_collider() -> CollisionShape3D:
	var p: Node3D = get_parent()
	while p:
		var ap = p.get_node_or_null("CollisionShape3D")
		if ap:
			return ap
		p = p.get_parent()
	return null


func replace_with_body_part(src_part: BodyPart) -> void:
	var host: Node3D = get_parent()
	var src_player: AnimationPlayer = src_part._get_animation_player()
	var src_anim_root: Node = src_player.get_node(src_player.root_node)
	var src_part_path: NodePath = src_anim_root.get_path_to(src_part)
	var dest_part: Node3D = self
	var dest_player: AnimationPlayer = dest_part._get_animation_player()
	var dest_anim_root: Node = dest_player.get_node(dest_player.root_node)
	var dest_part_path: NodePath = dest_anim_root.get_path_to(dest_part)
	Log.debug(self, "Swapping", src_part, "for", dest_part, "player=", dest_player, "src path=", src_part_path, "dest path=", dest_part_path)
	
	# make a copy of the library because we're going to make destructive edits
	var dest_al: AnimationLibrary = dest_player.get_animation_library("").duplicate_deep()
	dest_player.remove_animation_library("")
	dest_player.add_animation_library("", dest_al)

	# resize the collision shape if needed
	# TODO: this should be the min of all the parts - this is a temporary hack
	if src_part.min_collider_height > 0.0:
		# FIXME: this is the hackiest thing ever. we probably can't assume a capsule?
		var c: CapsuleShape3D = _get_primary_collider().shape
		c.height = src_part.min_collider_height

	# replace the mesh nodes
	host.remove_child(self)
	var cloned_part: Node3D = src_part.duplicate()
	cloned_part.transform = self.transform
	host.add_child(cloned_part)
	
	# replace the animations
	for anim_name in dest_player.get_animation_list():
		var dest_anim: Animation = dest_player.get_animation(anim_name)
		var src_anim: Animation = src_player.get_animation(anim_name)

		for i in range(dest_anim.get_track_count(), 0, -1):
			var np: NodePath = dest_anim.track_get_path(i - 1)
			if np.slice(0, dest_part_path.get_name_count()) == dest_part_path:
				Log.debug(self, "Animation", anim_name, "removing track", i - 1, "for dest", np.get_concatenated_names())
				dest_anim.remove_track(i - 1)

		for i in range(src_anim.get_track_count()):
			var np: NodePath = src_anim.track_get_path(i)
			if np.slice(0, dest_part_path.get_name_count()) == src_part_path:
				Log.debug(self, "Animation", anim_name, "adding track", i, "for src", np.get_concatenated_names())
				src_anim.copy_track(i, dest_anim)
				# TODO: if we hit this case where the parts aren't 1 for 1, we'll need this
				#if src_part_path != dest_part_path:
				#	var new_idx := dest_anim.get_track_count() - 1
				#	# what? probably convert to string and then replace src prefix with dest?

	dest_player.clear_caches()
	queue_free()
