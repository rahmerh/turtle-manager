local modem = peripheral.find("modem") or error("No modem found")
local monitor = peripheral.find("monitor") or error("No monitor found")

rednet.open(peripheral.getName(modem))
monitor.setTextScale(0.5)

local turtles = {}

local function updateDisplay()
    monitor.clear()
    monitor.setCursorPos(1, 1)

    for id, data in pairs(turtles) do
        monitor.write("Turtle " .. id .. ":")
        local _, y = monitor.getCursorPos()
        monitor.setCursorPos(1, y + 1)

        monitor.write("  Status: " .. (data.message or "unknown"))
        monitor.setCursorPos(1, y + 2)

        monitor.write("  Fuel: " .. tostring(data.fuel))
        monitor.setCursorPos(1, y + 3)

        if data.position then
            local p = data.position
            monitor.write(string.format("  Pos: (%d, %d, %d)", p.x, p.y, p.z))
            monitor.setCursorPos(1, y + 4)
        else
            monitor.write("  Pos: Unknown")
            monitor.setCursorPos(1, y + 4)
        end

        monitor.setCursorPos(1, y + 5)
    end
end

while true do
    local senderId, msg = rednet.receive()
    local data = textutils.unserialize(msg)
    if data and data.type == "status" then
        turtles[senderId] = data
        updateDisplay()
    end
end
