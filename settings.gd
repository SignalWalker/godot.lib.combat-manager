@tool
extends RefCounted

const DEFAULT_COMBAT_SCENE_PATH: String = "runtime/default_combat_scene_path"

const DEFAULT_TURN_MANAGER_TYPE: String = "runtime/default_turn_manager_type"
const DEFAULT_CONDUCTOR_TYPE: String = "runtime/default_conductor_type"

const DEFAULT_ACTOR_CONTROLLER_TYPE: String = "runtime/actor/default_actor_controller_type"
const DEFAULT_ACTOR_STATE_TYPE: String = "runtime/actor/default_actor_state_type"

const DEFAULT_ACTION_DESCRIPTION_TYPE: String = "runtime/action/default_action_description_type"

const DEFINITIONS: Dictionary = {
	DEFAULT_COMBAT_SCENE_PATH: {
		"value": "",
		"type": TYPE_STRING_NAME,
		"hint": PROPERTY_HINT_FILE
	},
	DEFAULT_TURN_MANAGER_TYPE: {
		"value": "TurnManager",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "TurnManager"
	},
	DEFAULT_CONDUCTOR_TYPE: {
		"value": "Conductor",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "Conductor"
	},
	DEFAULT_ACTOR_CONTROLLER_TYPE: {
		"value": "ActorControllerFactory",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "ActorControllerFactory"
	},
	DEFAULT_ACTOR_STATE_TYPE: {
		"value": "ActorStateFactory",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "ActorStateFactory"
	},
	DEFAULT_ACTION_DESCRIPTION_TYPE: {
		"value": "ActionDescription",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_TYPE_STRING,
		"hint_string": "ActionDescription"
	},
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
