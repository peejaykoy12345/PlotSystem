local Service = {}

function Service:SetPlotData(plotData)
    self.plotData = plotData
end

function Service:GetPlotData()
    return self.plotData
end

return Service