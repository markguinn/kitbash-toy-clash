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
	head,
	torso,
	arm_l,
	arm_r,
	legs,
}

## which slots does this body part have, that could be swapped out?
@export var has_slots: Array[Slot] = []

## Which slots can this part potentially occupy?
@export var can_occupy_slots: Array[Slot] = []

## additional animation tracks that should be copied
## (beyond the ones that touch the actual part and its children)
@export var extra_tracks: Array[String] = []

## Other body parts that come along with this one
## If these nodes are also body parts, and they're not already occupying
## a child slot on this part, they'll replace other parts on the body if
## possible (TODO, not implemented yet)
@export var extra_nodes: Array[Node3D] = []

## How this body part impacts the overall player stats
## See body_part.gd#merge for how this stats are aggregated
@export var stats: StatBlock = StatBlock.new()

@export_group("Optional overrides")
@export var active_slot: Slot
@export var active_parent_part: BodyPart # null means the container is the parent
@export var container: BodyPartContainer

var is_for_display := false

func _ready() -> void:
	if not container:
		container = _get_body_part_container()
	if not container and not is_for_display:
		Log.error(self, "No body part container found!")
	if not active_slot:
		active_slot = can_occupy_slots[0] if can_occupy_slots.size() > 0 else Slot.torso
	if not active_parent_part:
		active_parent_part = _get_parent_part()
	for signal_name in AUTO_CONNECT_SIGNALS:
		var method_name: String = "_on_" + signal_name
		if has_method(method_name) and container and not is_for_display:
			Log.debug(self, name, "connecting", signal_name, "to", method_name)
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


func _get_parent_part() -> BodyPart:
	var p = get_parent()
	while p and p is Node:
		# TODO: it'd be nice to interect and check the slots but prob not necessary now, maybe ever
		if p is BodyPart: #and p.has_slots:
			return p
		p = p.get_parent()
	return p


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


func get_child_body_parts() -> Array[BodyPart]:
	var queue: Array[Node] = []
	var out: Array[BodyPart] = []
	queue.append_array(get_children())
	while not queue.is_empty():
		var n = queue.pop_back()
		if n is BodyPart:
			out.append(n)
		else:
			queue.append_array(n.get_children())
	return out


# returns mesh objects that are part of this part, but not
# child body parts
func get_direct_meshes() -> Array[Node3D]:
	var queue: Array[Node] = []
	var out: Array[Node3D] = []
	queue.append_array(get_children())
	while not queue.is_empty():
		var n = queue.pop_back()
		if n is MeshInstance3D:
			out.append(n)
		elif n is not BodyPart:
			queue.append_array(n.get_children())
	return out

const MEASURE_TAGS = {
	Slot.head: "swap:head",
	Slot.torso: "swap:torso",
	Slot.arm_l: "swap:arm_l",
	Slot.arm_r: "swap:arm_r",
	Slot.legs: "swap:legs",
}
func replace_with_body_part(src_part: BodyPart) -> BodyPart:
	Log.measure_start(MEASURE_TAGS[active_slot])
	# grab some references to nodes in the animation tree so we can adjust the
	# filtered tracks later on. we may find this constraining later on, but it's
	# the simplest approach i could think of for now
	var anim_tree: AnimationTree = _get_animation_tree()
	var attack_oneshot: AnimationNodeOneShot
	if anim_tree and anim_tree.tree_root is AnimationNodeBlendTree:
		attack_oneshot = anim_tree.tree_root.get_node(&"attack")

	# make a copy of the animation library on the destination host, 
	# because we're going to make destructive edits
	var dest_player: AnimationPlayer = _get_animation_player()
	var dest_anim_root: Node = dest_player.get_node(dest_player.root_node)
	var dest_anim_lib: AnimationLibrary = dest_player.get_animation_library(&"").duplicate_deep()
	dest_player.remove_animation_library(&"")
	dest_player.add_animation_library(&"", dest_anim_lib)
	
	var src_player: AnimationPlayer = src_part._get_animation_player()
	var src_anim_lib: AnimationLibrary = src_player.get_animation_library(&"")
	var src_anim_root: Node = src_player.get_node(src_player.root_node)

	var cloned_part := _do_replacement(
		src_part,
		src_anim_root,
		src_anim_lib,
		self,
		dest_anim_root,
		dest_anim_lib,
		get_child_body_parts(),
		attack_oneshot
	)

	#Log.debug(self, "---------------------------------------")
	#for cloned_kid in cloned_part.get_child_body_parts():
		#for original_kid in original_kids:
			## TODO: this will need adjustment when we get multiple arms on one torso
			#if cloned_kid.active_slot == original_kid.active_slot:
				#Log.debug(self, cloned_kid.name, "=>", original_kid.name, "---------------------------------------")
				#cloned_kid.print_tree_pretty()
				#original_kid.print_tree_pretty()
				##_do_replacement(
					##original_kid,
					##dest_anim_root,
					##original_anim_lib,
					##cloned_kid,
					##dest_anim_root,
					##dest_anim_lib,
					##attack_oneshot
				##)

	dest_player.clear_caches()
	container.parts_changed.emit(self, cloned_part)
	queue_free()

	Log.measure_end(MEASURE_TAGS[active_slot], 200)
	return cloned_part


