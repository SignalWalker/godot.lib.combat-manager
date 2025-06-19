extends RefCounted

var type: Script

func _init(ty: Variant) -> void:
	if ty is Script:
		self.type = ty
	elif ty is String || ty is StringName:
		self.type = get_script_by_name(ty as String)

static func exists(name: String) -> bool:
	return type_exists(name) || !get_script_props_by_name(name).is_empty()

static func get_script_props_by_name(name: String) -> Dictionary:
	for cls: Dictionary in ProjectSettings.get_global_class_list():
		if cls["class"] == name:
			return cls
	push_error("could not find type {0}".format([name]))
	return {}

static func get_script_by_name(name: String) -> Script:
	var cls: Dictionary = get_script_props_by_name(name)
	if cls.is_empty():
		push_error("could not find type {0}".format([name]))
		return null
	else:
		return load(cls["path"]) as Script

static func _derives_from(base: StringName, script: Script) -> bool:
	if script == null:
		return false
	elif script.get_global_name() == base:
		return true
	else:
		return _derives_from(base, script.get_base_script())

func derives_from(base: StringName) -> bool:
	return _derives_from(base, self.type)

func instantiate() -> Variant:
	if self.type is GDScript:
		return (self.type as GDScript).new()
	elif self.type is CSharpScript:
		return (self.type as CSharpScript).new()
	else:
		push_error("unimplemented: instantiate types that are neither GDScript nor CSharpScript ({0})".format([self.type]))
		return null
