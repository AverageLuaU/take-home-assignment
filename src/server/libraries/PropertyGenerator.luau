local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Configuration = require(ReplicatedStorage.Shared.Configuration)
local RNG = Random.new()

local PropertyGenerator = {}

-- Randomly select baggage material
function PropertyGenerator.GenerateBaggageMaterial(): Enum.Material
	local MaterialList = Configuration.POSSIBLE_BAGGAGE_MATERIALS
	return MaterialList[RNG:NextInteger(1, #MaterialList)]
end

-- Randomly generate baggage color
function PropertyGenerator.GenerateBaggageColor(): Color3
	local NewHue = RNG:NextNumber(
		Configuration.POSSIBLE_BAGGAGE_COLOR_HUE_RANGE[1],
		Configuration.POSSIBLE_BAGGAGE_COLOR_HUE_RANGE[2]
	)
	local NewSaturation = RNG:NextNumber(
		Configuration.POSSIBLE_BAGGAGE_COLOR_SATURATION_RANGE[1],
		Configuration.POSSIBLE_BAGGAGE_COLOR_SATURATION_RANGE[2]
	)
	local NewValue = RNG:NextNumber(
		Configuration.POSSIBLE_BAGGAGE_COLOR_VALUE_RANGE[1],
		Configuration.POSSIBLE_BAGGAGE_COLOR_VALUE_RANGE[2]
	)

	return Color3.fromHSV(NewHue, NewSaturation, NewValue)
end

return PropertyGenerator
