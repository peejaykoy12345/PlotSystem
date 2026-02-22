local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SimpleDialogue = require(ReplicatedStorage.Packages.simpledialogue)

local npc = workspace.DialogueNPCS.ShopNPC

local plr = Players.LocalPlayer

local module = {}

function module:Init()
    local dialogue = SimpleDialogue.new(npc)

    local dialogueTree = SimpleDialogue.CreateTree({
        SimpleDialogue.CreateNode("What do you want to do?", {
            SimpleDialogue.CreateOption("Sell", function()
                local SellScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("SellGui")
                local MainFrame = SellScreenGUI.Frame

                MainFrame.Visible = true
            end),
            SimpleDialogue.CreateOption("Buy", function()
                local ShopScreenGUI = plr.PlayerGui:WaitForChild("GUI"):WaitForChild("ShopGui")
                local MainFrame = ShopScreenGUI.Frame

                MainFrame.Visible = true
            end)
        })
    })

    dialogue:SetDialogueTree(dialogueTree)
end

return module