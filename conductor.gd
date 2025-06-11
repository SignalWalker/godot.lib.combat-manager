class_name ConductorFactory extends Resource

class Conductor extends RefCounted:
	var combat_ref: WeakRef

	func combat() -> Combat:
		return self.combat_ref.get_ref() as Combat

	func _init(com: Combat) -> void:
		self.combat_ref = weakref(com)

	## Called after an actor is added to combat
	func _actor_added(_actor: Actor) -> void:
		pass

	## Called after an actor has been removed from combat
	func _actor_removed(_actor: Actor) -> void:
		pass

	## Called after an action is enqueued
	func _action_enqueued(_index: int, _ticket: Combat.Ticket) -> void:
		pass

	## Called after an action is resolved
	func _action_resolved(_ticket: Combat.Ticket) -> void:
		pass

	## Called after one or more actions are canceled before resolving.
	func _actions_canceled(_tickets: Array[Combat.Ticket]) -> void:
		pass

	## Called as the combat starts
	func _combat_starting() -> void:
		pass

	## Called as the combat ends
	func _combat_ending() -> void:
		pass

func _initialize(combat: Combat) -> Conductor:
	return Conductor.new(combat)
