extends PanelContainer

signal reset_button_pressed

@onready var answer_bar_container: HBoxContainer = %AnswerBarContainer
@onready var reset_button: Button = %ResetButton
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D
var ANSWER_BAR = preload("res://assets/answer_bar.tres")

const MI_SFX_36 = preload("res://assets/sound effects/coloralpha/MI_SFX 36.wav")


func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	audio_stream_player_2d.stream = MI_SFX_36

	
func _on_reset_button_pressed():
	audio_stream_player_2d.play()
	reset_button_pressed.emit()
	
func clear_answer_bar():
	for answer_bar_tile in answer_bar_container.get_children():
		answer_bar_tile.call_deferred("queue_free")
