extends RefCounted

## An enqueued action
class Ticket extends RefCounted:

	var next: Ticket

	## A [b][i]coroutine[/i][/b] [code]func(combat: Combat, actor: Actor, targets: Array<Actor>) -> void[/code] defining the effect of the action
	var action: Action

	func _init(n: Action) -> void:
		self.action = n

	func is_valid() -> bool:
		return self.action != null && self.action.is_valid()

	func push(tk: Ticket) -> void:
		var old := self.next
		self.next = tk
		tk.next = old

	func pop(prev: Ticket) -> Action:
		if prev != null:
			prev.next = self.next
		self.next = null
		return self.action

class TicketQueue extends RefCounted:
	var front: Ticket = null
	var back: Ticket = null
	var size: int = 0

	func _new_ticket(com: Combat, act: Action) -> Ticket:
		act.combat = com
		var tk := Ticket.new(act)
		return tk

	func is_empty() -> bool:
		return self.size == 0

	func push(com: Combat, act: Action) -> Ticket:
		var tk := self._new_ticket(com, act)

		if self.front == null:
			self.front = tk
		else:
			self.back.push(tk)

		self.back = tk

		self.size += 1

		print("action pushed by {0} at index {1}".format([act.executor.name, self.size - 1]))

		return tk

	func pop() -> Ticket:
		if self.front == null:
			return null

		var res := self.front
		var next := res.next
		res.next = null

		self.front = next
		if next == null:
			self.back = null

		self.size -= 1

		return res

	func get_at(index: int) -> Ticket:
		if index >= self.size:
			return null
		var res := self.front
		while index > 0:
			res = res.next
			index -= 1
		return res

	func insert(com: Combat, index: int, act: Action) -> Ticket:
		assert(index >= 0)

		if index >= self.size:
			return self.push(com, act)

		var tk := self._new_ticket(com, act)
		if index == 0:
			tk.next = self.front
			self.front = tk
		else:
			var prev := self.get_at(index - 1)
			prev.next = tk

		self.size += 1

		print("action inserted by {0} at index {1}".format([act.executor.name, index]))

		return tk

	func _iter_init(state: Array) -> bool:
		state[0] = self.front
		return state[0] != null

	func _iter_next(state: Array) -> bool:
		var next := (state[0] as Ticket).next
		state[0] = next
		return next != null

	func _iter_get(state: Variant) -> Ticket:
		return state[0] as Ticket

class ActionTuple extends RefCounted:
	var action: Action
	var canceled: Array[Action]
	var handled: bool = false

	func _init(a: Action = null, c: Array[Action] = []) -> void:
		self.action = a
		self.canceled = c

	func cancel() -> void:
		if self.action != null:
			self.canceled.push_back(self.action)
			self.action = null

enum QueueStatus {
	READY,
	RESOLVING
}

var combat_ref: WeakRef
var combat: Combat:
	get:
		if self.combat_ref == null:
			return null
		return self.combat_ref.get_ref()
	set(value):
		self.combat_ref = weakref(value)

var status: QueueStatus = QueueStatus.READY

var queue: TicketQueue = TicketQueue.new()

signal finished_or_canceled_resolving(res: ActionTuple)

func _init(com: Combat) -> void:
	self.combat = com


func push(act: Action) -> void:
	self.queue.push(self.combat, act)

func pop() -> Action:
	if self.queue.is_empty():
		return null
	return self.queue.pop().action

## Returns (Action, Array[Action]), where res[0] is the first valid action (or null) and res[1] is all popped invalid actions
func pop_first_valid() -> ActionTuple:
	var res: Action = null
	var invalid_actions: Array[Action] = []
	# get the next valid action
	while !self.queue.is_empty():
		var front: Action = self.queue.pop().action
		if front.is_valid():
			res = front
			break
		else:
			invalid_actions.push_back(front)

	return ActionTuple.new(res, invalid_actions)

func peek() -> Action:
	if self.queue.is_empty():
		return null
	return self.queue.front.action

func insert(index: int, action: Action) -> void:
	self.queue.insert(self.combat, index, action)

func size() -> int:
	return self.queue.size

func is_empty() -> bool:
	return self.queue.is_empty()

func get_at(index: int) -> Action:
	var res := self.queue.get_at(index)
	if res == null:
		return null
	return res.action

func clear_invalid_actions() -> Array[Action]:
	var actions: Array[Action] = []
	var prev: Ticket = null
	var current: Ticket = self.queue.front
	while current != null:
		var next := current.next

		if current.is_valid():
			prev = current
		else:
			actions.push_back(current.pop(prev))

		current = next

	return actions

func is_ready() -> bool:
	return self.status == QueueStatus.READY

func is_resolving() -> bool:
	return self.status == QueueStatus.RESOLVING

func can_resolve() -> bool:
	return self.is_ready() && !self.is_empty()

func _finish_resolving(res: ActionTuple) -> void:
	self.status = QueueStatus.READY
	self.finished_or_canceled_resolving.emit(res)


func resolve_next() -> ActionTuple:
	if self.is_resolving():
		return await self.finished_or_canceled_resolving

	self.status = QueueStatus.RESOLVING

	if self.is_empty():
		self._finish_resolving(ActionTuple.new())
		return ActionTuple.new()

	var res := self.pop_first_valid()

	if res.action != null:
		if (await self.combat.conductor.can_resolve(res.action)):
			if self.combat.end_called:
				res.cancel()
			else:
				await res.action.resolve()
				res.action.resolved.emit()
		else:
			res.cancel()

	self._finish_resolving(res)

	return res

func _iter_init(state: Array) -> bool:
	return self.queue._iter_init(state)

func _iter_next(state: Array) -> bool:
	return self.queue._iter_next(state)

func _iter_get(state: Variant) -> Action:
	return self.queue._iter_get(state).action
