class_name PassTurn extends Action

func _init(act: Actor) -> void:
	super(act)

func _get_valid_targets() -> Array[Actor]:
	return [self.executor]

func _is_valid() -> bool:
	return (self.executor as Actor).combat().actors.has((self.executor as Actor).id)

func _resolve() -> void:
	await (self.executor as Actor).combat().post_message("{} waits...".format([(self.executor as Actor).state.name]))

