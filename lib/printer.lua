local printer = {}

local defaultColour = colours.white

local function printColoured(colour, ...)
    term.setTextColour(colour)
    print(...)
    term.setTextColour(defaultColour)
end

local function writeColoured(colour, ...)
    term.setTextColour(colour)
    write(...)
    term.setTextColour(defaultColour)
end

printer.print_error = function(msg)
    printColoured(colours.red, msg)
end

printer.print_warning = function(msg)
    printColoured(colours.yellow, msg)
end

printer.print_success = function(msg)
    printColoured(colours.green, msg)
end

printer.print_info = function(msg)
    printColoured(colours.lightBlue, msg)
end

printer.write_prompt = function(msg)
    writeColoured(colours.white, msg)
end

return printer
