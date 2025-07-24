local mover = require("mover")
local printer = require("printer")
local fueler = require("fueler")

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
    for _ = 1, 3 do
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

    turtle.forward()

    while turtle.detectUp() do
        turtle.digUp()
    end

    while turtle.detectDown() do
        turtle.digDown()
    end
end

local function mine_layer(progress)
    if not progress.current_row then
        progress.current_row = 0
        save_progress(progress)
    else
        -- TODO: Resume to current_row in progress
        progress.current_row = 0
        save_progress(progress)
    end

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

-- === Main ===
local progress = load_progress()

if not progress then
    printer.print_error("Job file missing, please run prepare before starting a new quarry.")
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
mover.turn_to_direction("south")

local success, data = turtle.inspect()
if success and data.name:match("chest") then
    print("That's a chest!")
end

for _ = 1, 5 do

end

mover.turn_to_direction("north")

printer.print_info("Mining " .. progress.total_layers .. " layers.")
progress.current_layer = progress.total_layers

turtle.digDown()
turtle.down()
turtle.digDown()
for _ = 0, progress.total_layers - 1 do
    mine_layer(progress)

    if progress.boundaries.width % 2 == 0 then
        mover.turn_right()
    else
        mover.turn_left()
        mover.turn_left()
    end

    if progress.current_layer > 1 then
        start_new_layer()
        progress.current_layer = progress.current_layer - 1
        save_progress(progress)
    end
end

for _ = 1, 4 do
    mover.turn_left()
end

printer.print_success("Job completed!")

mover.turn_to_direction("north")
printer.print_info("Returning to X: " .. target.x .. " Y: " .. target.y .. " Z: " .. target.z)
mover.move_to(target.x, target.y, target.z)
mover.turn_to_direction("north")
