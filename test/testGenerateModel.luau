local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ModelGenUtils = require(ReplicatedStorage.LiminalGenerator.model_gen.ModelGenUtils)

local Generator = require(ReplicatedStorage.LiminalGenerator.algorithm.Generator)
local Settings = require(ReplicatedStorage.LiminalGenerator.gen_setting.Settings)
local RoomDataSet =
	require(ReplicatedStorage.LiminalGenerator.gen_setting.room_data_set.RoomDataSet)

-- local FlagGridsWrapper = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGridsWrapper)
-- local FlagGrid = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGrid)

return function(
	worldPos: Vector3,
	cellSize: number,
	size: Vector3,
	seed: number,
	roomDataSet: RoomDataSet.RoomDataSet,
	genSettings: { Settings.gen_settings }
)
	if size.Y ~= 1 then
		warn(
			"Programm not yet coded to handle multiple floors"
				.. "to generate, returning to default YSize value: 1"
		)
		size = Vector3.new(size.X, 1, size.Z)
	end

	local generator = Generator.new(seed, genSettings, roomDataSet)

	print("Generating ...")
	local beginTime = os.clock()
	local roomStorage, corridorStorage = generator:generate(size.X, size.Y, size.Z)
	local delta = (os.clock() - beginTime) * 1000
	print("✅ Generation completed in " .. tostring(delta) .. "ms")

	print("Creating Model ...")
	local beginModelTime = os.clock()
	local model =
		ModelGenUtils.createGenerated(cellSize, worldPos, roomDataSet, corridorStorage, roomStorage)
	local modelDelta = (os.clock() - beginModelTime) * 1000
	print("✅ Model Creation completed in " .. tostring(modelDelta) .. "ms")

	-- print("What it should look like: ")
	-- local grid = FlagGrid.new(50, 1, 50)
	-- for _, room in roomStorage:iterateRoom() do
	-- 	local p1 = room:getPos()
	-- 	local p2 = p1 + room:getSize()

	-- 	grid:volumeSet(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z)
	-- end
	-- local cGrid = FlagGrid.new(50, 1, 50)
	-- for _, corridor in corridorStorage:iterateCorridor() do
	-- 	corridor:addOnGrid(cGrid)
	-- end
	-- local wrapped = FlagGridsWrapper.new({ grid, cGrid })

	-- print(tostring(wrapped))

	return model
end
