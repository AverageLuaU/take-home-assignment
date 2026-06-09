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
		BaggageInstance: Folder,

		Container: Instance,
		BaggageVisual: typeof(BaggageTemplate),
		ClickDetector: ClickDetector,

		Expired: typeof(Signal.new()),
		Activated: typeof(Signal.new()),
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

	self.Expired = Signal.new()
	self.Activated = Signal.new()

	self.Container = Container
	self.Id = tonumber(BaggageInstance.Name)
	self.Material = Enum.Material:FromValue(BaggageInstance:GetAttribute("Material") :: number)
	self.Color = BaggageInstance:GetAttribute("Color")

	self.Lifetime = BaggageInstance:GetAttribute("Lifetime")
	self.CreationTime = BaggageInstance:GetAttribute("CreationTime")

	self.StartAttachment = StartAttachment
	self.EndAttachment = EndAttachment
	self:CreateVisual()

	self.ClickDetector = Instance.new("ClickDetector")
	self.ClickDetector.MaxActivationDistance = Configuration.DEFAULT_BAGGAGE_ACTIVATION_DISTANCE
	self.ClickDetector.MouseClick:Connect(function()
		self:Activate()
	end)
	self.ClickDetector.Parent = self.BaggageVisual

	self.BaggageInstance = BaggageInstance

	return self
end

function Baggage.Activate(self: Class)
	self.Activated:Fire()
end

function Baggage.Expire(self: Class)
	self.Expired:Fire()
end

function Baggage.Start(self: Class)
	assert(self._BaggageMoveConnection == nil, "Baggage.Start: Attempted to start while already started.")
	local StartServerTime = workspace:GetServerTimeNow() -- Client sync, use once to avoid heavy bandwidth usage
	local StartClientTime = os.clock()

	self._BaggageMoveConnection = RunService.Heartbeat:Connect(function()
		local ClientTimeElapsed = os.clock() - StartClientTime
		local Progress = (StartServerTime + ClientTimeElapsed - self.CreationTime) / self.Lifetime

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
	self:DestroyVisual()
	self.ClickDetector:Destroy()
	self.Expired:Destroy()
	self.Activated:Destroy()
	self.Container = nil :: any
	self.BaggageInstance = nil :: any
end

return Baggage
