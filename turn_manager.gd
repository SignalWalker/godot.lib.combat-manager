class_name TurnManager extends RefCounted

var combat_ref: WeakRef

var combat: Combat:
	get:
		return self.combat_ref.get_ref()
	set(value):
		self.combat_ref = weakref(value)

## Emitted when the turn order preview should be updated.
signal update_preview(new_preview: Array[Actor])

func _init(com: Combat) -> void:
	self.combat = com

## Called during `Combat.advance()`, and should be the function in which turns are taken.
## Should return a list of actors who acted during this advance step.
## `Combat.advance()` awaits this function, so it can safely be a coroutine.
## Note that, while this is being called, the combat will be in the `ADVANCING` state.
func advance() -> Array[Actor]:
	assert(false, "called base TurnManager.advance()")
	return []

## Get an array of the next few turns. Intended to be used for the GUI and is never actually called by any CombatManager class,
## so it doesn't necessarily need to be implemented.
func get_preview() -> Array[Actor]:
	return []
