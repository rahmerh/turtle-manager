local mover = require("mover")
local printer = require("printer")
local locator = require("locator")

local progress_file = "quarry-job"
local function load_progress()
    if not fs.exists(progress_file) then
        printer.print_error("Make sure to prepare a job before starting it first.")
        return
    end

    local f = fs.open(progress_file, "r")
    local data = textutils.unserialize(f.readAll())
    f.close()

    return data
end

local function save_progress(progress)
    local f = fs.open(progress_file, "w")
    f.write(textutils.serialize(progress))
    f.close()
end

-- === Quarrying ===
local function mine_to_next_layer()
    for _ = 1, 2 do
        if turtle.detectDown() then
            turtle.digDown()
        end
        turtle.down()
        turtle.digDown()
    end
end

local function remove_coord(coords, x, z)
    for i, pair in ipairs(coords) do
        if pair[1] == x and pair[2] == z then
            printer.print_info("Mined coord: X: " .. x .. " Z: " .. z)
            table.remove(coords, i)
            return true
        end
    end
    return false
end

local function mine_row(progress, length)
    for _ = 0, length - 1 do
        local pos = locator.get_pos()

        while turtle.detect() do
            turtle.dig()
        end

        turtle.forward()

        while turtle.detectUp() do
            turtle.digUp()
        end

        while turtle.detectDown() do
            turtle.digDown()
        end

        print("Mining at " .. pos.x .. " " .. pos.z)

        remove_coord(progress.layer_coords, pos.x, pos.z)
        save_progress(progress)
    end
end


-- === Main ===
local progress = load_progress()
if not progress then return end

local target = progress.boundaries.start_pos

mover.move_to(target.x, target.y, target.z)

mine_to_next_layer()
-- Min 1 because the init fn above already did that.
mine_row(progress, progress.boundaries.depth - 1)
