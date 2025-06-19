class_name Conductor extends RefCounted

var combat_ref: WeakRef

var combat: Combat:
	get:
		return self.combat_ref.get_ref()
	set(value):
		self.combat_ref = weakref(value)

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

## Called as the combat starts
func combat_starting() -> void:
	pass

## A coroutine that decides whether the combat can advance, and allows the conductor to pause advancement.
## If this returns false, combat does not advance.
func can_advance() -> bool:
	return true

## Called after combat is advanced, with the actors who acted during that advance step (if any).
func combat_advanced(_actors: Array[Actor]) -> void:
	pass

## Called just before emitting `Combat.ended`
func combat_ended() -> void:
	pass
