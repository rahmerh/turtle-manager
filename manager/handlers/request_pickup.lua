local wireless = require("wireless")

local printer = require("shared.printer")
local errors = require("shared.errors")

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

wireless.router.register_handler("rpc", "pickup:request", function(sender, msg)

end)

-- return function(msg)
--     local runners = turtle_store.get_by_role("runner")
--
--     if not runners and #runners == 0 then
--         return nil, errors.wireless.NO_AVAILABLE_RUNNERS
--     end
--
--     local task_is_received = false
--     while not task_is_received do
--         for _, runner in ipairs(runners) do
--             if runner.status == "Offline" or runner.status == "Stale" then
--                 goto continue
--             end
--
--             if runner.status == "Idle" then
--                 local sender, confirmation = wireless.send_runner_task(runner.id, msg, "pickup")
--
--                 if not sender then
--                     printer.print_warning(confirmation)
--                     break
--                 end
--
--                 task_is_received = true
--                 break
--             end
--
--             ::continue::
--         end
--
--         -- All runners are busy, find the one with the least amount of tasks and queue it.
--         if not task_is_received then
--             local runner = find_least_queued(runners)
--
--             if not runner then
--                 return nil, errors.wireless.NO_AVAILABLE_RUNNERS
--             end
--
--             local sender = wireless.send_runner_task(runner.id, msg, "pickup")
--
--             if not sender then
--                 break
--             end
--
--             task_is_received = true
--             break
--         end
--     end
--
--     if not task_is_received then
--         return nil, errors.wireless.COULD_NOT_ASSIGN
--     end
-- end
