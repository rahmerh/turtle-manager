local modem = peripheral.find("modem") or error("No modem found")
rednet.open(peripheral.getName(modem))
local id = os.getComputerID()

if turtle.getFuelLevel() == 0 then
    for i = 1, 16 do
        turtle.select(i)
        if turtle.refuel(1) then
            print("Refueled from slot " .. i)
            break
        end
    end
end

local function sendStatus(msg)
    local status = {
        type = "status",
        message = msg,
        fuel = turtle.getFuelLevel(),
        id = id,
        position = gps.locate(2)
    }
    rednet.send(1, textutils.serialize(status))
end

sendStatus("Online")

while true do
    sendStatus("Idle")
    local senderId, msg = rednet.receive(5)

    if msg then
        local cmd = textutils.unserialize(msg)
        if cmd and cmd.type == "command" and cmd.command == "step" then
            if turtle.forward() then
                sendStatus("Stepped forward")
            else
                sendStatus("Blocked")
            end
        end
    end
end
