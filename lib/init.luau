local default_data_set = require(script.Parent.TestAssets.data.default_data_set)
local Generator = require(script.algorithm.Generator)
local Directions = require(script.gen_data.Directions)
local Settings = require(script.gen_setting.Settings)

local RoomDataSet = require(script.gen_setting.room_data_set.RoomDataSet)
local room_data_set_json_type = require(script.gen_setting.room_data_set.room_data_set_json_type)

local ModelGenUtils = require(script.model_gen.ModelGenUtils)

local CorridorStorage = require(script.gen_data.storage.CorridorStorage)
local RoomStorage = require(script.gen_data.storage.RoomStorage)
local ComplexTileDirections = require(script.gen_setting.ComplexTileDirections)
local SimpleTileDirections = require(script.gen_setting.SimpleTileDirections)

-- types
export type room_data_set_json_type = room_data_set_json_type.roomDataSetJson

export type RoomStorage = RoomStorage.RoomStorage
export type CorridorStorage = CorridorStorage.CorridorStorage

export type gen_settings = Settings.gen_settings

local function _rawGenerate(
	size: Vector3,
	generator: Generator.Generator,
	roomDataSet: RoomDataSet.RoomDataSet
)
	print("Generating ...")
	local beginTime = os.clock()
	local roomStorage, corridorStorage = generator:generate(size.X, size.Y, size.Z)
	local delta = (os.clock() - beginTime) * 1000
	print("✅ Generation completed in " .. tostring(delta) .. "ms")

	return roomStorage, corridorStorage
end

local function generate(
	worldPos: Vector3,
	cellSize: number,
	size: Vector3,
	seed: number,
	roomDataSetJson: room_data_set_json_type.roomDataSetJson,
	genSettings: { Settings.gen_settings }
)
	if size.Y ~= 1 then
		warn(
			"Programm not yet coded to handle multiple floors"
				.. "to generate, returning to default YSize value: 1"
		)
		size = Vector3.new(size.X, 1, size.Z)
	end

	local roomDataSet = RoomDataSet.new(roomDataSetJson)
	local generator = Generator.new(seed, genSettings, roomDataSet)

	return _rawGenerate(size, generator, roomDataSet)
end

local function generateModel(
	worldPos: Vector3,
	cellSize: number,
	size: Vector3,
	seed: number,
	roomDataSetJson: room_data_set_json_type.roomDataSetJson,
	genSettings: { Settings.gen_settings }
)
	if size.Y ~= 1 then
		warn(
			"Programm not yet coded to handle multiple floors"
				.. "to generate, returning to default YSize value: 1"
		)
		size = Vector3.new(size.X, 1, size.Z)
	end

	local roomDataSet = RoomDataSet.new(roomDataSetJson)
	local generator = Generator.new(seed, genSettings, roomDataSet)

	local roomStorage, corridorStorage = _rawGenerate(size, generator, roomDataSet)

	print("Creating Model ...")
	local beginModelTime = os.clock()
	local model =
		ModelGenUtils.createGenerated(cellSize, worldPos, roomDataSet, corridorStorage, roomStorage)
	local modelDelta = (os.clock() - beginModelTime) * 1000
	print("✅ Model Creation completed in " .. tostring(modelDelta) .. "ms")

	return model
end

return {
	DEFAULT_DATA_SET_JSON = default_data_set,
	DEFAULT_CELL_SIZE = default_data_set.cell_size,

	SETTINGS = Settings,

	Directions = Directions,
	SimpleTileDirections = SimpleTileDirections,
	ComplexTileDirections = ComplexTileDirections,

	generate = generate,
	generateModel = generateModel,
}
