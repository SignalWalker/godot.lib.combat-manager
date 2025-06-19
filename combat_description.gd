@tool
class_name CombatDescription extends Resource
## A description of an instance of combat.

const Type := preload("./type.gd")
const CMSettings := preload("./settings.gd")

## The initial list of enemies in this combat
@export var combatants: Array[CombatantDefinition] = []

## The type that will be used for turn management
@export_custom(PROPERTY_HINT_TYPE_STRING, "TurnManager", PROPERTY_USAGE_DEFAULT) var turn_manager_type: String = CMSettings.get_setting(CMSettings.DEFAULT_TURN_MANAGER_TYPE, "TurnManager")

## The type that will be used as the conductor for this combat
@export_custom(PROPERTY_HINT_TYPE_STRING, "Conductor", PROPERTY_USAGE_DEFAULT) var conductor_type: String = CMSettings.get_setting(CMSettings.DEFAULT_CONDUCTOR_TYPE, "Conductor")

func _property_can_revert(prop: StringName) -> bool:
	match prop:
		&"turn_manager_type":
			return true
		&"conductor_type":
			return true
		_:
			return false

func _property_get_revert(prop: StringName) -> Variant:
	match prop:
		&"turn_manager_type":
			return CMSettings.get_setting(CMSettings.DEFAULT_TURN_MANAGER_TYPE, "TurnManager")
		&"conductor_type":
			return CMSettings.get_setting(CMSettings.DEFAULT_CONDUCTOR_TYPE, "Conductor")
		_:
			return null

func instantiate_turn_manager(combat: Combat) -> TurnManager:
	var script := Type.new(self.turn_manager_type)
	assert(script.derives_from(&"TurnManager"), "CombatDescription tried to instantiate script as TurnManager that does not derive from TurnManager ({0})".format([script]))
	assert(script.type is GDScript || script.type is CSharpScript, "CombatDescription.turn_manager_type must be a GDScript or C# type")
	if script.type is GDScript:
		return (script.type as GDScript).new(combat) as TurnManager
	elif script.type is CSharpScript:
		return (script.type as CSharpScript).new(combat) as TurnManager
	else:
		assert(false, "unreachable")
		return null

func instantiate_conductor(combat: Combat) -> Conductor:
	var script := Type.new(self.conductor_type)
	assert(script.derives_from(&"Conductor"), "CombatDescription tried to instantiate script as Conductor that does not derive from Conductor ({0})".format([script]))
	assert(script.type is GDScript || script.type is CSharpScript, "CombatDescription.conductor_type must be a GDScript or C# type")
	if script.type is GDScript:
		return (script.type as GDScript).new(combat) as Conductor
	elif script.type is CSharpScript:
		return (script.type as CSharpScript).new(combat) as Conductor
	else:
		assert(false, "unreachable")
		return null
