class_name Action extends RefCounted

var combat_ref: WeakRef = null

## The combat in which this action is executing
var combat: Combat:
	get:
		if self.combat_ref == null:
			return null
		return self.combat_ref.get_ref() as Combat
	set(value):
		if self.combat_ref != null:
			push_error("action already assigned to combat...?")
		self.combat_ref = weakref(value)

## The entity (or entities) executing this action
var executor: Variant = null

## The entity (or entities) that are targetted by this action, if any
var target: Variant = null

## Emitted after this action resolves.
signal resolved()

## Emitted after this action is canceled.
signal canceled()

func _init(exec: Variant) -> void:
	self.executor = exec

## Whether this action is executable.
func is_valid() -> bool:
	push_error("called base Action.is_valid()")
	return false

## Can be called by Controllers to check whether an Action could be used in the given combat by the given executor
## FIX: (god i wish gdscript would let you override static methods in descendant classes)
func could_be_valid(com: Combat, exec: Variant) -> bool:
	return true

## Can be called by Controllers to get a list of valid targets for this Action, given the combat and executor
## FIX: (god i wish gdscript would let you override static methods in descendant classes)
func get_valid_targets(com: Combat, exec: Variant) -> Array[Actor]:
	push_error("called base Action.get_valid_targets()")
	return []

## Get the number of targets expected for this action, given the combat and executor
## FIX: (god i wish gdscript would let you override static methods in descendant classes)
func get_target_count(com: Combat, exec: Variant) -> int:
	push_error("called base Action.get_target_count()")
	return 0

## Resolve the action. This can be a coroutine.
func resolve() -> void:
	push_error("called base Action.resolve()")
