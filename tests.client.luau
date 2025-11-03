local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(ReplicatedStorage.LiminalGenerator.gen_setting.Settings)

local FlagGrid = require(ReplicatedStorage.LiminalGenerator.gen_data.FlagGrid)
local Iris = require(ReplicatedStorage.Packages.iris)

local displayGeneratorTest = require(ReplicatedStorage.Test.displayGeneratorTest)
local displayPathfinder = require(ReplicatedStorage.Test.algorithm.displayPathfinder)

local default_data_set = require(ReplicatedStorage.TestAssets.data.default_data_set)

local DEFAULT_GEN_SETTINGS = {
	[Settings.DEAD_END_LUCK] = 512,
}

local DATA_SET_NAMES = {
	default_data_set.data_set_name,
}

local TEST_ROOM_DATA_SET_JSONS = {
	[default_data_set.data_set_name] = default_data_set,
}

Iris.Init()

local rConnection: RBXScriptConnection?

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

	Iris.CollapsingHeader({ "Test the Generator" })
	do
		local delta = Iris.State(0.1)
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

		local cellSize = Iris.State(10)
		Iris.InputNum({ "Size of a grid cell" }, { number = cellSize })

		local seed = Iris.State(543434512)
		Iris.InputNum({ "The Generation seed" }, { number = seed })

		local roomAmount = Iris.State(20)
		Iris.InputNum({ "The amount of rooms to spawn" }, { number = roomAmount })

		local roomDataSetName = Iris.State(DATA_SET_NAMES[1])
		Iris.ComboArray(
			{ "The Room Data Set to use to generate" },
			{ index = roomDataSetName },
			DATA_SET_NAMES
		)

		local button = Iris.Button({ "start" })
		if button.clicked() then
			if workspace:FindFirstChild("generated") then
				workspace:FindFirstChild("generated"):Destroy()
			end

			task.defer(function()
				displayGeneratorTest(
					worldPos.value,
					cellSize.value,
					worldSize.value,
					seed.value,
					DEFAULT_GEN_SETTINGS,
					TEST_ROOM_DATA_SET_JSONS[roomDataSetName.value],
					delta.value
				)
			end)
		end
	end
	Iris.End()

	Iris.End()
end)
