local turtle_store = require("turtle_store")
local wireless = require("wireless")
local display = require("display")
local utils = require("utils")

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

    local found_runner = false
    while not found_runner do
        for _, runner in ipairs(runners) do
            if runner.status == "Idle" then
                print("Preparing pickup task for " .. runner.id)

                wireless.send(runner.id, msg, "runner_pool")

                local runner_sender, _, _ = wireless.receive(10, "runner_pool_ack")

                if not runner_sender then
                    return
                end

                runner.status = "Running"
                turtle_store.upsert(runner.id, runner)
                found_runner = true

                print("Sent pickup request to runner " .. runner.id)

                break
            end
        end

        if not found_runner then
            print("Pausing for 10s, waiting for a new runner...")
            sleep(10)
        else
            break
        end
    end
end
