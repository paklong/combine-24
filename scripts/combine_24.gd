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

@onready var operator_tile_plus: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTilePlus
@onready var operator_tile_minus: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileMinus
@onready var operator_tile_multiply: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileMultiply
@onready var operator_tile_division: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer/OperatorTileDivision
@onready var operator_tile_open: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileOpen
@onready var operator_tile_ans: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileAns
@onready var operator_tile_closed: operator_tile = $OperatorRow/VBoxContainer/HBoxContainer2/OperatorTileClosed


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
	operator_tile_closed: ')',
	operator_tile_ans: 'Ans'
}

#endregion

var actions := []
var valid_actions := []
var available_number := 4
var answer := 0.0

func _ready() -> void:
	for _number_tile in number_tiles:
		_number_tile.number_tile_press.connect(_on_tile_press)
	
	for _operator_tile in operator_tiles:
		_operator_tile.update_operator(operator_tiles[_operator_tile])
		_operator_tile.operator_tile_press.connect(_on_tile_press)
		
	answer_bar.reset_button_pressed.connect(_on_answer_bar_reset_button_pressed)
	
	number_row.get_random_tiles()
	answer_bar.clear_answer_bar()
	
	reset_image.position = Vector2(470, 530)
	reset_image.scale = Vector2(0.35, 0.35)

func _on_tile_press(tile_reference, value):
	print ('Tile pressed: %s' % str(value))
	add_to_actions(tile_reference, value)

func _on_answer_bar_reset_button_pressed():
	answer_bar.clear_answer_bar()
	number_row.enable_all_tiles()
	actions = []
	valid_actions = []
	answer = 0.0	
	update_answer_label()

func add_to_actions(tile_reference, value):
	actions.append([tile_reference, value])
	
	print ('actions :' + str(actions.map(func(x): return x[1])))
	process_action()
	

func process_action():
	valid_actions.clear()
	answer_bar.clear_answer_bar()
	available_number = 4
	var last_valid_action = null
	
	for action in actions:
		var tile_reference = action[0]
		var value = action[1]
		
		if is_valid_action(last_valid_action, value):
			
			if str(value) == 'Ans':
				valid_actions.insert(0, [operator_tile_open, '('])
				valid_actions.append([operator_tile_closed, ')'])
				last_valid_action = ')'

			else:
				valid_actions.append(action)
				if tile_reference is number_tile:
					tile_reference.disable_tile()
					available_number -= 1
					
				last_valid_action = value

	print ('valid_actions :' + str(valid_actions.map(func(x): return x[1])))
	evaluate_actions()

func is_valid_action(last_action, current_action) -> bool:
	# Check number validity
	if is_number(current_action):
		return last_action == null or last_action in ['(', '+', '-', '×', '÷']
	# Check operator validity
	if is_operator(current_action):
		return last_action != null and not is_operator(last_action) and str(last_action) != '(' and available_number > 0
	# Check opening parenthesis validity
	if current_action == '(':
		return last_action == null or last_action in ['(', '+', '-', '×', '÷']

	# Check closing parenthesis validity
	if current_action == ')':
		return last_action != null and (is_number(last_action) or str(last_action) == ')') and has_matching_open_parenthesis()

	# Special actions: 'Ans'
	if current_action == 'Ans':
		return valid_actions.size() > 0 and not is_operator(last_action) # Ensure there's something to evaluate
	return false

func is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT

func is_operator(value) -> bool:
	return value in ['+', '-', '×', '÷']

func has_matching_open_parenthesis() -> bool:
	var open_count = 0
	var close_count = 0
	for action in valid_actions:
		if str(action[1]) == '(':
			open_count += 1
		elif str(action[1]) == ')':
			close_count += 1
	return open_count > close_count

		
func add_new_tile(action, start=false):
	
	var tile = null
	var tile_reference = action[0]
	var value = action[1]
	if tile_reference is number_tile:
		tile = NUMBER_TILE.instantiate()  # Or use the appropriate node type
		answer_bar_container.add_child(tile)
		tile.update_number(value)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
	elif tile_reference is operator_tile:
		tile = OPERATOR_TILE.instantiate()  # Or use the appropriate node type
		answer_bar_container.add_child(tile)
		if start:
			answer_bar_container.move_child(tile, 0)
		tile.update_operator(value)
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
	tile.disable_button()

#
	
func evaluate_actions():
	var operand_stack = []  # Stack to hold numbers and intermediate results
	var operator_stack = []  # Stack to hold operators and parentheses

	var i = 0
	while i < valid_actions.size():
		
		var tile_reference = valid_actions[i][0]
		var value = valid_actions[i][1]
		
		add_new_tile(valid_actions[i])
		
		if tile_reference is number_tile:
			operand_stack.append(value)
			
		elif str(value) == '(':
			operator_stack.append(value)

		elif str(value) == ')':
			# Pop from stacks and evaluate until '(' is found
			while operator_stack.size() > 0 and operator_stack[-1] != '(':
				if operand_stack.size() < 2:
					return  # Incomplete expression, defer evaluation
				operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))
			operator_stack.pop_back()  # Remove '('
			
		elif str(value) in ['+', '-', '×', '÷']:
			# Pop from stack and evaluate based on operator precedence
			while operator_stack.size() > 0 and precedence(operator_stack[-1]) >= precedence(value):
				if operand_stack.size() < 2:
					return  # Incomplete expression, defer evaluation
				operand_stack.append(apply_operator(operator_stack.pop_back(), operand_stack.pop_back(), operand_stack.pop_back()))
			operator_stack.append(value)
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
		print('answer: ' + str(answer))

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
