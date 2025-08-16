local _private = {}
local string_util = {}

function _private.base36(n)
    local t = {}
    repeat
        local d = n % 36
        t[#t + 1] = string.char((d < 10) and (48 + d) or (87 + d))
        n = math.floor(n / 36)
    until n == 0
    return table.concat(t):reverse()
end

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

function string_util.generate_id()
    local salt = math.random(1, 1e9)
    local now  = os.epoch("utc")
    return (_private.base36(os.getComputerID()) .. _private.base36(now % 2 ^ 31) .. _private.base36(salt)):sub(1, 10)
end

function string_util.first_line(s)
    return (tostring(s):match("^[^\r\n]+")) or tostring(s)
end

return string_util
