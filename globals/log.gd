extends Node

const EMPTY = ""

enum LogLevel {DEBUG, INFO, WARNING, ERROR}

var default_level: String
var base_format: String
var level_formats: Dictionary[LogLevel, String] = {}
var level_icons: Dictionary[LogLevel, String] = {}


func _ready() -> void:
	default_level = Game.config.get_value("log_levels", "DEFAULT", "WARNING")
	base_format = Game.config.get_value("log_format", "base_line", "%s %8d %s: %s")
	level_formats[LogLevel.DEBUG] = Game.config.get_value("log_format", "DEBUG", "%s")
	level_formats[LogLevel.INFO] = Game.config.get_value("log_format", "INFO", "%s")
	level_formats[LogLevel.WARNING] = Game.config.get_value("log_format", "WARNING", "%s")
	level_formats[LogLevel.ERROR] = Game.config.get_value("log_format", "ERROR", "%s")
	level_icons[LogLevel.DEBUG] = Game.config.get_value("log_icon", "DEBUG", "")
	level_icons[LogLevel.INFO] = Game.config.get_value("log_icon", "INFO", "")
	level_icons[LogLevel.WARNING] = Game.config.get_value("log_icon", "WARNING", "")
	level_icons[LogLevel.ERROR] = Game.config.get_value("log_icon", "ERROR", "")

	if !Game.is_dev_mode():
		print(Engine.get_license_text())

	#Log.error(self, "test err")
	#Log.warn(self, "test warn")
	#Log.info(self, "test info")
	#Log.debug(self, "test debug")


func _get_source_name(source: Variant) -> String:
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
	return source_name


func _format(source: Variant, level: LogLevel, args: Array[Variant]) -> String:
	var source_name := _get_source_name(source)
	var target_level_raw = Game.config.get_value("log_levels", source_name, default_level)
	var target_level: LogLevel = target_level_raw if target_level_raw is int else LogLevel[target_level_raw]
	if level < target_level:
		return EMPTY
	var output := _convert_and_join(args)
	var icon: String = Game.config.get_value("log_icon", source_name, level_icons.get(level, ""))
	var source_format: String = Game.config.get_value("log_format", source_name, "")
	if source_format:
		output = source_format % [output]
	output = base_format % [icon, Time.get_ticks_msec(), source_name, output]
	output = level_formats.get(level, "%s") % [output]
	return output


func _log(source: Variant, level: int, args: Array[Variant]) -> void:
	var output = _format(source, level, args)
	if output:
		print_rich(output)


func _convert_and_join(a: Array[Variant]) -> String:
	return " ".join(a.map(func(v): return str(v)))


func error(source: Variant, ...args) -> void:
	var output = _format(source, LogLevel.ERROR, args)
	if output:
		push_error("%s: %s" % [_get_source_name(source), _convert_and_join(args)])
		print_rich(output)


func warn(source: Variant, ...args) -> void:
	var output = _format(source, LogLevel.WARNING, args)
	if output:
		push_warning("%s: %s" % [_get_source_name(source), _convert_and_join(args)])
		print_rich(output)


func info(source: Variant, ...args) -> void:
	_log(source, LogLevel.INFO, args)


func debug(source: Variant, ...args) -> void:
	if Game.is_dev_mode():
		_log(source, LogLevel.DEBUG, args)


var debounced_log_ms := 500
var debounced_log_level := LogLevel.DEBUG
func debounced(source: Variant, ...args) -> void:
	if Game.is_dev_mode() and not Now.throttle(debounced_log_ms, str(source)):
		_log(source, debounced_log_level, args)


#region perf logging

var measurements: Dictionary[String, int] = {}

func measure_start(op_name: String) -> void:
	measurements[op_name] = Time.get_ticks_msec()


func measure(op_name: String, op_tag: StringName, warn_threshold = 1000) -> void:
	log_measurement(op_name, op_tag, Time.get_ticks_msec() - measurements.get(op_name, 0), warn_threshold)


func log_measurement(op_name: String, op_tag: String, ms: int, warn_threshold = 1000) -> void:
	var format: String = Game.config.get_value("log_format", "PERF", "")
	if format:
		print_rich(format % [Now.msec, op_name, op_tag, ms])
	if ms > warn_threshold:
		warn("SLOW", op_name, op_tag, ":", ms, ">", warn_threshold)


func measure_end(op_name: String, warn_threshold = 1000) -> void:
	if op_name == &"global_ready":
		var window = JavaScriptBridge.get_interface("window")
		if window:
			log_measurement(op_name, &"end", window.measureGlobalReadyEnd())
			return
	measure(op_name, &"end", warn_threshold)

#endregion
