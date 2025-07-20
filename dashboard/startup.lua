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
        if data.lastSeen and (os.clock() - data.lastSeen > 5) then
            turtles[id] = nil
            updateDisplay()
        end

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

local function handleTouch(x, y)
    for _, btn in ipairs(buttonMap) do
        if x >= btn.x1 and x <= btn.x2 and y == btn.y1 then
            rednet.send(btn.id, textutils.serialize({
                type = "command",
                command = "step"
            }))
            return
        end
    end
end

updateDisplay()

while true do
    local eventData = { os.pullEvent() }
    local event = eventData[1]

    if event == "rednet_message" then
        local senderId, msg = eventData[2], eventData[3]
        local data = textutils.unserialize(msg)
        if data and data.type == "status" then
            turtles[senderId] = data
            turtles[senderId].lastSeen = os.clock()
            updateDisplay()
        end
    elseif event == "monitor_touch" then
        handleTouch(eventData[3], eventData[4])
    end
end
