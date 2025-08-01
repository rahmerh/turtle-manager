local core = require("wireless._internal.core")
local store = require("wireless._internal.turtle_store")

local time = require("shared.time")

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

function heartbeat.install_on(router)
    router.register_handler(PROTOCOL, "heartbeat:beat", function(sender, msg)
        local rec = store.get(sender)
        if not rec then return false end

        store.patch(sender, {
            last_seen = time.epoch_in_seconds(),
            status    = msg.status,
            metadata  = msg.data or rec.metadata,
        })
        return true
    end)
end

return heartbeat
