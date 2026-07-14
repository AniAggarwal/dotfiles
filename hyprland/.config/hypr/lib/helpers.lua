-- Small, generic helpers shared across the Hyprland config (hyprland.lua + lib/ modules).

local M = {}

-- Register a keybind. Thin wrapper over hl.bind so call sites read `bind(keys, dsp, opts)`.
function M.bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts)
end

-- Register a keybind that runs a shell command.
function M.bind_exec(keys, cmd, opts)
    M.bind(keys, hl.dsp.exec_cmd(cmd), opts)
end

-- Combine several dispatchers into one callable that runs them in order.
function M.dispatch_many(...)
    local dispatchers = { ... }

    return function()
        for _, dispatcher in ipairs(dispatchers) do
            hl.dispatch(dispatcher)
        end
    end
end

-- Build a gradient value ({ colors = {...}, angle = N }) for color options.
function M.grad(colors, angle)
    return { colors = colors, angle = angle }
end

return M
