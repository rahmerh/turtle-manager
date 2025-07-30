local utils = {}

function utils.epoch_in_seconds()
    return math.floor(os.epoch("utc") / 1000)
end

function utils.timestamp()
    return "[" .. os.date("%H:%M:%S", utils.epoch_in_seconds()) .. "]"
end

return utils
