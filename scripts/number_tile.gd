extends PanelContainer

signal number_tile_press(number : int)

@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var button: Button = %Button
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D

const MI_SFX_25 = preload("res://assets/sound effects/coloralpha/MI_SFX 25.wav")

var number := 1

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	audio_stream_player_2d.stream = MI_SFX_25
	
func _on_button_pressed():
	audio_stream_player_2d.play()
	#print ('Tile pressed: %d' % number) 
	number_tile_press.emit(number)

func update_number(new_number : int):
	number = new_number
	rich_text_label.text = '[font_size=50][center]%d[/center][/font_size]' % new_number

func generate_random_numer():
	update_number(randi_range(1, 9))

func disable_botton():
	button.hide()
