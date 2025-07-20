local modem = peripheral.find("modem") or error("No modem found")
local monitor = peripheral.find("monitor") or error("No monitor found")

rednet.open(peripheral.getName(modem))
monitor.setTextScale(0.5)

local heartbeat = os.startTimer(1)

local turtles = {}
local buttonMap = {}

local function drawButton(id, y)
    local label = " Excavate "
    y = y + 1
    local x = 25
    local width = #label

    monitor.setBackgroundColor(colors.lime)
    monitor.setTextColor(colors.black)
    monitor.setCursorPos(x, y)
    monitor.write(string.rep(" ", width))
    monitor.setCursorPos(x, y)
    monitor.write(label)

    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.white)

    table.insert(buttonMap, {
        id = id,
        x1 = x,
        x2 = x + #label - 1,
        y1 = y,
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

        monitor.write("  Status: " .. data.message)
        drawButton(id, y)
        monitor.setCursorPos(1, y + 1)

        monitor.setCursorPos(1, y + 6)
    end
end

local function handleTouch(x, y)
    for _, btn in ipairs(buttonMap) do
        if x >= btn.x1 and x <= btn.x2 and y >= btn.y1 and y <= btn.y2 then
            rednet.send(btn.id, textutils.serialize({
                type = "command",
                command = "excavate",
                args = { x = 5, y = 5, z = 5 }
            }))
            break
        end
    end
end

updateDisplay()

while true do
    local eventData = { os.pullEvent() }
    local event = eventData[1]

    if event == "rednet_message" then
        local senderId, msg, protocol = eventData[2], eventData[3], eventData[4]
        local data = textutils.unserialize(msg)

        if protocol == "turtle-handshake" and data and data.type == "hello" then
            print("Handshake from turtle " .. senderId)
            rednet.send(senderId, textutils.serialize({
                type = "hello_ack",
                role = "dashboard"
            }), "dashboard-handshake")
        elseif data and data.type == "status" then
            turtles[senderId] = data
            turtles[senderId].lastSeen = os.clock()
            updateDisplay()
        end
    elseif event == "monitor_touch" then
        handleTouch(eventData[3], eventData[4])
    elseif event == "timer" and eventData[2] == heartbeat then
        for id, data in pairs(turtles) do
            if data.lastSeen and (os.clock() - data.lastSeen > 5) then
                turtles[id] = nil
                updateDisplay()
            end
        end

        heartbeat = os.startTimer(1)
    end
end
