local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FlagGridsWrapper = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGridsWrapper)
local FlagGrid = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGrid)
local ModelGenUtils = require(ReplicatedStorage.LiminalGenerator.model_gen.ModelGenUtils)

local Generator = require(ReplicatedStorage.LiminalGenerator.algorithm.Generator)
local Settings = require(ReplicatedStorage.LiminalGenerator.gen_setting.Settings)

local RoomDataSet =
	require(ReplicatedStorage.LiminalGenerator.gen_setting.room_data_set.RoomDataSet)
local default_data_set = require(ReplicatedStorage.TestAssets.data.default_data_set)

local CELL_SIZE = 15
local roomDataSet = RoomDataSet.new(default_data_set)

local generator = Generator.new(0, {
	[Settings.DEAD_END_LUCK] = 512,
	[Settings.ROOM_AMOUNT] = 20,
	[Settings.ACCESS_SEARCH_DEPTH] = 3,
}, roomDataSet)

print("Generating ...")
local beginTime = os.clock()
local roomStorage, corridorStorage = generator:generate(50, 1, 50)
local delta = (os.clock() - beginTime) * 1000
print("✅ Generation completed in " .. tostring(delta) .. "ms")

print("Creating Model ...")
local beginModelTime = os.clock()
local model = ModelGenUtils.createGenerated(
	CELL_SIZE,
	Vector3.new(-37.5, 3, -37.5),
	roomDataSet,
	corridorStorage,
	roomStorage
)
local modelDelta = (os.clock() - beginModelTime) * 1000
print("✅ Model Creation completed in " .. tostring(modelDelta) .. "ms")

print("What it should look like: ")
local grid = FlagGrid.new(50, 1, 50)
for _, room in roomStorage:iterateRoom() do
	local p1 = room:getPos()
	local p2 = p1 + room:getSize()

	grid:volumeSet(p1.X, p1.Y, p1.Z, p2.X, p2.Y, p2.Z)
end
local cGrid = FlagGrid.new(50, 1, 50)
for _, corridor in corridorStorage:iterateCorridor() do
	corridor:addOnGrid(cGrid)
end
local wrapped = FlagGridsWrapper.new({ grid, cGrid })

print(tostring(wrapped))

model.Parent = workspace
