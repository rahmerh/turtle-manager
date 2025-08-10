local s = {
    state = "running"
}

function s.pause()
    s.state = "paused"
end

function s.resume()
    s.state = "running"
end

function s.handle_state()
    while s.state == "paused" do
        sleep(5)
    end
end

return s
