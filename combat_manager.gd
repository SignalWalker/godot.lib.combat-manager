class_name SCombatManager extends Node

var default_combat_scene: PackedScene

## A function taking a single parameter (the combat description) and returning an iterator over items of type CombatantDefinition
var get_party_members: Callable = func(_desc: CombatDescription) -> Variant: return []:
	get:
		return get_party_members
	set(value):
		assert(value.is_valid(), "get_party_members must be valid")
		assert(value.get_argument_count() == 1, "get_party_members must take one argument (the combat description)")
		# wish i could check for return value, but alas...
		get_party_members = value

func _init() -> void:
	var path: Variant = CombatManagerSettings.get_setting(CombatManagerSettings.DEFAULT_COMBAT_SCENE_PATH, null)
	assert(path != null && (path is StringName || path is String), "must set combat_manager/%s" % CombatManagerSettings.DEFAULT_COMBAT_SCENE_PATH)
	default_combat_scene = load(path)

func _load_combat(description: Variant) -> CombatDescription:
	assert(description != null && (description is CombatDescription || description is String || description is StringName), "first argument to start_combat must be non-null and either a CombatDescription or a String-like path to a CombatDescription")
	if description is CombatDescription:
		return description
	else:
		var desc: Variant = ResourceLoader.load(description as String)
		assert(desc is CombatDescription, "could not load combat description: resource at path {0} is not a combat description (found: {1})".format([description as String, desc]))
		return desc as CombatDescription

func start_combat(description: Variant, additional_actors: Variant = []) -> Combat:
	var desc: CombatDescription = self._load_combat(description)
	# gui
	var combat_screen: Node = default_combat_scene.instantiate()
	# party members
	var extra_actors: Array[CombatantDefinition] = []
	for party_member: CombatantDefinition in self.get_party_members.call(desc):
		extra_actors.push_back(party_member)
	for add: CombatantDefinition in additional_actors:
		extra_actors.push_back(add)
	# start
	var combat: Combat = Combat.new(desc, extra_actors)
	self._start_combat(combat_screen, combat)
	return combat

func _start_combat(combat_screen: Node, state: Combat) -> void:
	if combat_screen.has_method(&"start"):
		# instantiate transition
		var transition_class: GDScript = state.description.transition
		var transition: Node = null
		if transition_class != null:
			if !transition_class.can_instantiate():
				printerr("cannot instantiate instance of combat transition: ", transition_class)
			transition = transition_class.new()
			if transition is not Node:
				printerr("instantiated combat transition is not a Node: ", transition)
				transition = null
		if transition == null:
			transition = SwirlTransition.new()
		# push overlay
		var ovl: SceneManager.Overlay = SceneManager.push_overlay(combat_screen, transition)
		if !(await ovl.wait_active()):
			printerr("could not start combat: could not push combat screen overlay, status: ")
			return
		state.gui_root_ref = weakref(combat_screen)
		combat_screen.call(&"start", state)
	else:
		printerr("could not start combat: could not call [code]combat_screen.start[/code]")
