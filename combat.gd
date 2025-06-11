## A state machine for running a battle
class_name Combat extends RefCounted

## An enqueued action
class Ticket extends RefCounted:
	## The ID of this ticket. Used for external identification.
	var id: int
	## A [b][i]coroutine[/i][/b] [code]func(combat: Combat, actor: Actor, targets: Array<Actor>) -> void[/code] defining the effect of the action
	var action: Action

	func _init(ident: int, tion: Action) -> void:
		self.id = ident
		self.action = tion
		if self.action.ticket != null:
			printerr("action already assigned to ticket...?")
		self.action.ticket_ref = weakref(self)

	func is_valid() -> bool:
		return self.action._is_valid()

	func resolve() -> void:
		await self.action._resolve()
		self.action.resolved.emit()

enum CombatStatus {
	PENDING,
	ONGOING,
	DONE
}

var status: CombatStatus = CombatStatus.PENDING

## The description used to initialize this combat
var description: CombatDescription

## An object whose functions are called in response to various state changes
var conductor: ConductorFactory.Conductor

## Manages turn order
var turn_manager: TurnManagerFactory.TurnManager

## Root of the GUI for controlling this combat (if set)
var gui_root_ref: WeakRef

## Combatants, indexed by their ID (which is assigned as they're added to the combat)
var actors: Dictionary[int, Actor] = {}

## The next available actor ID.
var next_actor_id: int = 0

## The next available ticket ID.
var next_ticket_id: int = 0

## Queue of actions that haven't yet been executed
var action_queue: Array[Ticket] = []

## Callback for posting messages to the combat screen
var msg_callback: Callable = func(msg: Variant) -> void:
	if msg is String or msg is StringName:
		print_rich(msg)
	else:
		printerr("couldn't print message")

## Emitted after an actor is added to this combat.
signal actor_added(actor: Actor)

## Emitted after an actor is removed from this combat.
signal actor_removed(actor: Actor)

## Emitted after an action is enqueued
signal action_enqueued(index: int, action: Ticket)

## Emitted after an action resolves
signal action_resolved(action: Ticket)

## Emitted after an action is removed from the queue without having resolved. [b][i]NOT[/i][/b] emitted for actions canceled by combat ending.
signal actions_canceled(actions: Array[Ticket])

## Emitted as this combat is starting
signal starting(is_started: bool)

## Emitted as this combat is ending
signal ending(is_done: bool)

func _init(desc: CombatDescription, additional_actors: Array[CombatantDefinition]) -> void:
	self.description = desc
	self.turn_manager = desc.turn_manager._initialize(self)
	self.conductor = desc.conductor._initialize(self)
	for com: CombatantDefinition in additional_actors:
		self.push_actor(com.controller, com.state)
	for com: CombatantDefinition in desc.combatants:
		self.push_actor(com.controller, com.state)

func gui_root() -> Control:
	if self.gui_root_ref != null:
		return self.gui_root_ref.get_ref()
	else:
		return null

func start() -> void:
	if self.status != CombatStatus.PENDING:
		printerr("called start() on non-pending combat")
		return
	self.status = CombatStatus.ONGOING
	self.conductor._combat_starting()
	self.starting.emit()

func end() -> void:
	if self.status != CombatStatus.ONGOING:
		printerr("called end() on non-started combat")
		return
	self.status = CombatStatus.DONE
	self.conductor._combat_ending()
	self.ending.emit()

func wait_ended() -> Variant:
	match self.status:
		CombatStatus.PENDING:
			return await self.ending
		CombatStatus.ONGOING:
			return await self.ending
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

	self.conductor._actor_added(actor)
	self.turn_manager._actor_added(actor)
	self.actor_added.emit(actor)

	return actor.id

## Clear action queue of all actions that are no longer valid.
func clear_invalid_actions() -> void:
	var tickets: Array[Ticket] = []
	# iterate backward through the action queue
	for index: int in range(self.action_queue.size() - 1, -1, -1):
		var ticket: Ticket = self.action_queue[index]
		if !ticket.is_valid():
			# we're iterating backward, so it's fine to remove the current element, because the position of the next element won't change
			tickets.push_back(self.action_queue.pop_at(index))

	self.conductor._actions_canceled(tickets)
	self.actions_canceled.emit(tickets)

## Remove an actor and return it, if the given ID is present in the actor dictionary.
func remove_actor(id: int) -> Actor:
	if id not in self.actors:
		return null
	var actor: Actor = self.actors[id]
	self.actors.erase(id)
	self.clear_invalid_actions()

	self.conductor._actor_removed(actor)
	self.actor_removed.emit(actor)

	return actor

## Get the next action in the queue, if there is one
func peek_action() -> Ticket:
	if self.action_queue.is_empty():
		return null
	return self.action_queue[0]

## Insert an action ticket at the specified position.
##
## If you want to push an action to the end of the queue, please use [code]push_action[/code] instead.
func insert_action(index: int, action: Action) -> void:
	if action.combat_ref != null:
		printerr("action already assigned to combat...?")
	action.combat_ref = weakref(self)

	var ticket: Ticket = Ticket.new(self.next_ticket_id, action)
	self.next_ticket_id += 1

	self.action_queue.insert(index, ticket)

	self.conductor._action_enqueued(index, ticket)
	self.action_enqueued.emit(index, ticket)

## Push an action to the end of the queue.
func push_action(action: Action) -> void:
	self.insert_action(self.action_queue.size(), action)

