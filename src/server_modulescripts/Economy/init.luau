local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local module = {}

function module:CalculatePrice(itemName: string, qty: number)
    local item_data = ItemData[itemName]
    if not item_data then return end

    local price = item_data.SellPrice * qty
    return price
end

return module