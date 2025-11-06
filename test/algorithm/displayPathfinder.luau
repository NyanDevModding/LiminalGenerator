local UserInputService = game:GetService("UserInputService")

local pathfinder =
	require(script.Parent.Parent.Parent.LiminalGenerator.algorithm.corridor_connection.pathfinder)
local DisplayUtils = require(script.Parent.Parent.DisplayUtils)

local FlagGrid = require(script.Parent.Parent.Parent.LiminalGenerator.gen_data.FlagGrid)
local Access = require(script.Parent.Parent.Parent.LiminalGenerator.gen_elements.access.Access)
local RoomData = require(script.Parent.Parent.Parent.LiminalGenerator.gen_setting.room.RoomData)

return function(
	key: Enum.KeyCode,
	worldPos: Vector3,
	cellSize: Vector3,
	folder: Folder,
	roomGrid: FlagGrid.FlagGrid,
	p1: Vector3,
	p2: Vector3
)
	local pathfinderCoroutine = coroutine.create(pathfinder)

	local testRoom1 = RoomData.new("test_1", Vector3.new(1, 1, 1), { DisplayUtils.TEST_ACCESS_1 })
	local testRoom2 = RoomData.new("test_2", Vector3.new(1, 1, 1), { DisplayUtils.TEST_ACCESS_2 })
	roomGrid:set(p1.X, p1.Y, p1.Z)
	roomGrid:set(p2.X, p2.Y, p2.Z)

	local firstPos, secondPos =
		p1 + testRoom1:getAccessData(1):getRelativePosition(),
		p2 + testRoom2:getAccessData(1):getRelativePosition()
	local access1, access2 =
		Access.createAccess(
			testRoom1,
			DisplayUtils.TEST_ACCESS_1,
			firstPos.X,
			firstPos.Y,
			firstPos.Z
		),
		Access.createAccess(
			testRoom2,
			DisplayUtils.TEST_ACCESS_2,
			secondPos.X,
			secondPos.Y,
			secondPos.Z
		)

	for i = 1, 20, 1 do
		local size = math.random(0, 2)
		local posX = math.random(1, roomGrid:getXSize())
		local posZ = math.random(1, roomGrid:getZSize())

		if
			posX + size > roomGrid:getXSize()
			or posZ + size > roomGrid:getZSize()
			or (posX == access1.x + 1 and posZ == access1.z)
			or (posX == access2.x - 1 and posZ == access2.z)
			or (
				access1.x + 1 <= posX + size
				and access1.z <= posZ + size
				and access1.x + 1 >= posX
				and access1.z >= posZ
			)
		then
			continue
		end

		roomGrid:volumeSet(posX, 1, posZ, posX + size, 1, posZ + size)
	end

	-- Create the workspace grid
	for _, c in folder:GetChildren() do
		c:Destroy()
	end

	local gridFolder = DisplayUtils.create2DGrid(roomGrid, worldPos, cellSize, {}, {}, {})
	gridFolder.Name = "grid"
	gridFolder.Parent = folder

	local vertexQueue = {}
	local visitedStack = {}

	local connection = UserInputService.InputEnded:Connect(function(input: InputObject)
		local path = {}

		if input.KeyCode == key then
			if coroutine.status(pathfinderCoroutine) == "dead" then
				return
			end

			-- step the pathfinder
			local ok, v1, v2 =
				coroutine.resume(pathfinderCoroutine, roomGrid, access1, access2, nil, true)

			if coroutine.status(pathfinderCoroutine) == "dead" then
				print("skibidi")
				if not ok then
					print(v1)
				end

				DisplayUtils.plotCorridor(worldPos, cellSize, folder, v1)
				return
			end

			-- Destroy the old grid
			for _, c in folder:GetChildren() do
				c:Destroy()
			end

			if v2 ~= nil then
				vertexQueue = v1 or {}
				visitedStack = v2 or {}
			else
				path = v1 or {}
			end

			-- Update the workspace grid
			local gridFolder = DisplayUtils.create2DGrid(
				roomGrid,
				worldPos,
				cellSize,
				vertexQueue,
				visitedStack,
				path
			)
			gridFolder.Name = "grid"
			gridFolder.Parent = folder
		end
	end)

	return connection
end