# TODO: work with the anim libraries instead of the players and pass them in
# this method probably shouldn't call any global stuff (e.g get_parent below!)
func _do_replacement(
	src_part: BodyPart,
	src_anim_root: Node,
	src_anim_library: AnimationLibrary,
	dest_part: BodyPart,
	dest_anim_root: Node,
	dest_anim_library: AnimationLibrary,
	parts_to_keep: Array[BodyPart],
	attack_oneshot: AnimationNodeOneShot
) -> BodyPart:
	var host: Node3D = dest_part.get_parent()
	var src_part_path: String = src_anim_root.get_path_to(src_part).get_concatenated_names()
	var dest_part_path: String = dest_anim_root.get_path_to(dest_part).get_concatenated_names()
	var part_paths_to_keep: Array[StringName] = []
	part_paths_to_keep.assign(parts_to_keep.map(func(bp: BodyPart): return dest_anim_root.get_path_to(bp).get_concatenated_names()))

	Log.debug(self, "Swapping", src_part, "for", dest_part, "src path=", src_part_path, "dest path=", dest_part_path)

	# replace any extra mesh nodes the src body calls out first
	for extra_node in src_part.extra_nodes:
		var np: NodePath = src_part.get_path_to(extra_node)
		var old_node: Node3D = self.get_node_or_null(np)
		if old_node:
			old_node.get_parent().remove_child(old_node)
			old_node.queue_free()
		var cloned_node: Node3D = extra_node.duplicate()
		host.add_child(cloned_node)

	# replace the main mesh node
	host.remove_child(self)
	var cloned_part: Node3D = src_part.duplicate()
	cloned_part.container = container
	host.add_child(cloned_part)
	cloned_part.active_parent_part = active_parent_part
	cloned_part.active_slot = active_slot
	# TODO: this probably won't hold up. We'll probably need some ways to override it
	cloned_part.position = dest_part.position

	# restore the parts that we want to keep (e.g. arms on the torso)
	for new_child_part: BodyPart in cloned_part.get_child_body_parts():
		for old_child_part: BodyPart in parts_to_keep:
			if new_child_part.active_slot == old_child_part.active_slot:
				var new_child_parent := new_child_part.get_parent()
				new_child_parent.remove_child(new_child_part)
				old_child_part.reparent(new_child_parent, false)
				old_child_part.position = new_child_part.position
				old_child_part.active_parent_part = cloned_part
				new_child_part.queue_free()
				break

	# replace the animations, first by removing conflicting animation tracks
	# from the destination (i.e. tracks referencing the node(s) we're replacinig)
	for anim_name in dest_anim_library.get_animation_list():
		if not dest_anim_library.has_animation(anim_name) or not src_anim_library.has_animation(anim_name):
			continue
		var dest_anim: Animation = dest_anim_library.get_animation(anim_name)
		var src_anim: Animation = src_anim_library.get_animation(anim_name)

		for i in range(dest_anim.get_track_count(), 0, -1):
			var np: NodePath = dest_anim.track_get_path(i - 1)
			var nps: String = np.get_concatenated_names()

			if part_paths_to_keep.find_custom(func(ptk: String): return nps.begins_with(ptk)) >= 0:
				Log.debug(self, "Animation", anim_name, "skipping track", i - 1, "for dest", nps)
				continue

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

		# add the relevant animation tracks from the new body part to the
		# destination animation player
		for i in range(src_anim.get_track_count()):
			var np: NodePath = src_anim.track_get_path(i)
			var nps: String = np.get_concatenated_names()

			if part_paths_to_keep.find_custom(func(ptk: String): return nps.begins_with(ptk)) >= 0:
				Log.debug(self, "Animation", anim_name, "skipping track", i - 1, "for src", nps)
				continue

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

	return cloned_part
