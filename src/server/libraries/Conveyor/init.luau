--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Types = require(ReplicatedStorage.Shared.Types)
local Baggage = require(script.Baggage)

local BaggageTemplate: BasePart = ReplicatedStorage.Assets.Baggage

local Conveyor = {}
Conveyor.__index = Conveyor

export type Class = typeof(setmetatable(
	{} :: {
		ConveyorInstance: Types.ConveyorInstance,
		SpawnInterval: number,
		_SpawnConnection: RBXScriptConnection?,
	},
	Conveyor
))

local InstantiatedConveyors = {} :: {
	[Types.ConveyorInstance]: Class,
}

function Conveyor.getConveyor(ConveyorInstance: Types.ConveyorInstance): Class?
	return InstantiatedConveyors[ConveyorInstance]
end

function Conveyor.new(ConveyorInstance: Types.ConveyorInstance): Class
	local self = setmetatable({}, Conveyor) :: Class

	self.ConveyorInstance = ConveyorInstance

	return self
end

function Conveyor.RemoveBaggage(self: Class, BaggageId: number) end

function Conveyor.AddBaggage(self: Class)
	-- local NewBaggage = Baggage.new(self.ConveyorInstance)
end

function Conveyor.SetSpawnInterval(self: Class, NewSpawnInterval: number)
	self.SpawnInterval = NewSpawnInterval
end

function Conveyor.StartSpawning(self: Class)
	assert(
		self.SpawnInterval ~= nil,
		"Conveyor.StartSpawning: Attempted to start conveyor before assigning SpawnInterval."
	)
	assert(self._SpawnConnection == nil, "Conveyor.StartSpawning: Attempted to start conveyor while started.")

	local StartTime = 0
	self._SpawnConnection = RunService.Heartbeat:Connect(function()
		local CurrentTime = os.clock()
		local TimeElapsed = CurrentTime - StartTime

		if TimeElapsed >= self.SpawnInterval then
			StartTime = CurrentTime
			self:AddBaggage()
		end
	end)
end

function Conveyor.StopSpawning(self: Class)
	if self._SpawnConnection then
		self._SpawnConnection:Disconnect()
		self._SpawnConnection = nil
	end
end

function Conveyor.Destroy(self: Class)
	self:StopSpawning()
end

return Conveyor
