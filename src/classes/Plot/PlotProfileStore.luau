local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local ServerPackages = ServerScriptService.ServerPackages

local ProfileStore = require(ServerPackages.profilestore)

type Plot = {}

local PlayerPlots: {[Player]: Plot} = {}

local PROFILE_TEMPLATE = {
   Plants = {},
   Tier = 1,
}

local PlayerStore = ProfileStore.New("PlayerStore", PROFILE_TEMPLATE)
local Profiles: {[Player]: typeof(PlayerStore:StartSessionAsync())} = {}

local PlotProfileStore = {}

local function CFrameToTable(cf: CFrame)
    local x, y, z, r00, r01, r02, r10, r11, r12, r20, r21, r22 = cf:GetComponents()
    return {
        x = x,
        y = y,
        z = z,
        r00 = r00,
        r01 = r01,
        r02 = r02,
        r10 = r10,
        r11 = r11,
        r12 = r12,
        r20 = r20,
        r21 = r21,
        r22 = r22
    }
end

local function TableToCFrame(t)
    return CFrame.new(
        t.x, t.y, t.z,
        t.r00, t.r01, t.r02,
        t.r10, t.r11, t.r12,
        t.r20, t.r21, t.r22
    )
end

local function PlayerAdded(player)
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
            print("PLANTS DATA: ", profile.Data.Plants)
        else
            profile:EndSession()
        end

    else
        player:Kick(`Profile load fail - Please rejoin`)
    end
end

-- In case Players have joined the server earlier than this script ran:
for _, player in Players:GetPlayers() do
   task.spawn(PlayerAdded, player)
end

function PlotProfileStore:Init()
    print("INITIALIZED!")
    Players.PlayerAdded:Connect(PlayerAdded)

    Players.PlayerRemoving:Connect(function(player)
        local profile = Profiles[player]

        local plot: Plot = PlayerPlots[player]

        if plot then
            local data = plot:GetCurrentData()

            local plantsDataRaw = data.Plants or {}
            local plantsDataSafe: any = {}

            for _, plant in ipairs(plantsDataRaw) do
                local plantCopy = {}
                for k, v in pairs(plant) do
                    if typeof(v) == "CFrame" then
                        plantCopy[k] = CFrameToTable(v)
                    else
                        plantCopy[k] = v
                    end
                end
                table.insert(plantsDataSafe, plantCopy)
            end

            profile.Data.Plants = plantsDataSafe
            profile.Data.Tier = data.Tier

            plot:UnclaimPlot()
            PlayerPlots[player] = nil
        end
    end)
end

function PlotProfileStore:SetPlotToPlayer(plr: Player, plot: Plot)
    PlayerPlots[plr] = plot
end

function PlotProfileStore:GetPlantsData(player: Player)
    local profile = Profiles[player]
    if not profile then return {} end

    local plantsData: any = {}
    for _, plant in ipairs(profile.Data.Plants or {}) do
        local plantCopy = {}
        for k, v in pairs(plant) do
            if type(v) == "table" and v.x and v.y and v.z and v.r00 then
                plantCopy[k] = TableToCFrame(v)
            else
                plantCopy[k] = v
            end
        end
        table.insert(plantsData, plantCopy)
    end

    return plantsData
end

function PlotProfileStore:GetTierData(plr: Player)
   local profile = Profiles[plr]
    if not profile then return 1 end

    return profile.Data.Tier or 1
    
end

return PlotProfileStore