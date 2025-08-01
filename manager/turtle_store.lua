local utils = require("shared.utils")
local display = require("shared.display")

local turtle_store = {}

local TURTLE_FILE = "turtles"

local turtles = {}

local function save()
    local f = fs.open(TURTLE_FILE, "w")
    f.write(textutils.serialize(turtles))
    f.close()
end

local function ensure_loaded()
    if not fs.exists(TURTLE_FILE) then
        turtles = {}
        return
    end

    local f = fs.open(TURTLE_FILE, "r")
    local raw = f.readAll()
    f.close()

    turtles = textutils.unserialize(raw)
end

function turtle_store.get(id)
    ensure_loaded()

    return turtles[id]
end

function turtle_store.get_by_role(role)
    ensure_loaded()

    local result = {}
    for _, turtle in pairs(turtles) do
        if turtle.role == role then
            table.insert(result, turtle)
        end
    end
    return result
end

function turtle_store.upsert(id, data)
    ensure_loaded()

    turtles[id] = data
    save()
end

function turtle_store.detect_stale()
    ensure_loaded()
    local now = utils.epoch_in_seconds()

    for id, data in pairs(turtles) do
        if now - data.last_seen >= 10 then
            turtles[id].status = "Offline"

            local lines = display.status_lines_for(turtles[id])
            display.add_or_update_block(id, lines, "err")
        elseif now - data.last_seen >= 5 then
            turtles[id].status = "Stale"

            local lines = display.status_lines_for(turtles[id])
            display.add_or_update_block(id, lines, "warn")
        end
    end
    save()
end

return turtle_store
