class_name ActorControllerFactory extends Resource

class ActorController extends RefCounted:
	var actor_ref: WeakRef

	func actor() -> Actor:
		return self.actor_ref.get_ref() as Actor

	func combat() -> Combat:
		var act: Actor = self.actor()
		if act == null:
			return null
		return act.combat()

	func _init(act: Actor) -> void:
		self.actor_ref = weakref(act)

	## Choose the next action taken by the given actor
	func _choose_action() -> Action:
		print_debug("called base ActorController._choose_action")
		return PassTurn.new(self.actor())

func _initialize(actor: Actor) -> ActorController:
	print_debug("called base ActorControllerFactory._initialize()")
	return ActorController.new(actor)
