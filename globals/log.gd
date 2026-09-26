extends Node

const DEBUG = 1
const INFO = 2
const WARNING = 3
const ERROR = 4
const EMPTY = []

const HEADER_FORMAT = "%s %8d %s:"
const VENDOR_LICENSE_PATH = "res://vendor_licenses.txt"

const LABELS = {
	DEBUG:   "🙈",
	INFO:    "👀",
	WARNING: "⚠️",
	ERROR:   "‼️",
}

var default_level: int


func _ready() -> void:
	default_level = Game.config.get_value("log_levels", "DEFAULT", 3)

	if !Game.is_dev_mode() and FileAccess.file_exists(VENDOR_LICENSE_PATH):
		var file = FileAccess.open(VENDOR_LICENSE_PATH, FileAccess.READ)
		prints(file.get_as_text())
		
	#Log.error(self, "test err")
	#Log.warn(self, "test warn")
	#Log.info(self, "test info")
	#Log.debug(self, "test debug")


func _format(source: Variant, level: int, args: Array[Variant]) -> Array[Variant]:
	var source_name: String
	if source is String or source is StringName:
		source_name = source
	elif source.get_script():
		source_name = source.get_script().get_global_name()
	if not source_name:
		if source is Node:
			source_name = source.name
		else:
			source_name = str(source)
	var target_level = Game.config.get_value("log_levels", source_name, default_level)
	if level < target_level:
		return EMPTY
	var header := HEADER_FORMAT % [
		LABELS[level],
		Time.get_ticks_msec(),
		source_name,
	]
	var output: Array[Variant] = [header]
	output.append_array(args)
	return output


func _log(source: Variant, level: int, args: Array[Variant]) -> void:
	var output = _format(source, level, args)
	if output:
		prints.callv(output)


func _convert_and_join(a: Array[Variant]) -> String:
	return " ".join(a.map(func(v): return str(v)))


func error(source: Variant, ...args) -> void:
	var output = _format(source, ERROR, args)
	if output:
		push_error(_convert_and_join(output))
		prints.callv(output)


func warn(source: Variant, ...args) -> void:
	var output = _format(source, WARNING, args)
	if output:
		push_warning(_convert_and_join(output))
		prints.callv(output)


func info(source: Variant, ...args) -> void:
	_log(source, INFO, args)


func debug(source: Variant, ...args) -> void:
	if Game.is_dev_mode():
		_log(source, DEBUG, args)


var debounced_log_ms := 500
var debounced_log_level := DEBUG
func debounced(source: Variant, ...args) -> void:
	if Game.is_dev_mode() and not Now.throttle(debounced_log_ms, str(source)):
		_log(source, debounced_log_level, args)
	
