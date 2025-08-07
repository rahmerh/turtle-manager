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

function list.filter_map_by(map, key_path, value)
    local result = {}

    for k, v in pairs(map) do
        if resolve_path(v, key_path) == value then
            result[k] = v
        end
    end

    return result
end

function list.sort_by(array, field, descending)
    table.sort(array, function(a, b)
        if descending then
            return a[field] > b[field]
        else
            return a[field] < b[field]
        end
    end)
    return array
end

function list.find(array, field, value)
    for _, item in ipairs(array) do
        if item[field] == value then
            return item
        end
    end
    return nil
end

return list
