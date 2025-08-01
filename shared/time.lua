local time = {}

function time.epoch_in_seconds()
    return math.floor(os.epoch("utc") / 1000)
end

function time.timestamp()
    return "[" .. os.date("%H:%M:%S", time.epoch_in_seconds()) .. "]"
end

function time.alive_duration_in_seconds()
    return os.clock()
end

return time
