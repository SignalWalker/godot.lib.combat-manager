## A state machine for running a battle
class_name Combat extends RefCounted

const ActQueue := preload("action/action_queue.gd")

enum CombatStatus {
	PENDING,
	ONGOING,
	ADVANCING,
	DONE
}

var status: CombatStatus = CombatStatus.PENDING
## Whether `end()` was called during advancement
var end_called: bool = false

## The description used to initialize this combat
var description: CombatDescription

## An object that determines turn order and whose functions are called in response to various state changes
var conductor: Conductor

## Root of the GUI for controlling this combat (if set)
var gui_root_ref: WeakRef

var gui_root: Node:
	get:
		return self.gui_root_ref.get_ref()
	set(value):
		self.gui_root_ref = weakref(value)

## Combatants, indexed by their ID (which is assigned as they're added to the combat)
var actors: Dictionary[int, Actor] = {}

## The next available actor ID.
var next_actor_id: int = 0

## Queue of actions that haven't yet been executed
var action_queue: ActQueue

## Callback for posting messages to the combat screen
var msg_callback: Callable = func(msg: Variant) -> void:
	if msg is String or msg is StringName:
		print_rich(msg)
	else:
		push_error("couldn't print message")

## Emitted after an actor is added to this combat.
signal actor_added(actor: Actor)

## Emitted after an actor is removed from this combat.
signal actor_removed(actor: Actor)

## Emitted after an actor becomes active after having been inactive
signal actor_became_active(actor: Actor)

## Emitted after an actor becomes inactive after having been active
signal actor_became_inactive(actor: Actor)

## Emitted after an actor's state changes
signal actor_mutated(actor: Actor)

## Emitted before an actor takes a turn.
signal actor_taking_turn(actor: Actor)

## Emitted after an actor takes a turn.
signal actor_taken_turn(actor: Actor)

## Emitted after an action is enqueued
signal action_enqueued(index: int, action: Action)

## Emitted after an action resolves
signal action_resolved(action: Action)

## Emitted after an action is removed from the queue without having resolved. [b][i]NOT[/i][/b] emitted for actions canceled by combat ending.
signal actions_canceled(actions: Array[Action])

## Emitted when there is at least one queued action and no actions are currently resolving
signal can_resolve_actions()

## Emitted after the last action in the queue is resolved (or canceled during resolution)
signal resolved_last_action()

## Emitted as this combat is starting
signal starting(is_started: bool)

## Emitted after successfully advancing combat
signal advanced(actors: Array[Actor])

## Emitted after finishing advancing for any reason.
signal finished_advancing()

## Emitted when `end()` is first called
signal ending()

## Emitted as this combat is ending
signal ended()

func _init(desc: CombatDescription, additional_actors: Array[CombatantDefinition]) -> void:
	self.description = desc
	self.action_queue = ActQueue.new(self)
	self.conductor = desc.instantiate_conductor(self)
	for com: CombatantDefinition in additional_actors:
		self.push_actor(com.controller, com.state)
	for com: CombatantDefinition in desc.combatants:
		self.push_actor(com.controller, com.state)

func start() -> void:
	if self.status != CombatStatus.PENDING:
		push_error("called start() on non-pending combat")
		return
	self.status = CombatStatus.ONGOING
	self.conductor.combat_starting()
	self.starting.emit()

func is_ongoing() -> bool:
	return self.status == CombatStatus.ONGOING

func is_advancing() -> bool:
	return self.status == CombatStatus.ADVANCING

func is_ongoing_or_advancing() -> bool:
	return self.status == CombatStatus.ONGOING || self.status == CombatStatus.ADVANCING

func is_ending() -> bool:
	return self.end_called

func is_done() -> bool:
	return self.status == CombatStatus.DONE

func _finish_advancing() -> void:
	self.status = CombatStatus.ONGOING
	self.finished_advancing.emit()

func advance() -> void:
	if self.end_called:
		push_warning("called advance() on combat that is currently ending")
		return

	if self.is_advancing():
		push_warning("called advance() on combat that is already advancing")
		await self.finished_advancing
		return

	if !self.is_ongoing():
		push_error("tried to advance non-ongoing combat")
		return

	self.status = CombatStatus.ADVANCING

	if !(await self.conductor.can_advance()):
		self._finish_advancing()
		return

	if self.end_called:
		# end() was called while waiting on conductor.can_advance()
		self._finish_advancing()
		return

	var turn_actors := await self.conductor.advance()

	self._finish_advancing()

	if self.end_called:
		# end() was called while waiting on conductor.advance()
		return

	self.conductor.combat_advanced(turn_actors)
	self.advanced.emit(turn_actors)

