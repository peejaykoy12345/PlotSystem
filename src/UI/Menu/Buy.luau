local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remotes = require(ReplicatedStorage.Packages.remotes)
local BuyEvent: RemoteEvent = remotes:getEventAsync("Buy")
local ConsumableAddedEvent: RemoteEvent = remotes:getEventAsync("ConsumableAdded")
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local ShopData = require(ReplicatedStorage.Shared.ShopData)

local plr = Players.LocalPlayer
local SellScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("ShopGui")
local MainFrame = SellScreenGUI.Frame
local ItemContainer = MainFrame.ScrollingFrame
local ItemTemplate = ItemContainer.Template

local CloseButton = MainFrame.Frame.CloseButton

local UI = {}

local function CreateFrame(itemName: string, shopData)
    local frame = ItemTemplate:Clone()
    frame.Name = itemName
    frame.ItemName.Text = itemName
    frame.Visible = true
    frame.Price.Text = "Price: $" .. tostring(shopData.Price)
    frame.Parent = ItemContainer

    local QuantityTextbox = frame.QuantityTextbox
    QuantityTextbox:GetPropertyChangedSignal("Text"):Connect(function()
        local text = QuantityTextbox.Text
        local clean = text:gsub("%D", "")
        if text ~= clean then
            QuantityTextbox.Text = clean
        end
    end)

    frame.BuyButton.Activated:Connect(function()
        local qty = tonumber(QuantityTextbox.Text) or 1
        if qty <= 0 then return end

        BuyEvent:FireServer(itemName, qty)
    end)
end

function UI:Init()
    for itemName, itemData in pairs(ShopData) do
        CreateFrame(itemName, itemData)
    end

    CloseButton.Activated:Connect(function()
        MainFrame.Visible = false
    end)
end

return UI