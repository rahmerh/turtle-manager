local printer = require("printer")

local startX, startZ, startY, depth, width = tonumber(arg[1]), tonumber(arg[2]), tonumber(arg[3]),
    tonumber(arg[4]), tonumber(arg[5])
if not startX or not startZ or not startY or not depth or not width then
    printer.print_error("Usage: prepare.lua <start_x> <start_z> <start_y> <forward> <right>")
    return
end

local progress_file = "quarry-progress"
if fs.exists(progress_file) then
    local file = fs.open(progress_file, "r")
    local firstLine = file.readLine()
    file.close()

    print("here")

    if firstLine then
        printer.print_warning("Found existing coords.todo with unmined coordinates.")
        write("Overwrite and start new job? (y/N): ")
        local response = read()
        if response:lower() ~= "y" then
            print("Cancelled.")
            return
        end

        fs.delete(progress_file)
    end
end

local coords = {}
for dz = 0, depth - 1 do
    for dx = 0, width - 1 do
        table.insert(coords, { startX + dx, startZ + dz })
    end
end

local progress = {
    start_pos = { x = startX, y = startY, z = startZ },
    quarry_dimensions = {},
    current_layer = startY,
    layer_coords = coords
}

local f = fs.open(progress_file, "w")
f.write(textutils.serialize(progress))
f.close()

printer.print_success("Initialized job.")