func end() -> void:
	if !self.is_ongoing_or_advancing():
		push_error("called end() on combat that is not currently ongoing or advancing")
		return

	if self.is_ending():
		push_warning("called end() on combat that is already ending")
		await self.ended
		return

	self.end_called = true
	self.conductor.combat_ending()
	self.ending.emit()

	if self.is_advancing():
		await self.finished_advancing

	self.status = CombatStatus.DONE

	self.conductor.combat_ended()
	self.ended.emit()


func wait_ended() -> Variant:
	match self.status:
		CombatStatus.PENDING:
			return await self.ended
		CombatStatus.ONGOING:
			return await self.ended
		CombatStatus.DONE:
			return true
		_:
			assert(false, "unreachable")
			return null

func post_message(msg: Variant) -> void:
	await self.msg_callback.call(msg)

## Add an actor and return its assigned ID.
func push_actor(con: ActorControllerFactory, state: ActorStateFactory) -> int:
	var actor: Actor = Actor.new(self.next_actor_id, self, con, state)
	self.next_actor_id += 1
	self.actors[actor.id] = actor

	self.conductor.actor_added(actor)
	self.actor_added.emit(actor)

	return actor.id


## Remove an actor and return it, if the given ID is present in the actor dictionary.
func pop_actor(id: int) -> Actor:
	if id not in self.actors:
		return null
	var actor: Actor = self.actors[id]
	self.actors.erase(id)

	self.conductor.actor_removed(actor)
	self.actor_removed.emit(actor)

	return actor

## Insert an action ticket at the specified position.
##
## If you want to push an action to the end of the queue, please use [code]push_action[/code] instead.
func insert_action(index: int, action: Action) -> void:
	self.action_queue.insert(index, action)

	self.conductor.action_enqueued(index, action)
	self.action_enqueued.emit(index, action)

	if self.can_resolve_an_action():
		self.can_resolve_actions.emit()

## Push an action to the end of the queue.
func push_action(action: Action) -> void:
	self.insert_action(self.action_queue.size(), action)

## Whether an action is currently being resolved
func is_resolving() -> bool:
	return self.action_queue.is_resolving()

## Returns true if this is ongoing or advacning, there's at least one action queued, and there is not currently an action resolving
func can_resolve_an_action() -> bool:
	return !self.end_called && self.is_ongoing_or_advancing() && self.action_queue.can_resolve()

## Pop the next valid action and resolve it, if it exists and we're not already resolving it.
func resolve_next_action() -> void:
	var res := await self.action_queue.resolve_next()

	# NOTE :: checked end_called in action_queue.resolve_next, so we don't need to do that here

	if res.handled:
		return

	res.handled = true

	if !res.canceled.is_empty():
		for act: Action in res.canceled:
			act.canceled.emit()

		self.conductor.actions_canceled(res.canceled)
		self.actions_canceled.emit(res.canceled)

	if res.action != null:
		self.conductor.action_resolved(res.action)
		self.action_resolved.emit(res.action)

	if self.action_queue.is_empty():
		# that was the last action in the queue
		self.conductor.resolved_last_action()
		self.resolved_last_action.emit()

	if self.can_resolve_an_action():
		self.can_resolve_actions.emit()

func _actor_became_inactive(a: Actor) -> void:
	assert(a.id in self.actors)
	self.actor_became_inactive.emit(a)

func _actor_became_active(a: Actor) -> void:
	assert(a.id in self.actors)
	self.actor_became_active.emit(a)

func _actor_mutated(a: Actor) -> void:
	assert(a.id in self.actors)
	self.actor_mutated.emit(a)

func _actor_taking_turn(a: Actor) -> void:
	assert(a.id in self.actors)
	self.actor_taking_turn.emit(a)

func _actor_taken_turn(a: Actor) -> void:
	assert(a.id in self.actors)
	self.actor_taken_turn.emit(a)

# [--------] ACTOR ITERATORS [--------]

## An iterator over all actors where `is_active() == true`
func active_actors() -> Iterator:
	return Iterator.filter(self.actors, func(a: Actor) -> bool: return a.is_active())
