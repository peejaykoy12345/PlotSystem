local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerStorage = game:GetService("ServerStorage")
local Packages = ReplicatedStorage.Packages

local remotes = require(Packages.remotes)

local Classes = ServerScriptService.Classes
local PlotClass = require(Classes.Plot)

local PlantEvent: RemoteEvent = remotes:getEventAsync("Plant")
local DestroyPlantEvent: RemoteEvent = remotes:getEventAsync("DestroyPlant")

local PlantBindable = Instance.new("BindableEvent", ServerStorage)
PlantBindable.Name = "PlantBindable"

local PlotsFolder = workspace.FarmPlot

local PlotInstances: {typeof(PlotClass)} = {}
local PlayerPlots = {} -- Track which plot each player owns

-- Initialize all plots
for _, plotModel in pairs(PlotsFolder:GetChildren()) do
    local plot = PlotClass.new({plot = plotModel})

    plot.OnClaim.Event:Connect(function(plr)
        PlayerPlots[plr] = plot
    end)

    plot.OnUnclaim.Event:Connect(function(plr)
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