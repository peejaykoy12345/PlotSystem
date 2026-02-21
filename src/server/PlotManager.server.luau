local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages

local remotes = require(Packages.remotes)
local GetPlotFunction: RemoteFunction = remotes:getFunctionAsync("GetPlot")

local Classes = ServerScriptService.Classes
local PlotClass = require(Classes.Plot)

local PlantEvent: RemoteEvent = remotes:getEventAsync("Plant")
local DestroyPlantEvent: RemoteEvent = remotes:getEventAsync("DestroyPlant")

local PlantBindable = Instance.new("BindableEvent", ServerStorage)
PlantBindable.Name = "PlantBindable"

local SendCache = Instance.new("BindableEvent", ServerStorage)
SendCache.Name = "SendCache"

local PlotsFolder = workspace.FarmPlot

local PlotInstances: {typeof(PlotClass)} = {}
local PlayerPlots = {} -- Track which plot each player owns

local function getPlayerPlotData(plr)
    local plotData = {
        Plants = {}
    }

    for _, plant in ipairs(PlayerPlots[plr].plants) do
        table.insert(plotData.Plants, {
           CFrame = plant.CFrame, 
           nearbyRange = plant.nearbyRange
        })
    end

    return plotData
end

-- Initialize all plots
for _, plotModel in pairs(PlotsFolder:GetChildren()) do
    local plot = PlotClass.new({plot = plotModel})

    local onChangedConnection: RBXScriptConnection?

    plot.OnClaim.Event:Connect(function(plr)
        onChangedConnection = plot.OnChanged.Event:Connect(function()
            local plotData = getPlayerPlotData(plr)
            SendCache:Fire(plr, plotData)
        end)
        PlayerPlots[plr] = plot
        SendCache:Fire(plr, getPlayerPlotData(plr))
    end)

    plot.OnUnclaim.Event:Connect(function(plr)
        if onChangedConnection then
            onChangedConnection:Disconnect()
            onChangedConnection = nil
        end
        PlayerPlots[plr] = nil
    end)

    table.insert(PlotInstances, plot)
end

require(Classes.Plot.PlotProfileStore):Init()

local function handlePlant(player, plantName, pos)
    local plot = PlayerPlots[player]
    if not plot then 
        return 
    end
    
    plot:TryPlacePlant(player, plantName, pos)
end

PlantBindable.Event:Connect(handlePlant)
PlantEvent.OnServerEvent:Connect(handlePlant)

DestroyPlantEvent.OnServerEvent:Connect(function(player, plant)
    local plot = PlayerPlots[player]
    if not plot then 
        return 
    end
    
    plot:TryDestroyPlant(player, plant)
end)