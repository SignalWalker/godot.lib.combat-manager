class_name CombatDescription extends Resource

## The initial list of enemies in this combat
@export var combatants: Array[CombatantDefinition] = []

@export var turn_manager: TurnManagerFactory

## Script for mid-battle events, etc., if set
@export var conductor: ConductorFactory = ConductorFactory.new()
