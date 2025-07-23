local printer = {}

local defaultColor = colors.white

local function printColored(color, ...)
    term.setTextColor(color)
    print(...)
    term.setTextColor(defaultColor)
end

local function writeColored(color, ...)
    term.setTextColor(color)
    write(...)
    term.setTextColor(defaultColor)
end

printer.print_error = function(msg)
    printColored(colors.red, msg)
end

printer.print_warning = function(msg)
    printColored(colors.yellow, msg)
end

printer.print_success = function(msg)
    printColored(colors.green, msg)
end

printer.print_info = function(msg)
    printColored(colors.cyan, msg)
end

printer.write_warning = function(msg)
    writeColored(colors.yellow, msg)
end

printer.write_info = function(msg)
    writeColored(colors.cyan, msg)
end

return printer
