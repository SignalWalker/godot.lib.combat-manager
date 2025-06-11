class_name Actor extends RefCounted

enum ActorStatus {
	INACTIVE,
	ACTIVE
}

## The actor's ID, which is used as its key within the Combat's combatant dictionary.
var id: int
## The combat to which this actor belongs
var combat_ref: WeakRef
## The actor's AI
var controller: ActorControllerFactory.ActorController
## The actor's state
var state: ActorStateFactory.ActorState

var status: ActorStatus = ActorStatus.ACTIVE

func _init(ident: int, com: Combat, con: ActorControllerFactory, sta: ActorStateFactory) -> void:
	self.id = ident
	self.combat_ref = weakref(com)
	self.state = sta._initialize(self)
	self.controller = con._initialize(self)
	self.status = ActorStatus.ACTIVE

func combat() -> Combat:
	return self.combat_ref.get_ref() as Combat

func take_turn() -> void:
	self.combat().push_action(await self.controller._choose_action())
