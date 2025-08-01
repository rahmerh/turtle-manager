local list = {}

function list.map_contains_value(map, entry)
    for _, v in pairs(map) do
        if v == entry then return true end
    end
    return false
end

return list
