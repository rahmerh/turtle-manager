local colour_helper = {}

local fallback = colours.white

local quarry_status_colours = {
    Offline = colours.grey,
    Stale = colours.yellow,
    Completed = colours.lightBlue,
}

local runner_status_colours = {
    Offline = colours.grey,
    Stale = colours.yellow,
    Running = colours.lightBlue,
    Idle = colours.white,
}

function colour_helper.quarry_status_to_colour(status)
    return quarry_status_colours[status] or fallback
end

function colour_helper.runner_status_to_colour(status)
    for runner_status, status_colour in pairs(runner_status_colours) do
        if string.find(status, runner_status, 1, true) then
            return status_colour
        end
    end

    return fallback
end

return colour_helper
