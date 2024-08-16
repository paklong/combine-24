extends PanelContainer


@onready var number_tile_1: PanelContainer = %NumberTile1
@onready var operator_tile_1: PanelContainer = %OperatorTile1
@onready var number_tile_2: PanelContainer = %NumberTile2
@onready var operator_tile_2: PanelContainer = %OperatorTile2
@onready var number_tile_3: PanelContainer = %NumberTile3
@onready var operator_tile_3: PanelContainer = %OperatorTile3
@onready var number_tile_4: PanelContainer = %NumberTile4

@onready var tiles := [
	number_tile_1,
	operator_tile_1,
	number_tile_2,
	operator_tile_2,
	number_tile_3,
	operator_tile_3,
	number_tile_4
]

func hide_all_tiles():
	for tile in tiles:
		tile.hide()
