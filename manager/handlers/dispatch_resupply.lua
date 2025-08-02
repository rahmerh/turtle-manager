local turtle_store = require("turtle_store")
local wireless = require("wireless")

local printer = require("shared.printer")
local errors = require("shared.errors")

local function find_least_queued(turtles)
    local result_id, result

    for id, t in pairs(turtles) do
        local amount_of_tasks = tonumber(t.queued_tasks) or 0
        if not result or amount_of_tasks < result.queued_tasks then
            result = t
            result_id = id
        end
    end

    return result_id, result
end

return function(sender, msg)
    wireless.ack(sender, msg)

    local runners = turtle_store.get_by_role("runner")

    if not runners and next(runners) == nil then
        return nil, errors.wireless.NO_AVAILABLE_RUNNERS
    end

    local task_is_received = false
    while not task_is_received do
        for id, runner in pairs(runners) do
            if runner.metadata.status == "Offline" or runner.metadata.status == "Stale" then
                goto continue
            end

            if runner.metadata.status == "Idle" then
                local payload = {
                    target    = msg.data.target,
                    desired   = msg.data.desired,
                    requester = sender,
                    job_id    = msg.id,
                }
                local ok, err = wireless.resupply.dispatch(id, payload)

                if not ok then
                    printer.print_warning(err)
                    break
                end

                task_is_received = true
                break
            end

            ::continue::
        end

        -- All runners are busy, find the one with the least amount of tasks and queue it.
        if not task_is_received then
            local id, runner = find_least_queued(runners)

            if not runner then
                return nil, errors.wireless.NO_AVAILABLE_RUNNERS
            end

            local payload = {
                target    = msg.data.target,
                desired   = msg.data.desired,
                requester = sender,
                job_id    = msg.id,
            }
            local ok, err = wireless.resupply.dispatch(id, payload)

            if not ok then
                printer.print_warning(err)
                break
            end

            task_is_received = true
            break
        end
    end

    if not task_is_received then
        return nil, errors.wireless.COULD_NOT_ASSIGN
    end
end
