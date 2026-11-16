class_name SwapPartsDialog
extends CanvasLayer

# TODO: move this into its own scene
# TODO: only allow swapping body parts that match
# TODO: show or highlight the selected body part
# TODO: should something else hold the actual swapping?

@export var src_body: BodyPartContainer:
	set(v):
		src_body = v
		for c in src_part_holder.get_children():
			c.queue_free()
		src_part_holder.add_child(v)
		v.position = Vector3.ZERO
		v.rotation = Vector3.ZERO

@export var dest_body: BodyPartContainer:
	set(v):
		dest_body = v
		for c in dest_part_holder.get_children():
			c.queue_free()
		dest_part_holder.add_child(dest_body)
		v.position = Vector3.ZERO
		v.rotation = Vector3.ZERO

@export var src_parts: Array[BodyPart]:
	set(v):
		src_parts = v
		src_item_list.clear()
		for s in v:
			src_item_list.add_item(s.name)

@export var dest_parts: Array[BodyPart]:
	set(v):
		dest_parts = v
		dest_item_list.clear()
		for s in v:
			dest_item_list.add_item(s.name)

@onready var src_part_holder: Node3D = $SrcPartViewport/PartHolder
@onready var dest_part_holder: Node3D = $DestPartViewport/PartHolder

@onready var src_item_list: ItemList = $MarginContainer/VBoxContainer/HBoxContainer/SrcSide/ItemList
@onready var dest_item_list: ItemList = $MarginContainer/VBoxContainer/HBoxContainer/DestSide/ItemList
@onready var button: Button = $MarginContainer/VBoxContainer/Button
@onready var src_part_viewport: SubViewport = $SrcPartViewport
@onready var dest_part_viewport: SubViewport = $DestPartViewport


func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	src_item_list.item_selected.connect(_on_src_item_selected)
	dest_item_list.item_selected.connect(_on_dest_item_selected)


func _on_src_item_selected(idx: int) -> void:
	for i in range(src_parts.size()):
		for m in src_parts[i].get_direct_meshes():
			m.visible = (i == idx)


func _on_dest_item_selected(idx: int) -> void:
	for part in dest_body.parts:
		for m in part.get_direct_meshes():
			m.visible = part.name == dest_parts[idx].name


func _on_button_pressed() -> void:
	var src: BodyPart
	var dest: BodyPart
	if src_item_list.get_selected_items().size() > 0:
		src = src_parts[src_item_list.get_selected_items()[0]]
	if dest_item_list.get_selected_items().size() > 0:
		dest = dest_parts[dest_item_list.get_selected_items()[0]]
	if src and dest:
		dest.replace_with_body_part(src)
	hide()
	get_tree().paused = false


func _process(delta: float) -> void:
	src_part_holder.rotation.y += delta
	dest_part_holder.rotation.y -= delta
