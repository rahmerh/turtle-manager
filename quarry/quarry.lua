local quarry = {}

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

return quarry
