class_name StateMachine

extends Node

@export var currentState : State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			states[child.name] = child
		else:
			push_warning("State machine has incompatible child node")
			
