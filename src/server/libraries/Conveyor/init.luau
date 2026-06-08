--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Configuration = require(ReplicatedStorage.Shared.Configuration)
local PropertyGenerator = require(ServerScriptService.Libraries.PropertyGenerator)
local Types = require(ReplicatedStorage.Shared.Types)
local Baggage = require(script.Baggage)

local Conveyor = {}
Conveyor.__index = Conveyor

export type Class = typeof(setmetatable(
	{} :: {
		ConveyorInstance: Types.ConveyorInstance,
		SpawnInterval: number,
		Baggages: { [number]: Baggage.Class },
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

function Conveyor.GetBaggage(self: Class, BaggageId: number): Baggage.Class?
	return self.Baggages[BaggageId]
end

function Conveyor.RemoveBaggage(self: Class, BaggageId: number)
	local ExistingBaggage = self:GetBaggage(BaggageId)
	assert(ExistingBaggage ~= nil, "Conveyor.RemoveBaggage: Attempted to remove non-existant baggage id: " .. BaggageId)

	self.Baggages[BaggageId] = nil
	ExistingBaggage:Destroy()
end

function Conveyor.AddBaggage(self: Class)
	local NewBaggageMaterial = PropertyGenerator.GenerateBaggageMaterial()
	local NewBaggageColor = PropertyGenerator.GenerateBaggageColor()

	local NewBaggage =
		Baggage.new(self.ConveyorInstance, Configuration.DEFAULT_BAGGAGE_LIFETIME, NewBaggageMaterial, NewBaggageColor)
	self.Baggages[NewBaggage.Id] = NewBaggage

	NewBaggage.Expired:Once(function()
		self:RemoveBaggage(NewBaggage.Id) -- Destroy and deindex
	end)
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
