local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local SendPlotCache: RemoteEvent = remotes:getEventAsync("SendPlot")

local ServerController = {}

function ServerController:OnNewCache(plr: Player, plotData)
    SendPlotCache:FireClient(plr, plotData)
end

return ServerController