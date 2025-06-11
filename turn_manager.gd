class_name TurnManagerFactory extends Resource

class TurnManager extends RefCounted:
	## Emitted when the turn order preview should be updated
	signal update_preview(new_preview: Array[Actor])

	## Pop the actor whose turn is next from the queue.
	func _pop_next() -> Actor:
		printerr("called base TurnManagerState._get_next()")
		return null

	## Get an array of the next few turns. Used only for generating previews in the UI.
	func _get_preview() -> Array[Actor]:
		printerr("called base TurnManagerState._get_preview()")
		return []

	## Called when an actor is added to a combat
	func _actor_added(_actor: Actor) -> void:
		pass

	## Called when an actor is removed from a combat
	func _actor_removed(_actor: Actor) -> void:
		pass

func _initialize(_combat: Combat) -> TurnManager:
	return TurnManager.new()