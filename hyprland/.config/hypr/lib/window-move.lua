-- Directional window movement: rearrange within a monitor, or cross to the adjacent one.
--
-- We want the pre-0.54 behaviour: rearrange within the monitor when there's a window in the
-- way, otherwise cross to the adjacent monitor. Since the 0.54 layout refactor, the native
-- move({direction=…}) decides whether to cross by testing a "focal point" at the window's
-- centre; with a wide monitor stacked over a narrower, horizontally-offset one, an off-centre
-- window's focal point lands back on the source monitor, so it never crosses
-- (hyprwm/Hyprland#13420, #8605 — closed "not planned"). move({monitor=…}) instead routes
-- through getMonitorInDirection and is reliable, but it can't rearrange within a monitor.
--
-- So: use direction= normally, and only override to monitor= in the one case the native path
-- gets wrong — a tiled window with no neighbour that way on its own monitor, but a monitor
-- existing in that direction. Everything else (rearrange, floating, true edges) stays native.

local function box_center(w)
    return w.at.x + w.size.x / 2, w.at.y + w.size.y / 2
end

-- Is there a tiled, visible window in `dir` from `w`, on the same monitor as `w`?
local function window_in_direction(w, dir)
    local wmon = w.monitor
    if not wmon then return false end
    local wcx, wcy = box_center(w)
    for _, c in ipairs(hl.get_windows()) do
        local cmon = c.monitor
        if c.address ~= w.address and c.mapped and c.visible and not c.floating and cmon and cmon.id == wmon.id then
            local ccx, ccy = box_center(c)
            local h_overlap = c.at.x < w.at.x + w.size.x and c.at.x + c.size.x > w.at.x
            local v_overlap = c.at.y < w.at.y + w.size.y and c.at.y + c.size.y > w.at.y
            if dir == "l" and ccx < wcx and v_overlap then return true end
            if dir == "r" and ccx > wcx and v_overlap then return true end
            if dir == "u" and ccy < wcy and h_overlap then return true end
            if dir == "d" and ccy > wcy and h_overlap then return true end
        end
    end
    return false
end

-- Is there a monitor whose edge sticks to `w`'s monitor in `dir` (mirrors getMonitorInDirection)?
local function monitor_in_direction(w, dir)
    local cur = w.monitor
    if not cur then return false end
    -- monitor size is reported in pixels; divide by scale for logical layout extent.
    local cx, cy, cw, ch = cur.x, cur.y, cur.width / cur.scale, cur.height / cur.scale
    local TOL = 3
    for _, m in ipairs(hl.get_monitors()) do
        if m.id ~= cur.id then
            local mx, my, mw, mh = m.x, m.y, m.width / m.scale, m.height / m.scale
            local h_overlap = mx < cx + cw and mx + mw > cx
            local v_overlap = my < cy + ch and my + mh > cy
            if dir == "l" and math.abs(cx - (mx + mw)) < TOL and v_overlap then return true end
            if dir == "r" and math.abs((cx + cw) - mx) < TOL and v_overlap then return true end
            if dir == "u" and math.abs(cy - (my + mh)) < TOL and h_overlap then return true end
            if dir == "d" and math.abs((cy + ch) - my) < TOL and h_overlap then return true end
        end
    end
    return false
end

-- Returns a keybind callback that moves the active window one step in `dir` ("l"/"r"/"u"/"d").
local function move_window(dir)
    return function()
        local w = hl.get_active_window()
        if not w then return end
        if not w.floating and not window_in_direction(w, dir) and monitor_in_direction(w, dir) then
            hl.dispatch(hl.dsp.window.move({ monitor = dir }))
        else
            hl.dispatch(hl.dsp.window.move({ direction = dir }))
        end
    end
end

return move_window
