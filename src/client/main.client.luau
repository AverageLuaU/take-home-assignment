--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Configuration = require(ReplicatedStorage.Shared.Configuration)
local Types = require(ReplicatedStorage.Shared.Types)
local Conveyor = require(ReplicatedStorage.Libraries.Conveyor)

local ActivateBaggageEvent = ReplicatedStorage.Shared.Events.ActivateBaggage
local SetSpawnIntervalEvent = ReplicatedStorage.Shared.Events.SetSpawnInterval

local function InitializeSpawnIntervalSelector(SpawnIntervalSelectionGui: Types.SpawnIntervalSelectorGui)
	-- Quick client-side implementation
	local Frame = SpawnIntervalSelectionGui.Frame
	local Bar = Frame.Bar
	local Hold = Frame.Hold
	local DragDetector = Hold.UIDragDetector

	local CurrentDesiredValue: number = Configuration.DEFAULT_SPAWN_INTERVAL
	local UpdateDesiredValueTask: thread?

	SpawnIntervalSelectionGui.Minimum.Text = Configuration.SPAWN_INTERVAL_MINIMUM
	SpawnIntervalSelectionGui.Maximum.Text = Configuration.SPAWN_INTERVAL_MAXIMUM
	SpawnIntervalSelectionGui.Current.Text = "Current: " .. CurrentDesiredValue

	local function UpdateDrag()
		local Scale = math.clamp(DragDetector.DragUDim2.X.Scale, -0.5, 0.5)
		local NewScale = math.map(Scale, -0.5, 0.5, 0, 1)
		Bar.Size = UDim2.fromScale(NewScale, 1)
		CurrentDesiredValue = (Configuration.SPAWN_INTERVAL_MAXIMUM - Configuration.SPAWN_INTERVAL_MINIMUM) * NewScale
			+ Configuration.SPAWN_INTERVAL_MINIMUM
		SpawnIntervalSelectionGui.Current.Text = ("Current: %.2f"):format(CurrentDesiredValue)
	end

	local function StartDrag()
		UpdateDesiredValueTask = task.spawn(function() -- Limit remote frequency to save bandwidth
			while true do
				task.wait(Configuration.SPAWN_INTERVAL_UPDATE_FREQUENCY)
				SetSpawnIntervalEvent:FireServer(CurrentDesiredValue)
			end
		end)
	end

	local function StopDrag()
		if UpdateDesiredValueTask and coroutine.status(UpdateDesiredValueTask) == "suspended" then
			task.cancel(UpdateDesiredValueTask)
			UpdateDesiredValueTask = nil
		end
		SetSpawnIntervalEvent:FireServer(CurrentDesiredValue)
	end

	DragDetector.DragStart:Connect(StartDrag)
	DragDetector.DragContinue:Connect(UpdateDrag)
	DragDetector.DragEnd:Connect(StopDrag)
end

local function ConveryorAdded(ConveyorInstance: Types.ConveyorInstance)
	local NewConveyor = Conveyor.new(ConveyorInstance)

	NewConveyor.BaggageActivated:Connect(function(BaggageId: number)
		print("Baggage Id: " .. BaggageId)
		ActivateBaggageEvent:FireServer(ConveyorInstance, BaggageId)
	end)
end

local function ConveyorRemoving(ConveyorInstance: Types.ConveyorInstance)
	local ExistingConveyor = Conveyor.getConveyor(ConveyorInstance)
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
