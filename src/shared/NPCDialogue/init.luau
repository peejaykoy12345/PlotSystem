local module = {}

function module:Init()
    for _, module_script in pairs(script:GetChildren()) do
        if module_script:IsA("ModuleScript") then
            require(module_script):Init()
        end
    end
end

return module