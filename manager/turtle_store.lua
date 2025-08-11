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

function turtle_store.patch(id, data)
    ensure_loaded()

    local function deep_patch(dst, src)
        for k, v in pairs(src) do
            if type(v) == "table" then
                if next(v) ~= nil and type(dst[k]) == "table" then
                    deep_patch(dst[k], v)
                else
                    dst[k] = v
                end
            else
                dst[k] = v
            end
        end
    end

    local rec = turtles[id] or { id = id }
    deep_patch(rec, data)
    turtles[id] = rec

    save()
    return rec
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
