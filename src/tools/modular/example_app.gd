extends "res://tools/modular/module.gd"

func _get_module_name():
	return "example-app"
	
func _on_initialize() -> Dictionary:
	return { valid = true }

func get_signals() -> Array:
	return []

func _on_show_modules_pressed():
	_modular.show_modules()
