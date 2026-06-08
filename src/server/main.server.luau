local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local Configuration = require(ReplicatedStorage.Shared.Configuration)
local Types = require(ReplicatedStorage.Shared.Types)
local Conveyor = require(ServerScriptService.Libraries.Conveyor)

local CurrentSpawnInterval = Configuration.DEFAULT_SPAWN_INTERVAL
local SpawnIntervalSelectionGui = ServerStorage.Assets.SpawnIntervalSelector
local SpawnIntervalSelectionPlayer: Player?

local function GrantSpawnIntervalSelectionGui(Player: Player)
	assert(
		SpawnIntervalSelectionPlayer == nil,
		"GrantSpawnIntervalSelectionGui: SpawnIntervalSelectionPlayer already assigned."
	)
	SpawnIntervalSelectionPlayer = Player
	SpawnIntervalSelectionGui:Clone().Parent = Player.PlayerGui
end

local function PlayerAdded(Player: Player)
	if SpawnIntervalSelectionPlayer == nil then
		GrantSpawnIntervalSelectionGui(Player)
	end
end

local function PlayerRemoving(Player: Player)
	if Player == SpawnIntervalSelectionPlayer then
		SpawnIntervalSelectionPlayer = nil
	end
end

local function ConveyorAdded(ConveyorInstance: Types.ConveyorInstance)
	local NewConveyor = Conveyor.new(ConveyorInstance)
	NewConveyor:SetSpawnInterval(CurrentSpawnInterval)
	NewConveyor:StartSpawning()
end

local function ConveyorRemoving(ConveyorInstance: Types.ConveyorInstance)
	local ExistingConveyor = Conveyor.getConveyor(ConveyorInstance)
	if ExistingConveyor then
		ExistingConveyor:Destroy()
	end
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)

for _, ConveyorInstance in CollectionService:GetTagged(Configuration.CONVEYOR_TAG) do
	ConveyorAdded(ConveyorInstance)
end
CollectionService:GetInstanceAddedSignal(Configuration.CONVEYOR_TAG):Connect(ConveyorAdded)
CollectionService:GetInstanceRemovedSignal(Configuration.CONVEYOR_TAG):Connect(ConveyorRemoving)
