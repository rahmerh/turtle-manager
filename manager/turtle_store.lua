local utils = require("utils")

local turtle_store = {}

local TURTLE_FILE = "turtles"

local turtles = {}

local function save()
    local f = fs.open(TURTLE_FILE, "w")
    f.write(textutils.serialize(turtles))
    f.close()
end

local function ensure_loaded()
    if next(turtles) ~= nil then return end

    if not fs.exists(TURTLE_FILE) then
        turtles = {}
        turtle_store.save()
        return
    end

    local f = fs.open(TURTLE_FILE, "r")
    local raw = f.readAll()
    f.close()

    local ok, data = pcall(textutils.unserialize, raw)
    if ok and type(data) == "table" then
        turtles = data
    else
        turtles = {}
    end
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

function turtle_store.purge_stale(max_stale_seconds)
    ensure_loaded()
    local now = utils.epoch_in_seconds()

    local to_remove = {}
    for id, data in pairs(turtles) do
        if now - data.last_seen >= max_stale_seconds then
            table.insert(to_remove, id)
        elseif now - data.last_seen >= max_stale_seconds / 2 then
            turtles[id].status = "Stale"
        end
    end

    for _, k in ipairs(to_remove) do
        turtles[k] = nil
    end
end

return turtle_store
