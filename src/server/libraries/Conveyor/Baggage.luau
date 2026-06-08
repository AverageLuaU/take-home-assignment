--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)
local Signal = require(ReplicatedStorage.Packages.Signal)

local BaggageId = 0

local Baggage = {}
Baggage.__index = Baggage

export type Class = typeof(setmetatable(
	{} :: {
		Id: number,
		Lifetime: number,
		CreationTime: number,

		Material: Enum.Material,
		Color: Color3,
		BaggageInstance: Folder,

		Expired: typeof(Signal.new()),
		_ExpirationTask: thread?,
	},
	Baggage
))

function Baggage.new(ConveyorInstance: Types.ConveyorInstance, Lifetime: number, Material: Enum.Material, Color: Color3)
	local self = setmetatable({}, Baggage) :: Class

	self.Expired = Signal.new()

	self.Material = Material
	self.Color = Color

	self.Id = BaggageId -- UID
	BaggageId += 1

	self.BaggageInstance = Instance.new("Folder")
	self.BaggageInstance:SetAttribute("Id", self.Id)
	self.BaggageInstance:SetAttribute("Material", Material.Value) -- Attributes don't store materials natively, can reconstruct on client
	self.BaggageInstance:SetAttribute("Color", Color)
	self.BaggageInstance:SetAttribute("CreationTime", workspace:GetServerTimeNow()) -- For client sync

	self.CreationTime = os.clock()
	self:SetLifetime(Lifetime)

	self.BaggageInstance.Parent = ConveyorInstance

	return self
end

function Baggage.CancelExpirationTask(self: Class)
	if self._ExpirationTask and coroutine.status(self._ExpirationTask) == "suspended" then
		task.cancel(self._ExpirationTask)
	end
end

function Baggage.Expire(self: Class)
	self:CancelExpirationTask()
	self.Expired:Fire()
end

function Baggage.RefreshExpirationTask(self: Class)
	self:CancelExpirationTask()

	local TimeElapsed = os.clock() - self.CreationTime
	self._ExpirationTask = task.delay(self.Lifetime - TimeElapsed, function()
		self:Expire()
	end)
end

function Baggage.SetLifetime(self: Class, NewLifetime: number)
	if os.clock() - self.CreationTime <= NewLifetime then
		self:Expire()
	else
		self.Lifetime = NewLifetime
		self.BaggageInstance:SetAttribute("Lifetime", NewLifetime)
		self:RefreshExpirationTask()
	end
end

function Baggage.Destroy(self: Class)
	self:CancelExpirationTask()
	self.Expired:Destroy()
	self.BaggageInstance:Destroy()
end

return Baggage
