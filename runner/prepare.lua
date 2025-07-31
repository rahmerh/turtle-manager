local printer = require("printer")

printer.print_info("Coordinates of the unloading chest:")

local unloading_chest_x, unloading_chest_y, unloading_chest_z
local unloading_chest_complete = false

while not unloading_chest_complete do
    if not unloading_chest_x then
        printer.write_prompt("X: ")
        unloading_chest_x = read()
    elseif not unloading_chest_y then
        printer.write_prompt("Y: ")
        unloading_chest_y = read()
    elseif not unloading_chest_z then
        printer.write_prompt("Z: ")
        unloading_chest_z = read()
    end

    if unloading_chest_x and unloading_chest_y and unloading_chest_z then
        unloading_chest_complete = true
    end
end

printer.print_info("Coordinates of the coal chest:")

local coal_chest_x, coal_chest_y, coal_chest_z
local coal_chest_complete = false

while not coal_chest_complete do
    if not coal_chest_x then
        printer.write_prompt("X: ")
        coal_chest_x = read()
    elseif not coal_chest_y then
        printer.write_prompt("Y: ")
        coal_chest_y = read()
    elseif not coal_chest_z then
        printer.write_prompt("Z: ")
        coal_chest_z = read()
    end

    if coal_chest_x and coal_chest_y and coal_chest_z then
        coal_chest_complete = true
    end
end

local config = {
    unloading_chest_pos = {
        x = unloading_chest_x,
        y = unloading_chest_y,
        z = unloading_chest_z
    },
    coal_chest_pos = {
        x = coal_chest_x,
        y = coal_chest_y,
        z = coal_chest_z
    }
}

local config_file = fs.open("runner.conf", "w+")
config_file.write(textutils.serialize(config))
config_file.close()

printer.print_success("Runner configured, reboot the turtle to start.")
