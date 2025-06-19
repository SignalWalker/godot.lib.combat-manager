class_name ActorControllerFactory extends Resource

class ActorController extends RefCounted:
	var base: ActorControllerFactory

	var actor_ref: WeakRef

	var actor: Actor:
		get:
			return self.actor_ref.get_ref()
		set(value):
			self.actor_ref = weakref(value)

	var combat: Combat:
		get:
			return self.actor.combat

	func _init(bs: ActorControllerFactory, act: Actor) -> void:
		self.base = bs
		self.actor = act

	## Returns an Iterator outputting Actions that could be valid when executed by the given executor (which defaults to self.actor)
	func valid_actions(exec: Variant = null) -> Iterator:
		var e: Variant = self.actor if exec == null else exec
		return Iterator.map(self.actor.state.actions, func(desc: ActionDescription) -> Action:
			return desc.instantiate(e)
		).and_filter(func(act: Action) -> bool:
			return act != null && act.could_be_valid(self.combat, e)
		)

	## Choose the next action taken by the given actor
	func choose_action() -> Action:
		push_warning("called base ActorController._choose_action")
		return null

func initialize(actor: Actor) -> ActorController:
	push_warning("called base ActorControllerFactory._initialize()")
	return ActorController.new(self, actor)
