class_name PassTurn extends Action

func _init(act: Actor) -> void:
	super(act)

func get_valid_targets(_com: Combat, exec: Variant) -> Array[Actor]:
	if exec is Actor && (exec as Actor).is_active():
		return [exec as Actor]
	elif exec is Array[Actor] && Action.iterable_is_active(exec as Array[Actor]):
		return exec as Array[Actor]
	else:
		return []

func could_be_valid(_com: Combat, exec: Variant) -> bool:
	return Action.variant_is_active(exec)

func get_target_count(_com: Combat, _exec: Variant) -> int:
	return 1

func is_valid() -> bool:
	return self.could_be_valid(self.combat, self.executor)

func resolve() -> void:
	if self.executor is Actor:
		await (self.executor as Actor).combat.post_message("{0} waits...".format([(self.executor as Actor).state.name]))
	elif self.executor is Array[Actor]:
		for a: Actor in (self.executor as Array[Actor]):
			await a.combat.post_message("{0} waits...".format([a.name]))
