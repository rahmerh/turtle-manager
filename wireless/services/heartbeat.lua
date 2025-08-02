local core = require("wireless._internal.core")

local heartbeat = {}

local PROTOCOL = "telemetry"

local function beat(receiver, data)
    core.send(receiver, {
        operation = "heartbeat:beat",
        id = os.getComputerID(),
        timestamp = os.epoch("utc"),
        data = data
    }, PROTOCOL)
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
