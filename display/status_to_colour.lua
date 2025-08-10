local status_to_colour = {}

local fallback = colours.white

local quarry_status_colours = {
    Starting = colours.green,
    Stale = colours.yellow,
    Paused = colours.yellow,
    Offline = colours.grey,
    Completed = colours.lightBlue,
}

local runner_status_colours = {
    Offline = colours.grey,
    Stale = colours.yellow,
    Running = colours.lightBlue,
    Idle = colours.white,
}

function status_to_colour.quarry_status_to_colour(status)
    for quarry_status, status_colour in pairs(quarry_status_colours) do
        if string.find(status, quarry_status, 1, true) then
            return status_colour
        end
    end

    return fallback
end

function status_to_colour.runner_status_to_colour(status)
    for runner_status, status_colour in pairs(runner_status_colours) do
        if string.find(status, runner_status, 1, true) then
            return status_colour
        end
    end

    return fallback
end

return status_to_colour
