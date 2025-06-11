class_name SCombatManager extends Node

var default_combat_scene: PackedScene

func _init() -> void:
	var path: Variant = CombatManagerSettings.get_setting(CombatManagerSettings.DEFAULT_COMBAT_SCENE_PATH, null)
	assert(path != null && (path is StringName || path is String), "must set combat_manager/%s" % CombatManagerSettings.DEFAULT_COMBAT_SCENE_PATH)
	default_combat_scene = load(path)

func _load_combat(description: Variant) -> CombatDescription:
	if description is CombatDescription:
		return description
	elif description is String or description is StringName:
		var desc: Variant = ResourceLoader.load(description as String)
		if desc is not CombatDescription:
			printerr("could not load combat description: resource at path ", description as String, " is not a combat description (found: ", desc, ")")
			return null
		return desc as CombatDescription
	else:
		printerr("first argument to start_combat must be either String-like or CombatDescription")
		return null

func start_combat(description: Variant) -> Combat:
	var desc: CombatDescription = self._load_combat(description)
	if desc == null:
		# already printed errors
		return null
	# gui
	var combat_screen: Node = (preload("res://gui/combat.tscn") as PackedScene).instantiate()
	# party members
	var party_members: Array[CombatantDefinition] = []
	for p: PartyMember in StateManager.active_party_members():
		party_members.push_back(p.combatant_definition())
	# start
	var combat: Combat = Combat.new(desc, party_members)
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
