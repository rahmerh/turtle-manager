local turtle_store = require("turtle_store")
local wireless = require("wireless")
local printer = require("printer")

local function find_least_queued(turtles)
    local result = nil

    for _, t in pairs(turtles) do
        local amount_of_tasks = tonumber(t.queued_tasks) or 0
        if not result or amount_of_tasks < result.queued_tasks then
            result = t
        end
    end

    return result
end

return function(_, msg)
    local runners = turtle_store.get_by_role("runner")
    if not runners then
        error("No runners registered.")
    end

    local task_is_received = false
    while not task_is_received do
        for _, runner in ipairs(runners) do
            if runner.status == "Idle" then
                local sender, confirmation = wireless.send_runner_task(runner.id, msg, "resupply")

                if not sender then
                    printer.print_warning(confirmation)
                    break
                end

                task_is_received = true
                break
            end
        end

        -- All runners are busy, find the one with the least amount of tasks and queue it.
        if not task_is_received then
            local runner = find_least_queued(runners)

            if not runner then
                printer.print_warning("No runners available.")
                return
            end

            local sender, confirmation = wireless.send_runner_task(runner.id, msg, "resupply")

            if not sender then
                printer.print_warning(confirmation)
                break
            end

            task_is_received = true
            break
        end
    end
end
