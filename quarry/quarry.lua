local movement = require("movement")
local wireless = require("wireless")

local list = require("shared.list")
local errors = require("shared.errors")
local inventory = require("shared.inventory")
local printer = require("shared.printer")

local quarry = {}

local fluids = {
    "minecraft:water",
    "minecraft:lava"
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

function quarry.scan_fluid_columns(job, movement_context)
    local water_columns = {}

    local starting_coordinates = movement.get_current_coordinates()
    local starting_orientation = movement.determine_orientation()
    local selected = turtle.getSelectedSlot()

    movement.move_back()

    -- local current_coordinates = movement.get_current_coordinates(true)
    -- table.insert(water_columns, current_coordinates)

    local water_row = job.current_row()
    while true do
        local ok, info = turtle.inspect()

        if not ok then
            break
        end

        repeat
            movement.move_forward(movement_context)
            local current_coordinates = movement.get_current_coordinates(true)
            table.insert(water_columns, current_coordinates)

            ok, info = turtle.inspect()
        until not quarry.is_fluid_block(info.name)

        local moved_to_next_column, moved_err

        if water_row % 2 == 0 then
            movement.turn_right()
            moved_to_next_column, moved_err = movement.move_forward(movement_context)
            movement.turn_right()
        else
            movement.turn_left()
            moved_to_next_column, moved_err = movement.move_forward(movement_context)
            movement.turn_left()
        end

        water_row = water_row + 1

        if not moved_to_next_column and moved_err ~= errors.NO_FUEL then
            break
        elseif moved_to_next_column then
            local current_coordinates = movement.get_current_coordinates(true)
            table.insert(water_columns, current_coordinates)
        end
    end

    for _, value in ipairs(water_columns) do
        local cobblestone_slot = inventory.find_item("minecraft:cobblestone")
        if not cobblestone_slot then
            printer.print_info("Requesting cobblestone...")
            local desired = { ["minecraft:cobblestone"] = 64 }
            wireless.resupply.request(movement_context.manager_id, movement.get_current_coordinates(), desired)
            local runner_id, job_id = wireless.resupply.await_arrival()
            inventory.drop_slots(3, 3, "up")
            wireless.resupply.signal_ready(runner_id, job_id)
            wireless.resupply.await_done()
            cobblestone_slot = inventory.find_item("minecraft:cobblestone")
        end

        turtle.select(cobblestone_slot)

        movement.move_to(value.x, value.y, value.z, movement_context)
        turtle.placeDown()

        movement.move_to(value.x, value.y + 1, value.z, movement_context)
        turtle.placeDown()

        movement.move_to(value.x, value.y + 2, value.z, movement_context)
        turtle.placeDown()
    end
    turtle.select(selected)

    movement.move_to(starting_coordinates.x, starting_coordinates.y, starting_coordinates.z, movement_context)
    movement.turn_to_direction(starting_orientation)
end

function quarry.fill_fluids(movement_context)
end

return quarry
