class_name CombatantDefinition extends Resource

const Type := preload("./type.gd")
const CMSettings := preload("./settings.gd")

@export var controller: ActorControllerFactory = Type.new(CMSettings.get_setting(CMSettings.DEFAULT_ACTOR_CONTROLLER_TYPE, "ActorControllerFactory")).instantiate()
@export var state: ActorStateFactory = Type.new(CMSettings.get_setting(CMSettings.DEFAULT_ACTOR_STATE_TYPE, "ActorStateFactory")).instantiate()

# ## The type that will be used for turn management
# @export_custom(PROPERTY_HINT_TYPE_STRING, "ActorController", PROPERTY_USAGE_DEFAULT) var actor_controller_type: String = CMSettings.get_setting(CMSettings.DEFAULT_ACTOR_CONTROLLER_TYPE, "ActorController")
#
# ## The type that will be used as the conductor for this combat
# @export_custom(PROPERTY_HINT_TYPE_STRING, "ActorState", PROPERTY_USAGE_DEFAULT) var actor_state_type: String = CMSettings.get_setting(CMSettings.DEFAULT_ACTOR_STATE_TYPE, "ActorState")
#
# func _property_can_revert(prop: StringName) -> bool:
# 	match prop:
# 		&"actor_controller_type":
# 			return true
# 		&"actor_state_type":
# 			return true
# 		_:
# 			return false
#
# func _property_get_revert(prop: StringName) -> Variant:
# 	match prop:
# 		&"actor_controller_type":
# 			return CMSettings.get_setting(CMSettings.DEFAULT_TURN_MANAGER_TYPE, "ActorController")
# 		&"actor_state_type":
# 			return CMSettings.get_setting(CMSettings.DEFAULT_CONDUCTOR_TYPE, "ActorState")
# 		_:
# 			return null
