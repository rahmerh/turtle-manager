local mover = require("mover")
local printer = require("printer")
local fueler = require("fueler")
local unloader = require("unloader")
local job = require("job")

local function start_new_layer()
    for _ = 1, 2 do
        turtle.digDown()
        mover.move_down()
        turtle.digDown()
    end

    job.next_layer()
end

local function mine_next_column()
    fueler.refuel_from_inventory()

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

local function get_row_direction_for_layer(width, layer)
    if width % 2 == 1 then
        return (layer % 2 == 0) and "south" or "north"
    else
        local dirs = { "east", "south", "west", "north" }
        return dirs[layer % 4 + 1]
    end
end

local function mine_amount_of_rows(amount, length)
    local turn_right = job.current_row() % 2 == 0
    for i = 1, amount do
        -- We do -1 here since we assume the turtle already is in the start pos of that row
        for _ = 1, length - 1 do
            mine_next_column()

            if unloader.should_unload() then
                unloader.unload()
            end
        end

        if i < amount then
            if turn_right then
                mover.turn_right()
                mine_next_column()
                mover.turn_right()
            else
                mover.turn_left()
                mine_next_column()
                mover.turn_left()
            end
        end

        turn_right = not turn_right

        job.increment_row()
    end
end

local function move_to_current_row_in_progress()
    local boundaries = job.get_boundaries()
    local current_layer = job.current_layer()
    local current_row = job.current_row()

    local current_layer_row_direction = get_row_direction_for_layer(boundaries.width, current_layer)

    local even_row = current_row % 2 == 0
    local to_move_x
    local to_move_z
    if current_layer_row_direction == "north" then
        to_move_x = current_row

        if even_row then
            to_move_z = 0
        else
            to_move_z = boundaries.depth - 1
        end
    elseif current_layer_row_direction == "east" then
        to_move_z = boundaries.depth - (current_row + 1)
        if even_row then
            to_move_x = 0
        else
            to_move_x = boundaries.width - 1
        end
    elseif current_layer_row_direction == "south" then
        to_move_x = boundaries.width - (current_row + 1)
        if even_row then
            to_move_z = boundaries.depth - 1
        else
            to_move_z = 0
        end
    elseif current_layer_row_direction == "west" then
        to_move_z = current_row
        if even_row then
            to_move_x = boundaries.width - 1
        else
            to_move_x = 0
        end
    end

    mover.move_to_z(boundaries.start_pos.z - to_move_z, true)
    mover.move_to_x(boundaries.start_pos.x + to_move_x, true)

    local orientation_to_face
    if even_row then
        orientation_to_face = current_layer_row_direction
    else
        orientation_to_face = mover.opposite_orientation_of(current_layer_row_direction)
    end
    mover.turn_to_direction(orientation_to_face)

    -- +2 here since we have to account for the movements down before starting the first layer.
    local steps_to_move_down = (boundaries.layers - current_layer) * 3 + 2

    local layer_y = boundaries.start_pos.y - steps_to_move_down
    mover.move_to_y(layer_y, true)

    if turtle.detectDown() then
        turtle.digDown()
    end
end

-- === Main ===
local success, msg = job.load()
if not success then
    printer.print_error(msg)
    return
end

job.starting()

local chest_detail = turtle.getItemDetail(2)
if not chest_detail or chest_detail.count < 4 or not chest_detail.name:lower():match("chest") then
    printer.print_error("Slot 2 must contain at least 4 chests.")
    return
end

local boundaries = job.get_boundaries()

printer.print_info("Moving to X: " ..
    boundaries.start_pos.x .. " Y: " .. boundaries.start_pos.y .. " Z: " .. boundaries.start_pos.z)
if not mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z) then
    printer.print_error("Could not move to starting point.")
    return
end
mover.turn_to_direction("north")
printer.print_success("Arrived at destination, starting quarry.")

local function run_quarry()
    job.start()
    while job.current_layer() >= 0 do
        start_new_layer()

        mine_amount_of_rows(boundaries.width, boundaries.depth)

        if boundaries.width % 2 == 0 then
            mover.turn_right()
        else
            mover.turn_left()
            mover.turn_left()
        end

        -- Assume correct position for next layer.
        mover.move_down()

        job.next_layer()
    end
end

local function kill_switch()
    printer.print_info("Press enter to stop")
    repeat
        local _, key = os.pullEvent("key")
    until key == keys.enter
end

parallel.waitForAny(run_quarry, kill_switch)

printer.print_success("Done.")
job.complete()

-- if job.is_in_progress() then
--     move_to_current_row_in_progress()
--
--     local left_over_rows = progress.boundaries.width - progress.current_row
--     if not mine_amount_of_rows(left_over_rows, progress.boundaries.depth, progress) then
--         goto restart
--     end
--
--     progress.current_layer = progress.current_layer - 1
--     save_progress(progress)
--
--     if progress.boundaries.width % 2 == 0 then
--         mover.turn_right()
--     else
--         mover.turn_left()
--         mover.turn_left()
--     end
--
--     mover.move_down()
-- else
--     printer.print_info("Moving to X: " .. target.x .. " Y: " .. target.y .. " Z: " .. target.z)
--     if not mover.move_to(target.x, target.y, target.z) then
--         printer.print_error("Could not move to starting point.")
--         return
--     end
--     printer.print_success("Arrived at destination, starting quarry.")
--
--     printer.print_info("Preparing unloading area")
--     local key, value = unloader.create_initial_unloading_area(target.x, target.y, target.z)
--     progress.unloading_chests[key] = value
--     save_progress(progress)
--
--     printer.print_info("Mining " .. progress.total_layers + 1 .. " layers.")
--     if not progress.current_layer then
--         progress.current_layer = progress.total_layers
--         save_progress(progress)
--     end
--
--     mover.turn_to_direction("north")
-- end
--
-- while progress.current_layer >= 0 do
--     start_new_layer()
--
--     progress.current_row = 0
--     if not mine_amount_of_rows(progress.boundaries.width, progress.boundaries.depth, progress) then
--         move_to_current_row_in_progress(progress)
--         goto restart
--     end
--
--     progress.current_row = nil
--
--     if progress.boundaries.width % 2 == 0 then
--         mover.turn_right()
--     else
--         mover.turn_left()
--         mover.turn_left()
--     end
--
--     -- Assume correct position for next layer.
--     mover.move_down()
--
--     progress.current_layer = progress.current_layer - 1
--     save_progress(progress)
-- end
--
-- for _ = 1, 4 do
--     mover.turn_left()
-- end
--
-- unloader.unload_at_chest(1, progress)
-- mover.move_to(target.x, target.y, target.z)
-- mover.turn_to_direction("north")
