local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local content = fs.readFile("./import.rbxl") 
local game = roblox.deserializePlace(content)

fs.writeFile("./map/Workspace.rbxm", roblox.serializeModel({game.Workspace}))
fs.writeFile("./map/Lighting.rbxm", roblox.serializeModel({game.Lighting}))
fs.writeFile("./assets/client/Assets.rbxm", roblox.serializeModel({game.ReplicatedStorage.Assets}))
fs.writeFile("./assets/server/Assets.rbxm", roblox.serializeModel({game.ServerStorage.Assets}))