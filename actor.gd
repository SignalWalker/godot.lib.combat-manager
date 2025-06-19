class_name Actor extends RefCounted

## The actor's ID, which is used as its key within the Combat's combatant dictionary.
var id: int
## The combat to which this actor belongs
var combat_ref: WeakRef:
	get:
		return combat_ref
	set(value):
		if combat_ref != null:
			push_warning("changing combat on actor that already has combat set")
		combat_ref = value


## The actor's AI
var controller: ActorControllerFactory.ActorController:
	get:
		return controller
	set(value):
		controller = value
		self.emit_mutated()

## The actor's state
var state: ActorStateFactory.ActorState:
	get:
		return state
	set(value):
		var was_active := self.is_active()

		state = value
		self.emit_mutated()

		var is_now_active := self.is_active()
		if was_active && !is_now_active:
			self.emit_inactive()
		elif !was_active && is_now_active:
			self.emit_active()

var combat: Combat:
	get:
		return self.combat_ref.get_ref() as Combat
	set(value):
		self.combat_ref = weakref(value)

var name: String:
	get:
		if self.state == null:
			push_error("trying to get name on actor without state")
			return "<ERROR>"
		return self.state.name
	set(value):
		if self.state == null:
			push_error("tried to set name on actor without state")
			return
		self.state.name = value

## Emitted after this actor becomes inactive after having been inactive (ex. hp reduced to 0)
signal became_inactive()

## Emitted after this actor becomes active after having been inactive (ex. revived after being knocked out)
signal became_active()

## Emitted after this actor's state changes.
signal mutated()

## Emitted just before the actor begins choosing an action
signal taking_turn()

## Emitted after the actor has taken a turn
signal taken_turn()

func _init(ident: int, com: Combat, con: ActorControllerFactory, sta: ActorStateFactory) -> void:
	self.id = ident
	self.combat = com
	self.state = sta.initialize(self)
	self.controller = con.initialize(self)

	self.became_inactive.connect(self._on_became_inactive)
	self.became_active.connect(self._on_became_active)
	self.mutated.connect(self._on_mutated)

func take_turn() -> void:
	if self.state != null:
		if !self.state.begin_turn():
			return

	self.taking_turn.emit()

	if self.controller != null:
		var action := await self.controller.choose_action()
		if action != null:
			self.combat.push_action(action)

	if self.state != null:
		self.state.end_turn()

	self.taken_turn.emit()

func is_active() -> bool:
	return self.state != null && self.state.is_active()

func emit_inactive() -> void:
	self.became_inactive.emit()

func emit_active() -> void:
	self.became_inactive.emit()

func emit_mutated():
	self.mutated.emit()

func _on_became_inactive() -> void:
	if self.combat != null:
		self.combat._actor_became_inactive(self)

func _on_became_active() -> void:
	if self.combat != null:
		self.combat._actor_became_active(self)

func _on_mutated() -> void:
	if self.combat != null:
		self.combat._actor_mutated(self)
