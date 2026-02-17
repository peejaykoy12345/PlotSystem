local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SellEvent: RemoteEvent = remotes:getEventAsync("Sell")
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local ModuleScripts = ServerScriptService["Module Scripts"]
local Economy = require(ModuleScripts.Economy)
local Inventory = require(ModuleScripts.Inventory)

SellEvent.OnServerEvent:Connect(function(plr: Player, itemName: string, qty: number)
    if Inventory:GetItemCount(plr, itemName) < qty then return end

    local price = Economy:CalculatePrice(itemName, qty)

    print("Price is $" .. tostring(price) .. " for selling " .. itemName .. " for " .. tostring(qty) .. " amount")

    Inventory:Remove(plr, itemName, qty)
    UpdateInventoryEvent:FireClient(plr, Inventory:GetPlayerItems(plr))

    Economy:AddPlayerMoney(plr, price)
end)