local string_util = {}

function string_util.key_to_pretty_name(key)
    local _, name = key:match("([^:]+):(.+)")
    name = name:gsub("_", " ")
    name = name:gsub("(%a)([%w_']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end)

    return name
end

function string_util.capitalize(value)
    return value:gsub("^%l", string.upper)
end

function string_util.starts_with(str, value)
    return str:sub(1, #value) == value
end

function string_util.split_by(str, seperator)
    local result = {}
    local pattern = "([^" .. seperator .. "]+)"
    for part in str:gmatch(pattern) do
        table.insert(result, part)
    end
    return result
end

return string_util
