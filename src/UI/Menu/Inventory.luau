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
local CloseButton = MainFrame.Frame.CloseButton

local UI = {}

function UI:Init()
    UpdateInventoryEvent.OnClientEvent:Connect(function(items: {[string]: number})
        local seen = {}  -- track items we processed

        -- Update or add items
        for itemName, qty in pairs(items) do
            local frame = ItemContainer:FindFirstChild(itemName)
            if frame then
                frame.Quantity.Text = qty
            else
                frame = ItemTemplate:Clone()
                print("Cloned:", frame)
                print("Children:")
                for _, child in ipairs(frame:GetChildren()) do
                    print("-", child.Name, child.ClassName)
                end
                frame.Name = itemName
                frame.ItemName.Text = itemName
                frame.Quantity.Text = qty
                frame.Visible = true
                frame.Parent = ItemContainer
            end
            seen[itemName] = true
        end

        -- Remove items that are not in the new inventory
        for _, frame in pairs(ItemContainer:GetChildren()) do
            if frame.Name ~= "Template" and frame:IsA("Frame") and not seen[frame.Name] then
                frame:Destroy()
            end
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end

        if input.KeyCode == Enum.KeyCode.G then
            MainFrame.Visible = not MainFrame.Visible
        end
    end)

    CloseButton.Activated:Connect(function()
        MainFrame.Visible = false
    end)
end

return UI