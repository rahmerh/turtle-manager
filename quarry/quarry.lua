local quarry = {}

local FORBIDDEN = {
    ["minecraft:bedrock"] = true,
    ["minecraft:end_portal"] = true,
    ["minecraft:end_portal_frame"] = true,
    ["minecraft:barrier"] = true,
    ["computercraft:turtle_advanced"] = true,
    ["computercraft:turtle_normal"] = true,
}

function quarry.get_row_direction_for_layer(width, layer)
    if width % 2 == 1 then
        return (layer % 2 == 0) and "south" or "north"
    else
        local dirs = { "east", "south", "west", "north" }
        return dirs[layer % 4 + 1]
    end
end

function quarry.starting_location_for_row(layer, row, boundaries)
    local current_layer_row_direction = quarry.get_row_direction_for_layer(boundaries.width, layer)

    local even_row = row % 2 == 0
    local to_move_x
    local to_move_z
    if current_layer_row_direction == "north" then
        to_move_x = row

        if even_row then
            to_move_z = 0
        else
            to_move_z = boundaries.depth - 1
        end
    elseif current_layer_row_direction == "east" then
        to_move_z = boundaries.depth - (row + 1)
        if even_row then
            to_move_x = 0
        else
            to_move_x = boundaries.width - 1
        end
    elseif current_layer_row_direction == "south" then
        to_move_x = boundaries.width - (row + 1)
        if even_row then
            to_move_z = boundaries.depth - 1
        else
            to_move_z = 0
        end
    elseif current_layer_row_direction == "west" then
        to_move_z = row
        if even_row then
            to_move_x = boundaries.width - 1
        else
            to_move_x = 0
        end
    end

    local steps_to_move_down = (boundaries.layers - layer) * 3 + 2

    local target_x = boundaries.starting_position.x + to_move_x
    local target_y = boundaries.starting_position.y - steps_to_move_down
    local target_z = boundaries.starting_position.z - to_move_z

    return {
        x = target_x,
        y = target_y,
        z = target_z
    }
end

function quarry.mine_up()
    local up_ok, up_metadata = turtle.inspectUp()
    if up_ok and up_metadata and not FORBIDDEN[up_metadata.name] then
        while turtle.detectUp() do
            turtle.digUp()
        end
    end
end

function quarry.mine_down()
    local down_ok, down_metadata = turtle.inspectDown()
    if down_ok and down_metadata and not FORBIDDEN[down_metadata.name] then
        while turtle.detectDown() do
            turtle.digDown()
        end
    end
end

function quarry.mine()
    local ok, metadata = turtle.inspect()
    if ok and metadata and not FORBIDDEN[metadata.name] then
        while turtle.detect() do
            turtle.dig()
        end
    end
end

