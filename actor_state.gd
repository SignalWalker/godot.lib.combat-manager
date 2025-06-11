class_name ActorStateFactory extends Resource

class ActorState extends RefCounted:
	## The actor containing this state
	var actor: WeakRef

	## Emitted whenever this actor's state changes
	signal mutated()

	## The name of this actor
	@export var name: String:
		get:
			return name
		set(value):
			name = value
			self.mutated.emit()

	func _init(a: Actor, n: String) -> void:
		self.actor = weakref(a)
		self.name = n

## The name of this actor
@export var name: String = "<Unnamed>"

## Actions executable by this actor
@export var actions: Array[GDScript] = []

func _initialize(actor: Actor) -> ActorState:
	return ActorState.new(actor, self.name)
