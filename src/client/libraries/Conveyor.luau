--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Types = require(ReplicatedStorage.Shared.Types)

local Conveyor = {}
Conveyor.__index = Conveyor

export type Class = typeof(setmetatable(
	{} :: {
		ConveyorInstance: BasePart,
	},
	Conveyor
))

local InstantiatedConveyors = {} :: {
	[BasePart]: Class,
}

function Conveyor.getConveyor(ConveyorInstance: BasePart): Class?
	return InstantiatedConveyors[ConveyorInstance]
end

function Conveyor.new(ConveyorInstance: BasePart): Class
	local self = setmetatable({}, Conveyor) :: Class
	InstantiatedConveyors[ConveyorInstance] = self

	self.ConveyorInstance = ConveyorInstance

	return self
end

function Conveyor.Destroy(self: Class)
	InstantiatedConveyors[self.ConveyorInstance] = nil
	self.ConveyorInstance = nil :: any
end

return Conveyor
