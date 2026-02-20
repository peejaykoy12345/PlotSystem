local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Packages = ReplicatedStorage.Packages

-- Open source library for creating and fetching remotes
local remotes = require(Packages.remotes) 

-- Uses profile store for reliable datastore
local PlotProfileStore = require(script.PlotProfileStore) -- For the datastore (e.g plant cframe and growth)

local Classes = ServerScriptService.Classes 

-- PlantClass contains methods like Grow, LoadGrowth and
-- each plant will have a unique function provided by the PlantsData module
local PlantsClass = require(Classes.Plants)

local SharedFolder = ReplicatedStorage.Shared

-- For context:
-- Plants have different Growth function so it is stored here:
-- Also their other stats like growth rate and max growth is also stored here:
local PlantsData = require(SharedFolder.PlantsData)
-- Table utilities like copyTable and mergeTable
-- Makes it easier to manipulate tables
-- and makes it so that other scripts can use these utils
local TableUtils = require(SharedFolder.TableUtils)

-- This is for shared utilities such as are plants nearby
-- The client also needs to check if plants are nearby for visual feedback
local PlotUtils = require(SharedFolder.PlotUtils)

-- If the event doesn't exist yet remotes module creates it but only if it's ran on the server
-- Client event for sending notifications
local NotifEvent: RemoteEvent = remotes:getEventAsync("Notification")

local Plot = {}
Plot.__index = Plot

local GROW_TICK = 1 -- Seconds per grow in plants
local TICK_UPGRADE_TICK = 100 -- Seconds for upgrade

local DEBUG = false

function Plot.new(params)
	assert(params.plot, "Plot is needed")
	local self = setmetatable({}, Plot)

	-- There won't be any owner yet because the plot is only being initialized
	self.owner = nil  
	self.plot = params.plot
	self.plants = {}

	-- Tiers can incrase max plants on a plot and depending on the plant
	-- it will grow faster.
	-- For the only plant currently in the game "Brick" the default growth rate is 1
	-- For tier 2 the growth rate is 2 and so on.
	self.tier = 1 
	self.maxTier = 3

	-- So the player can't plant that many plants and actually needs to upgrade tier
	self.maxPlants = 10

	-- This is where the model of the plants are stored and put in
	self.plantsFolder = self.plot.Plants

	-- If triggered the server handler can know who the owner is and TryPlace and TryDestroy gets an event connected to it
	-- This is important because when the PlantEven or Unplantevent triggers the server will need to call their respective methods
	-- but first the server needs to know what plot the player even owns in the first place so we use this
	self.OnClaim = Instance.new("BindableEvent") 
	-- If triggered the server handler will unference the plot owner
	self.OnUnclaim = Instance.new("BindableEvent")

	self:ConnectProximityPrompt() -- Connect the clickdetector event

	return self
end

function Plot:ConnectProximityPrompt()
	local plot = self.plot
	local ProximityPrompt = Instance.new("ProximityPrompt")
	ProximityPrompt.ActionText = "Claim Plot"
	ProximityPrompt.RequiresLineOfSight = false
	ProximityPrompt.Parent = plot.Sign.Part

	ProximityPrompt.Triggered:Connect(function(player)
		self:TryClaimPlot(player) -- Will check if the player is able to claim first
	end)
end

function Plot:StartCoroutine(coroutineName: string, coroutineFunction: () -> ())
	-- If a coroutine is already running with the same name, stop it
	-- and start a new one.
	-- This makes it so that the coroutine is fresh and nothing is left off of the last player plot
	if self[coroutineName] and coroutine.status(self[coroutineName]) ~= "dead" then -- Prevent unexpected bugs on runtime
		coroutine.close(self[coroutineName]) -- stop coroutine
	end

	-- We don't use different flags for the coroutines because
	-- these coroutines must stop together not just one.
	self.stopCoroutine = false  -- Reset flag

	self[coroutineName] = coroutine.create(coroutineFunction)

	-- I use coroutines because it offers more control over task.spawn
	coroutine.resume(self[coroutineName]) -- Start coroutine
end

