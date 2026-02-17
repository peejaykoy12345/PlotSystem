local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = require(ReplicatedStorage.Packages.remotes)
local NotifEvent: RemoteEvent = remotes:getEventAsync("Notification")

local Inventory = require(ServerScriptService["Module Scripts"].Inventory)

local PlantModelsFolder = ReplicatedStorage.PlantModels

type PlantData = {
    Model: Model,
    GrowthRate: number,
    MaxGrowth: number,
    Harvest: number,
    Offset: CFrame,
    GrowFunc: (any) -> ()?,
    LoadGrowthFunc: (any) -> ()?,
    onHarvest: (any) -> ()?,
}

type GrowFuncParams = {
    Plant: any,
}

return {
    ["Bamboo"] = {
        Model = PlantModelsFolder.Bamboo,
        GrowthRate = 1,
        MaxGrowth = 20,
        Harvest = 1,
        Offset = CFrame.new(0, 0, 0),
        GrowFunc = function(params: GrowFuncParams)
            local plant = params.Plant
            print(plant.Model:GetFullName(), " ", plant.MaxGrowth, " ", plant.Growth)

            local brick: BasePart = plant.Model.Bamboo
            
            local growthAmount: number = plant.GrowthRate * plant.Plot.tier
            local currentSize: Vector3 = brick.Size

            local remainingGrowth = plant.MaxGrowth - plant.Growth

            local finalGrowthAmount = math.min(growthAmount, remainingGrowth)

            brick.Size = Vector3.new(
                currentSize.X,
                currentSize.Y + finalGrowthAmount,
                currentSize.Z
            )

            plant.Growth += finalGrowthAmount
        end,
        LoadGrowthFunc = function(params: GrowFuncParams)
            local plant = params.Plant
            local brick: BasePart = plant.Model.Bamboo
            
            local growthAmount: number = plant.Growth * plant.Plot.tier
            
            local currentSize: Vector3 = brick.Size
            
            brick.Size = Vector3.new(
                currentSize.X,
                currentSize.Y + growthAmount,
                currentSize.Z
            )
        end,
        onHarvest = function(params)
            local plant = params.Plant
            local plot = plant.Plot
            local owner = plot.owner

            if plant.Growth < plant.MaxGrowth then 
                NotifEvent:FireClient(owner, "You can't harvest this plant. It hasn't fully growned yet!")
                return 
            end

            plot:DestroyPlant(plant.Model)
            Inventory:Add(owner, "Bamboo", 1)
        end
    }
}