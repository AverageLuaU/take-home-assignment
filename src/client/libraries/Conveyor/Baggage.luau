local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Signal = require(ReplicatedStorage.Packages.Signal)
local Configuration = require(ReplicatedStorage.Shared.Configuration)

local BaggageTemplate = ReplicatedStorage.Assets.Baggage

local Baggage = {}
Baggage.__index = Baggage

export type Class = typeof(setmetatable(
	{} :: {
		Id: number,
		Color: Color3,
		Material: Enum.Material,
		CreationTime: number,

		StartAttachment: Attachment,
		EndAttachment: Attachment,
		BaggageVisual: typeof(BaggageTemplate),
		BaggageInstance: Folder,
		Container: Instance,

		Expired: typeof(Signal.new()),
		_BaggageMoveConnection: RBXScriptConnection?,
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

	self.Container = Container
	self.Id = BaggageInstance:GetAttribute("Id")
	self.Material = Enum.Material:FromValue(BaggageInstance:GetAttribute("Material") :: number)
	self.Color = BaggageInstance:GetAttribute("Color")

	self.Lifetime = BaggageInstance:GetAttribute("Lifetime")
	self.CreationTime = BaggageInstance:GetAttribute("CreationTime")

	self:CreateVisual()

	self.StartAttachment = StartAttachment
	self.EndAttachment = EndAttachment
	self.BaggageInstance = BaggageInstance

	return self
end

function Baggage.Expire(self: Class)
	self.Expired:Fire()
end

function Baggage.Start(self: Class)
	assert(self._BaggageMoveConnection == nil, "Baggage.Start: Attempted to start while already started.")
	self._BaggageMoveConnection = RunService.Heartbeat:Connect(function()
		local CurrentServerTime = workspace:GetServerTimeNow() -- Client sync
		local Progress = CurrentServerTime / (self.CreationTime + self.Lifetime)

		if Progress >= 1 then
			self:Expire()
			return
		end

		self.BaggageVisual.CFrame = self.StartAttachment.WorldCFrame:Lerp(self.EndAttachment.WorldCFrame, Progress)
	end)
end

function Baggage.Stop(self: Class)
	if self._BaggageMoveConnection then
		self._BaggageMoveConnection:Disconnect()
		self._BaggageMoveConnection = nil
	end
end

function Baggage.CreateVisual(self: Class)
	self.BaggageVisual = BaggageTemplate:Clone()
	self.BaggageVisual.Color = self.Color
	self.BaggageVisual.Material = self.Material
	self.BaggageVisual.CFrame = self.StartAttachment.WorldCFrame

	-- Spawn Animation
	self.BaggageVisual.Transparency = 1
	self.BaggageVisual.Rotation = Vector3.one * 180
	TweenService:Create(self.BaggageVisual, Configuration.BAGGAGE_SPAWN_ANIMATION_TWEENINFO, {
		Transparency = 0,
		Rotation = Vector3.zero,
	}):Play()

	self.BaggageVisual.Parent = self.Container
end

function Baggage.DestroyVisual(self: Class)
	-- Destroy Animation (before destroy visual)
	local DestroyAnimation = TweenService:Create(self.BaggageVisual, Configuration.BAGGAGE_SPAWN_ANIMATION_TWEENINFO, {
		Transparency = 1,
		Rotation = Vector3.one * 180,
	})
	DestroyAnimation.Completed:Once(function()
		self.BaggageVisual:Destroy()
	end)
	DestroyAnimation:Play()
end

function Baggage.Destroy(self: Class)
	self:Stop()
	self.Container = nil :: any
	self.BaggageInstance = nil :: any
end

return Baggage