function Plot:StartGrowCoroutine()
	self:StartCoroutine("growCoroutine", function()
		while task.wait(GROW_TICK) do
			if self.stopCoroutine then break end
			-- Purpose: To know which plants are in self.plants
			-- We use this to debug if plant's arent growing or simply doesn't exist
			if DEBUG then
				print("========= Contents of self.plants is: =========")
				print(self.plants)
			end
			for _, plant in pairs(self.plants) do
				-- Purpose: To know if the model actually exists in workspace (To know if there are ghost plants)
				if DEBUG then
					print("=== GROW() CALLED ===")
					print("self:", plant)
					print("plant.Model:", plant.Model)
				end
				-- Calls CanGrow()
				-- If fully grown we skip
				if not plant:CanGrow() then
					continue
				end
				-- Call the unique grow method on each plant
				-- PlantsData store :Grow() methods for each plant
				-- Some plants might grow differently so we store in in PlantsData
				plant:Grow()
			end
		end
	end)
end

function Plot:StartUpgradeTierCoroutine()
	self:StartCoroutine("upgradeTierCoroutine", function()
		while task.wait(TICK_UPGRADE_TICK) do
			if self.stopCoroutine then break end
			if self.tier >= self.maxTier then
				return -- Stop the coroutine when it hits max tier (so it wont waste resources)
			end

			self.tier += 1 

			self:Upgrade() -- Upgrade to the latest tier

			-- Let the player know that their plot has upgraded
			NotifEvent:FireClient(self.owner, `Your plot has been upgraded to tier {self.tier}! You can now plant up to {self.maxPlants} plants!`)
		end
	end)
end

-- If called when the tier upgrades the tier will upgrade to the next tier
-- If called to load the tier it will upgrade to the loaded tier
function Plot:Upgrade()
	local tier = self.tier

	local newMaxPlants = tier * 10 -- For each tier the player will be able to store 10 more plants!
	self.maxPlants = newMaxPlants
end

function Plot:CanClaimPlot(plr: Player)
	-- Player can't claim two plots at the same time
	if plr:GetAttribute("HasClaimedPlot") == true then
		NotifEvent:FireClient(plr, "You already own a plot!")
		return false
	end

	-- Player can't claim owned plots
	if self.owner ~= nil then
		NotifEvent:FireClient(plr, "You can't claim an owned plot!")
		return false
	end

	return true
end

function Plot:TryClaimPlot(plr: Player)
	if not self:CanClaimPlot(plr) then 
		return 
	end

	self.owner = plr

	plr:SetAttribute("HasClaimedPlot", true) -- Add the flag so that this player won't be able to claim two plots

	self:LoadData() -- Load the data from profile store

	-- Start the grow coroutine and upgrade coroutine
	self:StartGrowCoroutine() 
	self:StartUpgradeTierCoroutine()

	-- Let PlotProfileStore know that we now own this plot
	-- PlotProfileStore will automatically remove the reference that the player owns this plot once the player leaves
	PlotProfileStore:SetPlotToPlayer(self.owner, self)

	self.OnClaim:Fire(plr) -- Let the server know we now own this plot

	NotifEvent:FireClient(plr, "Plot claimed")
end

-- Triggered by PlotProfileStore on PlayerRemoving (called after saving)
-- Only triggers if a player who claimed a plot leaves
function Plot:UnclaimPlot()
	self.stopCoroutine = true -- Stop the loop

	self.OnUnclaim:Fire(self.owner) -- Let the server know the player no longer owns this plot

	-- Make sure it is closed
	-- We check if the coroutines exist because there might be an error or bug that prevented coroutines to not be created
	-- We also don't stop it if it's already stopped
	if self.growCoroutine and coroutine.status(self.growCoroutine) ~= "dead" then
		coroutine.close(self.growCoroutine)
	end
	if self.upgradeTierCoroutine and coroutine.status(self.upgradeTierCoroutine) ~= "dead" then
		coroutine.close(self.upgradeTierCoroutine)
	end

	-- Remove references
	self.growCoroutine = nil
	self.upgradeTierCoroutine = nil

	self.tier = 1 -- Reset tier

	-- Destroy all the plants
	self:DestroyAllPlants()
	self.plants = {}

	self.owner = nil -- This makes it so that this plot can be claimed again
end

