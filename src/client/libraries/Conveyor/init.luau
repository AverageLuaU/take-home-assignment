--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Baggage = require(script.Baggage)

local Conveyor = {}
Conveyor.__index = Conveyor

export type Class = typeof(setmetatable(
	{} :: {
		ConveyorInstance: Types.ConveyorInstance,
		StartAttachment: Attachment,
		EndAttachment: Attachment,
		Baggages: { [number]: Baggage.Class },

		BaggageActivated: typeof(Signal.new()),

		_BaggageAddedConnection: RBXScriptConnection,
		_BaggageRemovingConnection: RBXScriptConnection,
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

	self.BaggageActivated = Signal.new()
	self.Baggages = {}

	self.StartAttachment = ConveyorInstance:WaitForChild("Start") :: Attachment
	self.EndAttachment = ConveyorInstance:WaitForChild("End") :: Attachment
	self.ConveyorInstance = ConveyorInstance

	local function BaggageInstanceAdded(BaggageInstance: Instance)
		if not BaggageInstance:IsA("Folder") then
			return
		end
		self:AddBaggage(BaggageInstance)
	end
	local function BaggageInstanceRemoving(BaggageInstance: Instance)
		if not BaggageInstance:IsA("Folder") then
			return
		end

		-- Remove prematurely if the server informs the client to do so
		local BaggageId = tonumber(BaggageInstance.Name) :: number
		if self:GetBaggage(BaggageId) then
			self:RemoveBaggage(BaggageId)
		end
	end

	for _, BaggageInstance in ConveyorInstance:GetChildren() do
		BaggageInstanceAdded(BaggageInstance)
	end
	self._BaggageAddedConnection = ConveyorInstance.ChildAdded:Connect(BaggageInstanceAdded)
	self._BaggageRemovingConnection = ConveyorInstance.ChildRemoved:Connect(BaggageInstanceRemoving)

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
	local NewBaggage = Baggage.new(BaggageInstance, self.ConveyorInstance, self.StartAttachment, self.EndAttachment)
	self.Baggages[NewBaggage.Id] = NewBaggage
	NewBaggage:Start()

	NewBaggage.Activated:Connect(function()
		self.BaggageActivated:Fire(NewBaggage.Id)
	end)
	NewBaggage.Expired:Once(function()
		self:RemoveBaggage(NewBaggage.Id)
	end)
end

function Conveyor.Destroy(self: Class)
	InstantiatedConveyors[self.ConveyorInstance] = nil
	self._BaggageAddedConnection:Disconnect()
	self.BaggageActivated:Destroy()

	for _, ExistingBaggage in self.Baggages do
		ExistingBaggage:Destroy()
	end

	self.Baggages = nil :: any
	self.ConveyorInstance = nil :: any
end

return Conveyor
