local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleDialogue = require(ReplicatedStorage.Packages.simpledialogue)

local npc = workspace.DialogueNPCS.ShopNPC

local plr = Players.LocalPlayer

local module = {}

function module:Init()
    local dialogue = SimpleDialogue.new(npc)

    local dialogueTree = SimpleDialogue.CreateTree({
        SimpleDialogue.CreateNode("Would you like to sell items?", {
            SimpleDialogue.CreateOption("Yes of course!", function()
                local SellScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("SellGui")
                local MainFrame = SellScreenGUI.Frame

                MainFrame.Visible = true
            end)
        })
    })

    dialogue:SetDialogueTree(dialogueTree)
end

return module