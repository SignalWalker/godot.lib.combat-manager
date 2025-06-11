@tool
extends EditorPlugin

func get_plugin_path() -> String:
	return get_script().resource_path.get_base_dir()

func _enable_plugin() -> void:
	add_autoload_singleton("CombatManager", get_plugin_path() + "/combat_manager.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton("CombatManager")

func _enter_tree() -> void:
	if !Engine.is_editor_hint():
		return
	Engine.set_meta(&"CombatManagerPlugin", self)
	CombatManagerSettings.prepare()
	Engine.remove_meta("CombatManagerPlugin")
