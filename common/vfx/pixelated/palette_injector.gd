@tool
class_name PaletteInjector
extends ColorRect

@export_enum("none", "rgb", "oklab") var quantization_algorithm: int = 0:
	set(v):
		quantization_algorithm = v % 3
		update_params()
		
@export var active_palette: int = 0:
	set(v):
		active_palette = v % palettes.size()
		update_params()

@export var palettes: Array[Texture2D] = []:
	set(v):
		palettes = v
		update_params()

func update_params() -> void:
	var sm: ShaderMaterial = material
	sm.set_shader_parameter("quantization_algorithm", quantization_algorithm)
	if active_palette < palettes.size():
		sm.set_shader_parameter("palette_texture", palettes[active_palette])
		sm.set_shader_parameter("palette_size", palettes[active_palette].get_size() / 8.0)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_palette_up"):
		active_palette += 1
	if event.is_action_pressed("switch_palette_down"):
		active_palette -= 1
	if event.is_action_pressed("switch_palette_algo"):
		quantization_algorithm += 1
