local UserInputService = game:GetService("UserInputService")

local LiminalGenerator = script.Parent.Parent.Parent.LiminalGenerator

local handleIncrustation =
	require(LiminalGenerator.algorithm.corridor_connection.collisionHandler.handleIncrustation)

local DisplayUtils = require(script.Parent.Parent.DisplayUtils)
local AccessConnectStorage =
	require(script.Parent.Parent.Parent.LiminalGenerator.gen_data.storage.AccessConnectStorage)

local FlagGrid = require(LiminalGenerator.gen_data.FlagGrid)
local Corridor = require(LiminalGenerator.gen_elements.corridor.Corridor)
local CorridorStorage = require(LiminalGenerator.gen_data.storage.CorridorStorage)
local Room = require(LiminalGenerator.gen_elements.room.Room)
local RoomStorage = require(LiminalGenerator.gen_data.storage.RoomStorage)

local SeededRandom = require(LiminalGenerator.algorithm.SeededRandom)
local RoomData = require(LiminalGenerator.gen_setting.room.RoomData)
local RoomDataSet = require(LiminalGenerator.gen_setting.room_data_set.RoomDataSet)
local default_data_set = require(script.Parent.Parent.Parent.TestAssets.data.default_data_set)

local CORRIDOR_COLOR = Color3.fromRGB(0, 133, 7)
local PLACED_CORRIDOR_COLOR = Color3.fromRGB(0, 38, 255)

