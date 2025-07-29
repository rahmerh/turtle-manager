local utils = {}

function utils.epoch_in_seconds()
    return math.floor(os.epoch("utc") / 1000)
end

return utils
