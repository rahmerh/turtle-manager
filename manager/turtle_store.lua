local time = require("lib.time")

local turtle_store = {}

local TURTLE_FILE = "turtles.db"

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
    for id, turtle in pairs(turtles) do
        if turtle.role == role then
            result[id] = turtle
        end
    end

    return result
end

function turtle_store.update(id, data)
    ensure_loaded()

    local rec = turtles[id] or { id = id }

    if data.last_seen then
        rec.last_seen = data.last_seen
    end
    if data.status then
        rec.status = data.status
    end
    if data.metadata then
        rec.metadata = data.metadata
    end

    turtles[id] = rec

    save()
    return rec
end

function turtle_store.set_status(id, status)
    ensure_loaded()

    if not turtles[id] or not turtles[id].metadata then
        return
    end

    turtles[id].metadata.status = status
    save()
    return turtles[id]
end

function turtle_store.upsert(id, data)
    ensure_loaded()

    turtles[id] = data
    save()
end

function turtle_store.list()
    ensure_loaded()
    return turtles
end

return turtle_store
