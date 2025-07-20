local excavator = require("excavator")

local modem = peripheral.find("modem") or error("No modem found")
rednet.open(peripheral.getName(modem))

local dashboards = {}

rednet.broadcast(textutils.serialize({
    type = "hello",
    role = "turtle",
    id = os.getComputerID()
}), "turtle-handshake")

local timeout = os.clock() + 2
while os.clock() < timeout do
    local sender, msg, proto = rednet.receive("dashboard-handshake", 0.5)
    if msg then
        local data = textutils.unserialize(msg)
        if data and data.type == "hello_ack" then
            dashboards[sender] = true
        end
    end
end

local function sendStatus(msg)
    for id in pairs(dashboards) do
        rednet.send(id, textutils.serialize({
            type = "status",
            from = os.getComputerID(),
            fuel = turtle.getFuelLevel(),
            message = msg,
        }))
    end
end

while true do
    sendStatus("Idle")

    local _, msg = rednet.receive(1)

    if msg == nil then goto continue end

    local cmd = textutils.unserialize(msg)

    print("Got command: " .. cmd.command)

    if cmd.command == "excavate" and cmd.args then
        local x = tonumber(cmd.args.x)
        local y = tonumber(cmd.args.y)
        local z = tonumber(cmd.args.z)
        excavator.excavate(x, y, z)
    end

    ::continue::
end
