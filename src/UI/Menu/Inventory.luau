local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local plr = Players.LocalPlayer
local InventoryScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("InventoryGui")
local MainFrame = InventoryScreenGUI.Frame
local ItemContainer = MainFrame.ScrollingFrame
local ItemTemplate = ItemContainer.Template

local UI = {}

function UI:Init()
    UpdateInventoryEvent.OnClientEvent:Connect(function(items: {[string]: number})
        print("Ran")
        for itemName, qty in pairs(items) do
            local frame = ItemContainer:FindFirstChild(itemName)
            if frame then
                frame.Quantity.Text = qty
            else
                frame = ItemTemplate:Clone()
                frame.Name = itemName
                frame.ItemName.Text = itemName
                frame.Quantity.Text = qty
                frame.Visible = true
                frame.Parent = ItemContainer
            end 
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.E then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)
end

return UI