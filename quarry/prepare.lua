local printer = require("lib.printer")
local job = require("job")

local function prompt_num(label)
    while true do
        printer.write_prompt(label)
        local n = tonumber(read())
        if n then return n end
        printer.print_warning("Please enter a number.")
    end
end

if job.exists() then
    printer.print_warning("Found existing job.")

    local answered = false
    while not answered do
        printer.write_prompt("Overwrite? y/n: ")
        local response = read()

        if response:lower() == "y" then
            break
        elseif response:lower() == "n" then
            printer.print_success("Canelling setup, exiting.")
            return
        end
    end
end

printer.print_info("Coordinates of quarry's starting location:")

local starting_position_x, starting_position_y, starting_position_z
while not starting_position_x or not starting_position_y or not starting_position_z do
    if not starting_position_x then
        starting_position_x = prompt_num("X: ")
    elseif not starting_position_y then
        starting_position_y = prompt_num("Y: ")
    elseif not starting_position_z then
        starting_position_z = prompt_num("Z: ")
    end
end

printer.print_info("Dimensions of the quarry (Starting from the starting position, facing north)")

local width, depth
while not width or not depth do
    if not width then
        width = prompt_num("Width: ")
    elseif not depth then
        depth = prompt_num("Depth: ")
    end
end

local min_y_level = 59
local layer_thickness = 3
local layers = math.floor((starting_position_y + min_y_level) / layer_thickness)
local data = {
    boundaries = {
        starting_position = {
            x = tonumber(starting_position_x),
            y = tonumber(starting_position_y),
            z = tonumber(starting_position_z)
        },
        width = tonumber(width),
        depth = tonumber(depth),
        layers = tonumber(layers)
    },
    resumable = true,
    status = "new"
}

job.create(data)

printer.print_success("Quarry initialized, reboot to start quarry.")
