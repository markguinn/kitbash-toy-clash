class_name BodyPart
extends Node3D

const AUTO_CONNECT_SIGNALS = [
	"attack_start", 
	"attack_end",
	"special_start", 
	"special_end",
	"dash_start", 
	"dash_end",
	"walk_start",
	"walk_end",
	"change_direction",
]

enum Slot {
	any,
	head,
	torso,
	arm_l,
	arm_r,
	legs,
}

## this does nothing for now. we'll need to think about it more and evolve it
@export var slot: Slot = Slot.any
## additional animation tracks that should be copied
## (beyond the ones that touch the actual part and its children)
@export var extra_tracks: Array[String] = []
## other body parts that come along with this one
@export var extra_nodes: Array[Node3D] = []
## how this body part impact the overall player stats
@export var stats: StatBlock

var container: BodyPartContainer


func _ready() -> void:
	container = _get_body_part_container()
	if not container:
		Log.error(self, "No body part container found!")
	if not stats:
		stats = StatBlock.new()
	for signal_name in AUTO_CONNECT_SIGNALS:
		var method_name: String = "_on_" + signal_name
		if has_method(method_name) and container:
			Log.debug(self, "connecting", signal_name, "to", method_name)
			container.connect(signal_name, _handle_container_signal.bind(method_name))


func _handle_container_signal(dir: Vector3, method_name: String):
	call_deferred(method_name, dir)


func _get_body_part_container() -> BodyPartContainer:
	var p = get_parent()
	while p and p is Node:
		if p is BodyPartContainer:
			return p
		p = p.get_parent()
	return null


func _get_animation_player() -> AnimationPlayer:
	var p: Node3D = get_parent()
	while p:
		var ap = p.get_node_or_null("AnimationPlayer")
		if ap:
			return ap
		p = p.get_parent()
	return null


func _get_animation_tree() -> AnimationTree:
	var p: Node3D = get_parent()
	while p:
		var ap = p.get_node_or_null("AnimationTree")
		if ap:
			return ap
		p = p.get_parent()
	return null


func replace_with_body_part(src_part: BodyPart) -> void:
	var host: Node3D = get_parent()
	var src_player: AnimationPlayer = src_part._get_animation_player()
	var src_anim_root: Node = src_player.get_node(src_player.root_node)
	var src_part_path: String = src_anim_root.get_path_to(src_part).get_concatenated_names()
	var dest_part: Node3D = self
	var dest_player: AnimationPlayer = dest_part._get_animation_player()
	var dest_anim_root: Node = dest_player.get_node(dest_player.root_node)
	var dest_part_path: String = dest_anim_root.get_path_to(dest_part).get_concatenated_names()
	Log.debug(self, "Swapping", src_part, "for", dest_part, "player=", dest_player, "src path=", src_part_path, "dest path=", dest_part_path)

	var anim_tree: AnimationTree = _get_animation_tree()
	var attack_oneshot: AnimationNodeOneShot
	if anim_tree and anim_tree.tree_root is AnimationNodeBlendTree:
		attack_oneshot = anim_tree.tree_root.get_node(&"attack")

	# make a copy of the library because we're going to make destructive edits
	var dest_al: AnimationLibrary = dest_player.get_animation_library("").duplicate_deep()
	dest_player.remove_animation_library("")
	dest_player.add_animation_library("", dest_al)

	# replace the mesh nodes
	for extra_node in src_part.extra_nodes:
		var np: NodePath = src_part.get_path_to(extra_node)
		var old_node: Node3D = self.get_node_or_null(np)
		if old_node:
			old_node.get_parent().remove_child(old_node)
			old_node.queue_free()
		var cloned_node: Node3D = extra_node.duplicate()
		host.add_child(cloned_node)

	host.remove_child(self)
	var cloned_part: Node3D = src_part.duplicate()
	host.add_child(cloned_part)

	# replace the animations
	for anim_name in dest_player.get_animation_list():
		var dest_anim: Animation = dest_player.get_animation(anim_name)
		var src_anim: Animation = src_player.get_animation(anim_name)

		for i in range(dest_anim.get_track_count(), 0, -1):
			var np: NodePath = dest_anim.track_get_path(i - 1)
			var nps: String = np.get_concatenated_names()
			var remove := false
			for t in dest_part.extra_tracks:
				if nps == t:
					remove = true
			for t in src_part.extra_tracks:
				if nps == t:
					remove = true
			if nps.begins_with(dest_part_path):
				remove = true
			for extra_node in src_part.extra_nodes:
				if nps.begins_with(src_anim_root.get_path_to(extra_node).get_concatenated_names()):
					remove = true
			if remove:
				Log.debug(self, "Animation", anim_name, "removing track", i - 1, "for dest", nps)
				dest_anim.remove_track(i - 1)
				if attack_oneshot:
					attack_oneshot.set_filter_path(np, false)

		for i in range(src_anim.get_track_count()):
			var np: NodePath = src_anim.track_get_path(i)
			var nps: String = np.get_concatenated_names()
			var add := false
			for t in src_part.extra_tracks:
				if nps == t:
					add = true
			if nps.begins_with(src_part_path):
				add = true
			for extra_node in src_part.extra_nodes:
				if nps.begins_with(src_anim_root.get_path_to(extra_node).get_concatenated_names()):
					add = true
			if add:
				Log.debug(self, "Animation", anim_name, "adding track", i, "for src", nps)
				src_anim.copy_track(i, dest_anim)
				if attack_oneshot and src_part.stats.attack_cooldown > 0:
					attack_oneshot.set_filter_path(np, true)
					Log.debug(self, "Animation", anim_name, "filtering attack track", i, "for src", nps)

				#var new_idx := dest_anim.get_track_count() - 1
				#dest_anim.track_set_path(new_idx, dest_part_path)
				# TODO: if we hit this case where the parts aren't 1 for 1, we'll need this
				#if src_part_path != dest_part_path:
				#	# what? probably convert to string and then replace src prefix with dest?

	dest_player.clear_caches()
	container.parts_changed.emit(dest_part, cloned_part)
	queue_free()
