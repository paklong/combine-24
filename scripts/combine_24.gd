extends Node2D

#region Select all children
const NUMBER_TILE = preload("res://scenes/number_tile.tscn")
const OPERATOR_TILE = preload("res://scenes/operator_tile.tscn")

@onready var answer_bar: PanelContainer = %AnswerBar
@onready var answer_bar_container: HBoxContainer = $AnswerBar/AnswerBarContainer

@onready var number_row: PanelContainer = %NumberRow
@onready var operator_row: PanelContainer = %OperatorRow

@onready var number_tile_1: PanelContainer = $NumberRow/HBoxContainer/NumberTile1
@onready var number_tile_2: PanelContainer = $NumberRow/HBoxContainer/NumberTile2
@onready var number_tile_3: PanelContainer = $NumberRow/HBoxContainer/NumberTile3
@onready var number_tile_4: PanelContainer = $NumberRow/HBoxContainer/NumberTile4

@onready var operator_tile_open: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileOpen
@onready var operator_tile_plus: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTilePlus
@onready var operator_tile_minus: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileMinus
@onready var operator_tile_multiply: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileMultiply
@onready var operator_tile_division: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileDivision
@onready var operator_tile_closed: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileClosed

@onready var operator_tile_undo: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileUndo
@onready var operator_tile_redo: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileRedo
@onready var operator_tile_ans: PanelContainer = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileAns

@onready var answer_label: RichTextLabel = %AnswerLabel
@onready var reset_image: Sprite2D = $AnswerBar/ResetImage
@onready var reset_button: Button = $AnswerBar/ResetImage/ResetButton





@onready var number_tiles := [
	number_tile_1,
	number_tile_2,
	number_tile_3,
	number_tile_4
]

@onready var operator_tiles := {
	operator_tile_plus: '+',
	operator_tile_minus: '-',
	operator_tile_multiply: '×',
	operator_tile_division: '÷',
	operator_tile_open: '(',
	operator_tile_undo: '<',
	operator_tile_redo: '>',
	operator_tile_closed: ')',
	operator_tile_ans: 'Ans'
}

#endregion

var actions := []
var undo := []
var answer := 0.0

func _ready() -> void:
	for _number_tile in number_tiles:
		_number_tile.number_tile_press.connect(_on_number_tile_press)
	
	get_random_tiles()
	
	for _operator_tile in operator_tiles:
		_operator_tile.update_operator(operator_tiles[_operator_tile])
		_operator_tile.operator_tile_press.connect(_on_operator_tile_press)
		
	clear_answer_bar()
	answer_bar.reset_button_pressed.connect(_on_answer_bar_reset_button_pressed)
	reset_image.position = Vector2(480, 510)
	
func _on_number_tile_press(_number_tile, number):
	print ('Tile pressed: %d' % number) 
	add_to_actions('number', number, _number_tile)
	
func get_random_tiles():
	for _number_tile in number_tiles:
		_number_tile.generate_random_numer()
		
func _on_operator_tile_press(_operator_tile, operator):
	print ('Operator pressed: %s' % operator)
	if operator in ['+','-','×','÷']:
		add_to_actions('operator', operator, _operator_tile)
	elif operator in ['<', '>', 'Ans']:
		add_to_actions('special operator', operator, _operator_tile)
	elif operator in ['(', ')']:
		add_to_actions('parentheses operator', operator, _operator_tile)
		
func clear_answer_bar():
	for answer_bar_tile in answer_bar_container.get_children():
		answer_bar_tile.call_deferred("queue_free")

func _on_answer_bar_reset_button_pressed():
	clear_answer_bar()
	for _number_tile in number_tiles:
		_number_tile.enable_tile()
	actions = []
	undo = []
	answer = 0.0	

func add_to_actions(action_type, value, tile_reference=null):
	if action_type == 'number':
		if rules_check(action_type):
			# Append both the value and the tile reference as a tuple
			actions.append([value, tile_reference])
			tile_reference.disable_tile()  # Disable the tile after it's used
			undo = []
			process_action()

	elif action_type == 'operator':
		if rules_check(action_type):
			actions.append([value, tile_reference])
			undo = []
			process_action()

	elif action_type == 'parentheses operator':
		if value == '(':
			if rules_check(action_type, value):
				actions.append([value, tile_reference])
				undo = []
				process_action()
		elif value == ')':
			if rules_check(action_type, value):  # Ensure valid placement of ')'
				actions.append([value, tile_reference])
				undo = []
				process_action()

	elif action_type == 'special operator':
		if value == '<':  # Undo
			if actions.size() > 0:
				var last_action = actions.pop_back()
				undo.append(last_action)

				# Re-enable the tile if the last action was a number tile
				if last_action[1] != null and last_action[1].has_method("enable_tile"):
					last_action[1].enable_tile()

				# Handle undo for "Ans" (return to the previous state)
				if actions.size() > 0:
					var last_value = actions[-1][0]
					if typeof(last_value) in [TYPE_INT, TYPE_FLOAT] and last_value == answer:
						var ans_action = actions.pop_back()
						undo.append(ans_action)
						# Re-enable the number tile if the previous action was a number
						if ans_action[1] != null and ans_action[1].has_method("enable_tile"):
							ans_action[1].enable_tile()

				process_action()

		elif value == '>':  # Redo
			if undo.size() > 0:
				var redo_action = undo.pop_back()
				actions.append(redo_action)
				# Disable the tile again if the redo action was a number tile
				if redo_action[1] != null and redo_action[1].has_method("disable_tile"):
					redo_action[1].disable_tile()
				process_action()

		elif value == 'Ans':
			# Evaluate the current expression and replace with "Ans"
			evaluate_actions()

			# Save the state before clearing for "Ans"
			if actions.size() > 0:
				undo.append(actions.duplicate())

			actions.clear()
			actions.append([answer, tile_reference])  # Use the last answer
			process_action()


			
