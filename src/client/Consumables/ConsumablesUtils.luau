local Utils = {}

function Utils:GetPlantName(name: string)
	-- Remove [number] at the end
	name = string.gsub(name, "%s%[%d+%]$", "")
	
	-- Remove " Seed" at the end
	name = string.gsub(name, " Seed$", "")
	
	return name
end

return Utils