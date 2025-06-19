extends Node

const CMSettings := preload("./settings.gd")

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

## A function that adds the combat screen to the scene
var add_screen_to_scene: Callable = func(_combat: Combat, screen: Node) -> void:
	self.get_tree().root.add_child(screen)

func _init() -> void:
	var path: Variant = CMSettings.get_setting(CMSettings.DEFAULT_COMBAT_SCENE_PATH, null)
	assert(path != null && (path is StringName || path is String), "must set combat_manager/%s" % CMSettings.DEFAULT_COMBAT_SCENE_PATH)
	default_combat_scene = load(path)

func _load_combat(description: Variant) -> CombatDescription:
	assert(description != null && (description is CombatDescription || description is String || description is StringName), "first argument to start_combat must be non-null and either a CombatDescription or a String-like path to a CombatDescription")
	if description is CombatDescription:
		return description
	else:
		var desc: Variant = ResourceLoader.load(description as String)
		assert(desc is CombatDescription, "could not load combat description: resource at path {0} is not a combat description (found: {1})".format([description as String, desc]))
		return desc as CombatDescription

func start_combat(description: Variant, additional_actors: Variant = [], defer: bool = true) -> Combat:
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
	if defer:
		self._start_combat.call_deferred(combat_screen, combat)
	else:
		self._start_combat(combat_screen, combat)
	return combat

func _start_combat(combat_screen: Node, state: Combat) -> void:
	if combat_screen.has_method(&"start"):
		# add screen to scene
		state.gui_root = combat_screen
		combat_screen.ready.connect(func() -> void:
			combat_screen.call(&"start", state)
		)
		self.add_screen_to_scene.call(state, combat_screen)
	else:
		push_error("could not start combat: could not call [code]combat_screen.start[/code]")
