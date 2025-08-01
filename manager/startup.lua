local printer = require("shared.printer")
local display = require("shared.display")
local turtle_store = require("turtle_store")
local wireless = require("shared.wireless")
local utils = require("shared.utils")
local file = require("shared.file")

local handlers = {
    announce = require("handlers.announce"),
    heartbeat = require("handlers.heartbeat"),
    request_pickup = require("handlers.request_pickup"),
    request_resupply = require("handlers.request_resupply"),
    task_completed = require("handlers.task_completed")
}

local retry_later = {}

local function retry_failed_tasks()
    while true do
        sleep(60)
        for key, task in pairs(retry_later) do
            printer.print_info("Retrying task sent by " .. key)

            file.write_to_file(task, "temp")

            local ok, _
            if task.msg and handlers[task.protocol] then
                ok, _ = handlers[task.protocol](task.sender, task.msg)

                retry_later[key].status = "Retrying"
            elseif task.msg then
                printer.print_warning("ASDF Unhandled protocol: " .. tostring(task.protocol))
            end

            if ok then
                retry_later[key] = nil
            end
        end
    end
end

local function main()
    while true do
        display.render()

        local sender, msg, protocol = wireless.receive_any()

        local ok, err
        if msg and handlers[protocol] then
            ok, err = handlers[protocol](sender, msg)
        elseif msg then
            printer.print_warning("Unhandled protocol: " .. tostring(protocol))
        end

        if not ok and err then
            local key = sender .. "_" .. utils.epoch_in_seconds()
            retry_later[key] = { sender = sender, msg = msg, protocol = protocol, timestamp = utils.epoch_in_seconds() }
        end

        turtle_store.detect_stale()
    end
end

printer.print_success("Manager online.")

parallel.waitForAny(main, retry_failed_tasks)
