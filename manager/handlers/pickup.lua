local turtle_store = require("turtle_store")
local wireless = require("wireless")

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

return function(sender, msg)
    local runners = turtle_store.get_by_role("runner")

    if not runners then
        error("Replace with retry later")
    end

    if msg == "complete" then
        local runner = turtle_store.get(sender)
        runner.status = "Idle"
        turtle_store.upsert(sender, runner)
        return
    end

    local task_is_received = false
    while not task_is_received do
        for _, runner in ipairs(runners) do
            if runner.status == "Idle" then
                wireless.send(runner.id, { pos = msg, type = "pickup" }, "runner_pool")
                wireless.receive(10, "runner_pool_ack")

                -- Task has been picked up.

                task_is_received = true
                break
            end
        end

        -- All runners are busy, find the one with the least amount of tasks and queue it.
        if not task_is_received then
            local runner = find_least_queued(runners)

            if not runner then
                error("TODO fill in")
            end

            wireless.send(runner.id, { pos = msg, type = "pickup" }, "runner_pool")

            wireless.receive(10, "runner_pool_ack")
            task_is_received = true

            -- Task has been picked up.
        end
    end
end
