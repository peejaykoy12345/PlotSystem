local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerPackages = ServerScriptService.ServerPackages

local ProfileStore = require(ServerPackages.profilestore)

local ConsumablesHandler = require(script.Parent)

local PROFILE_TEMPLATE = {
   Consumables = {}
}

local PlayerStore = ProfileStore.New("ConsumablesStore", PROFILE_TEMPLATE)
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
            print(`Profile loaded for {player.DisplayName}! coming from Consumables`)

            ConsumablesHandler:LoadPlayerConsumables(player, profile.Data.Consumables)
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

        profile.Data.Consumables = ConsumablesHandler:GetPlayerSaveData(player)

        profile:EndSession()
    end)
end

return module