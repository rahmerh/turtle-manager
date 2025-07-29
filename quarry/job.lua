local JOB_FILE = "job-file"

local STATUS_IDLE = "Idle"
local STATUS_STARTING = "Starting quarry"
local STATUS_IN_PROGRESS = "In progress"

local job = {
    _data = nil
}

-- === Internal ===

local function validate(data)
    if type(data) ~= "table" then return false end

    local b = data.boundaries
    if not b or not b.start_pos or not b.width or not b.depth or not b.layers then return false end

    data.current_layer = data.current_layer or b.layers
    data.current_row = data.current_row or 0
    data.unloading_chests = data.unloading_chests or {}
    data.resumable = data.resumable == nil and true or data.resumable
    data.status = data.status or STATUS_IDLE

    return true
end

local function set_status(status)
    job._data.status = status
    job.save()
end

-- === Public ===

function job.load()
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

    job._data = data
    return true
end

function job.save()
    if not job._data then error("No progress loaded") end

    local f = fs.open(JOB_FILE, "w")
    f.write(textutils.serialize(job._data))
    f.close()
end

function job.initialize(data)
    if not validate(data) then
        error("Invalid job data, not saving.")
    end
    job._data = data
    job.save()
end

function job.complete()
    fs.delete(JOB_FILE)
end

function job.pause()
    set_status(STATUS_IDLE)
end

function job.starting()
    set_status(STATUS_STARTING)
end

function job.start()
    set_status(STATUS_IN_PROGRESS)
end

function job.status()
    return job._data.status
end

function job.increment_row()
    job._data.current_row = job._data.current_row + 1
    job.save()
end

function job.set_row(row)
    job._data.current_row = row
    job.save()
end

function job.current_row()
    return job._data.current_row
end

function job.next_layer()
    job._data.current_layer = job._data.current_layer - 1
    job._data.current_row = 0
    job.save()
end

function job.current_layer()
    return job._data.current_layer
end

function job.register_unloading_chest(pos)
    local max = 0
    for k in pairs(job._data.unloading_chests) do
        if type(k) == "number" and k > max then max = k end
    end
    local key = max + 1
    job._data.unloading_chests[key] = pos
    job.save()
    return key
end

function job.get_boundaries()
    return job._data.boundaries
end

function job.is_in_progress()
    return job._data.status == STATUS_IN_PROGRESS
end

return job
