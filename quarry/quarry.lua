local mover = require("mover")
local printer = require("printer")
local fueler = require("fueler")
local unloader = require("unloader")
local locator = require("locator")

-- === Progress functions ===
local progress_file = "job-file"
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
local function start_new_layer()
    for _ = 1, 2 do
        if turtle.detectDown() then
            turtle.digDown()
        end
        turtle.down()
        turtle.digDown()
    end
end

local function mine_next_column()
    fueler.refuel()

    while turtle.detect() do
        turtle.dig()
    end

    mover.move_forward()

    while turtle.detectUp() do
        turtle.digUp()
    end

    while turtle.detectDown() do
        turtle.digDown()
    end
end

local function mine_layer(progress)
    local amount_of_rows = progress.boundaries.width
    for i = 1, amount_of_rows do
        -- We do -1 here since we assume the turtle already is in the start pos of that layer.
        for _ = 1, progress.boundaries.depth - 1 do
            mine_next_column()
        end

        progress.current_row = progress.current_row + 1
        save_progress(progress)

        if i < amount_of_rows then
            if progress.current_row % 2 == 0 then
                mover.turn_left()
                mine_next_column()
                mover.turn_left()
            else
                mover.turn_right()
                mine_next_column()
                mover.turn_right()
            end
        end
    end
end

local function resume_quarry(progress)
    mover.move_to_x(progress.boundaries.start_pos.x)
    mover.move_to_z(progress.boundaries.start_pos.z)

    local pos = locator.get_pos()

    local layer_diff = progress.total_layers - progress.current_layer
    local target_y = progress.boundaries.start_pos.y - (layer_diff * 3)

    mover.move_to_y(target_y)
end

-- === Main ===
local progress = load_progress()

if not progress then
    printer.print_error("Job file missing, please run prepare before starting a new quarry.")
    return
end

local chest_detail = turtle.getItemDetail(2)
if not chest_detail or chest_detail.count < 4 or not chest_detail.name:lower():match("chest") then
    printer.print_error("Slot 2 must contain at least 4 chests.")
    return
end

local target = progress.boundaries.start_pos

printer.print_info("Moving to X: " .. target.x .. " Y: " .. target.y .. " Z: " .. target.z)

if not mover.move_to(target.x, target.y, target.z) then
    printer.print_error("Could not move to starting point.")
    return
end

printer.print_success("Arrived at destination, starting quarry.")

printer.print_info("Preparing unloading area")

unloader.create_unloading_area(target.x, target.y, target.z)

printer.print_info("Mining " .. progress.total_layers .. " layers.")
progress.current_layer = progress.total_layers

mover.turn_to_direction("north")

for _ = 0, progress.total_layers - 1 do
    progress.current_row = 0
    if progress.current_layer > 1 then
        start_new_layer()
        progress.current_layer = progress.current_layer - 1
        save_progress(progress)
    end

    mine_layer(progress)

    if progress.boundaries.width % 2 == 0 then
        mover.turn_right()
    else
        mover.turn_left()
        mover.turn_left()
    end

    -- Assume correct position for next layer.
    turtle.down()

    if progress.current_layer % 2 == 0 then
        unloader.unload_at_chest(1)
        resume_quarry(progress)
    end
end

for _ = 1, 4 do
    mover.turn_left()
end

printer.print_success("Job completed!")

printer.print_info("Returning to X: " .. target.x .. " Y: " .. target.y .. " Z: " .. target.z)
mover.move_to(target.x, target.y, target.z)
mover.turn_to_direction("north")
