local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SendPlotCache: RemoteEvent = remotes:getEventAsync("SendPlot")

local Service = {}

function Service:Init()
    SendPlotCache.OnClientEvent:Connect(function(cacheName, data) 
        self:SetCacheData(cacheName, data)
    end)
end

function Service:SetCacheData(cacheName: string, plotData)
    self[cacheName] = plotData
end

function Service:GetCacheData(cacheName: string)
    return self[cacheName]
end

return Service