return function(
	key: Enum.KeyCode,
	worldPos: Vector3,
	cellSize: Vector3,
	folder: Folder,
	presetNum: number,
	doDisplay: boolean
)
	local handleIncrustationCoroutine = coroutine.create(handleIncrustation)

	local roomGrid = FlagGrid.new(10, 1, 10)
	local corridorGrid = FlagGrid.new(10, 1, 10)

	local roomStorage = RoomStorage.new()
	local corridorStorage = CorridorStorage.new()

	local accessConnectStorage = AccessConnectStorage.new(10, 1, 10)

	local genSettings = {}
	local roomDataSet = RoomDataSet.new(default_data_set)
	local seededRandom = SeededRandom.new(0)

	local corridor
	local testRoom1 = Room.new(
		Vector3.new(5, 1, 1),
		RoomData.new("test_1", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_3 })
	)
	local testRoom2 = Room.new(
		Vector3.new(5, 1, 10),
		RoomData.new("test_2", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_4 })
	)
	roomGrid:set(5, 1, 1)
	roomGrid:set(5, 1, 10)
	roomStorage:addRoom(testRoom1)
	roomStorage:addRoom(testRoom2)

	local roomData3 = RoomData.new("test_3", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_1 })
	local roomData4 = RoomData.new("test_4", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_2 })

	if presetNum == 1 then
		local testRoom3 = Room.new(
			Vector3.new(1, 1, 5),
			RoomData.new("test_3", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_1 })
		)
		local testRoom4 = Room.new(
			Vector3.new(10, 1, 5),
			RoomData.new("test_4", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_2 })
		)
		roomGrid:set(1, 1, 5)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local collisionCorridor = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor)

		testRoom3:setAdjacentByNum(collisionCorridor, 1)
		testRoom4:setAdjacentByNum(collisionCorridor, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 2 then
		local testRoom3 = Room.new(
			Vector3.new(1, 1, 4),
			RoomData.new("test_3", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_1 })
		)
		local testRoom4 = Room.new(
			Vector3.new(1, 1, 6),
			RoomData.new("test_4", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_1 })
		)
		roomGrid:set(1, 1, 4)
		roomGrid:set(1, 1, 6)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local collisionCorridor = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor:addVertex(2)
		collisionCorridor:setVertex(2, Vector3.new(5, 1, 4))
		collisionCorridor:addVertex(3)
		collisionCorridor:setVertex(3, Vector3.new(5, 1, 6))

		testRoom3:setAdjacentByNum(collisionCorridor, 1)
		testRoom4:setAdjacentByNum(collisionCorridor, 1)

		collisionCorridor:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 3 then
		local testRoom3 = Room.new(
			Vector3.new(1, 1, 5),
			RoomData.new("test_3", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_1 })
		)
		local testRoom4 = Room.new(
			Vector3.new(10, 1, 5),
			RoomData.new("test_4", Vector3.new(0, 0, 0), { DisplayUtils.TEST_ACCESS_2 })
		)
		roomGrid:set(1, 1, 5)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local collisionCorridor = Corridor.newFromRooms(testRoom1, 1, testRoom4, 1)
		collisionCorridor:addVertex(2)
		collisionCorridor:setVertex(2, Vector3.new(5, 1, 5))
		collisionCorridor:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor)

		testRoom1:setAdjacentByNum(collisionCorridor, 1)
		testRoom4:setAdjacentByNum(collisionCorridor, 1)

		corridor = Corridor.newFromRooms(testRoom3, 1, testRoom2, 1)
		corridor:addVertex(2)
		corridor:setVertex(2, Vector3.new(5, 1, 5))

		testRoom3:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 4 then
		local testRoom3 = Room.new(Vector3.new(1, 1, 4), roomData3)
		local testRoom4 = Room.new(Vector3.new(10, 1, 4), roomData4)
		roomGrid:set(1, 1, 4)
		roomGrid:set(10, 1, 4)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local testRoom5 = Room.new(Vector3.new(1, 1, 5), roomData3)
		local testRoom6 = Room.new(Vector3.new(10, 1, 5), roomData4)
		roomGrid:set(1, 1, 5)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom5)
		roomStorage:addRoom(testRoom6)

		local testRoom7 = Room.new(Vector3.new(1, 1, 6), roomData3)
		local testRoom8 = Room.new(Vector3.new(10, 1, 6), roomData4)
		roomGrid:set(1, 1, 6)
		roomGrid:set(10, 1, 6)
		roomStorage:addRoom(testRoom7)
		roomStorage:addRoom(testRoom8)

		local collisionCorridor1 = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor1:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor1)

		testRoom3:setAdjacentByNum(collisionCorridor1, 1)
		testRoom4:setAdjacentByNum(collisionCorridor1, 1)

		local collisionCorridor2 = Corridor.newFromRooms(testRoom5, 1, testRoom6, 1)
		collisionCorridor2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor2)

		testRoom5:setAdjacentByNum(collisionCorridor2, 1)
		testRoom6:setAdjacentByNum(collisionCorridor2, 1)

		local collisionCorridor3 = Corridor.newFromRooms(testRoom7, 1, testRoom8, 1)
		collisionCorridor3:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor3)

		testRoom7:setAdjacentByNum(collisionCorridor3, 1)
		testRoom8:setAdjacentByNum(collisionCorridor3, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 5 then
		-- multiple_collision_fuse
		local testRoom3 = Room.new(Vector3.new(1, 1, 4), roomData3)
		local testRoom4 = Room.new(Vector3.new(10, 1, 4), roomData4)
		roomGrid:set(1, 1, 4)
		roomGrid:set(10, 1, 4)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local testRoom5 = Room.new(Vector3.new(1, 1, 7), roomData3)
		local testRoom6 = Room.new(Vector3.new(10, 1, 5), roomData4)
		roomGrid:set(1, 1, 7)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom5)
		roomStorage:addRoom(testRoom6)

		local collisionCorridor1 = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor1:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor1)

		testRoom3:setAdjacentByNum(collisionCorridor1, 1)
		testRoom4:setAdjacentByNum(collisionCorridor1, 1)

		local collisionCorridor2 = Corridor.newFromRooms(testRoom5, 1, testRoom6, 1)
		collisionCorridor2:addVertex(2)
		collisionCorridor2:setVertex(2, Vector3.new(5, 1, 7))
		collisionCorridor2:addVertex(3)
		collisionCorridor2:setVertex(3, Vector3.new(5, 1, 5))
		collisionCorridor2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor2)

		testRoom5:setAdjacentByNum(collisionCorridor2, 1)
		testRoom6:setAdjacentByNum(collisionCorridor2, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 6 then
		-- mixed_collision
		local testRoom3 = Room.new(Vector3.new(1, 1, 4), roomData3)
		local testRoom4 = Room.new(Vector3.new(10, 1, 5), roomData4)
		roomGrid:set(1, 1, 4)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local testRoom5 = Room.new(Vector3.new(1, 1, 7), roomData3)
		local testRoom6 = Room.new(Vector3.new(10, 1, 6), roomData4)
		roomGrid:set(1, 1, 7)
		roomGrid:set(10, 1, 6)
		roomStorage:addRoom(testRoom5)
		roomStorage:addRoom(testRoom6)

		local collisionCorridor1 = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor1:addVertex(2)
		collisionCorridor1:setVertex(2, Vector3.new(5, 1, 4))
		collisionCorridor1:addVertex(3)
		collisionCorridor1:setVertex(3, Vector3.new(5, 1, 5))
		collisionCorridor1:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor1)

		testRoom3:setAdjacentByNum(collisionCorridor1, 1)
		testRoom4:setAdjacentByNum(collisionCorridor1, 1)

		local collisionCorridor2 = Corridor.newFromRooms(testRoom5, 1, testRoom6, 1)
		collisionCorridor2:addVertex(2)
		collisionCorridor2:setVertex(2, Vector3.new(5, 1, 7))
		collisionCorridor2:addVertex(3)
		collisionCorridor2:setVertex(3, Vector3.new(5, 1, 6))
		collisionCorridor2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor2)

		testRoom5:setAdjacentByNum(collisionCorridor2, 1)
		testRoom6:setAdjacentByNum(collisionCorridor2, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 7 then
		-- mixed_collision
		local testRoom3 = Room.new(Vector3.new(1, 1, 4), roomData3)
		local testRoom4 = Room.new(Vector3.new(10, 1, 5), roomData4)
		roomGrid:set(1, 1, 4)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local testRoom5 = Room.new(Vector3.new(1, 1, 7), roomData3)
		local testRoom6 = Room.new(Vector3.new(10, 1, 6), roomData4)
		roomGrid:set(1, 1, 7)
		roomGrid:set(10, 1, 6)
		roomStorage:addRoom(testRoom5)
		roomStorage:addRoom(testRoom6)

		local collisionCorridor1 = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor1:addVertex(2)
		collisionCorridor1:setVertex(2, Vector3.new(5, 1, 4))
		collisionCorridor1:addVertex(3)
		collisionCorridor1:setVertex(3, Vector3.new(5, 1, 5))
		collisionCorridor1:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor1)

		testRoom3:setAdjacentByNum(collisionCorridor1, 1)
		testRoom4:setAdjacentByNum(collisionCorridor1, 1)

		local collisionCorridor2 = Corridor.newFromRooms(testRoom5, 1, testRoom6, 1)
		collisionCorridor2:addVertex(2)
		collisionCorridor2:setVertex(2, Vector3.new(5, 1, 7))
		collisionCorridor2:addVertex(3)
		collisionCorridor2:setVertex(3, Vector3.new(5, 1, 6))
		collisionCorridor2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor2)

		testRoom5:setAdjacentByNum(collisionCorridor2, 1)
		testRoom6:setAdjacentByNum(collisionCorridor2, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	elseif presetNum == 8 then
		-- single-cell corridors

		local testRoom3 = Room.new(Vector3.new(1, 1, 3), roomData3)
		local testRoom4 = Room.new(Vector3.new(7, 1, 3), roomData4)
		roomGrid:set(1, 1, 3)
		roomGrid:set(7, 1, 3)
		roomStorage:addRoom(testRoom3)
		roomStorage:addRoom(testRoom4)

		local testRoom5 = Room.new(Vector3.new(3, 1, 5), roomData3)
		local testRoom6 = Room.new(Vector3.new(10, 1, 5), roomData4)
		roomGrid:set(3, 1, 5)
		roomGrid:set(10, 1, 5)
		roomStorage:addRoom(testRoom5)
		roomStorage:addRoom(testRoom6)

		local testRoom7 = Room.new(Vector3.new(3, 1, 7), roomData3)
		local testRoom8 = Room.new(Vector3.new(7, 1, 7), roomData4)
		roomGrid:set(3, 1, 7)
		roomGrid:set(7, 1, 7)
		roomStorage:addRoom(testRoom7)
		roomStorage:addRoom(testRoom8)

		local collisionCorridor1 = Corridor.newFromRooms(testRoom3, 1, testRoom4, 1)
		collisionCorridor1:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor1)

		testRoom3:setAdjacentByNum(collisionCorridor1, 1)
		testRoom4:setAdjacentByNum(collisionCorridor1, 1)

		local collisionCorridor2 = Corridor.newFromRooms(testRoom5, 1, testRoom6, 1)
		collisionCorridor2:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor2)

		testRoom5:setAdjacentByNum(collisionCorridor2, 1)
		testRoom6:setAdjacentByNum(collisionCorridor2, 1)

		local collisionCorridor3 = Corridor.newFromRooms(testRoom7, 1, testRoom8, 1)
		collisionCorridor3:addOnGrid(corridorGrid)
		corridorStorage:addCorridor(collisionCorridor3)

		testRoom7:setAdjacentByNum(collisionCorridor3, 1)
		testRoom8:setAdjacentByNum(collisionCorridor3, 1)

		corridor = Corridor.newFromRooms(testRoom1, 1, testRoom2, 1)

		testRoom1:setAdjacentByNum(corridor, 1)
		testRoom2:setAdjacentByNum(corridor, 1)
	end

	local roomGridFolder = Instance.new("Folder")
	local corridorFolder = Instance.new("Folder")
	local createdCorridorFolder = Instance.new("Folder")
	local adjacentsFolder = Instance.new("Folder")

	-- Create the workspace grid
	for _, c in folder:GetChildren() do
		c:Destroy()
	end

	if doDisplay then
		local testFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)
		testFolder.Name = "incrustation_collision_grid"
		testFolder.Parent = folder
	end

	local tester = function(input: InputObject)
		if input.KeyCode == key then
			if coroutine.status(handleIncrustationCoroutine) == "dead" then
				return false
			end

			-- step the pathfinder
			local ok, yieldNum: number, v1, v2, v3, v4, v5 = coroutine.resume(
				handleIncrustationCoroutine,
				corridor,
				genSettings,
				roomDataSet,
				seededRandom,
				roomGrid,
				roomStorage,
				corridorGrid,
				corridorStorage,
				accessConnectStorage,
				true
			)

			if coroutine.status(handleIncrustationCoroutine) == "dead" then
				if not ok then
					error(yieldNum) -- as yieldNum is the error message
				end

				if not doDisplay then
					return false
				end

				-- Right after the division of the collision corridor
				createdCorridorFolder:Destroy()
				corridorFolder:Destroy()

				corridorFolder = DisplayUtils.plotCorridorStorage(
					worldPos,
					cellSize,
					corridorStorage,
					PLACED_CORRIDOR_COLOR,
					nil,
					2,
					0.5,
					0.5
				)

				corridorFolder.Name = "corridors"
				corridorFolder.Parent = folder

				-- Display Adjacents
				adjacentsFolder:Destroy()

				adjacentsFolder =
					DisplayUtils.plotAdjacents(worldPos, cellSize, roomStorage, corridorStorage)

				adjacentsFolder.Name = "adjacents"
				adjacentsFolder.Parent = folder

				return true
			end

			if not doDisplay then
				return true
			end

			if yieldNum == 1 then
				-- When we collected all the directions
				local collision = v1
				local direction1: Vector3 = v2
				local direction2: Vector3 = v3
				local otherDirection1: Vector3 = v4
				local otherDirection2: Vector3 = v5

				-- Display rooms too
				roomGridFolder:Destroy()

				roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)

				roomGridFolder.Name = "rooms"
				roomGridFolder.Parent = folder

				local collisionPart: Part =
					roomGridFolder:FindFirstChild(collision.X .. "_" .. collision.Z)
				collisionPart.Color = Color3.fromRGB(255, 0, 43)

				local direction1Part: Part = roomGridFolder:FindFirstChild(
					collision.X + direction1.X .. "_" .. collision.Z + direction1.Z
				)
				direction1Part.Color = Color3.fromRGB(255, 187, 0)

				if direction2 == otherDirection1 then
					local part: Part = roomGridFolder:FindFirstChild(
						collision.X + direction2.X .. "_" .. collision.Z + direction2.Z
					)
					part.Color = Color3.fromRGB(208, 255, 0)

					local otherPart: Part = roomGridFolder:FindFirstChild(
						collision.X + otherDirection2.X .. "_" .. collision.Z + otherDirection2.Z
					)
					otherPart.Color = Color3.fromRGB(255, 187, 0)
				elseif direction2 == otherDirection2 then
					local part: Part = roomGridFolder:FindFirstChild(
						collision.X + direction2.X .. "_" .. collision.Z + direction2.Z
					)
					part.Color = Color3.fromRGB(208, 255, 0)

					local otherPart: Part = roomGridFolder:FindFirstChild(
						collision.X + otherDirection1.X .. "_" .. collision.Z + otherDirection1.Z
					)
					otherPart.Color = Color3.fromRGB(255, 187, 0)
				else
					local p1: Part, p2: Part, p3: Part =
						roomGridFolder:FindFirstChild(
							collision.X + direction2.X .. "_" .. collision.Z + direction2.Z
						),
						roomGridFolder:FindFirstChild(
							collision.X + otherDirection1.X
								.. "_"
								.. collision.Z + otherDirection1.Z
						),
						roomGridFolder:FindFirstChild(
							collision.X + otherDirection2.X
								.. "_"
								.. collision.Z + otherDirection2.Z
						)

					p1.Color = Color3.fromRGB(255, 187, 0)
					p2.Color = Color3.fromRGB(255, 187, 0)
					p3.Color = Color3.fromRGB(255, 187, 0)
				end

				-- Display corridors too
				corridorFolder:Destroy()

				corridorFolder = DisplayUtils.plotCorridorStorage(
					worldPos,
					cellSize,
					corridorStorage,
					PLACED_CORRIDOR_COLOR,
					nil,
					2,
					0.5,
					0.5
				)

				corridorFolder.Name = "corridors"
				corridorFolder.Parent = folder

				-- Display the corridor too
				createdCorridorFolder:Destroy()
				createdCorridorFolder = Instance.new("Folder")

				DisplayUtils.plotCorridor(
					worldPos,
					cellSize,
					createdCorridorFolder,
					corridor,
					2,
					0.5,
					0.2,
					CORRIDOR_COLOR
				)

				createdCorridorFolder.Name = "created_corridors"
				createdCorridorFolder.Parent = folder
			elseif yieldNum == 2 then
				-- When the room is placed
				roomGridFolder:Destroy()

				roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)

				roomGridFolder.Name = "rooms"
				roomGridFolder.Parent = folder

				-- Display Adjacents
				adjacentsFolder:Destroy()

				adjacentsFolder =
					DisplayUtils.plotAdjacents(worldPos, cellSize, roomStorage, corridorStorage)

				adjacentsFolder.Name = "adjacents"
				adjacentsFolder.Parent = folder
			elseif yieldNum == 3 then
				-- Right after the division of the collision corridor
				corridorFolder:Destroy()

				corridorFolder = DisplayUtils.plotCorridorStorage(
					worldPos,
					cellSize,
					corridorStorage,
					PLACED_CORRIDOR_COLOR,
					nil,
					2,
					0.5,
					0.5
				)

				corridorFolder.Name = "corridors"
				corridorFolder.Parent = folder

				-- Display Rooms
				roomGridFolder:Destroy()

				roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)

				roomGridFolder.Name = "rooms"
				roomGridFolder.Parent = folder

				-- Display Adjacents
				adjacentsFolder:Destroy()

				adjacentsFolder =
					DisplayUtils.plotAdjacents(worldPos, cellSize, roomStorage, corridorStorage)

				adjacentsFolder.Name = "adjacents"
				adjacentsFolder.Parent = folder
			elseif yieldNum == 4 then
				-- Right after the division of the corridor
				corridor = v3

				if corridor == nil then
					-- Corridor not divided, just shrinked
					corridor = v2
				end

				-- Check if the corridor got roomified
				if corridor ~= nil then
					createdCorridorFolder:Destroy()
					createdCorridorFolder = Instance.new("Folder")

					DisplayUtils.plotCorridor(
						worldPos,
						cellSize,
						createdCorridorFolder,
						corridor,
						2,
						0.5,
						0.2,
						CORRIDOR_COLOR
					)

					createdCorridorFolder.Name = "created_corridors"
					createdCorridorFolder.Parent = folder
				end

				-- Display CorridorStorage too
				corridorFolder:Destroy()

				corridorFolder = DisplayUtils.plotCorridorStorage(
					worldPos,
					cellSize,
					corridorStorage,
					PLACED_CORRIDOR_COLOR,
					nil,
					2,
					0.5,
					0.5
				)

				corridorFolder.Name = "corridors"
				corridorFolder.Parent = folder

				-- Display rooms
				roomGridFolder:Destroy()

				roomGridFolder = DisplayUtils.createFlag2DGrid(roomGrid, worldPos, cellSize)

				roomGridFolder.Name = "rooms"
				roomGridFolder.Parent = folder

				-- Display Adjacents
				adjacentsFolder:Destroy()

				adjacentsFolder =
					DisplayUtils.plotAdjacents(worldPos, cellSize, roomStorage, corridorStorage)

				adjacentsFolder.Name = "adjacents"
				adjacentsFolder.Parent = folder
			end
		end

		return
	end

	if doDisplay then
		return UserInputService.InputEnded:Connect(tester)
	else
		-- Simulate R click
		local simulatedInput = { KeyCode = key }
		repeat
			local alive = tester(simulatedInput)
		until not alive
		print("Test finished")
	end

	return nil
end
