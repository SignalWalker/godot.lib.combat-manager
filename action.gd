class_name Action extends RefCounted

## The combat in which this action is executing
var combat_ref: WeakRef = null

## The id of the Combat.Ticket containing this Action
var ticket_ref: WeakRef = null

## The entity (or entities) executing this action
var executor: Variant

## Emitted after this action resolves. NOTE: Combat calls `emit()` for this
signal resolved()

func _init(exec: Variant) -> void:
	self.executor = exec

func combat() -> Combat:
	return self.combat_ref.get_ref() as Combat

func ticket() -> Combat.Ticket:
	return self.ticket_ref.get_ref() as Combat.Ticket

## Get a list of actors targetable by this action
func _get_valid_targets() -> Array[Actor]:
	printerr("called base Action._get_valid_targets()")
	return []

## Whether this action is executable.
func _is_valid() -> bool:
	printerr("called base Action._is_valid()")
	return false

## Resolve the action. This can be a coroutine.
func _resolve() -> void:
	printerr("called base Action._resolve()")
