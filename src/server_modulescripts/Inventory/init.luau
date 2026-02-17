local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = require(ReplicatedStorage.Packages.remotes)
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local module = {}
local inventories = {}

function module:Add(plr: Player, item: string, amount)
	if not inventories[plr.UserId] then
		warn(`Inventory not set for {plr.Name}`)
		return
	end
	
	if inventories[plr.UserId][item] then
		inventories[plr.UserId][item] += amount
	else
		inventories[plr.UserId][item] = amount
	end

	UpdateInventoryEvent:FireClient(plr, self:GetPlayerItems(plr))
end

function module:Remove(plr: Player, item: string, amount: number)
	inventories[plr.UserId] = inventories[plr.UserId] or {}
	
	if not inventories[plr.UserId][item] then return end

	if inventories[plr.UserId][item] >= amount then
		inventories[plr.UserId][item] -= amount
		if inventories[plr.UserId][item] <= 0 then
			inventories[plr.UserId][item] = nil
		end
	end

	UpdateInventoryEvent:FireClient(plr, self:GetPlayerItems(plr))
end

function module:RemoveSomeItems(plr: Player, items: {[string]: number})
	for item, qty in pairs(items) do
		module:Remove(plr, item, qty)
	end
end

function module:GetPlayerItems(plr: Player)
	inventories[plr.UserId] = inventories[plr.UserId] or {}
	
	return inventories[plr.UserId]
end

function module:GetItemCount(plr: Player, item: string)
	if not inventories[plr.UserId] then return 0 end
	return inventories[plr.UserId][item] or 0
end

function module:MeetsItemRequirements(plr: Player, required_items: {[string]: number})
	if next(required_items) == nil then return true end
	
	for item, quantity in pairs(required_items) do
		local count = module:GetItemCount(plr, item)
		print(quantity)
		if count < quantity then return false end
	end
	return true
end

function module:LoadPlayerItems(plr: Player, items: {[string]: number})
	inventories[plr.UserId] = items
end

return module