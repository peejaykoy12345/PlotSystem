local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PlantModelsFolder = ReplicatedStorage.PlantModels

type PlantData = {
    Model: Model,
    GrowthRate: number,
    MaxGrowth: number,
    Harvest: number,
    Offset: CFrame,
    GrowFunc: (any) -> ()?,
    LoadGrowthFunc: (any) -> ()?
}

type GrowFuncParams = {
    Plant: any,
}

return {
    ["Brick"] = {
        Model = PlantModelsFolder.Brick,
        GrowthRate = 1,
        MaxGrowth = 10,
        Harvest = 1,
        Offset = CFrame.new(0, 1, 0),
        GrowFunc = function(params: GrowFuncParams)
            local plant = params.Plant
            print(plant.Model:GetFullName(), " ", plant.MaxGrowth, " ", plant.Growth)
            local brick: BasePart = plant.Model.Brick
            
            local growthAmount: number = plant.GrowthRate * plant.Plot.tier
            
            local currentSize: Vector3 = brick.Size
            
            brick.Size = Vector3.new(
                currentSize.X,
                currentSize.Y + growthAmount,
                currentSize.Z
            )

            plant.Growth += growthAmount
        end,
        LoadGrowthFunc = function(params: GrowFuncParams)
            local plant = params.Plant
            local brick: BasePart = plant.Model.Brick
            
            local growthAmount: number = plant.Growth * plant.Plot.tier
            
            local currentSize: Vector3 = brick.Size
            
            brick.Size = Vector3.new(
                currentSize.X,
                currentSize.Y + growthAmount,
                currentSize.Z
            )
        end
    }
}