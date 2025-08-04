local list = require("lib.list")

local JOB_FILE = "job.conf"

local job = {
    _data = nil,
    statuses = {
        idle = "Idle",
        starting = "Starting quarry",
        in_progress = "In progress",
    }
}

-- === Internal ===

local function validate(data)
    if type(data) ~= "table" then
        return false
    end

    local is_valid = false

    is_valid = data.boundaries ~= nil and data.boundaries.starting_position ~= nil
    is_valid = tonumber(data.boundaries.starting_position.x) ~= nil
    is_valid = tonumber(data.boundaries.starting_position.y) ~= nil
    is_valid = tonumber(data.boundaries.starting_position.z) ~= nil
    is_valid = data.boundaries.width ~= nil and tonumber(data.boundaries.width) ~= nil
    is_valid = data.boundaries.depth ~= nil and tonumber(data.boundaries.depth) ~= nil
    is_valid = data.boundaries.layers ~= nil and tonumber(data.boundaries.layers) ~= nil
    is_valid = data.resumable ~= nil and type(data.resumable) == "boolean"

    return is_valid
end

local function load()
    if not fs.exists(JOB_FILE) then
        return nil, "Job file missing"
    end

    local f = fs.open(JOB_FILE, "r")
    local raw = f.readAll()
    f.close()

    local ok, data = pcall(textutils.unserialize, raw)
    if not ok or not validate(data) then
        return nil, "Invalid or corrupt progress file"
    end

    return data
end

local function save()
    if not job._data then error("No progress loaded") end

    local f = fs.open(JOB_FILE, "w+")
    f.write(textutils.serialize(job._data))
    f.close()
end

-- === Public ===

function job.create(data)
    if not validate(data) then
        return nil, "Invalid job data."
    end

    job._data = data
    save()
end

function job.exists()
    local exists = fs.exists(JOB_FILE)
    local is_valid = false
    if exists then
        local data, err = load()

        if data and not err then
            is_valid = true
        end
    end

    return exists and is_valid
end

--- Loads the job's information from file, initializing this instance.
--- @return boolean|boolean, string?  boolean or nil,error
function job.initialize()
    local data, err = load()

    if not data and err then
        return false, err
    end

    job._data = data
    return true
end

function job.complete()
    fs.delete(JOB_FILE)
end

function job.status()
    return job._data.status
end

function job.set_status(status)
    if not list.map_contains_value(job.statuses, status) then
        error("Invalid status: '" .. status .. "'")
    end

    job._data.status = status
    save()
end

function job.increment_row()
    if not job._data.current_row then
        job._data.current_row = 0
    end

    job._data.current_row = job._data.current_row + 1

    save()
end

function job.set_row(row)
    job._data.current_row = row
    save()
end

function job.current_row()
    return job._data.current_row or 0
end

function job.next_layer()
    if not job._data.current_layer then
        job._data.current_layer = job._data.boundaries.layers
    end

    job._data.current_layer = job._data.current_layer - 1
    job._data.current_row = 0
    save()
end

function job.current_layer()
    return job._data.current_layer or job._data.boundaries.layers
end

function job.get_boundaries()
    return job._data.boundaries
end

function job.is_in_progress()
    return job._data.status == job.statuses.in_progress or job._data.status == job.statuses.starting
end

return job
