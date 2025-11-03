--[=[
Class SeededRandom

SeededRandom is a class that will provide the same number (between 0 and 1023)
for the same seed. It provides a new number each call.
]=]
local SeededRandom = {}
SeededRandom.__index = SeededRandom

SeededRandom.MAX_RESULT = 1023

export type SeededRandom = typeof(SeededRandom.new())

function SeededRandom.new(seed: number)
	return setmetatable({
		_seed = seed,
		_step = 0,
	}, SeededRandom)
end

function SeededRandom.random(self: SeededRandom)
	math.randomseed(self._seed + self._step)
	self._step += 1
	return math.random(0, 1023)
end

return SeededRandom
