local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()
local camera = workspace.CurrentCamera

local remotes = require(ReplicatedStorage.Packages.remotes)
local UseConsumableEvent: RemoteEvent = remotes:getEventAsync("UseConsumable")
local ConsumableAddedEvent: RemoteEvent = remotes:getEventAsync("ConsumableAdded")
local UpdateConsumableEvent: RemoteEvent = remotes:getEventAsync("UpdateConsumable")

local SeedConsumables = require(script.SeedConsumables)

local function updateConsumable(consumable)
    local uses = consumable.Uses
    local tool = consumable.Tool

    if not tool then return end
    tool.Name = consumable.Name .. " [" .. tostring(uses) .. "]"
end

local toolUseDebounce = false

local function GetPlantName(tool: Tool): string
	local toolName: string = tool.Name
	
	-- Remove [number] at the end
	toolName = string.gsub(toolName, "%s%[%d+%]$", "")
	
	-- Remove " Seed" at the end
	toolName = string.gsub(toolName, " Seed$", "")
	
	return toolName
end

ConsumableAddedEvent.OnClientEvent:Connect(function(consumable)

    local tool: Tool = consumable.Tool
    local uses = consumable.Uses

    if tool:GetAttribute("Type") == "Seed Consumable" then
        local equip_debounce = false
        tool.Activated:Connect(function()
            if toolUseDebounce then return end
            if not SeedConsumables:CanPlacePlant(GetPlantName(tool)) then return end
            toolUseDebounce = true
            task.delay(0.4, function()
                toolUseDebounce = false
            end)

            local position = mouse.Hit.Position
            local cleanName = tool.Name:gsub("%s*%b[]$", "")
            UseConsumableEvent:FireServer(cleanName, position)
        end)
        tool.Equipped:Connect(function()
            
            if equip_debounce then return end
            equip_debounce = true
            task.delay(0.7, function()
                equip_debounce = false
            end)
            SeedConsumables:OnEquip(GetPlantName(tool))
        end)
        tool.Unequipped:Connect(function()
            SeedConsumables:OnUnequip()
        end)
    else 
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
    end

    

    updateConsumable(consumable)
end)

UpdateConsumableEvent.OnClientEvent:Connect(function(consumable)
    updateConsumable(consumable)
end)