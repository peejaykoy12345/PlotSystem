local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()

local remotes = require(ReplicatedStorage.Packages.remotes)
local UseConsumableEvent: RemoteEvent = remotes:getEventAsync("UseConsumable")
local ConsumableAddedEvent: RemoteEvent = remotes:getEventAsync("ConsumableAdded")
local UpdateConsumableEvent: RemoteEvent = remotes:getEventAsync("UpdateConsumable")

local function getBaseName(name: string): string
    return name:match("^(.-)%s%[%d+%]$") or name
end

local function updateConsumable(consumable)
    local uses = consumable.Uses
    local tool = consumable.Tool

    if not tool then return end
    tool.Name = consumable.Name .. " [" .. tostring(uses) .. "]"
end

local toolUseDebounce = false

ConsumableAddedEvent.OnClientEvent:Connect(function(consumable)
    local tool = consumable.Tool
    local uses = consumable.Uses

    tool.Activated:Connect(function()
        if toolUseDebounce then return end
        toolUseDebounce = true
        task.delay(0.4, function()
            toolUseDebounce = false
        end)

        local position = mouse.Hit.Position
        local cleanName = tool.Name:gsub("%s*%b[]$", "")
        UseConsumableEvent:FireServer(cleanName, position)
    end)

    updateConsumable(consumable)

end)

UpdateConsumableEvent.OnClientEvent:Connect(function(consumable)
    updateConsumable(consumable)
end)