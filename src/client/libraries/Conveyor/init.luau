--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Baggage = require(script.Baggage)

local Conveyor = {}
Conveyor.__index = Conveyor

export type Class = typeof(setmetatable(
	{} :: {
		ConveyorInstance: Types.ConveyorInstance,
		Baggages: { [number]: Baggage.Class },
		_BaggageAddedConnection: RBXScriptConnection,
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
	InstantiatedConveyors[ConveyorInstance] = self

	self.ConveyorInstance = ConveyorInstance

	local function BaggageInstanceAdded(BaggageInstance: Instance)
		if not BaggageInstance:IsA("Folder") then
			return
		end
		self:AddBaggage(BaggageInstance)
	end

	for _, BaggageInstance in ConveyorInstance:GetChildren() do
		BaggageInstanceAdded(BaggageInstance)
	end
	self._BaggageAddedConnection = ConveyorInstance.ChildAdded:Connect(BaggageInstanceAdded)

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

function Conveyor.AddBaggage(self: Class, BaggageInstance: Folder)
	local StartAttachment = self.ConveyorInstance.Start
	local EndAttachment = self.ConveyorInstance.End

	local NewBaggage = Baggage.new(BaggageInstance, self.ConveyorInstance, StartAttachment, EndAttachment)
	self.Baggages[NewBaggage.Id] = NewBaggage
	NewBaggage:Start()

	NewBaggage.Expired:Once(function()
		self:RemoveBaggage(NewBaggage.Id)
	end)
end

function Conveyor.Destroy(self: Class)
	InstantiatedConveyors[self.ConveyorInstance] = nil
	self._BaggageAddedConnection:Disconnect()

	for _, ExistingBaggage in self.Baggages do
		ExistingBaggage:Destroy()
	end

	self.Baggages = nil :: any
	self.ConveyorInstance = nil :: any
end

return Conveyor
