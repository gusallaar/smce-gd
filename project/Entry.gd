extends Node

export var main_scene: PackedScene = null

onready var _header: Label = $Header
onready var _log: RichTextLabel = $Log
onready var _button: Button = $Button

var error: String = ""


func _ready():
	_button.connect("pressed", self, "_on_clipboard_copy")

	print("User dir: ", OS.get_user_data_dir())
	if ! Util.copy_dir("res://gdnative/lib/RtResources", "user://RtResources"):
		return _error("Failed to copy in RtResources")

	print("Copied RtResources")

	var bar = BoardRunner.new()
	if bar == null:
		return _error("Shared library not loaded")

	_continue()


func _continue():
	if ! main_scene:
		return _error("No Main Scene")
	get_tree().change_scene_to(main_scene)


func _error(message: String) -> void:
	var file: File = File.new()
	var result = file.open("user://logs/godot.log", File.READ)
	var logfile = file.get_as_text()
	file.close()

	_log.text = logfile
	_header.text += "\n" + message
	error = "Error Reason: " + message + "\n" + logfile


func _on_clipboard_copy() -> void:
	OS.clipboard = error