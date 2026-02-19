local ServerStorage = game:GetService("ServerStorage")


local ItemData = {
    ["Bamboo"] = {
        SellPrice = 100,
    },
    ["Bamboo Seed"] = {
        Type = "Seed Consumable",
        SellPrice = 25,
        OnUse = function(params)
            local PlantBindable: BindableEvent? = ServerStorage:FindFirstChild("PlantBindable")
            if not PlantBindable then return end
            
            local consumable = params.Consumable

            PlantBindable:Fire(consumable.Owner, "Bamboo", params.Position)
        end,
    }
}

return ItemData