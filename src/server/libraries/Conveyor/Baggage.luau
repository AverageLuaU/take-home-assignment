--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local BaggageId = 0

local Baggage = {}
Baggage.__index = Baggage

export type Class = typeof(setmetatable(
	{} :: {
		Id: number,
		BaggageInstance: Folder,
	},
	Baggage
))

function Baggage.new(ConveyorInstance: Types.ConveyorInstance, Lifetime: number)
	local self = setmetatable({}, Baggage) :: Class

	self.Id = BaggageId -- UID
	BaggageId += 1

	local BaggageInstance = Instance.new("Folder")
    BaggageInstance:SetAttribute("Id", self.Id)
    

    BaggageInstance.Parent = ConveyorInstance
    self.BaggageInstance = BaggageInstance

	return self
end

function Baggage:SetLifetime(NewLifetime: number) end

function Baggage.Destroy(self) end

return Baggage
