local time = {}

function time.epoch_in_seconds()
    return math.floor(os.epoch("utc") / 1000)
end

function time.timestamp()
    return os.date("%H:%M:%S", time.epoch_in_seconds())
end

function time.timestamp_millis()
    local epoch_ms = os.epoch("utc")
    local total_seconds = math.floor(epoch_ms / 1000)
    local millis = epoch_ms % 1000

    local hours = math.floor(total_seconds / 3600) % 24
    local minutes = math.floor(total_seconds / 60) % 60
    local seconds = total_seconds % 60

    return string.format("%02d:%02d:%02d:%03d", hours, minutes, seconds, millis)
end

function time.alive_duration_in_seconds()
    return os.clock()
end

return time
