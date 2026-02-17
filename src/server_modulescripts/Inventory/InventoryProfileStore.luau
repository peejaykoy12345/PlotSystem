local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerPackages = ServerScriptService.ServerPackages

local remotes = require(ReplicatedStorage.Packages.remotes)
local UpdateInventoryEvent: RemoteEvent = remotes:getEventAsync("UpdateInventory")

local ProfileStore = require(ServerPackages.profilestore)

local Inventory = require(script.Parent)

local PROFILE_TEMPLATE = {
   Inventory = {},
}

local PlayerStore = ProfileStore.New("InventoryStore", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local module = {}

local function PlayerAdded(player: Player)
    local profile = PlayerStore:StartSessionAsync(`{player.UserId}`, {
        Cancel = function()
            return player.Parent ~= Players
        end,
    })

    if profile ~= nil then
        profile:AddUserId(player.UserId) 
        profile:Reconcile() 

        profile.OnSessionEnd:Connect(function()
            Profiles[player] = nil
            player:Kick(`Profile session end - Please rejoin`)
        end)

        if player.Parent == Players then
            Profiles[player] = profile
            print(`Profile loaded for {player.DisplayName}!`)

            Inventory:LoadPlayerItems(player, profile.Data.Inventory)
            
            local InventoryGUI = player:WaitForChild("PlayerGui"):WaitForChild("GUI"):WaitForChild("InventoryGui")

            UpdateInventoryEvent:FireClient(player, Inventory:GetPlayerItems(player))
        else
            profile:EndSession()
        end

    else
        player:Kick(`Profile load fail - Please rejoin`)
    end
end

for _, player in Players:GetPlayers() do
   task.spawn(PlayerAdded, player)
end

function module:Init()
    print("INITIALIZED!")
    Players.PlayerAdded:Connect(PlayerAdded)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]
        local inventory_data = Inventory:GetPlayerItems(player)
        if not inventory_data then return end

        profile.Data.Inventory = inventory_data

        profile:EndSession()
    end)
end

return module