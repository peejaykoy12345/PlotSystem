local ServerStorage = game:GetService("ServerStorage")

local SendCache: BindableEvent = ServerStorage:WaitForChild("SendCache")

local PlotCacheController = require(script.Parent.PlotCacheServerController)

local Handler = {}

function Handler:Init()
    SendCache.Event:Connect(function(plr, plotData)
        PlotCacheController:OnNewCache(plr, plotData)
    end) 
end

return Handler