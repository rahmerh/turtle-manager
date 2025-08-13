local Toggle = require("display.elements.toggle")

local settings_page = {}
settings_page.__index = settings_page

function settings_page.new(m, settings)
    local auto_pickup = Toggle.new(m,
        "Auto recover completed quarries?", {
            fg = colours.black,
            bg = m:get_default_bg_colour()
        },
        settings:read(settings.keys.auto_recover_quarries),
        function(value)
            settings:set(settings.keys.auto_recover_quarries, value)
        end)

    return setmetatable({
        m = m,
        auto_pickup = auto_pickup,
    }, settings_page)
end

function settings_page:handle_click(x, y)
    local click_handled = false

    click_handled = self.auto_pickup:handle_click(x, y)

    return click_handled
end

function settings_page:render(x, y)
    self.auto_pickup:render(x + 1, y + 1)
end

return settings_page
