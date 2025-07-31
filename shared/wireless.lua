local protocols = {
    heartbeat = "heartbeat",
    announce = "announce",
    runner_tasks = "runner_tasks",
    task_completed = "task_completed",
    kill = "kill",
    request_pickup = "request_pickup",
    request_resupply = "request_resupply"
}

local default_receive_timeout = 5

local wireless = {}

if not rednet.isOpen() then
    for _, side in ipairs(peripheral.getNames()) do
        if peripheral.getType(side) ~= "modem" then
            goto continue
        end

        rednet.open(side)

        if not rednet.isOpen() then
            error("No modem found for rednet communication", 0)
        end

        ::continue::
    end
end

function wireless.receive_any()
    return rednet.receive(nil, default_receive_timeout)
end

function wireless.send_heartbeat(receiver, metadata)
    return rednet.send(receiver, metadata, protocols.heartbeat)
end

function wireless.register_new_turtle(role)
    rednet.broadcast(role, protocols.announce)

    local sender, msg, _ = rednet.receive(protocols.announce, default_receive_timeout)
    if sender and msg == "ack" then
        return sender
    end

    return nil, "No manager found."
end

function wireless.acknowledge_announcement(receiver)
    rednet.send(receiver, "ack", protocols.announce)
end

function wireless.send_runner_task(receiver, data, task_type)
    local message = { data = data, type = task_type }
    rednet.send(receiver, message, protocols.runner_tasks)

    local sender, message, protocol = rednet.receive(protocols.runner_tasks, default_receive_timeout)

    if not sender then
        return nil, "Turtle " .. receiver .. " didn't confirm message received in time."
    end

    return sender, message, protocol
end

function wireless.receive_runner_task()
    return rednet.receive(protocols.runner_tasks, default_receive_timeout)
end

function wireless.confirm_task_received(receiver)
    rednet.send(receiver, "ack", protocols.runner_tasks)
end

function wireless.task_completed(receiver, task_type)
    rednet.send(receiver, task_type, protocols.task_completed)
end

function wireless.kill(id)
    rednet.send(id, id, protocols.kill)
end

function wireless.receive_kill()
    return rednet.receive(protocols.kill, default_receive_timeout)
end

function wireless.request_pickup(receiver, pos)
    rednet.send(receiver, pos, protocols.request_pickup)
end

function wireless.request_resupply(receiver, pos, desired)
    rednet.send(receiver, { turtle_pos = pos, desired = desired }, protocols.request_resupply)
end

return wireless
