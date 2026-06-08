local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")

local SpawnIntervalSelectionGui = ServerStorage.Assets.SpawnIntervalSelector
local SpawnIntervalSelectionPlayer: Player?

local function GrantSpawnIntervalSelectionGui(Player: Player)
	assert(SpawnIntervalSelectionPlayer == nil, "GrantSpawnIntervalSelectionGui: SpawnIntervalSelectionPlayer already assigned.")
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

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)
