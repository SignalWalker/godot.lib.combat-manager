@tool
extends EditorPlugin

const Type := preload("./type.gd")
const CMSettings := preload("./settings.gd")

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()

func _enable_plugin() -> void:
	if !Type.exists("Iterator"):
		push_error("CombatManager requires Iterator")
		return
	add_autoload_singleton("CombatManager", get_plugin_path() + "/combat_manager.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("CombatManager")

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return
	Engine.set_meta(&"CombatManagerPlugin", self)
	CMSettings.prepare()

func _exit_tree() -> void:
	if !Engine.is_editor_hint():
		return
	Engine.remove_meta("CombatManagerPlugin")
