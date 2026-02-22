local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UseConsumableEvent: RemoteEvent = remotes:getEventAsync("UseConsumable")
local ConsumableAddedEvent: RemoteEvent = remotes:getEventAsync("ConsumableAdded")
local GetConsumablesFunction: RemoteFunction = remotes:getFunctionAsync("GetConsumables")

local ConsumablesFolder = ReplicatedStorage.Consumables

local ConsumableClass = require(ServerScriptService.Classes.Consumable)

local ConsumablesHandler = {}

local PlayerConsumables: {[Player]: {[string]: typeof(ConsumableClass)}} = {}

type ConsumablesDataStore = {
    Name: string,
    Uses: number,
}

function ConsumablesHandler:InitializeRemoteEvents()
    UseConsumableEvent.OnServerEvent:Connect(function(plr, toolName: string, pos: Vector3)
        local plrTable = PlayerConsumables[plr]
        if not plrTable then return end

        local consumable = plrTable[toolName]
        if not consumable then return end

        local ran_out: boolean = consumable:Use({Position = pos})
        if ran_out then
            plrTable[toolName]:Destroy()
            plrTable[toolName] = nil
        end
    end)

    GetConsumablesFunction.OnServerInvoke = function(plr)
        return PlayerConsumables[plr]
    end
end

function ConsumablesHandler:LoadPlayerConsumables(plr: Player, saveData: {ConsumablesDataStore})
    -- Initializes the table
    PlayerConsumables[plr] = {}
    
    for _, data in ipairs(saveData) do
        local toolName = data.Name
        local uses = data.Uses

        self:GivePlayerConsumable(plr, toolName, uses)
    end

    self:GivePlayerConsumable(plr, "Bamboo Seed", 5)
end

function ConsumablesHandler:GivePlayerConsumable(plr: Player, toolName: string, how_many: number?)
    local plrTable = PlayerConsumables[plr]
    if not plrTable then return end

    how_many = how_many or 1

    print(toolName, "FROM GIVEPLAYER CONSUMABLE")

    if plrTable[toolName] then
        plrTable[toolName]:AddUses(how_many)
    else
        local ToolTemplate = ConsumablesFolder:FindFirstChild(toolName)
        if not ToolTemplate then
            warn("Tool template for " .. toolName .. " not found!")
            return
        end
        
        local Tool = ToolTemplate:Clone()
        Tool.Parent = plr.Backpack

        local ConsumableParams = {
            Owner = plr,
            Name = toolName,
            Tool = Tool,
            Uses = how_many,
        }
        local consumable = ConsumableClass.new(ConsumableParams)
        plrTable[toolName] = consumable

        ConsumableAddedEvent:FireClient(plr, plrTable[toolName])
    end
end

function ConsumablesHandler:GetPlayerSaveData(plr :Player)
    local data = {}

    for _, consumable in pairs(PlayerConsumables[plr]) do
        table.insert(data, consumable:GetSaveData())
    end

    PlayerConsumables[plr] = nil

    return data
end

return ConsumablesHandler