local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Plants = {}
Plants.__index = Plants

type Plot = {}

export type PlantData = {
    Plot: Plot,
    Model: Model,
    GrowthRate: number,
    MaxGrowth: number,
    Harvest: number,
    PlantCFrame: CFrame,
    Offset: CFrame,
    Growth: number?,
    GrowFunc: (any) -> ()?,
    LoadGrowthFunc: (any) -> ()?
}

function Plants.new(data: PlantData)
    local self = setmetatable({}, Plants)

    self.Plot = data.Plot
    self.Name = data.Model.Name
    self.Model = data.Model:Clone()
    self.GrowthRate = data.GrowthRate
    self.MaxGrowth = data.MaxGrowth
    self.Harvest = data.Harvest

    self.PrimaryPart = self.Model.PrimaryPart

    self.Growth = data.Growth or 0  
    
    self.Model:PivotTo(data.PlantCFrame * data.Offset)
    self.Model.Parent = self.Plot.plot.Plants

    self.GrowFunc = data.GrowFunc
    self.LoadGrowthFunc = data.LoadGrowthFunc
    self.onHarvest = data.onHarvest

    local Prompt = Instance.new("ProximityPrompt")
    Prompt.RequiresLineOfSight = false
    Prompt.ActionText = "Harvest"
    Prompt.Parent = self.PrimaryPart

    Prompt.Triggered:Connect(function()
        if self.onHarvest then
            self.onHarvest({ Plant = self })
        else
            warn(`No onHarvest method for plant: {self.Name}`)
        end
    end)

    return self
end

function Plants:Destroy()
    self.Model:Destroy()
end

function Plants:CanGrow()
    return self.Growth < self.MaxGrowth
end

function Plants:Grow()
    --[[if not self.Model or not self.Model.Parent then
        warn("Model was destroyed or lost parent!")
        return
    end]]
    self.GrowFunc({ Plant = self })
end

function Plants:LoadGrowth()
    self.LoadGrowthFunc({ Plant = self })
end

export type PlantsType = typeof(setmetatable({}, Plants))

return Plants :: PlantsType