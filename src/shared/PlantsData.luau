local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlantModelsFolder = ReplicatedStorage.PlantModels

export type PlantData = {
    Model: Model,
    GrowthRate: number,
    MaxGrowth: number,
    Harvest: number,
    Offset: CFrame,
    nearbyRange: number,
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
        nearbyRange = 3,
        GrowFunc = function(params: GrowFuncParams)
            local plant = params.Plant
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
    }
}