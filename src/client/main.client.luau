--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Configuration = require(ReplicatedStorage.Shared.Configuration)
local Types = require(ReplicatedStorage.Shared.Types)
local Conveyor = require(ReplicatedStorage.Libraries.Conveyor)

local function InitializeSpawnIntervalSelector(SpawnIntervalSelectionGui: ScreenGui) end

local function ConveryorAdded(ConveyorInstance: Types.ConveyorInstance)
	local NewConveyor = Conveyor.new(ConveyorInstance)
end

local function ConveyorRemoving(ConveyorInstance: Types.ConveyorInstance)
	local ExistingConveyor = Conveyor.new(ConveyorInstance)
	if ExistingConveyor then
		ExistingConveyor:Destroy()
	end
end

-- Listen for Conveyors added to the DataModel
for _, ConveyorPart in CollectionService:GetTagged(Configuration.CONVEYOR_TAG) do
	ConveryorAdded(ConveyorPart)
end
CollectionService:GetInstanceAddedSignal(Configuration.CONVEYOR_TAG):Connect(ConveryorAdded)
CollectionService:GetInstanceRemovedSignal(Configuration.CONVEYOR_TAG):Connect(ConveyorRemoving)

-- Listen for SpawnIntervalSelectorGui
for _, SpawnIntervalSelectorGui in CollectionService:GetTagged(Configuration.SPAWN_INTERVAL_SELECTOR_GUI_TAG) do
	InitializeSpawnIntervalSelector(SpawnIntervalSelectorGui)
end
CollectionService:GetInstanceAddedSignal(Configuration.SPAWN_INTERVAL_SELECTOR_GUI_TAG)
	:Connect(InitializeSpawnIntervalSelector)
