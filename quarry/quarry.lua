local movement      = require("movement")
local wireless      = require("wireless")

local list          = require("lib.list")
local inventory     = require("lib.inventory")
local printer       = require("lib.printer")
local miner         = require("lib.miner")
local scanner       = require("lib.scanner")

local quarry        = {}

local fluids        = {
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

function quarry.is_fluid_block(name)
    return list.contains(fluids, name)
end

function quarry.mine_bedrock_layer(start_x, start_z, width, depth, movement_context)
    movement.move_to(start_x, -59, start_z, movement_context)
    movement.turn_to_direction("north")

    local to_move_forward = depth - 1

    while movement.get_current_coordinates().y > -60 do
        local moved_down = movement.move_down(movement_context)
        if not moved_down then
            break
        else
            miner.mine_down()
        end
    end

    for row = 1, width do
        for _ = 1, to_move_forward do
            miner.mine()

            while scanner.is_block("minecraft:bedrock", "forward") do
                miner.mine_up()
                movement.move_up(movement_context)
                miner.mine()
            end

            local moved_forward = movement.move_forward(movement_context)
            if moved_forward then
                to_move_forward = to_move_forward - 1
            end

            miner.mine_up()
            miner.mine_down()

            if inventory.are_all_slots_full() then
                quarry.unload(movement_context.manager_id)
            end

            while movement.get_current_coordinates().y > -60 do
                local moved_down = movement.move_down(movement_context)
                if not moved_down then
                    break
                else
                    miner.mine_down()
                end
            end
        end

        if row == width then
            break
        end

        if row % 2 == 0 then
            movement.move_up(movement_context)
            movement.move_up(movement_context)

            movement.turn_left()
            movement.move_forward(movement_context)
            movement.turn_left()

            movement.move_down(movement_context)
            movement.move_down(movement_context)
        else
            movement.move_up(movement_context)
            movement.move_up(movement_context)

            movement.turn_right()
            movement.move_forward(movement_context)
            movement.turn_right()

            movement.move_down(movement_context)
            movement.move_down(movement_context)
        end

        to_move_forward = depth - 1
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

    local current_coordinates = movement.get_current_coordinates()
    current_coordinates.y = current_coordinates.y - 1 -- Adjust down, since we're on top of the chest.
    wireless.pickup.request(manager_id, current_coordinates)

    if not scanner.is_free("forward") then
        miner.mine()
    end

    movement.move_forward()
    movement.move_down()
end

return quarry
