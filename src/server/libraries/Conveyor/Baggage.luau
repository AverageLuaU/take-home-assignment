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

function Baggage.new(ConveyorInstance: Types.ConveyorInstance)
	local self = setmetatable({}, Baggage) :: Class

	self.Id = BaggageId
	BaggageId += 1

	self.BaggageInstance = Instance.new("Folder")

	return self
end

function Baggage:SetLifetime(NewLifetime: number) end

function Baggage.Destroy(self) end

return Baggage
