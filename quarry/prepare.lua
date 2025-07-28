local printer = require("printer")
local job = require("job")

local startX, startY, startZ, depth, width = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]), tonumber(arg[4]),
    tonumber(arg[5])
if not startX or not startZ or not startY or not depth or not width then
    printer.print_error("Usage: prepare.lua <start_x> <start_y> <start_z> <depth> <width>")
    return
end

local success, _ = job.load()
if success then
    printer.print_warning("Found existing job.")
    printer.write_warning("Overwrite? y/n: ")
    local response = read()
    if response:lower() ~= "y" then
        print("Cancelled.")
        return
    end
end

local layers = math.floor((startY + 59) / 3)
local data = {
    boundaries = { start_pos = { x = startX, y = startY, z = startZ }, width = width, depth = depth, layers = layers },
    resumable = true,
    unloading_chests = {}
}

job.initialize(data)

printer.print_success("Initialized job.")
