local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = require(ReplicatedStorage.Packages.remotes)
local BuyEvent: RemoteEvent = remotes:getEventAsync("Buy")
local SellEvent: RemoteEvent = remotes:getEventAsync("Sell")
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local ModuleScripts = ServerScriptService["Module Scripts"]
local Economy = require(ModuleScripts.Economy)
local Inventory = require(ModuleScripts.Inventory)
local Consumables = require(ModuleScripts.ConsumablesHandler)

local ShopData = require(ReplicatedStorage.Shared.ShopData)

SellEvent.OnServerEvent:Connect(function(plr: Player, itemName: string, qty: number)
    if Inventory:GetItemCount(plr, itemName) < qty then return end

    local price = Economy:CalculatePrice(itemName, qty)

    print("Price is $" .. tostring(price) .. " for selling " .. itemName .. " for " .. tostring(qty) .. " amount")

    Inventory:Remove(plr, itemName, qty)
    UpdateInventoryEvent:FireClient(plr, Inventory:GetPlayerItems(plr))

    Economy:AddPlayerMoney(plr, price)
end)

BuyEvent.OnServerEvent:Connect(function(plr, itemName: string, qty: number)
    local ItemData = ShopData[itemName]
    if not ItemData then
        warn(`{itemName} does not have a shop data`)
        return
    end
    if Economy:GetPlayerMoney(plr) < ItemData.Price then return end

    local price = ItemData.Price * qty

    print("Price is $" .. tostring(price) .. " for buying " .. itemName .. " for " .. tostring(qty) .. " amount")

    if ItemData.Type == "Seed Consumable" then
        Consumables:GivePlayerConsumable(plr, itemName, qty)
        Economy:RemovePlayerMoney(plr, price)
    end
end)