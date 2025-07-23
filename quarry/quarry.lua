local mover = require("mover")

local progress_file = "quarry-progress"
local function load_progress()
    if not fs.exists(progress_file) then
        error("Missing progress")
    end

    local f = fs.open(progress_file, "r")
    local data = textutils.unserialize(f.readAll())
    f.close()

    return data
end

-- === Main ===
local progress = load_progress()
local target = progress.start_pos

mover.move_to(target.x, target.y, target.z)