func rules_check(action_type, value=null) -> bool:
	if action_type == 'number':
		# Numbers can be placed at the start, after an operator, or after an opening parenthesis
		if actions.size() == 0:  # First input must be a number or '('
			return true
		var last_action = actions[-1][0]  # Access the value part of the tuple
		if typeof(last_action) == TYPE_STRING and last_action in ['+', '-', '×', '÷', '(']:
			return true

	elif action_type == 'operator':
		# Operators can be placed after a number or a closing parenthesis
		if actions.size() > 0:
			var last_action = actions[-1][0]  # Access the value part of the tuple
			if typeof(last_action) == TYPE_INT or typeof(last_action) == TYPE_FLOAT or last_action == ')':
				return true

	elif action_type == 'parentheses operator':
		if value == '(':
			# '(' can be placed at the start, after an operator, or after another '('
			if actions.size() == 0:  # First input can be '('
				return true
			var last_action = actions[-1][0]  # Access the value part of the tuple
			if typeof(last_action) == TYPE_STRING and last_action in ['+', '-', '×', '÷', '(']:
				return true
		elif value == ')':
			# ')' can be placed after a number or another ')', and must have a matching '('
			if actions.size() > 0:
				var last_action = actions[-1][0]  # Access the value part of the tuple
				if typeof(last_action) == TYPE_INT or typeof(last_action) == TYPE_FLOAT or last_action == ')':
					# Ensure there's a matching '('
					var open_parentheses_count = 0
					var close_parentheses_count = 0
					for action in actions:
						if typeof(action[0]) == TYPE_STRING:
							if action[0] == '(':
								open_parentheses_count += 1
							elif action[0] == ')':
								close_parentheses_count += 1
					if open_parentheses_count > close_parentheses_count:
						return true

	return false




func process_action():
	print('undo: ' + str(undo))
	print('actions: ' + str(actions))

	# Clear the existing children in the container
	clear_answer_bar()
	for i in range(actions.size()):
		var value = actions[i][0]  # Access the value part of the tuple
		var tile
		if typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT:
			tile = NUMBER_TILE.instantiate()  # Or use the appropriate node type
			answer_bar_container.add_child(tile)
			tile.update_number(value)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
		elif typeof(value) == TYPE_STRING:
			tile = OPERATOR_TILE.instantiate()  # Or use the appropriate node type
			answer_bar_container.add_child(tile)
			tile.update_operator(value)
			tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
		tile.disable_button()
		
	evaluate_actions()
	#print(answer)


	
func evaluate_actions():
	var operand_stack = []  # Stack to hold numbers and intermediate results
	var operator_stack = []  # Stack to hold operators and parentheses

	var i = 0
	while i < actions.size():
		var current = actions[i][0]  # Access the value part of the tuple

		if typeof(current) == TYPE_INT or typeof(current) == TYPE_FLOAT:
			operand_stack.append(current)

		elif current == '(':
			operator_stack.append(current)

		elif current == ')':
			# Pop from stacks and evaluate until '(' is found
			while operator_stack.size() > 0 and operator_stack[-1] != '(':
				if operand_stack.size() < 2:
					return  # Incomplete expression, defer evaluation
				operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))
			operator_stack.pop_back()  # Remove '('

		elif current in ['+', '-', '×', '÷']:
			# Pop from stack and evaluate based on operator precedence
			while operator_stack.size() > 0 and precedence(operator_stack[-1]) >= precedence(current):
				if operand_stack.size() < 2:
					return  # Incomplete expression, defer evaluation
				operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))
			operator_stack.append(current)

		i += 1
	
	# Automatically close any unclosed parentheses
	while operator_stack.size() > 0:
		if operator_stack[-1] == '(':
			operator_stack.pop_back()  # Remove the unclosed '('
		else:
			if operand_stack.size() < 2:
				return  # Incomplete expression, defer evaluation
			operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))

	# Final evaluation of the remaining operators in the stack
	while operator_stack.size() > 0:
		if operand_stack.size() < 2:
			return  # Incomplete expression, defer evaluation
		operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))

	# The last element in operand_stack should be the result
	if operand_stack.size() > 0:
		answer = operand_stack.pop_back()
		update_answer_label()
		print(answer)
		
	# Handle "Ans" - replace the expression with "Ans" and auto-close parentheses
	if 'Ans' in actions.map(func(x): return x[0]):
		actions.clear()
		actions.append([answer, null])  # Use the last calculated answer as "Ans"
		process_action()

func apply_operator(operator: String, b: float, a: float):
	if operator == '+':
		return a + b
	elif operator == '-':
		return a - b
	elif operator == '×':
		return a * b
	elif operator == '÷':
		return a / b

func precedence(operator: String) -> int:
	if operator in ['+', '-']:
		return 1
	elif operator in ['×', '÷']:
		return 2
	return 0

	
func update_answer_label():
	if answer == int(answer):
		answer_label.text = '[center][font_size=100]%d' % int(answer)
	else:
		answer_label.text = '[center][font_size=100]%.2f' % answer
	
	if actions.size() == 0:
		answer_label.text = ''
