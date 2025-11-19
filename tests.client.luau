local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.LiminalGenerator.gen_setting.Settings)

local FlagGrid = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGrid)
local Iris = require(ReplicatedStorage.Packages.iris)

local displayGeneratorTest = require(ReplicatedStorage.Test.displayGeneratorTest)
local displayHandleIncrustation =
	require(ReplicatedStorage.Test.algorithm.displayHandleIncrustation)
local displayPathfinder = require(ReplicatedStorage.Test.algorithm.displayPathfinder)

local default_data_set = require(ReplicatedStorage.TestAssets.data.default_data_set)

local DATA_SET_NAMES = {
	default_data_set.data_set_name,
}

local TEST_ROOM_DATA_SET_JSONS = {
	[default_data_set.data_set_name] = default_data_set,
}

-- Handle incrustation test
local PRESETS_NAME = {
	"simple_cross",
	"single_side_fused",
	"single_vertex_fused",
	"multiple_collision_no_fuse",
	"multiple_collision_fuse",
	"mixed_collision", -- fused and not fused
	"vertex_collision", -- corridor making turns but still collides
	"single-cell corridors",
}
local PRESETS_NUM = {}

for num, presetName in pairs(PRESETS_NAME) do
	PRESETS_NUM[presetName] = num
end

Iris.Init()

local rConnection: RBXScriptConnection?
local fConnection: RBXScriptConnection?

Iris:Connect(function()
	Iris.Window("Test Mode")

	Iris.TextWrapped({ "Welcome in the LiminalGenerator test mode" })

	Iris.CollapsingHeader({ "Test pathfinder algorithm" })
	do
		local p1 = Iris.State(Vector3.new(1, 1, 1))
		Iris.InputVector3({ "First position in cells" }, { number = p1 })
		local p2 = Iris.State(Vector3.new(10, 1, 10))
		Iris.InputVector3({ "Second position in cells" }, { number = p2 })

		local key = Iris.State(Enum.KeyCode.R)
		Iris.ComboEnum({ "Key to press to step the algorithm" }, { index = key }, Enum.KeyCode)

		local worldPos = Iris.State(Vector3.new(0, 5, 0))
		Iris.InputVector3({ "Position of the grid" }, { number = worldPos })

		local gridSize = Iris.State(Vector2.new(10, 10))
		Iris.InputVector2({ "The size of the grid" }, { number = gridSize })

		local cellSize = Iris.State(10)
		Iris.InputNum({ "Size of a grid cell" }, { number = cellSize })

		local button = Iris.Button({ "start" })
		if button.clicked() then
			if rConnection then
				rConnection:Disconnect()
			end

			if workspace:FindFirstChild("test_grid") then
				workspace:FindFirstChild("test_grid"):Destroy()
			end

			local folder = Instance.new("Folder")
			folder.Name = "test_grid"

			rConnection = displayPathfinder(
				key.value,
				worldPos.value,
				cellSize.value,
				folder,
				FlagGrid.new(gridSize.value.X, 1, gridSize.value.Y),
				p1.value,
				p2.value
			)

			folder.Parent = workspace
		end
	end
	Iris.End()

	Iris.CollapsingHeader({ "Test handle incrustation algorithm" })
	do
		local key = Iris.State(Enum.KeyCode.F)
		Iris.ComboEnum({ "Key to press to step the algorithm" }, { index = key }, Enum.KeyCode)

		local worldPos = Iris.State(Vector3.new(0, 5, 0))
		Iris.InputVector3({ "Position of the grid" }, { number = worldPos })

		local cellSize = Iris.State(10)
		Iris.InputNum({ "Size of a grid cell" }, { number = cellSize })

		local presetName = Iris.State(PRESETS_NAME[2])
		Iris.ComboArray({ "The preset to use for testing" }, { index = presetName }, PRESETS_NAME)

		local doDisplay = Iris.State(true)
		Iris.Checkbox({ "Display the test" }, { isChecked = doDisplay })

		local button = Iris.Button({ "start" })
		if button.clicked() then
			if fConnection then
				fConnection:Disconnect()
			end

			if workspace:FindFirstChild("incrustation_collision_grid") then
				workspace:FindFirstChild("incrustation_collision_grid"):Destroy()
			end

			local folder = Instance.new("Folder")
			folder.Name = "incrustation_collision_grid"

			fConnection = displayHandleIncrustation(
				key.value,
				worldPos.value,
				cellSize.value,
				folder,
				PRESETS_NUM[presetName.value],
				doDisplay.value
			)

			folder.Parent = workspace
		end
	end
	Iris.End()

	Iris.CollapsingHeader({ "Test the Generator" })
	do
		local delta = Iris.State(1)
		Iris.InputNum(
			{ "Time to wait between two steps. Enter 0 if you dont want to wait" },
			{ number = delta }
		)

		local worldPos = Iris.State(Vector3.new(0, 5, 0))
		Iris.InputVector3({ "Position of the grid" }, { number = worldPos })

		local worldSize = Iris.State(Vector3.new(50, 1, 50))
		Iris.InputVector3(
			{ "The size of the world, please keep y = 1 for the time being" },
			{ number = worldSize }
		)

		local cellSize = Iris.State(2)
		Iris.InputNum({ "Size of a grid cell" }, { number = cellSize })

		local seed = Iris.State(543434512)
		Iris.InputNum({ "The Generation seed" }, { number = seed })

		local roomAmount = Iris.State(5)
		Iris.InputNum({ "The amount of rooms to spawn" }, { number = roomAmount })

		local roomDataSetName = Iris.State(DATA_SET_NAMES[1])
		Iris.ComboArray(
			{ "The Room Data Set to use to generate" },
			{ index = roomDataSetName },
			DATA_SET_NAMES
		)

		local button = Iris.Button({ "start" })
		if button.clicked() then
			if workspace:FindFirstChild("generator_test") then
				workspace:FindFirstChild("generator_test"):Destroy()
			end

			task.defer(function()
				displayGeneratorTest(worldPos.value, cellSize.value, worldSize.value, seed.value, {
					[Settings.DEAD_END_LUCK] = 512,
					[Settings.ROOM_AMOUNT] = roomAmount.value,
					[Settings.ACCESS_SEARCH_DEPTH] = 3,
				}, TEST_ROOM_DATA_SET_JSONS[roomDataSetName.value], delta.value)
			end)
		end
	end
	Iris.End()

	Iris.End()
end)
