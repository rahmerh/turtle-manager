local InfoBlock = require("display.elements.info_block")

local list = require("lib.list")

local runners_page = {}
runners_page.__index = runners_page

function runners_page:new(monitor, layout)
    return setmetatable({
        monitor = monitor,
        layout = layout
    }, self)
end

function runners_page:render(data)
    local quarries = list.filter_by(data, "role", "runner")

    local y_offset = 2
    local x_offset = self.layout.sidebar_width + 2
    for key, turtle in pairs(quarries) do
        local boundaries = {
            width = 20,
            height = 5
        }

        if not self.layout:does_element_fit_vertically(y_offset, boundaries.height) then
            x_offset = x_offset + boundaries.width + 1
            y_offset = 2
        end

        if not self.layout:does_element_fit_horizontally(x_offset, boundaries.width) then
            -- TODO: Add pager
            return
        end

        boundaries.x = x_offset
        boundaries.y = y_offset

        local opts = {
            block_colour = colours.white,
            text_colour = colours.black
        }

        local lines = { key, turtle.role, turtle.metadata.status }
        local block = InfoBlock:new(self.monitor, boundaries, opts, lines, self.layout)

        block:render()

        y_offset = y_offset + boundaries.height + 2
    end
end

return runners_page
