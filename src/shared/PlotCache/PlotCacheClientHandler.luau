local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SendPlotCache: RemoteEvent = remotes:getEventAsync("SendPlot")

local PlotCacheClientService = require(script.Parent.PlotCacheClientService)

return {
    init = function()
        SendPlotCache.OnClientEvent:Connect(function(plotData) 
            PlotCacheClientService:SetPlotData(plotData)
        end)
    end
}