extends PanelContainer

class_name number_tile
signal number_tile_press(tile, number : int)

@onready var v_box_container: VBoxContainer = %VBoxContainer
@onready var rich_text_label: RichTextLabel = %RichTextLabel
@onready var button: Button = %Button
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
@onready var cover: ColorRect = $Cover

const MI_SFX_25 = preload("res://assets/sound effects/coloralpha/MI_SFX 25.wav")

var number := 1.0

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)
	audio_stream_player_2d.stream = MI_SFX_25
	rich_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD

func _on_button_pressed():
	audio_stream_player_2d.play()
	#print ('Tile pressed: %d' % number) 
	number_tile_press.emit(self, number)

func update_number(new_number):
	number = new_number
	if new_number == int(new_number):
		rich_text_label.text = '[font_size=50][center]%d[/center][/font_size]' % int(new_number)
	else:
		rich_text_label.text = '[font_size=50][center]%.2f[/center][/font_size]' % new_number
	

func generate_random_numer():
	update_number(randi_range(1, 9))

func disable_button():
	button.hide()

func disable_tile():
	cover.show()

func enable_tile():
	cover.hide()
