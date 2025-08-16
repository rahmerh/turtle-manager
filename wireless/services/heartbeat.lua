local core = require("wireless._internal.core")

local heartbeat = {
    operation = "heartbeat:beat"
}

local function beat(receiver, data)
    local payload = {
        operation = "heartbeat:beat",
        data = data
    }
    return core.send(receiver, payload, core.protocols.telemetry)
end

function heartbeat.loop(receiver, interval, data_fn)
    local running = true
    local function run()
        while running do
            local payload = data_fn and data_fn() or nil
            beat(receiver, payload)
            sleep(interval)
        end
    end
    local function stop() running = false end
    return run, stop
end

return heartbeat
