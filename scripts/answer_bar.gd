extends PanelContainer

signal reset_button_pressed

@onready var reset_button: Button = %ResetButton
@onready var audio_stream_player_2d: AudioStreamPlayer2D = %AudioStreamPlayer2D


const MI_SFX_36 = preload("res://assets/sound effects/coloralpha/MI_SFX 36.wav")


func _ready() -> void:
	reset_button.pressed.connect(_on_reset_button_pressed)
	audio_stream_player_2d.stream = MI_SFX_36

func _on_reset_button_pressed():
	audio_stream_player_2d.play()
	reset_button_pressed.emit()
