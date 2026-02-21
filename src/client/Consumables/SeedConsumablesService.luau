local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UseConsumableEvent: RemoteEvent = remotes:getEventAsync("UseConsumable")

local PlantModels = ReplicatedStorage.PlantModels

local PlantsData = require(ReplicatedStorage.Shared.PlantsData)
local PlotUtils = require(ReplicatedStorage.Shared.PlotUtils)

local ConsumablesUtils = require(script.Parent.ConsumablesUtils)

local PlotCacheClientService = require(ReplicatedStorage.Shared.PlotCache.PlotCacheClientService)

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local camera: Camera = workspace.CurrentCamera

local SeedConsumables = {}

local function setModelTransparency(model: Model, transparency: number)
    for _, part in pairs(model:GetChildren()) do
        if part:IsA("BasePart") then
            part.Transparency = transparency
        end
    end
end

local function getPlantScanRadius(plantName: string)
    local plantData = PlantsData[plantName]
	if not plantData then 
		warn(`{plantName} does not exist in PlantsData`) -- Fallback just in case we mispell when adding new plants
		return
	end

    local scanRange = plantData.nearbyRange
    return scanRange
end

local equip_debounce = false
local toolUseDebounce = false

function SeedConsumables:SetupTool(tool: Tool)
    tool.Activated:Connect(function()
        if toolUseDebounce then return end
        if not SeedConsumables:CanPlacePlant(ConsumablesUtils:GetPlantName(tool.Name)) then return end
        toolUseDebounce = true
        task.delay(0.4, function()
            toolUseDebounce = false
        end)

        local position = mouse.Hit.Position
        local cleanName = tool.Name:gsub("%s*%b[]$", "")
        UseConsumableEvent:FireServer(cleanName, position)
    end)

    tool.Equipped:Connect(function()
        if equip_debounce then return end
        equip_debounce = true
        task.delay(0.7, function()
            equip_debounce = false
        end)
        SeedConsumables:OnEquip(ConsumablesUtils:GetPlantName(tool.Name))
    end)
    
    tool.Unequipped:Connect(function()
        SeedConsumables:OnUnequip()
    end)
end

function SeedConsumables:CanPlacePlant(plantName: string) : boolean
    if not self.previewModel or not self.mousePos then return end

    local scanRange = getPlantScanRadius(plantName)
    if not scanRange then return false end

    local plot = PlotCacheClientService:GetPlotData()
    if not plot then return false end

    local plants = plot.Plants
	if PlotUtils:ArePlantsNearby(plants, self.mousePos, scanRange) then
		return false
	end

    return true
end

function SeedConsumables:OnEquip(plantName: string)
    local plantData = PlantsData[plantName]
	if not plantData then 
		warn(`{plantName} does not exist in PlantsData`) -- Fallback just in case we mispell when adding new plants
		return false
	end

	local modelTemplate: Model? = PlantModels:FindFirstChild(plantName)
	if not modelTemplate then 
		warn(`Model template for {plantName} not found`)
		return 
	end

	local model: Model = modelTemplate:Clone()
	setModelTransparency(model, 0.4)
	model.Parent = workspace

    local scanRange = getPlantScanRadius(plantName)
    if not scanRange then return end

    if self.scan then self.scan:Destroy() end

    self.scan = Instance.new("Part")
    self.scan.Shape = Enum.PartType.Cylinder
    self.scan.Size = Vector3.new(0.1, scanRange * 2, scanRange * 2)
    self.scan.CFrame = CFrame.new(model:GetPivot().Position) * CFrame.Angles(0, math.rad(90), math.rad(90))
    self.scan.Anchored = true
    self.scan.CanCollide = false
    self.scan.Parent = model

    self.previewModel = model

    local Y_OFFSET = plantData.Offset

	self.connection = RunService.Heartbeat:Connect(function()
        local mousePos: Vector2 = UserInputService:GetMouseLocation()
        local ray: Ray = camera:ViewportPointToRay(mousePos.X, mousePos.Y)

        local rayParams = RaycastParams.new()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
        rayParams.FilterDescendantsInstances = {
            model,
            plr.Character
        }

        local result = workspace:Raycast(ray.Origin, ray.Direction * 500, rayParams)
        if not result then return end

        self.mousePos = (CFrame.new(result.Position) * Y_OFFSET).Position
        model:PivotTo(CFrame.new(self.mousePos))

        self.scan.Position = model:GetPivot().Position
    end)
end

function SeedConsumables:OnUnequip()
    print(self.previewModel, " and ", self.connection)
    if self.previewModel then
        self.previewModel:Destroy()
    end

    if self.scan then
        self.scan:Destroy()
    end

    if self.connection then
        self.connection:Disconnect()
    end
end

return SeedConsumables