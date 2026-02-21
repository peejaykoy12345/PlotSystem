local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UseConsumableEvent: RemoteEvent = remotes:getEventAsync("UseConsumable")

local plr = Players.LocalPlayer
local mouse = plr:GetMouse()

local Service = {}

local toolUseDebounce = false

function Service:SetupTool(tool: Tool)
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

return Service