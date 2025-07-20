local modem = peripheral.find("modem") or error("No modem found")
rednet.open(peripheral.getName(modem))

local DASHBOARD_ID = 1 -- Replace if dashboard has a different ID, or use rednet.broadcast

-- Optional: if you want to include position
local function getPosition()
    local x, y, z = gps.locate(2)
    if x then
        return { x = x, y = y, z = z }
    else
        return nil
    end
end

local function sendStatus()
    local status = {
        type = "status",
        message = "Idle",
        fuel = turtle.getFuelLevel(),
        id = os.getComputerID(),
        position = getPosition()
    }

    rednet.send(DASHBOARD_ID, textutils.serialize(status))
end

while true do
    sendStatus()
    sleep(5)
end
