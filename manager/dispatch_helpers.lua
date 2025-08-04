local dispatcher = {}

function dispatcher.find_least_queued(turtles, requester)
    local result_id, result

    for id, turtle in pairs(turtles) do
        if id == requester then
            goto skip
        end

        if turtle.metadata.status == "Offline" or turtle.metadata.status == "Stale" then
            goto skip
        end

        local amount_of_tasks = turtle.metadata.queued_tasks or 0
        local candidate_tasks = result and result.metadata.queued_tasks or math.huge

        if amount_of_tasks <= candidate_tasks then
            result = turtle
            result_id = id
        end

        ::skip::
    end

    return result_id
end

return dispatcher
