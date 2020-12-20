extends "res://tools/modular/module.gd"

func _get_module_name():
	return "example-module"

func _on_initialize() -> Dictionary:
	return { valid = true }

func get_signals() -> Array:
	return []
	

func _on_play_uajari_pressed():
	_modular.broadcast("music", "start", ["uajari"])
