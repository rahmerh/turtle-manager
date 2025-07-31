local mover = require("mover")
local printer = require("printer")
local fueler = require("fueler")
local unloader = require("unloader")
local job = require("job")
local wireless = require("wireless")
local errors = require("errors")
local locator = require("locator")

local manager_id = wireless.register_new_turtle("quarry")
if not manager_id then
    printer.print_error("No manager found, is there a manager instance running?")
    return
end

printer.print_info("Starting quarry #" .. os.getComputerID())

local UNBREAKABLE = {
    ["minecraft:bedrock"] = true,
    ["minecraft:end_portal"] = true,
    ["minecraft:end_portal_frame"] = true,
    ["minecraft:barrier"] = true,
}

local function mine_next_column()
    local ok, metadata = turtle.inspect()
    if ok and metadata and not UNBREAKABLE[metadata.name] then
        while turtle.detect() do
            turtle.dig()
        end
    end

    local moved, err = mover.move_forward()
    if not moved and err then
        return moved, err
    end

    local up_ok, up_metadata = turtle.inspectUp()
    if up_ok and up_metadata and not UNBREAKABLE[up_metadata.name] then
        while turtle.detectUp() do
            turtle.digUp()
        end
    end

    local down_ok, down_metadata = turtle.inspectDown()
    if down_ok and down_metadata and not UNBREAKABLE[down_metadata.name] then
        while turtle.detectDown() do
            turtle.digDown()
        end
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
            local mined, err = mine_next_column()

            if not mined and err == errors.NO_FUEL then
                local refueled, refueled_err = fueler.refuel_from_inventory()

                if not refueled and refueled_err == errors.NO_FUEL_STORED then
                    wireless.request_resupply(manager_id, locator.get_pos())

                    while not refueled do
                        printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
                        sleep(30)
                        refueled, refueled_err = fueler.refuel_from_inventory()
                    end
                end
            end

            if unloader.should_unload() then
                local chest_pos = unloader.unload()

                while not chest_pos do
                    printer.print_error("Not enough chests in slot 2, can't unload, sleeping for 10 seconds...")
                    sleep(10)

                    chest_pos = unloader.unload()
                end

                wireless.request_pickup(manager_id, chest_pos)
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

local function move_to_current_row()
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


    -- +2 here since we have to account for the movements down before starting the first layer.
    local steps_to_move_down = (boundaries.layers - current_layer) * 3 + 2

    local target_x = boundaries.start_pos.x + to_move_x
    local target_y = boundaries.start_pos.y - steps_to_move_down
    local target_z = boundaries.start_pos.z - to_move_z

    local arrived, err = mover.move_to(target_x, target_y, target_z, true)
    if not arrived and err == errors.NO_FUEL then
        local refueled, refueled_err = fueler.refuel_from_inventory()

        if not refueled and refueled_err == errors.NO_FUEL_STORED then
            wireless.request_resupply(manager_id, locator.get_pos())

            while not refueled do
                printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
                sleep(30)
                refueled, refueled_err = fueler.refuel_from_inventory()
            end
        end

        arrived, err = mover.move_to(target_x, target_y, target_z, true)
    end

    local orientation_to_face
    if even_row then
        orientation_to_face = current_layer_row_direction
    else
        orientation_to_face = mover.opposite_orientation_of(current_layer_row_direction)
    end
    mover.turn_to_direction(orientation_to_face)

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

local function run_quarry()
    local boundaries = job.get_boundaries()

    if job.is_in_progress() then
        job.starting()
        move_to_current_row()

        printer.print_success("Resuming quarry.")

        job.start()

        local direction = get_row_direction_for_layer(boundaries.width, job.current_layer())

        local rows, length
        if direction == "north" or direction == "south" then
            rows = boundaries.width
            length = boundaries.depth
        else
            rows = boundaries.depth
            length = boundaries.width
        end

        mine_amount_of_rows(rows - job.current_row(), length)
        job.next_layer()
        move_to_current_row()
    else
        local chest_detail = turtle.getItemDetail(2)
        if not chest_detail or chest_detail.count < 4 or not chest_detail.name:lower():match("chest") then
            printer.print_error("Slot 2 must contain at least 4 chests.")
            return
        end

        job.starting()

        printer.print_info("Moving to X: " ..
            boundaries.start_pos.x .. " Y: " .. boundaries.start_pos.y .. " Z: " .. boundaries.start_pos.z)
        local arrived, err = mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)
        while not arrived and err == errors.NO_FUEL do
            fueler.refuel_from_inventory()
            arrived, err = mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)
        end

        mover.turn_to_direction("north")
        printer.print_success("Arrived at destination, starting quarry.")
    end

    job.start()
    while job.current_layer() > 0 do
        move_to_current_row()

        local direction = get_row_direction_for_layer(boundaries.width, job.current_layer())

        local rows, length
        if direction == "north" or direction == "south" then
            rows = boundaries.width
            length = boundaries.depth
        else
            rows = boundaries.depth
            length = boundaries.width
        end

        mine_amount_of_rows(rows, length)

        job.next_layer()
    end

    mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)

    local chest_pos = unloader.unload()
    wireless.request_pickup(manager_id, chest_pos)

    job.complete()
end

local function kill_switch()
    while true do
        local _, id_to_kill = wireless.receive_kill()
        if id_to_kill == os.getComputerID() then
            printer.print_warning("Received kill command, exiting.")
            break
        end
    end
end

local function heartbeat()
    while true do
        local metadata = {
            status = job.status(),
            current_layer = job.current_layer() + 1,
            total_layers = job.get_boundaries().layers + 1
        }
        if not wireless.send_heartbeat(manager_id, metadata) then
            error("Could not locate manager.")
        end
        sleep(1)
    end
end

parallel.waitForAny(run_quarry, kill_switch, heartbeat)

printer.print_success("Done.")
