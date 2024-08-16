extends PanelContainer

signal operator_tile_press(operator : String)

@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var button: Button = %Button
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D

const MI_SFX_24 = preload("res://assets/sound effects/coloralpha/MI_SFX 24.wav")

var operator := '+'

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	audio_stream_player_2d.stream = MI_SFX_24

func _on_button_pressed():
	audio_stream_player_2d.play()
	#print ('Operator pressed: %s' % operator)
	operator_tile_press.emit(operator)

func update_operator(new_operator : String):
	operator = new_operator
	rich_text_label.text = '[font_size=50][center]%s[/center][/font_size]' % operator
	
func disable_botton():
	button.hide()
