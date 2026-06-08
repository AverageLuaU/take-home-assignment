local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local BaggageTemplate = ReplicatedStorage.Assets.Baggage

local Baggage = {}
Baggage.__index = Baggage

export type Class = typeof(setmetatable(
	{} :: {
		Id: number,
		Material: Enum.Material,
		Color: Color3,
		CreationTime: number,
		BaggageVisual: typeof(BaggageTemplate),

		BaggageInstance: Folder,
		Expired: typeof(Signal.new()),
	},
	Baggage
))

function Baggage.new(
	BaggageInstance: Folder,
	Container: Instance,
	StartAttachment: Attachment,
	EndAttachment: Attachment
): Class
	local self = setmetatable({}, Baggage) :: Class

	self.Id = BaggageInstance:GetAttribute("Id")
	self.Material = Enum.Material:FromValue(BaggageInstance:GetAttribute("Material") :: number)
	self.Color = BaggageInstance:GetAttribute("Color")
	self.CreationTime = BaggageInstance:GetAttribute("CreationTime")

	self.StartAttachment = StartAttachment
	self.EndAttachment = EndAttachment

	self.BaggageVisual = BaggageTemplate:Clone()
	self.BaggageVisual.Color = self.Color
	self.BaggageVisual.Material = self.Material
	self.BaggageVisual.CFrame = StartAttachment.WorldCFrame
	-- Spawn Animation
	self.BaggageVisual.Parent = Container

	self.BaggageInstance = BaggageInstance

	return self
end

function Baggage.Start(self: Class) end

function Baggage.Stop(self: Class) end

function Baggage.Destroy(self: Class)
	-- Destroy Animation (before destroy visual)
	self.BaggageInstance = nil :: any
end

return Baggage
