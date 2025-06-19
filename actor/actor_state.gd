class_name ActorStateFactory extends Resource

const Type := preload("../type.gd")

class ActorState extends RefCounted:
	## The factory that instantiated this actor state
	var base: ActorStateFactory:
		get:
			return base
		set(value):
			if base != null:
				push_warning("changing base on actor state that already has a base set")
			base = value
			# might as well...
			self.emit_mutated()

	## The actor containing this state
	var actor_ref: WeakRef

	var actor: Actor:
		get:
			if self.actor_ref == null:
				return null
			return self.actor_ref.get_ref()
		set(value):
			self.actor_ref = weakref(value)

	var combat: Combat:
		get:
			if self.actor == null:
				return null
			return self.actor.combat

	## The name of this actor
	var name: String:
		get:
			return name
		set(value):
			name = value
			self.emit_mutated()

	## Actions executable by this actor
	var actions: Array[ActionDescription]:
		get:
			if self.base == null:
				push_warning("tried to get action list on actor state without base")
				return []
			return self.base.actions

	func _init(b: ActorStateFactory, a: Actor) -> void:
		self.base = b
		self.actor = a
		self.name = b.name

	## Whether this actor should be considered an active participant in combat.
	func is_active() -> bool:
		return true

	## Called at the beginning of `Actor.take_turn`, and returns whether the turn should continue.
	## Intended for beginning-of-turn state changes and things like skipping a turn because of a status effect.
	func begin_turn() -> bool:
		return true

	## Called at the end of `Actor.take_turn`.
	## Intended for end-of-turn state changes.
	func end_turn() -> void:
		pass

	## Should be called when this changes
	func emit_mutated() -> void:
		if self.actor != null:
			self.actor.emit_mutated()

	## Should be called when this was inactive and has become active.
	func emit_active() -> void:
		if self.actor != null:
			self.actor.emit_active()

	## Should be called when this was active and has become inactive.
	func emit_inactive() -> void:
		if self.actor != null:
			self.actor.emit_inactive()


## The name of this actor
@export var name: String = "<Unnamed>"

## Actions executable by this actor
@export var actions: Array[ActionDescription] = []

func initialize(actor: Actor) -> ActorState:
	push_warning("called base ActorStateFactory.initialize")
	return ActorState.new(self, actor)
