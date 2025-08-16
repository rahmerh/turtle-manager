local turtle_status = {
    quarry = {
        active = "In progress",
        starting = "Starting"
    },
    runner = {
        running = "Running"
    },
    shared = {
        paused = "Paused",
        offline = "Offline",
    }
}

local fallback = colours.white

local quarry_status_colours = {
    Created = colours.green,
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

function turtle_status.quarry_status_to_colour(status)
    for quarry_status, status_colour in pairs(quarry_status_colours) do
        if string.find(status, quarry_status, 1, true) then
            return status_colour
        end
    end

    return fallback
end

function turtle_status.runner_status_to_colour(status)
    for runner_status, status_colour in pairs(runner_status_colours) do
        if string.find(status, runner_status, 1, true) then
            return status_colour
        end
    end

    return fallback
end

function turtle_status.is_turtle_active(status)
    local is_running = status == turtle_status.runner.running
    local is_in_progress = status == turtle_status.quarry.active or status == turtle_status.quarry.starting

    return is_running or is_in_progress
end

function turtle_status.is_paused(status)
    return status == turtle_status.shared.paused
end

return turtle_status
