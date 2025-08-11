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

return string_util