-- local function mine_amount_of_rows(amount, length)
--     local turn_right = job.current_row() % 2 == 0
--     for i = 1, amount do
--         -- We do -1 here since we assume the turtle already is in the start pos of that row
--         for _ = 1, length - 1 do
--             local mined, err = mine_next_column()
--
--             while not mined and err == errors.NO_FUEL do
--                 local refueled, refueled_err = fueler.refuel_from_inventory()
--
--                 if not refueled and refueled_err == errors.NO_FUEL_STORED then
--                     wireless.request_resupply(manager_id, locator.get_pos(), { ["minecraft:coal"] = 64 })
--
--                     while not refueled do
--                         printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
--                         sleep(30)
--                         refueled, refueled_err = fueler.refuel_from_inventory()
--                     end
--                 end
--
--                 mined, err = mine_next_column()
--             end
--
--             if unloader.should_unload() then
--                 local chest_pos, unload_err = unloader.unload()
--
--                 if not chest_pos and unload_err == errors.NO_FUEL then
--                     local refueled, refueled_err = fueler.refuel_from_inventory()
--
--                     if not refueled and refueled_err == errors.NO_FUEL_STORED then
--                         wireless.request_resupply(manager_id, locator.get_pos(), { ["minecraft:coal"] = 64 })
--
--                         while not refueled do
--                             printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
--                             sleep(30)
--                             refueled, refueled_err = fueler.refuel_from_inventory()
--                         end
--                     end
--                 elseif not chest_pos and unload_err == errors.NO_FUEL_STORED then
--                     wireless.request_resupply(manager_id, locator.get_pos(), { ["minecraft:chest"] = 63 })
--                     while not chest_pos do
--                         printer.print_warning("No chests, waiting for runner, sleeping for 30 seconds...")
--                         sleep(30)
--
--                         chest_pos = unloader.unload()
--                     end
--                 end
--
--                 wireless.request_pickup(manager_id, chest_pos)
--             end
--         end
--
--         if i < amount then
--             if turn_right then
--                 mover.turn_right()
--                 mine_next_column()
--                 mover.turn_right()
--             else
--                 mover.turn_left()
--                 mine_next_column()
--                 mover.turn_left()
--             end
--         end
--
--         turn_right = not turn_right
--
--         job.increment_row()
--     end
-- end
--
-- local function move_to_current_row()
--     local boundaries = job.get_boundaries()
--     local current_layer = job.current_layer()
--     local current_row = job.current_row()
--
--     local current_layer_row_direction = get_row_direction_for_layer(boundaries.width, current_layer)
--
--     local even_row = current_row % 2 == 0
--     local to_move_x
--     local to_move_z
--     if current_layer_row_direction == "north" then
--         to_move_x = current_row
--
--         if even_row then
--             to_move_z = 0
--         else
--             to_move_z = boundaries.depth - 1
--         end
--     elseif current_layer_row_direction == "east" then
--         to_move_z = boundaries.depth - (current_row + 1)
--         if even_row then
--             to_move_x = 0
--         else
--             to_move_x = boundaries.width - 1
--         end
--     elseif current_layer_row_direction == "south" then
--         to_move_x = boundaries.width - (current_row + 1)
--         if even_row then
--             to_move_z = boundaries.depth - 1
--         else
--             to_move_z = 0
--         end
--     elseif current_layer_row_direction == "west" then
--         to_move_z = current_row
--         if even_row then
--             to_move_x = boundaries.width - 1
--         else
--             to_move_x = 0
--         end
--     end
--
--
--     -- +2 here since we have to account for the movements down before starting the first layer.
--     local steps_to_move_down = (boundaries.layers - current_layer) * 3 + 2
--
--     local target_x = boundaries.start_pos.x + to_move_x
--     local target_y = boundaries.start_pos.y - steps_to_move_down
--     local target_z = boundaries.start_pos.z - to_move_z
--
--     local arrived, err = mover.move_to(target_x, target_y, target_z, true)
--     if not arrived and err == errors.NO_FUEL then
--         local refueled, refueled_err = fueler.refuel_from_inventory()
--
--         if not refueled and refueled_err == errors.NO_FUEL_STORED then
--             wireless.request_resupply(manager_id, locator.get_pos(), { ["minecraft:coal"] = 64 })
--
--             while not refueled do
--                 printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
--                 sleep(30)
--                 refueled, refueled_err = fueler.refuel_from_inventory()
--             end
--         end
--
--         arrived, err = mover.move_to(target_x, target_y, target_z, true)
--     end
--
--     local orientation_to_face
--     if even_row then
--         orientation_to_face = current_layer_row_direction
--     else
--         orientation_to_face = mover.opposite_orientation_of(current_layer_row_direction)
--     end
--     mover.turn_to_direction(orientation_to_face)
--
--     if turtle.detectDown() then
--         turtle.digDown()
--     end
-- end
--
-- local function run_quarry()
--     local boundaries = job.get_boundaries()
--
--     if job.is_in_progress() then
--         job.starting()
--         move_to_current_row()
--
--         printer.print_success("Resuming quarry.")
--
--         job.start()
--
--         local direction = get_row_direction_for_layer(boundaries.width, job.current_layer())
--
--         local rows, length
--         if direction == "north" or direction == "south" then
--             rows = boundaries.width
--             length = boundaries.depth
--         else
--             rows = boundaries.depth
--             length = boundaries.width
--         end
--
--         mine_amount_of_rows(rows - job.current_row(), length)
--         job.next_layer()
--         move_to_current_row()
--     else
--         job.starting()
--
--         local desired = {}
--         if not inventory.does_slot_contain_item(1, "minecraft:coal") then
--             desired["minecraft:coal"] = 64
--         end
--         if not inventory.does_slot_contain_item(2, "minecraft:chest") then
--             desired["minecraft:chest"] = 64
--         end
--
--         if next(desired) ~= nil then
--             wireless.request_resupply(manager_id, locator.get_pos(), desired)
--
--             while not inventory.does_slot_contain_item(1, "minecraft:coal") and not inventory.does_slot_contain_item(2, "minecraft:chest") do
--                 printer.print_warning("Waiting for supplies, sleeping 30s...")
--                 sleep(30)
--             end
--         end
--
--         printer.print_info("Moving to X: " ..
--             boundaries.start_pos.x .. " Y: " .. boundaries.start_pos.y .. " Z: " .. boundaries.start_pos.z)
--         local arrived, err = mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)
--         while not arrived and err == errors.NO_FUEL do
--             local refueled, refueled_err = fueler.refuel_from_inventory()
--
--             if not refueled and refueled_err == errors.NO_FUEL_STORED then
--                 wireless.request_resupply(manager_id, locator.get_pos(), { ["minecraft:coal"] = 64 })
--
--                 while not refueled do
--                     printer.print_warning("Out of fuel, waiting for runner, sleeping 30s...")
--                     sleep(30)
--                     refueled, refueled_err = fueler.refuel_from_inventory()
--                 end
--             end
--
--             arrived, err = mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)
--         end
--
--         mover.turn_to_direction("north")
--         printer.print_success("Arrived at destination, starting quarry.")
--     end
--
--     job.start()
--     while job.current_layer() > 0 do
--         move_to_current_row()
--
--         local direction = get_row_direction_for_layer(boundaries.width, job.current_layer())
--
--         local rows, length
--         if direction == "north" or direction == "south" then
--             rows = boundaries.width
--             length = boundaries.depth
--         else
--             rows = boundaries.depth
--             length = boundaries.width
--         end
--
--         mine_amount_of_rows(rows, length)
--
--         job.next_layer()
--     end
--
--     mover.move_to(boundaries.start_pos.x, boundaries.start_pos.y, boundaries.start_pos.z)
--
--     local chest_pos = unloader.unload()
--     wireless.request_pickup(manager_id, chest_pos)
--
--     job.complete()
-- end

return quarry
