extends Control

enum Severity {
	Debug,
	Info,
	Warning,
	Error,
}

export (Severity) var minimum_console_severity = Severity.Debug
export (Severity) var minimum_modular_severity = Severity.Debug

export (int) var initial_module_index = 0

export (bool) var automatically_open_first_app = false

var modules = {}

var _modules: Array
var _apps: Array
var _current = -1

var _broadcast_listeners = {}

onready var _console = $ui/modules/logs/margin_container/console

func _ready():
	_modules = _get_modules()
	
	var valid = true
	
	$ui/modules.set_tab_title(0, "MODULAR_LOGS")
	
	for index in range(_modules.size()):
		var module: Control = _modules[index]
		var result = _initialize_module(module)
		if not result.valid:
			valid = false
			_log_error("can't initialize module '%s'" % module.get_module_name())
			_log_error(result.message)
			break
		var title: String = module.get_module_name().to_upper()
		$ui/modules.set_tab_title(index + 1, title)
		

	var _topbar = $ui/topbar
	
	# TODO fix duplicated code
	
	_apps = _get_apps()
	for index in range(_apps.size()):
		var app: Control = _apps[index]
		var result = _initialize_module(app)
		if not result.valid:
			valid = false
			_log_error("can't initialize module '%s'" % app.get_module_name())
			_log_error(result.message)
			break
		app.hide()
		
		var app_thumbnail = preload("res://tools/modular/top_button.tscn").instance()
		var button = app_thumbnail.get_node("button")
		button.text = app.get_module_name().to_upper()
		button.connect("pressed", self, "_on_app_thumbnail_pressed", [index])
		
		_topbar.add_child(app_thumbnail)
	
	var total = _modules.size() + _apps.size()
	
	if total == 0:
		_log_warning("No modules")
	else:
		if valid:
			_log_debug("%s modules initialized successfully (%s + %s)" % [total, _apps.size(), _modules.size()])

	$ui/modules.current_tab = initial_module_index
	
	if automatically_open_first_app:
		open_app(0)
	
func get_module(module_name: String):
	return modules.get(module_name, null)

func show_modules():
	if _current == -1:
		_log_warning("already in modules")
		return true
	
	_apps[_current].hide()
	$ui.show()
	_current = -1

func open_app(index: int):
	if index < 0 or index >= _apps.size():
		_log_error("invalid app index %s (%s apps)" % [index, _apps.size()])
		return false
	
	if _current == index:
		_log_warning("already in app %s" % [index])
		return true
	
	$ui.hide()
	_current = index
	_apps[index].show()
	
	return true

func _initialize_module(module: Node) -> Dictionary:
	var module_name = module.get_module_name()
	
	if modules.has(module_name):
		return { valid = false, message = "duplicated module '%s'" % module_name}
	
	_log_info("initializing module '%s'" % module_name)
	var result = module.initialize(self)
	
	if not result.valid:
		return result
	
	var ls = module.get_signals()
	
	for l in ls:
		var key = _signal_key(l.category, l.signal_name)
		
		if not _broadcast_listeners.has(key):
			_broadcast_listeners[key] = []
		
		_broadcast_listeners[key].append({
			target = l.target,
			method_name = l.method_name
		})
	
	modules[module_name] = module

	return { valid = true }

func change_theme(new_theme: Theme):
	set_theme(new_theme)


# Local logging shortcuts

func _log_debug(message: String, level = 0):
	log_debug("modular", message, level)
func _log_info(message: String, level = 0):
	log_info("modular", message, level)
func _log_warning(message: String, level = 0):
	log_warning("modular", message, level)
func _log_error(message: String, level = 0):
	log_error("modular", message, level)


# General logging

func log_debug(category: String, message: String, level = 0):
	log_message(Severity.Debug, category, message, level)
func log_info(category: String, message: String, level = 0):
	log_message(Severity.Info, category, message, level)
func log_warning(category: String, message: String, level = 0):
	log_message(Severity.Warning, category, message, level)
func log_error(category: String, message: String, level = 0):
	log_message(Severity.Error, category, message, level)


func log_message(severity: int, category: String, message: String, _level = 0):
	var msg = "%-7s %-15s %s" % [_severity_str(severity), category, message]
	
	if severity >= minimum_console_severity:
		print(msg)
	if severity >= minimum_modular_severity:
		_console.text += msg + "\n"
		var numlines = _console.get_line_count()
		_console.cursor_set_line(numlines - 1)

func _severity_str(severity: int) -> String:
	var severities = Severity.keys()
	if severity >= 0 and severity < severities.size():
		return severities[severity]
	else:
		return "?%s?" % severity


func _get_modules():
	var children = $ui/modules.get_children()
	var ret = []
	for index in range(1, children.size()):
		var c = children[index]
		ret.append(c)
	return ret
	
func _get_apps():
	var children = $apps.get_children()
	var ret = []
	for index in range(0, children.size()):
		var c = children[index]
		ret.append(c)
	return ret
	
func broadcast(category: String, signal_name: String, args: Array):
	var key = _signal_key(category, signal_name)
	
	_log_info("broadcast: %s/%s (%s)" % [category, signal_name, args])
	
	if _broadcast_listeners.has(key):
		var listeners = _broadcast_listeners[key]
		for l in listeners:
			var obj: Object = l.target
			var method_name: String = l.method_name
			
			obj.callv(method_name, args)

func _signal_key(category: String, signal_name: String) -> String:
	return "%s:%s" % [category, signal_name]

func _on_quit_button_pressed():
	get_tree().quit()

func _on_app_thumbnail_pressed(index):
	open_app(index)
	
func make_empty(node: Node):
	while(node.get_child_count() > 0):
		var first_child = node.get_child(0)
		node.remove_child(first_child)
		first_child.queue_free()
