local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SendPlotCache: RemoteEvent = remotes:getEventAsync("SendPlot")

local Service = {}

function Service:NewCache(plr: Player, cacheName: string, data: any)
    SendPlotCache:FireClient(plr, cacheName, data)
end

return Service