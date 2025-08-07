local movement = require("movement")
local wireless = require("wireless")

local list = require("lib.list")
local inventory = require("lib.inventory")
local printer = require("lib.printer")
local miner = require("lib.miner")
local scanner = require("lib.scanner")
local errors = require("lib.errors")

local quarry = {}

local fluids = {
    "minecraft:water",
    "minecraft:lava"
}

local filler_blocks = {
    "minecraft:cobblestone",
    "minecraft:deepslate",
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

local function detect_fluid_in_next_column(movement_context)
    local fluid_detected = false

    local ok, info = turtle.inspect()
    if ok and quarry.is_fluid_block(info.name) then
        fluid_detected = true
    end

    local moved, _ = movement.move_forward(movement_context)

    if not fluid_detected then
        local ok_up, info_up = turtle.inspectUp()
        local ok_down, info_down = turtle.inspectDown()
        if ok_up and quarry.is_fluid_block(info_up.name) or
            ok_down and quarry.is_fluid_block(info_down.name) then
            fluid_detected = true
        end
    end

    if fluid_detected and moved then
        return movement.get_current_coordinates()
    end
end

function quarry.is_fluid_block(name)
    return list.contains(fluids, name)
end

function quarry.scan_fluid_columns(movement_context)
    local water_columns = {}

    local start_pos = movement.get_current_coordinates()
    table.insert(water_columns, start_pos)

    local start_facing = movement.determine_orientation()
    local selected = turtle.getSelectedSlot()

    while true do
        while true do
            local coordinates = detect_fluid_in_next_column(movement_context)
            if coordinates and not list.contains(water_columns, coordinates) then
                table.insert(water_columns, coordinates)
            else
                break
            end
        end

        if coordinates then
            table.insert(water_columns, coordinates)
        else
            break
        end
    end

    for _ = 1, #water_columns do
        local cobble_slot = inventory.find_item("minecraft:cobblestone")

        if not cobble_slot then
            printer.print_info("Requesting cobblestone...")
            local desired = { ["minecraft:cobblestone"] = 64 }
            wireless.resupply.request(movement_context.manager_id, movement.get_current_coordinates(), desired)
            local runner_id, job_id = wireless.resupply.await_arrival()
            inventory.drop_slots(3, 3, "up")
            wireless.resupply.signal_ready(runner_id, job_id)
            wireless.resupply.await_done()
            cobble_slot = inventory.find_item("minecraft:cobblestone")
        end

        local info = inventory.details_from_slot(cobble_slot)
        if info.count < 3 then
            local next_cobble_slot = inventory.find_item("minecraft:cobblestone", 1)

            inventory.merge_into_slot(next_cobble_slot, cobble_slot)
        end

        turtle.select(cobble_slot)

        local back = movement.opposite_of(start_facing)
        movement.turn_to_direction(back)

        turtle.placeDown()
        turtle.placeUp()

        movement.move_forward()
        movement.turn_right()
        movement.turn_right()

        turtle.place()
    end

    turtle.select(selected)
    movement.move_to(start_pos.x, start_pos.y, start_pos.z, { dig = true })
    movement.turn_to_direction(start_facing)
end

function quarry.mine_bedrock_layer(x, z, width, depth, movement_context)
    local coordinates = movement.get_current_coordinates()

    if coordinates.y > -59 then
        movement.move_to(x, -59, z, { dig = true })
        movement.turn_to_direction("north")

        for row = 1, width do
            for _ = 1, depth - 1 do
                miner.mine_up()
                miner.mine()

                movement.move_forward(movement_context)

                if inventory.are_all_slots_full() then
                    quarry.unload(movement_context.manager_id)
                end
            end

            if row % 2 == 0 then
                movement.turn_left()
                miner.mine()
                miner.mine_up()
                movement.move_forward(movement_context)
                movement.turn_left()
            else
                movement.turn_right()
                miner.mine()
                miner.mine_up()
                movement.move_forward(movement_context)
                movement.turn_right()
            end
        end
    end

    movement.move_to(x, -59, z, movement_context)
    movement.turn_to_direction("north")

    local movement_context_no_retries = {
        manager_id = movement_context.manager_id,
        retries = 0
    }

    for row = 1, width do
        local to_move_forward = depth - 1

        while true do
            if to_move_forward <= 0 then
                break
            end

            if inventory.are_all_slots_full() then
                quarry.unload(movement_context.manager_id)
            end

            local moved_down = 0
            while true do
                miner.mine()

                local ok, err = movement.move_down(movement_context_no_retries)

                if ok then
                    moved_down = moved_down + 1
                end

                local mined_err
                if not ok and err == errors.BLOCKED then
                    _, mined_err = miner.mine_down()
                end

                if err == errors.BLOCKED and mined_err == errors.BLOCKED then
                    break
                end

                if ok and moved_down >= 2 then
                    movement.turn_left()
                    movement.turn_left()
                    miner.mine()
                    movement.turn_right()
                    movement.turn_right()
                end
            end

            if not scanner.is_free("up") then
                miner.mine_up()
            end

            while scanner.is_block("minecraft:bedrock", "up") do
                local moved_back = movement.move_back(movement_context_no_retries)
                if moved_back then
                    to_move_forward = to_move_forward + 1
                end

                movement.move_up(movement_context_no_retries)
            end

            while scanner.is_block("minecraft:bedrock", "forward") and scanner.is_free("up") do
                movement.move_up(movement_context_no_retries)
                local moved_forward = movement.move_forward(movement_context_no_retries)

                if moved_forward then
                    miner.mine()
                    to_move_forward = to_move_forward - 1
                end

                if to_move_forward <= 0 then
                    break
                end
            end

            if to_move_forward <= 0 then
                break
            end

            while scanner.is_block("minecraft:bedrock", "down") and scanner.is_free("forward") do
                local moved_forward = movement.move_forward(movement_context_no_retries)
                if moved_forward then
                    miner.mine()
                    to_move_forward = to_move_forward - 1
                end

                if to_move_forward <= 0 then
                    break
                end
            end
        end

        while movement.get_current_coordinates().y < -59 do
            movement.move_up(movement_context_no_retries)
        end

        if row % 2 == 0 then
            movement.turn_left()
            miner.mine()
            movement.move_forward(movement_context)
            miner.mine_up()
            miner.mine_down()
            movement.turn_left()
        else
            movement.turn_right()
            miner.mine()
            movement.move_forward(movement_context)
            miner.mine_up()
            miner.mine_down()
            movement.turn_right()
        end
    end
end

function quarry.unload(manager_id)
    local has_chests = inventory.is_item_in_slot("minecraft:chest", 2)

    if not has_chests then
        printer.print_info("Requesting chests...")
        local desired = { ["minecraft:chest"] = 64 }
        wireless.resupply.request(manager_id, movement.get_current_coordinates(), desired)
        local runner_id, job_id = wireless.resupply.await_arrival()
        inventory.drop_slots(2, 2, "up")
        wireless.resupply.signal_ready(runner_id, job_id)
        wireless.resupply.await_done()
    end

    movement.move_back()
    movement.move_up()

    turtle.select(2)
    turtle.placeDown()
    inventory.drop_slots(3, 16, "down")

    wireless.pickup.request(manager_id, movement.get_current_coordinates())

    if not scanner.is_free("forward") then
        miner.mine()
    end

    movement.move_forward()
    movement.move_down()
end

return quarry
