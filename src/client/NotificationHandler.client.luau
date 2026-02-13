local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Packages = ReplicatedStorage.Packages

local remotes = require(Packages.remotes)
local NotifEvent: RemoteEvent = remotes:getEventAsync("Notification")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "NotificationGui"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local currentNotification = nil   -- Current active frame
local isAnimating = false         -- Prevent overlap during transitions

local function createNotificationFrame(message: string)
    local notifFrame = Instance.new("Frame")
    notifFrame.Size = UDim2.new(0, 300, 0, 80)
    notifFrame.Position = UDim2.new(1, 50, 0.1, 0) -- Start off-screen right
    notifFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    notifFrame.BorderSizePixel = 0
    notifFrame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = notifFrame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Thickness = 2
    stroke.Transparency = 0.8
    stroke.Parent = notifFrame
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, -20, 1, -20)
    textLabel.Position = UDim2.new(0, 10, 0, 10)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = message
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextSize = 18
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextWrapped = true
    textLabel.TextXAlignment = Enum.TextXAlignment.Center
    textLabel.TextYAlignment = Enum.TextYAlignment.Center
    textLabel.Parent = notifFrame
    
    return notifFrame
end

local function hideCurrentNotification(callback: () -> ())
    if not currentNotification then
        callback()
        return
    end
    
    isAnimating = true
    
    -- Fast slide-out
    local slideOut = TweenService:Create(
        currentNotification,
        TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.In),
        {Position = UDim2.new(1, 50, 0.1, 0)}
    )
    
    slideOut:Play()
    slideOut.Completed:Connect(function()
        if currentNotification then
            currentNotification:Destroy()
            currentNotification = nil
        end
        isAnimating = false
        callback()
    end)
end

local function showNotification(message: string)
    if isAnimating then return end  -- Safety (shouldn't happen)
    
    -- If there's already one showing → hide it first
    if currentNotification then
        hideCurrentNotification(function()
            showNotification(message)  -- Recurse once hidden
        end)
        return
    end
    
    isAnimating = true
    currentNotification = createNotificationFrame(message)
    
    -- Slide in
    local slideIn = TweenService:Create(
        currentNotification,
        TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -320, 0.1, 0)}
    )
    
    slideIn:Play()
    slideIn.Completed:Connect(function()
        isAnimating = false
        
        -- Auto-hide after display time
        task.delay(3, function()
            if currentNotification == nil then return end  -- Already replaced
            
            hideCurrentNotification(function()
                -- Nothing to do after hide
            end)
        end)
    end)
end

-- Listen for events
NotifEvent.OnClientEvent:Connect(function(message: string)
    if currentNotification then
        -- Interrupt current one → fast hide → show new
        hideCurrentNotification(function()
            showNotification(message)
        end)
    else
        -- No current → show normally
        showNotification(message)
    end
end)