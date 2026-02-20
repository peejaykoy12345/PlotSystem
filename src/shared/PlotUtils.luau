local module = {}

function module:ArePlantsNearby(plants, pos: Vector3, scanRange: number)
	for _, plant in ipairs(plants) do
		local plantPos = plant.Model:GetPivot().Position
		local nearbyRange = plant.nearbyRange or 0

		local dist = (pos - plantPos).Magnitude
		if dist <= scanRange + nearbyRange then
			return true
		end
	end

	return false
end

return module 