## Pop the next valid action and resolve it, if it exists
func resolve_next_action() -> void:
	var act: Ticket = null
	var invalid_actions: Array[Ticket] = []
	# get the next valid action
	while !self.action_queue.is_empty():
		act = self.action_queue.pop_front()
		if act.is_valid():
			break
		else:
			invalid_actions.push_back(act)

	# handle invalid actions
	if !invalid_actions.is_empty():
		self.conductor._actions_canceled(invalid_actions)
		self.actions_canceled.emit(invalid_actions)

	if act == null:
		# no queued valid actions
		return

	await act.resolve()

	# emit resolution events
	self.conductor._action_resolved(act)
	self.action_resolved.emit(act)

# [--------] ACTOR ITERATORS [--------]

## An iterator over all actors matching the given predicate [code]func(actor: Actor) -> bool[/code]
func iter_with(pred: Callable) -> ActorIter:
	return ActorIter.new(self, pred)

class ActorIter extends RefCounted:
	var combat: Combat
	var pred: Callable

	var remaining_ids: Array[int]
	var current_id: int

	func _init(com: Combat, p: Callable) -> void:
		self.combat = com
		self.pred = p
		self._iter_init([])

	func pop_id() -> bool:
		if self.remaining_ids.is_empty():
			# no more actors
			return false
		# advance
		self.current_id = self.remaining_ids.pop_back()
		# skip over IDs that are no longer in the actor dictionary
		while self.current_id not in self.combat.actors && !self.remaining_ids.is_empty():
			self.current_id = self.remaining_ids.pop_back()
		# return whether this ID is in the actor dict (which might not be true, if we ran out of IDs while skipping above)
		return self.current_id in self.combat.actors

	func check_current() -> bool:
		return self.pred.call(self._iter_get(null))

	func _iter_init(_iter: Array) -> bool:
		self.remaining_ids = self.combat.actors.keys()
		return self._iter_next([])

	func _iter_next(_iter: Array) -> bool:
		# Advance to the next valid ID
		if !self.pop_id():
			return false
		# Skip over actors that don't satisfy the predicate
		while !self.check_current():
			if !self.pop_id():
				# no more valid IDs; quit
				return false
		# current ID is valid and points to an actor that satisfies the predicate
		return true

	func _iter_get(_iter: Variant) -> Actor:
		return self.combat.actors[self.current_id]



# ## Iterator over all combatants matching the given predicate [code]func(faction: int, actor: Actor) -> bool[/code]
# func iter_with(pred: Callable) -> CombatantIter:
# 	return CombatantIter.new(self, pred)
#
# ## Iterator over all combatants
# func iter() -> CombatantIter:
# 	return self.iter_with(func(_faction: int, _actor: Actor) -> bool: return true)
#
# ## Iterator over all combatants outside the party
# func enemies() -> CombatantIter:
# 	return self.iter_with(func(faction: int, _actor: Actor) -> bool: return faction != 0)
#
# ## Iterator over all combatants within the party
# func party_members() -> CombatantIter:
# 	return self.iter_with(func(faction: int, _actor: Actor) -> bool: return faction == 0)
#
# ## An iterator over all enemies in a combat
# class CombatantIter:
# 	var combat: Combat
# 	var pred: Callable
#
# 	var remaining_factions: Array[int]
# 	var current_faction: int = 0
# 	var current_index: int = 0
#
# 	func _init(com: Combat, p: Callable) -> void:
# 		self.combat = com
# 		self.pred = p
# 		self._iter_init([])
#
# 	## Whether we're done iterating over the current faction
# 	func faction_complete() -> bool:
# 		# if the current faction is empty, if it's been removed from the combat, or if we've iterated past its end
# 		return self.current_faction not in combat.factions || combat.factions[current_faction].size() <= self.current_index
#
# 	## Whether there's more elements over which to iterate
# 	func finished() -> bool:
# 		# if there are no remaining factions and we're done with the current faction
# 		return self.remaining_factions.is_empty() && self.faction_complete()
#
# 	## Begin iteration over the next faction.
# 	func pop_faction() -> bool:
# 		if self.remaining_factions.is_empty():
# 			return false
# 		self.current_index = 0
# 		self.current_faction = self.remaining_factions.pop_back()
# 		return true
#
# 	## Call [code]self.pred[/code] for the current faction & actor.
# 	func check_current() -> bool:
# 		return self.pred.call(self.current_faction, self._iter_get(null))
#
# 	func _iter_init(_iter: Array) -> bool:
# 		self.remaining_factions = self.combat.factions.keys()
# 		# initialize faction & index
# 		self.pop_faction()
# 		# check whether there's a first item
# 		if self.finished():
# 			return false
# 		# skip over items that don't match our predicate
# 		if !self.check_current():
# 			if !self._iter_next([]):
# 				# skipped over everything, quit
# 				return false
# 		return !self.finished()
#
# 	## Advance to the next item (without checking whether it satisfies the predicate), and return whether we successfully advanced
# 	func advance() -> bool:
# 		self.current_index += 1
# 		# pop the current faction if we're done with it, and skip over empty factions
# 		while self.faction_complete():
# 			if !self.pop_faction():
# 				return false
# 		return !self.finished()
#
# 	func _iter_next(_iter: Array) -> bool:
# 		# try to advance, and return false if there's no next item
# 		if !self.advance():
# 			return false
# 		# skip over items that fail the predicate
# 		while !self.check_current():
# 			# try to advance, exit if we're done
# 			if !self.advance():
# 				return false
# 		# advanced successfully, and the current item satisfies the predicate
# 		return true
#
# 	func _iter_get(_iter: Variant) -> Actor:
# 		return self.combat.factions[self.current_faction][self.current_index]
