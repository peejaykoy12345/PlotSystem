local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local ConsumableAddedEvent: RemoteEvent = remotes:getEventAsync("ConsumableAdded")
local UpdateConsumableEvent: RemoteEvent = remotes:getEventAsync("UpdateConsumable")

local SeedConsumables = require(script.Parent.SeedConsumablesService)
local DefaultConsumable = require(script.Parent.DefaultConsumableService)

local function updateConsumable(consumable)
    local uses = consumable.Uses
    local tool = consumable.Tool

    if not tool then return end
    tool.Name = consumable.Name .. " [" .. tostring(uses) .. "]"
end

ConsumableAddedEvent.OnClientEvent:Connect(function(consumable)

    local tool: Tool = consumable.Tool

    if tool:GetAttribute("Type") == "Seed Consumable" then
        SeedConsumables:SetupTool(tool)
    else
        DefaultConsumable:SetupTool(tool)
    end

    updateConsumable(consumable)
end)

UpdateConsumableEvent.OnClientEvent:Connect(function(consumable)
    updateConsumable(consumable)
end)