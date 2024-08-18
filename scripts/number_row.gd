extends PanelContainer


@onready var number_tile_1: number_tile = %NumberTile1
@onready var number_tile_2: number_tile = %NumberTile2
@onready var number_tile_3: number_tile = %NumberTile3
@onready var number_tile_4: number_tile = %NumberTile4


@onready var number_tiles := [
	number_tile_1,
	number_tile_2,
	number_tile_3,
	number_tile_4
]

func get_random_tiles():
	for _number_tile in number_tiles:
		_number_tile.generate_random_numer()

func enable_all_tiles():
	for _number_tile in number_tiles:
		_number_tile.enable_tile()
