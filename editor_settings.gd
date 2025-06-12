@tool
class_name CombatManagerSettings extends RefCounted

const DEFAULT_COMBAT_SCENE_PATH: String = "runtime/default_combat_scene_path"

static var DEFINITIONS: Dictionary = {
	DEFAULT_COMBAT_SCENE_PATH: {
		"value": "",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_FILE
	}
}

static func prepare() -> void:
	for key: String in DEFINITIONS:
		var def: Dictionary = DEFINITIONS[key]
		var name: String = "combat_manager/%s" % key

		if !ProjectSettings.has_setting(name):
			ProjectSettings.set_setting(name, def.value)

		ProjectSettings.set_initial_value(name, def.value)

		var info: Dictionary = {
			"name": name,
			"type": def.type,
			"hint": def.get("hint", PROPERTY_HINT_NONE),
			"hint_string": def.get("hint_string", "")
		}
		ProjectSettings.add_property_info(info)

		ProjectSettings.set_as_basic(name, !def.has("is_advanced"))
		ProjectSettings.set_as_internal(name, def.has("is_hidden"))

static func get_setting(path: StringName, default: Variant) -> Variant:
	var full_path: String = "combat_manager/%s" % path
	if ProjectSettings.has_setting(full_path):
		var setting: Variant = ProjectSettings.get_setting(full_path)
		return setting
	else:
		return default
