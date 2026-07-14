-- "Group mode": SUPER+G enters a submap for managing window groups (toggle, lock, and move
-- windows into/out of groups with hjkl). Each action runs, then resets back to the default submap.

local helpers = require("lib.helpers")
local bind, dispatch_many = helpers.bind, helpers.dispatch_many

local M = {}

-- Run a dispatcher, then leave the submap.
local function group_mode_action(dispatcher)
    return dispatch_many(dispatcher, hl.dsp.submap("reset"))
end

-- Enter via a throwaway "group-entry" submap, then promote to the real "group" submap a tick
-- later. The intermediate step lets the SUPER+G keypress fully release before the group binds
-- (which also use SUPER+<key>) become active, so it doesn't immediately fire one of them.
local function enter_group_mode()
    hl.dispatch(hl.dsp.submap("group-entry"))
    hl.timer(function()
        hl.dispatch(hl.dsp.submap("group"))
    end, { timeout = 10, type = "oneshot" })
end

-- Wire up the entry keybind and the submaps. `mod` is the main modifier (e.g. "SUPER").
function M.setup(mod)
    bind(mod .. " + G", enter_group_mode)

    hl.define_submap("group-entry", "reset", function()
        bind("escape", hl.dsp.submap("reset"))
    end)

    hl.define_submap("group", "reset", function()
        bind("G", group_mode_action(hl.dsp.group.toggle()))
        bind(mod .. " + G", group_mode_action(hl.dsp.group.toggle()))

        bind("O", group_mode_action(hl.dsp.window.move({ out_of_group = true })))
        bind(mod .. " + O", group_mode_action(hl.dsp.window.move({ out_of_group = true })))

        bind("B", group_mode_action(hl.dsp.group.lock_active({ action = "toggle" })))
        bind(mod .. " + B", group_mode_action(hl.dsp.group.lock_active({ action = "toggle" })))

        bind("H", group_mode_action(hl.dsp.window.move({ into_group = "l" })))
        bind(mod .. " + H", group_mode_action(hl.dsp.window.move({ into_group = "l" })))

        bind("J", group_mode_action(hl.dsp.window.move({ into_group = "d" })))
        bind(mod .. " + J", group_mode_action(hl.dsp.window.move({ into_group = "d" })))

        bind("K", group_mode_action(hl.dsp.window.move({ into_group = "u" })))
        bind(mod .. " + K", group_mode_action(hl.dsp.window.move({ into_group = "u" })))

        bind("L", group_mode_action(hl.dsp.window.move({ into_group = "r" })))
        bind(mod .. " + L", group_mode_action(hl.dsp.window.move({ into_group = "r" })))

        bind("escape", hl.dsp.submap("reset"))
    end)
end

return M
