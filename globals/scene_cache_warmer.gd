class_name SceneCacheWarmer
extends Node3D

## Don't add things here unless there's no other good option. This will
## shift slowness to the initial game load.
@export var cache_at_load: Array[PackedScene] = []

static var was_cached: Dictionary[String, bool] = {}
static var singleton: SceneCacheWarmer

static func add(scene: PackedScene) -> void:
	if not was_cached.has(scene.resource_path) and singleton:
		var instance = scene.instantiate()
		if instance.has_method("_on_warming_cache"):
			instance._on_warming_cache()
		instance.ready.connect(
			func (): 
				instance.queue_free()
				#instance.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
				#instance.set_deferred("visible", false)
		)
		singleton.add_child(instance)
		was_cached[scene.resource_path] = true
		Log.info(singleton, "precaching", scene.resource_path)


func _ready() -> void:
	singleton = self
	for scene in cache_at_load:
		add(scene)