function Plot:GetPlantData()
	if #self.plants == 0 then return {} end

	local plantsData = {}
	for _, plant in ipairs(self.plants) do
		-- Avoid saving corrupted plants
		if not plant.PrimaryPart or not plant.PrimaryPart.Parent then
			warn("Skipping destroyed plant in GetCurrentData")
			continue
		end

		local plantData = {}
		-- We get the relative cframe to the plot so that when we load it again we can get the same position by converting it back to world cframe
		local relative_cframe = self.plot:GetPivot():ToObjectSpace(plant.PrimaryPart.CFrame)

		plantData.plantName = plant.Name -- Store plant name so we can rebuilt it again when it loads
		-- On PlotProfileStore CFrame is converted to a table because we can't datastore cframes
		plantData.relative_cframe = relative_cframe -- Store the relative cframe
		plantData.Growth = plant.Growth -- Then the growth so the plants still stay the same after loading not just position wise

		table.insert(plantsData, plantData)
	end

	return plantsData
end

function Plot:GetCurrentData()
	local data = {
		Plants = self:GetPlantData(), -- Get every plant's data
		Tier = self.tier, -- We store the tier because if we don't there's a possibility that the owner will load 20 plants but max is 10 (The owner had tier 2 last time)
	}

	return data
end

function Plot:LoadPlantData()
	local plantsLoadedData = PlotProfileStore:GetPlantsData(self.owner) -- Get the data from the profile
	for _, plantLoadedData in ipairs(plantsLoadedData) do
		-- We load in the plant's data (Model, GrowthRate, Growth method, etc)
		local plantName = plantLoadedData.plantName 
		local plantData = TableUtils:CopyTable(PlantsData[plantName]) -- Copy table to prevent modifying the original values
		if not plantData then 
			warn(`{plantName} does not exist in PlantsData`) -- Fallback. When adding plants we might mispell
			continue 
		end

		-- When loading, the table cframe is converted to cframe automatically when being fetched through PlotProfileStore
		local relativeCFrame: CFrame = plantLoadedData.relative_cframe -- Get the relative cframe

		-- It checks for -inf or NaN
		-- Remove ghost plants (If plant Y is corrupted then it is considered a ghost plant which won't appear in plot and also cause nil errors)
		if relativeCFrame.Y < -1000000 or relativeCFrame.Y ~= relativeCFrame.Y then 
			warn(`Skipping plant with corrupted position: Y = {relativeCFrame.Y}`)
			continue
		end

		-- Convert relative CFrame back to world CFrame by doing math
		local worldCFrame: CFrame = self.plot:GetPivot():ToWorldSpace(relativeCFrame)

		local growth = plantLoadedData.Growth

		-- This is the data outside of the plantData
		local plant = self:PlacePlant(plantName, worldCFrame, growth)
		if plant == nil then -- If it wasn't created or the class rejected it (Class doesn't reject any for now but in the future in might so we add this for safety)
			warn("Plant is nil")
			continue   
		end

		plant:LoadGrowth() -- Call the custom grow method (PlantsData also contain a LoadGrowFunc aside from GrowFunc)

		-- DATASTORE DEBUG
		-- Usually used when there's a problem with datastore and plant's arent loading
		if DEBUG then 
			print(plant, " loaded")
		end
	end
end

function Plot:LoadData()
	self:LoadPlantData()

	-- Load the tier
	local tier = PlotProfileStore:GetTierData(self.owner)
	if tier > self.maxTier then
		self.tier = self.maxTier -- If somehow the tier is higher than the max tier we set it to max tier. This prevents some weird glitches
	else   
		self.tier = tier -- if not we load it in normally
	end

	self:Upgrade() -- We upgrade to the current tier
end

function Plot:IsInside(part: BasePart, pos: Vector3)
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

function Plot:CanPlacePlant(plr:Player, plantName: string, pos: Vector3): boolean
	-- If there's no owner yet then no one should place plants
	if not self.owner then return false end

	local plantData = PlantsData[plantName]
	if not plantData then 
		warn(`{plantName} does not exist in PlantsData`) -- Fallback just in case we mispell when adding new plants
		return
	end

	-- It's impossible to trigger this without exploiting
	-- The client fires the remote to the server
	-- The server calls the TryPlace method on the plot that the player owns
	-- We add this check just in case
	if plr ~= self.owner then 
		NotifEvent:FireClient(plr, "You can't plant on other's plot")
		return false
	end

	if #self.plants >= self.maxPlants then
		NotifEvent:FireClient(self.owner, "You have the maximum amount of plants. Remove one first!")
		return false
	end

	-- The dirt part of the plot
	local plow: BasePart = self.plot.Plow
	local plow2: BasePart = self.plot.Plow2

	-- Check if the position of the click is inside one of the plows
	if self:IsInside(plow, pos) or self:IsInside(plow2, pos) then
		return true
	else
		-- If planted somewhere else then notify them
		NotifEvent:FireClient(self.owner, "Can't place plants because it needs to be planted on the soil of your plot")
		return false
	end

	-- nearbyRange is the radius of the space that the plant will take
	-- We name it scan range because in the utils it's the thing checking
	local scanRange = plantData.nearbyRange
	if PlotUtils:ArePlantsNearby(self.plants, pos, scanRange) then
		-- We don't notify the user because the client already does checking before firing the remote
		-- but if an exploiter fires it anyway they won't get past
		return false
	end
