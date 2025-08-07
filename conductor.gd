class_name Conductor extends RefCounted

var combat_ref: WeakRef

var combat: Combat:
	get:
		return self.combat_ref.get_ref()
	set(value):
		self.combat_ref = weakref(value)

## Emitted when the turn order preview should be updated.
signal update_turn_preview(new_preview: Array[Actor])

func _init(com: Combat) -> void:
	self.combat = com

## Called after an actor is added to combat
func actor_added(_actor: Actor) -> void:
	pass

## Called after an actor has been removed from combat
func actor_removed(_actor: Actor) -> void:
	pass

## Called after an action is enqueued
func action_enqueued(_index: int, _action: Action) -> void:
	pass

## A coroutine that decides whether the given action can be resolved, and allows the conductor to pause action resolution.
## If this returns false, the action is canceled.
func can_resolve(_action: Action) -> bool:
	return true

## Called after an action is resolved
func action_resolved(_action: Action) -> void:
	pass

## Called after one or more actions are canceled before resolving.
func actions_canceled(_actions: Array[Action]) -> void:
	pass

## Emitted after an action is resolved or canceled and there are no remaining actions in the queue.
func resolved_last_action() -> void:
	pass

## Called as the combat starts
func combat_starting() -> void:
	pass

## A coroutine that decides whether the combat can advance, and allows the conductor to pause advancement.
## If this returns false, combat does not advance.
func can_advance() -> bool:
	return true

## Called during `Combat.advance()`, and should be the function in which turns are taken.
## Should return a list of actors who acted during this advance step.
## `Combat.advance()` awaits this function, so it can safely be a coroutine.
## Note that, while this is being called, the combat will be in the `ADVANCING` state.
func advance() -> Array[Actor]:
	assert(false, "called base Conductor.advance()")
	return []

## Called after combat is advanced, with the actors who acted during that advance step (if any).
func combat_advanced(_actors: Array[Actor]) -> void:
	pass

## Called just before emitting `Combat.ending`, when combat is just about to end.
func combat_ending() -> void:
	pass

## Called just before emitting `Combat.ended`
func combat_ended() -> void:
	pass

## Get an array of the next few turns. Intended to be used for the GUI and is never actually called by any CombatManager class,
## so it doesn't necessarily need to be implemented.
func get_turn_preview() -> Array[Actor]:
	return []
