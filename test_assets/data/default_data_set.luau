local ReplicatedStorage = game:GetService("ReplicatedStorage")

local default_model = ReplicatedStorage.TestAssets.model.default

local room_data_set_json_type = require(
	script.Parent.Parent.Parent.LiminalGenerator.gen_setting.room_data_set.room_data_set_json_type
)
local Directions = require(script.Parent.Parent.Parent.LiminalGenerator.gen_data.Directions)
local ComplexTileDirections =
	require(script.Parent.Parent.Parent.LiminalGenerator.gen_setting.ComplexTileDirections)
local SimpleTileDirections =
	require(script.Parent.Parent.Parent.LiminalGenerator.gen_setting.SimpleTileDirections)

local simple = default_model.corridor.simple
local complex = default_model.corridor.complex
local dead_end = default_model.corridor.dead_end

-- BE AWARE THAT IN OUR GRID, THE POSITION OF A CELL IS ITS BOTTOM LEFT
-- CORNER, THUS, A SIZE OF {X, Y, Z} WOULD ACTUALLY HAVE A SIZE OF
-- {X+1, Y+1, Z+1} AS WE COUNT THE {0, 0, 0} CELL TOO
return {
	data_set_name = "test_default",
	data_set_version = "0.0",
	cell_size = 5,
	rooms = {
		{
			name = "long_straight_line",
			size = Vector3.new(2, 0, 14),
			accesses = {
				{
					type = 1,
					direction = Directions.SOUTH,
					position = Vector3.new(1, 0, 14),
				},
				{
					type = 1,
					direction = Directions.NORTH,
					position = Vector3.new(1, 0, 0),
				},
			},
			chance_to_spawn = 1,
			model = default_model.room.long_straight_line,
			rotate_y = true,
		},
		{
			name = "mid_square",
			size = Vector3.new(2, 0, 2),
			accesses = {
				{
					type = 1,
					direction = Directions.SOUTH,
					position = Vector3.new(1, 0, 2),
				},
				{
					type = 1,
					direction = Directions.WEST,
					position = Vector3.new(0, 0, 1),
				},
				{
					type = 1,
					direction = Directions.NORTH,
					position = Vector3.new(1, 0, 0),
				},
				{
					type = 1,
					direction = Directions.EAST,
					position = Vector3.new(2, 0, 1),
				},
			},
			chance_to_spawn = 1,
			model = default_model.room.mid_square,
			rotate_y = true,
		},
		{
			name = "big_square",
			size = Vector3.new(10, 0, 10),
			accesses = {
				{
					type = 1,
					direction = Directions.WEST,
					position = Vector3.new(0, 0, 5),
				},
				{
					type = 1,
					direction = Directions.SOUTH,
					position = Vector3.new(5, 0, 0),
				},
			},
			chance_to_spawn = 3,
			model = default_model.room.big_square,
			rotate_y = true,
		},
	},
	corridor_tiles = {
		uniform_tiles = {
			[1] = {
				simple_tiles = {
					[SimpleTileDirections.NORTH_WEST] = {
						model = simple.nw,
					},
					[SimpleTileDirections.NORTH_SOUTH] = {
						model = simple.ns,
					},
					[SimpleTileDirections.NORTH_EAST] = {
						model = simple.ne,
					},
					[SimpleTileDirections.WEST_SOUTH] = {
						model = simple.ws,
					},
					[SimpleTileDirections.WEST_EAST] = {
						model = simple.we,
					},
					[SimpleTileDirections.SOUTH_EAST] = {
						model = simple.se,
					},
				},
				complex_tiles = {
					[ComplexTileDirections.NORTH_WEST_EAST] = {
						model = complex.nwe,
					},
					[ComplexTileDirections.WEST_SOUTH_NORTH] = {
						model = complex.wsn,
					},
					[ComplexTileDirections.SOUTH_EAST_WEST] = {
						model = complex.sew,
					},
					[ComplexTileDirections.EAST_NORTH_SOUTH] = {
						model = complex.ens,
					},
					[ComplexTileDirections.NORTH_WEST_SOUTH_EAST] = {
						model = complex.nwse,
					},
				},
				dead_ends = {
					[Directions.NORTH] = {
						model = dead_end.north,
					},
					[Directions.WEST] = {
						model = dead_end.west,
					},
					[Directions.SOUTH] = {
						model = dead_end.south,
					},
					[Directions.EAST] = {
						model = dead_end.east,
					},
				},
			},
		},
		mixed_tiles = {},
	},
} :: room_data_set_json_type.roomDataSetJson
