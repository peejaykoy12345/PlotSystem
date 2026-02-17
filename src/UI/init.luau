local UI = {}

function UI:Init()
    for _, module_script in pairs(script:GetDescendants()) do
        if not module_script:IsA("ModuleScript") then continue end

        require(module_script):Init()
    end
end

return UI