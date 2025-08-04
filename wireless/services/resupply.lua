local rpc = require("wireless._internal.rpc")
local core = require("wireless._internal.core")

local time = require("lib.time")
local errors = require("lib.errors")

local resupply = {}

-- Requester methods
function resupply.request(receiver, turtle_position, desired_items)
    local ok, err = rpc.call(receiver, "resupply:request", {
        target = turtle_position,
        desired = desired_items
    })

    -- TODO: Handle errors better.

    return ok, err
end

function resupply.await_arrival()
    while true do
        local runner_id, msg, _ = core.receive(5)

        if msg and msg.operation == "resupply:arrived" then
            return runner_id, msg.job_id
        end
    end
end

function resupply.signal_ready(receiver, job_id)
    core.send(receiver, { job_id = job_id, operation = "resupply:ready" }, "rpc")
end

function resupply.await_done()
    while true do
        local runner_id, msg, _ = core.receive(5)

        if msg and msg.operation == "resupply:done" then
            return runner_id, msg.job_id
        end
    end
end

-- Runner methods
function resupply.runner_arrived(receiver, job_id)
    core.send(receiver, { job_id = job_id, operation = "resupply:arrived" }, "rpc")
end

function resupply.await_ready(job_id)
    local deadline = time.alive_duration_in_seconds() + 10
    while true do
        local runner_id, msg, _ = core.receive(5)

        if msg and msg.operation == "resupply:ready" and job_id == msg.job_id then
            return runner_id, msg.job_id
        end

        local now = time.alive_duration_in_seconds()
        if now > deadline then
            return nil, errors.wireless.TIMEOUT
        end
    end
end

function resupply.signal_done(receiver, job_id)
    core.send(receiver, { job_id = job_id, operation = "resupply:done" }, "rpc")
end

-- Manager methods
function resupply.dispatch(receiver, data)
    local ok, err = rpc.call(receiver, "resupply:dispatch", data)

    -- TODO: Handle errors better.

    return ok, err
end

return resupply
