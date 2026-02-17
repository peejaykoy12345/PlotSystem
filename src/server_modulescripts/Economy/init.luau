local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local module = {}

function module:CalculatePrice(itemName: string, qty: number)
    local item_data = ItemData[itemName]
    if not item_data then return end

    local price = item_data.SellPrice * qty
    return price
end

function module:GetPlayerMoneyInstance(plr :Player)
    local leaderstats = plr:WaitForChild("leaderstats")
    local money = leaderstats:WaitForChild("Money")

    return money
end

function module:GetPlayerMoney(plr: Player)
    return self:GetPlayerMoneyInstance(plr).Value
end

function module:AddPlayerMoney(plr: Player, amount: number)
    local money = self:GetPlayerMoneyInstance(plr)
    money.Value += amount
end

function module:RemovePlayerMoney(plr: Player, amount: number)
    local money = self:GetPlayerMoneyInstance(plr)

    if money.Value >= amount then
        money.Value -= amount
    else
        money.Value = 0
    end
end

return module