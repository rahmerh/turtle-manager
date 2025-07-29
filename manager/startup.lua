local printer = require("printer")
local wireless = require("wireless")
local display = require("display")

local TURTLE_FILE = "turtles"

local turtles = {}

local function persist_turtles()
    local f = fs.open(TURTLE_FILE, "w")
    f.write(textutils.serialize(turtles))
    f.close()
end

local function load_turtles()
    if not fs.exists(TURTLE_FILE) then
        persist_turtles()
    end

    local f = fs.open(TURTLE_FILE, "r")
    local raw = f.readAll()
    f.close()

    local ok, data = pcall(textutils.unserialize, raw)
    if not ok then
        return nil, "Invalid or corrupt turtle file"
    end

    return data
end

local function epoch_in_seconds()
    return math.floor(os.epoch("utc") / 1000)
end

local function purge_stale_turtles()
    local now = epoch_in_seconds()

    local to_remove = {}
    for id, data in pairs(turtles) do
        if now - data.last_seen >= 30 then
            table.insert(to_remove, id)
        end
    end

    for _, k in ipairs(to_remove) do
        wireless.kill(k)
        turtles[k] = nil
    end
end

local handlers = {
    ["announce"] = function(sender, msg)
        wireless.send(sender, "ack", "announce")

        turtles[sender] = {
            role = msg,
            last_seen = epoch_in_seconds(),
            status = "New",
            current_layer = 0,
            total_layers = 0
        }

        printer.print_info("New turtle: " .. sender)

        persist_turtles()
    end,
    ["heartbeat"] = function(sender, msg)
        if not turtles[sender] then
            wireless.kill(sender)
            return
        end
        turtles[sender].last_seen = epoch_in_seconds()
        turtles[sender].status = msg.status
        turtles[sender].current_layer = msg.current_layer
        turtles[sender].total_layers = msg.total_layers

        persist_turtles()
    end
}

turtles = load_turtles()

printer.print_success("Manager online.")

while true do
    display.turtles(turtles)

    local sender, msg, protocol = rednet.receive(nil, 5)
    if msg and handlers[protocol] then
        handlers[protocol](sender, msg)
    elseif msg then
        printer.print_warning("Unhandled protocol: " .. tostring(protocol))
    end

    purge_stale_turtles()
end
