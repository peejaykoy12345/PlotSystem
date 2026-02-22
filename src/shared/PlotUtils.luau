local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local remotes = require(ReplicatedStorage.Packages.remotes) 
local NotifEvent: RemoteEvent = remotes:getEventAsync("Notification")

local SharedFolder = ReplicatedStorage.Shared
local PlantsData = require(SharedFolder.PlantsData)

local isServer = RunService:IsServer()

local module = {}

function module:ArePlantsNearby(plants, pos: Vector3, scanRange: number)
	for _, plant in ipairs(plants) do
		local plantPos = plant.CFrame.Position
		local nearbyRange = plant.nearbyRange or 0

		local dist = (pos - plantPos).Magnitude
		if dist <= scanRange + nearbyRange then
			return true
		end
	end
	return false
end

function module:IsOnGround(pos: Vector3, ignoreList: {Instance}?, rayLength: number?)
    ignoreList = ignoreList or {}
    rayLength = rayLength or 5

    local rayOrigin = pos + Vector3.new(0, 5, 0)
    local rayDirection = Vector3.new(0, -rayLength, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = ignoreList

    local rayResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

	if rayResult then
		print(rayResult.Instance.Name)
		print(rayResult.Instance.Transparency)
		print(ignoreList)
	end

    return rayResult ~= nil and rayResult.Instance.Name ~= "DialogueFloatingPart"
end

function module:IsInside(part: BasePart, pos: Vector3)
	-- We treat the part's center as (0,0,0)
	local relativePos: Vector3 = part.CFrame:PointToObjectSpace(pos)
	-- We use half because the part extends equally in both directions from its center
	local halfSize: Vector3 = part.Size * 0.5

	-- Check if the position is inside the part's X and Z axis
	-- math.abs makes sure we check both positive and negative directions
	local insideX: boolean = math.abs(relativePos.X) <= halfSize.X
	local insideZ: boolean = math.abs(relativePos.Z) <= halfSize.Z

	return insideX and insideZ -- Return the result (True if inside and false if not)
end


function module:Notify(plr: Player, msg: string)
	if isServer then
		NotifEvent:FireClient(plr, msg)
	end
end

type CanPlacePlantParams = {
	IsOnGroundExcludeDescendants: {any}
}

function module:CanPlacePlant(plr: Player, plot, plantName: string, pos: Vector3, params: CanPlacePlantParams?): boolean
	local plantData = PlantsData[plantName]
	if not plantData then 
		warn(`{plantName} does not exist in PlantsData`) -- Fallback just in case we mispell when adding new plants
		return false
	end

	local Y_OFFSET = plantData.Offset.Position.Y

	local plants = plot.plants

	-- The dirt part of the plot
	local plow: BasePart = plot.plot.Plow
	local plow2: BasePart = plot.plot.Plow2	

	if not self:IsOnGround(pos, params.IsOnGroundExcludeDescendants, 6 + Y_OFFSET) then
        return false
    end

	-- nearbyRange is the radius of the space that the plant will take
	-- We name it scan range because in the utils it's the thing checking
	local scanRange = plantData.nearbyRange
	if self:ArePlantsNearby(plants, pos, scanRange) then
		-- We don't notify the user because the client already does checking before firing the remote
		-- but if an exploiter fires it anyway they won't get past
		return false
	end

	-- Check if the position of the click is inside one of the plows
	if self:IsInside(plow, pos) or self:IsInside(plow2, pos) then
		return true
	else
		-- If planted somewhere else then notify them
		self:Notify(plr, "Can't place plants because it needs to be planted on the soil of your plot")
		return false
	end
end

return module 