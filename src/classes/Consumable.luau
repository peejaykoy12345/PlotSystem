local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UpdateConsumableEvent: RemoteEvent = remotes:getEventAsync("UpdateConsumable")

local ItemData = require(ReplicatedStorage.Shared.ItemData)

local Consumable = {}
Consumable.__index = Consumable

type ConsumableParams = {
    Owner: Player,
    Name: string,
    Tool: Tool,
    Uses: number,
}

type UseParams = {
    Position: Vector3,
}

function Consumable.new(params: ConsumableParams)
    local self = setmetatable({}, Consumable)

    local consumableData = ItemData[params.Name]
    if not consumableData then
        warn(`Missing item data for {params.Name}`)
        return
    end

    self.Owner = params.Owner
    self.Name = params.Name
    self.Tool = params.Tool
    self.Uses = params.Uses
    self.OnUse = consumableData.OnUse

    self.Tool:SetAttribute("Consumable", true)
    self.Tool:SetAttribute("Type", consumableData.Type)

    return self
end

-- Returns true if ran out and false if not
function Consumable:Use(params: UseParams) : boolean?
    print(self.Owner)
    self.Uses -= 1

    params.Consumable = self
    self.OnUse(params)

    UpdateConsumableEvent:FireClient(self.Owner, self)

    if self.Uses > 0 then
        return false
    else
        return true
    end
end

function Consumable:AddUses(added_uses: number?)
    self.Uses += added_uses or 1

    UpdateConsumableEvent:FireClient(self.Owner, self)
end

function Consumable:GetSaveData()
    return {Name = self.Name, Uses = self.Uses}
end

function Consumable:Destroy()
    self.Tool:Destroy()
end

type ConsumableClass = typeof(setmetatable({}, Consumable))

return Consumable :: ConsumableClass