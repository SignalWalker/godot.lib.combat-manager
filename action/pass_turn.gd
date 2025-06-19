class_name PassTurn extends Action

func _init(act: Actor) -> void:
	super(act)

func get_valid_targets(_com: Combat, exec: Variant) -> Array[Actor]:
	if exec is Actor:
		return [exec as Actor]
	elif exec is Array[Actor]:
		return exec as Array[Actor]
	else:
		return []

func could_be_valid(_com: Combat, exec: Variant) -> bool:
	return exec != null && (exec is Actor || exec is Array[Actor])

func get_target_count(_com: Combat, _exec: Variant) -> int:
	return 1

func is_valid() -> bool:
	if self.executor is Actor:
		return (self.executor as Actor).is_active()
	elif self.executor is Array[Actor]:
		return (self.executor as Array[Actor]).all(func(a: Actor) -> bool: return a.is_active())
	return false

func resolve() -> void:
	await (self.executor as Actor).combat.post_message("{0} waits...".format([(self.executor as Actor).state.name]))
