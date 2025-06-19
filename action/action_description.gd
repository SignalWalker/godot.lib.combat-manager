@tool
class_name ActionDescription extends Resource

const Type := preload("../type.gd")

## The type of action this describes
@export_custom(PROPERTY_HINT_TYPE_STRING, "Action", PROPERTY_USAGE_DEFAULT) var type: String:
	get:
		return type
	set(value):
		type = value
		self._type_script = Type.get_script_by_name(type)

var _type_script: Script = null

var type_script: Script:
	get:
		return _type_script
	set(value):
		_type_script = value
		self.type = _type_script.get_global_name()

func instantiate(executor: Variant) -> Action:
	if self.type_script is GDScript:
		return (self.type_script as GDScript).new(executor)
	elif self.type_script is CSharpScript:
		return (self.type_script as CSharpScript).new(executor)
	else:
		push_error("unimplemented: instantiation of scripts that are neither GDScript nor C#")
		return null
