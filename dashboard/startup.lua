local modem = peripheral.find("modem") or error("No modem found")
local monitor = peripheral.find("monitor") or error("No monitor found")
rednet.open(peripheral.getName(modem))
monitor.setTextScale(0.5)

local turtles = {}
local buttonMap = {}

local function drawButton(id, y)
    local label = "[Step]"
    local x = 25
    monitor.setCursorPos(x, y)
    monitor.setTextColor(colors.lime)
    monitor.write(label)
    monitor.setTextColor(colors.white)

    table.insert(buttonMap, {
        id = id,
        x1 = x,
        y1 = y,
        x2 = x + #label - 1,
        y2 = y
    })
end

local function updateDisplay()
    monitor.clear()
    monitor.setCursorPos(1, 1)
    buttonMap = {}

    for id, data in pairs(turtles) do
        local y = select(2, monitor.getCursorPos())
        monitor.write("Turtle " .. id .. ":")
        monitor.setCursorPos(1, y + 1)
        monitor.write("  Status: " .. (data.message or "unknown"))
        monitor.setCursorPos(1, y + 2)
        monitor.write("  Fuel: " .. tostring(data.fuel))
        monitor.setCursorPos(1, y + 3)

        if data.position then
            local p = data.position
            monitor.write(string.format("  Pos: (%d,%d,%d)", p.x, p.y, p.z))
            monitor.setCursorPos(1, y + 4)
        else
            monitor.write("  Pos: Unknown")
            monitor.setCursorPos(1, y + 4)
        end

        drawButton(id, y + 5)
        monitor.setCursorPos(1, y + 6)
    end
end

local function handleTouch(_, x, y)
    print("Touch at:", x, y)
    monitor.setCursorPos(1, 20)
    monitor.clearLine()
    monitor.write("Touch at: " .. x .. ", " .. y)

    for _, btn in ipairs(buttonMap) do
        if x >= btn.x1 and x <= btn.x2 and y == btn.y1 then
            print("Button hit for turtle: " .. btn.id)
            monitor.setCursorPos(1, 21)
            monitor.clearLine()
            monitor.write("Sent to: " .. btn.id)
            rednet.send(btn.id, textutils.serialize({
                type = "command",
                command = "step"
            }))
            return
        end
    end

    monitor.setCursorPos(1, 21)
    monitor.clearLine()
    monitor.write("No button hit")
end

updateDisplay()

while true do
    local e = { os.pullEvent() }

    if e[1] == "rednet_message" then
        local senderId, msg = e[2], e[3]
        local data = textutils.unserialize(msg)
        if data and data.type == "status" then
            turtles[senderId] = data
            updateDisplay()
        end
    elseif e[1] == "monitor_touch" then
        handleTouch(table.unpack(e))
    end
end
