local printer = require("shared.printer")
local time = require("shared.time")

local job = require("job")
local quarry = require("quarry")
local wireless = require("wireless")
local movement = require("movement")

printer.print_info("Booting quarry #" .. os.getComputerID())

local initialized, init_err = job.initialize()
if not initialized and init_err then
    printer.print_error("Please run 'prepare' before starting this quarry.")
    return
end

wireless.open()
local manager_id, find_err = wireless.discovery.find("manager")
if not manager_id and find_err then
    printer.print_error("Could not determine manager: " .. find_err)
    return
end

wireless.registry.register(manager_id, "quarry")

local start_heartbeat, _ = wireless.heartbeat.loop(manager_id, 1, function()
    return {
        status = job.status(),
        current_layer = job.current_layer(),
        current_row = job.current_row()
    }
end)

local function main()
    local boundaries = job.get_boundaries()

    if not job.is_in_progress() then
        local moved, moved_error = movement.move_to(
            boundaries.starting_position.x,
            boundaries.starting_position.y,
            boundaries.starting_position.z)

        if not moved then
            error("Turtle stuck: " .. moved_error)
        end
    end

    local movement_context = {
        dig = true
    }

    job.set_status(job.statuses.in_progress)
    printer.print_info("Quarry #" .. os.getComputerID() .. " in progress...")
    while job.current_layer() > 0 do
        for _ = 1, boundaries.width - job.current_row() do
            local coords = quarry.starting_location_for_row(job.current_layer(), job.current_row(), boundaries)
            local moved, moved_error = movement.move_to(coords.x, coords.y, coords.z, movement_context)

            if not moved then
                error("Turtle stuck: " .. moved_error)
            end

            local direction = quarry.get_row_direction_for_layer(boundaries.width, job.current_layer())
            local orientation_to_face
            if job.current_row() % 2 == 0 then
                orientation_to_face = direction
            else
                orientation_to_face = movement.opposite_of(direction)
            end
            movement.turn_to_direction(orientation_to_face)
            quarry.mine_up()
            quarry.mine_down()

            for _ = 1, boundaries.depth - 1 do
                quarry.mine()
                movement.move_forward()
                quarry.mine_up()
                quarry.mine_down()
            end

            job.increment_row()
        end

        job.next_layer()
    end

    job.complete()
end

parallel.waitForAny(start_heartbeat, main)

job.set_status(job.statuses.idle)
