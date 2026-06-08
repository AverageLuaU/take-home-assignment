local roblox = require("@lune/roblox")
local fs = require("@lune/fs")

local content = fs.readFile("./import.rbxl") 
local game = roblox.deserializePlace(content)

fs.writeFile("./map/Workspace.rbxm", roblox.serializeModel({game.Workspace}))
fs.writeFile("./map/Lighting.rbxm", roblox.serializeModel({game.Lighting}))