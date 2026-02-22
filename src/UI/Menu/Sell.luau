local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SellEvent: RemoteEvent = remotes:getEventAsync("Sell")
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local plr = Players.LocalPlayer
local SellScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("SellGui")
local MainFrame = SellScreenGUI.Frame
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
                frame.Quantity.Text = "Quantity: " .. tostring(qty)
            else
                frame = ItemTemplate:Clone()
                frame.Name = itemName
                frame.ItemName.Text = itemName
                frame.Quantity.Text = "Quantity: " .. tostring(qty)
                frame.Visible = true
                frame.Parent = ItemContainer

                local QuantityTextbox = frame.QuantityTextbox

                QuantityTextbox:GetPropertyChangedSignal("Text"):Connect(function()
                    local text = QuantityTextbox.Text
                    -- Remove any non-digit characters
                    local clean = text:gsub("%D", "")
                    if text ~= clean then
                        QuantityTextbox.Text = clean
                    end
                end)

                local sellButton: TextButton = frame.SellButton
                sellButton.Activated:Connect(function()
                    local qty = tonumber(QuantityTextbox.Text) or 1
                    if qty <= 0 then return end

                    SellEvent:FireServer(itemName, qty)
                end)
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

    CloseButton.Activated:Connect(function()
        MainFrame.Visible = false
    end)
end

return UI