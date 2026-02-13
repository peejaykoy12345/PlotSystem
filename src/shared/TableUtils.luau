local TableUtils = {}

function TableUtils:MergeTables(t1, t2)
    for k, v in pairs(t2) do
        t1[k] = v
    end
end

function TableUtils:CopyTable(original)
    if not original then return end

    local copy = {}
    for k, v in pairs(original) do
        copy[k] = v
    end

    return copy
end

return TableUtils