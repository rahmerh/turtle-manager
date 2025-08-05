local list = {}

local function resolve_path(obj, path)
    local current = obj
    for key in string.gmatch(path, "[^%.]+") do
        if type(current) ~= "table" then return nil end
        current = current[key]
    end
    return current
end

function list.map_contains_value(map, entry)
    for _, v in pairs(map) do
        if v == entry then return true end
    end
    return false
end

function list.contains(arr, entry)
    for _, v in ipairs(arr) do
        if v == entry then return true end
    end
    return false
end

function list.filter_by(tbl, key_path, value)
    local result = {}

    for k, v in pairs(tbl) do
        if resolve_path(v, key_path) == value then
            result[k] = v
        end
    end

    return result
end

return list