end

function Plot:PlacePlant(plantName: string, plant_cframe: CFrame, growth: number?)
	local plantData = TableUtils:CopyTable(PlantsData[plantName])
	if not plantData then 
		warn(`{plantName} does not exist in PlantsData`) -- Fallback just in case we mispell when adding new plants
		return
	end

	-- This is the data outside of the PlantsData
	-- This is the data that will change everytime we can't store in in PlantsData
	local PlantAdditionalData = {
		Plot = self, -- We can't store this because we cant gurantee the player will always plant in the same plot class instance
		PlantCFrame = plant_cframe, -- if we store this in PlantsData we can't choose where we plant our plants then
		Growth = growth or 0, -- If from LoadPlantsData then we load growth. If the player only plant this now we default to 0
	}

	-- Merge the tables
	-- plantData will merge with the additional data
	TableUtils:MergeTables(plantData, PlantAdditionalData)

	-- If growth this means this was called by LoadPlantsData
	-- There wont be a growth parameter if this was called as a remote handler for PlacePlants event
	if growth then
		plantData.Offset = CFrame.new(0,0,0)
	end

	local plant = PlantsClass.new(plantData)
	table.insert(self.plants, plant)

	return plant -- So LoadPlantsData can do more stuff with it
end

-- We added this as the PlacePlantHandler when the remote triggers
-- Server will check what plot the player owns and uses this method on the plot that the player owns
-- This is why self.OnClaim bindable is important
-- This is different from PlacePlant because PlacePlant won't check for anything.
function Plot:TryPlacePlant(plr: Player, plantName: string, pos: Vector3)
	if not self:CanPlacePlant(plr, plantName, pos) then 
		return 
	end

	-- Place plant here
	self:PlacePlant(plantName, CFrame.new(pos))
end

function Plot:CanDestroyPlant(plr, plant)
	if not self.owner then return false end -- Don't destroy any plants if theres no owner yet
	if not plant then -- If plant doesn't exist or is nil return false
		return false
	end

	if plr ~= self.owner then -- If another person that isn't the owner tries to delete this we return false
		return false
	end

	return true
end

local function findPlantIndex(plants, target) : number?
	for i, plant in ipairs(plants) do
		-- We use plant.Model because the target will be a model from the workspace not the plant class
		if plant.Model == target or plant.Model.PrimaryPart == target then  
			return i
		end
	end
end

function Plot:DestroyAllPlants()
	for _, plant in ipairs(self.plants) do
		-- Call :Destroy() on plant class
		plant:Destroy()
	end
end

function Plot:DestroyPlant(plant)
	-- Find the index of the plant we want to remove
	local plantIndex = findPlantIndex(self.plants, plant)
	if not plantIndex then 
		warn("PLANT DOESNT EXIST") -- If it isn't in self.plants
		return 
	end

	self.plants[plantIndex]:Destroy() -- Call destroy method on class 
	table.remove(self.plants, plantIndex) -- Remove from the table
end

-- This is for destroy plant remote handling because it checks if the player is even allowed to do this
-- Server will check what plot the player owns and uses this method on the plot that the player owns
-- This is why self.OnClaim bindable is important
function Plot:TryDestroyPlant(plr, plant)
	if not self:CanDestroyPlant(plr, plant) then 
		return 
	end

	self:DestroyPlant(plant) -- This is for forcefully removing it (but in this case it is used with CanDestroyPlant)
end

export type PlotType = typeof(setmetatable({}, Plot)) -- We export the type so we can have intellisense in other scripts

return Plot :: PlotType