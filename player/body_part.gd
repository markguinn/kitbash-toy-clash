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


func replace_with_body_part(new_part: BodyPart) -> void:
	var cloned_part: Node3D = new_part.duplicate()
	var host: Node3D = get_parent()
	var src_player: AnimationPlayer = new_part._get_animation_player()
	var dest_player: AnimationPlayer = self._get_animation_player()
	Log.debug(self, "Swapping", new_part, "for", self, " (", dest_player, ")")
	
	# make a copy of the library because we're going to make destructive edits
	var dest_al: AnimationLibrary = dest_player.get_animation_library("").duplicate_deep()
	dest_player.remove_animation_library("")
	dest_player.add_animation_library("", dest_al)

	# resize the collision shape if needed
	# TODO: this should be the min of all the parts - this is a temporary hack
	if new_part.min_collider_height > 0.0:
		# FIXME: this is the hackiest thing ever. we probably can't assume a capsule?
		var c: CapsuleShape3D = _get_primary_collider().shape
		c.height = new_part.min_collider_height

	# replace the mesh nodes
	host.remove_child(self)
	cloned_part.transform = self.transform
	host.add_child(cloned_part)
	
	# replace the animations
	for anim_name in dest_player.get_animation_list():
		var a1: Animation = dest_player.get_animation(anim_name)
		var a2: Animation = src_player.get_animation(anim_name)
		Log.debug(self, "Animation", anim_name)
		for i in range(a1.get_track_count(), 0, -1):
			var np: NodePath = a1.track_get_path(i - 1)
			if np.get_name(1) == "legs":
				a1.remove_track(i - 1)
				Log.debug(self, "Removing track", i - 1, "from dest", np.get_concatenated_names())
		for i in range(a2.get_track_count()):
			var np: NodePath = a2.track_get_path(i)
			if np.get_name(1) == "legs":
				a2.copy_track(i, a1)
				Log.debug(self, "Adding track", i, "from src", np.get_concatenated_names())

	dest_player.clear_caches()
	queue_free()
