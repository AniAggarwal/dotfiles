-- Lua translation of hyprland.conf for Hyprland 0.55+.

local scripts_path = "~/.config/hypr/scripts"
local rofi_path = "~/.config/rofi/rofi-config.rasi"
local file_manager = "kitty -e yazi"
local main_mod = "SUPER"

local function bind(keys, dispatcher, opts)
    hl.bind(keys, dispatcher, opts)
end

local function bind_exec(keys, cmd, opts)
    bind(keys, hl.dsp.exec_cmd(cmd), opts)
end

local function dispatch_many(...)
    local dispatchers = { ... }

    return function()
        for _, dispatcher in ipairs(dispatchers) do
            hl.dispatch(dispatcher)
        end
    end
end

local function grad(colors, angle)
    return { colors = colors, angle = angle }
end

-----------------
-- Autostart
-----------------

hl.on("hyprland.start", function()
    local startup = {
        "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP",
        "systemctl --user start hyprpolkitagent",
        "systemctl --user start waybar.service",
        "hyprpaper",
        "systemctl --user start hypridle.service",
        "wl-paste --watch cliphist store",
        "dunst -config ~/.config/dunst/dunstrc",
        'gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"',
        scripts_path .. "/hpr-scratcher.py",
        "keepassxc",
        "fcitx5 -d",
        "/usr/lib/deja-dup/deja-dup-monitor",
        "pypr &> /tmp/pypr.log",
        scripts_path .. "/battery-notifications.sh",
    }

    for _, cmd in ipairs(startup) do
        hl.exec_cmd(cmd)
    end
end)

-----------------
-- Monitors
-----------------

hl.monitor({
    output = "eDP-1",
    mode = "3456x2160@60",
    position = "0x0",
    scale = "1.5",
    bitdepth = 10,
    cm = "srgb",
    sdr_eotf = "srgb",
    supports_wide_color = 1,
    supports_hdr = 1,
})

hl.monitor({
    output = "desc:LG Electronics LG HDR 4K 0x0002C181",
    mode = "3840x2160@60",
    scale = "1",
    position = "-3640x-2160",
})

hl.monitor({
    output = "desc:LG Electronics LG ULTRAWIDE 406NTPC9A176",
    mode = "3440x1440@60",
    scale = "1",
    position = "-3440x0",
})

hl.monitor({
    output = "desc:Dell Inc. DELL S2722QC 4GQKLD3",
    mode = "3840x2160@60",
    position = "-768x-2160",
    scale = "1",
})

hl.monitor({
    output = "desc: Guangxi Century Innovation Display Electronics Co. Ltd 40C1U 0000000000000",
    mode = "5120x2160@100",
    scale = "1",
    position = "auto-center-up",
    bitdepth = 10,
    cm = "srgb",
    sdr_eotf = "srgb",
    supports_wide_color = 0,
    supports_hdr = -1,
})

hl.monitor({
    output = "desc: Samsung Electric Company SAMSUNG 0x01000E00",
    mode = "3840x2160@30.00Hz",
    scale = "1",
    position = "auto-center-up",
})

hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "1",
})

hl.workspace_rule({
    workspace = "special:exposed",
    gaps_out = 60,
    gaps_in = 30,
    border_size = 3,
    no_shadow = true,
})

-----------------
-- Core config
-----------------

hl.config({
    render = {
        cm_enabled = true,
        cm_auto_hdr = 1,
    },

    xwayland = {
        force_zero_scaling = true,
    },

    input = {
        kb_layout = "us,jp",
        numlock_by_default = true,
        repeat_rate = 50,
        sensitivity = 0,
        follow_mouse = 2,
        float_switch_override_focus = 0,
        touchpad = {
            natural_scroll = true,
        },
    },

    general = {
        gaps_in = 2,
        gaps_out = 3,
        border_size = 2,
        col = {
            active_border = grad({ "rgba(ffffffaa)", "rgba(5c5c5c99)" }, 45),
            inactive_border = "rgba(595959aa)",
        },
        resize_on_border = true,
        extend_border_grab_area = 30,
        layout = "dwindle",
    },

    group = {
        groupbar = {
            render_titles = false,
            gradients = false,
            height = 0,
            indicator_gap = 0,
            indicator_height = 4,
            rounding = 10,
            rounding_power = 2.5,
            col = {
                inactive = grad({ "rgba(ffffff29)", "rgba(5c5c5c99)" }, 90),
                active = grad({ "rgba(ffffffaa)", "rgba(5c5c5c99)" }, 45),
                locked_inactive = grad({ "rgba(a3948199)", "rgba(5c5c5c00)" }, 90),
                locked_active = grad({ "rgba(f0e0ccb9)", "rgba(ffffff00)" }, 90),
            },
        },
        col = {
            border_active = grad({ "rgba(ffffffaa)", "rgba(5c5c5c99)" }, 45),
            border_inactive = "rgba(595959aa)",
            border_locked_active = grad({ "rgba(f0e0ccb9)", "rgba(5c5c5c99)" }, 90),
            border_locked_inactive = grad({ "rgba(a3948199)", "rgba(a3948199)" }, 90),
        },
    },

    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        swallow_regex = "^(kitty)$",
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },

    decoration = {
        rounding = 6,
        shadow = {
            enabled = false,
        },
        blur = {
            enabled = false,
            size = 10,
            passes = 5,
            new_optimizations = true,
            xray = false,
            ignore_opacity = true,
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = true,
        smart_split = false,
        smart_resizing = true,
    },

    binds = {
        focus_preferred_method = 0,
        movefocus_cycles_fullscreen = 0,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace",
})

-----------------
-- Animations
-----------------

hl.curve("overshot", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1.02 } } })
hl.curve("swipe", { type = "bezier", points = { { 0.05, 0.9 }, { 0.1, 1 } } })

hl.animation({ leaf = "fadeSwitch", enabled = true, speed = 3, bezier = "default" })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1, bezier = "overshot" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 1, bezier = "overshot" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 2, bezier = "overshot" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 2, bezier = "swipe", style = "slide" })

-----------------
-- Window rules
-----------------

hl.window_rule({
    name = "windscribe-float",
    match = { class = "^(Windscribe)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "brave-messages-fullscreen",
    match = {
        class = "^(brave-(.*)-Default)$",
        title = "^(.*)(Messages)(.*)$",
    },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "brave-discord-fullscreen",
    match = {
        class = "^(brave-(.*)-Default)$",
        title = "^(.*)(Discord)(.*)$",
    },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "linear-fullscreen-work",
    match = { class = "^(brave-bgdbmehlmdmddlgneophbcddadgknlpm-Profile_4)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "linear-fullscreen-personal",
    match = { class = "^(brave-bgdbmehlmdmddlgneophbcddadgknlpm-Default)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "notion-fullscreen",
    match = { class = "^(brave-cnmnfnkedfekfidgojcdmndbcipagogc-Profile_4)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "claude-fullscreen",
    match = { class = "^(brave-fmpnliohjhemenmnlpbfagaolkdacoja-Profile_4)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "gemini-fullscreen-default",
    match = { class = "^(brave-gdfaincndogidkdcdkhapmbffkckdkhn-Default)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "gemini-fullscreen-work",
    match = { class = "^(brave-gdfaincndogidkdcdkhapmbffkckdkhn-Profile_4)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "chatgpt-fullscreen",
    match = { class = "^(brave-cadlkienfkclaiaibeoongdcgmdikeeg-Default)$" },
    fullscreen_state = "-1 2",
})

hl.window_rule({
    name = "kitty-dropterm",
    match = { class = "^(kitty-dropterm)$" },
    float = true,
    center = true,
})

hl.window_rule({
    name = "termfilechooser",
    match = { title = "^(termfilechooser)$" },
    float = true,
    center = true,
    size = "1600 1000",
})

-----------------
-- Environment
-----------------

hl.env("AQ_DRM_DEVICES", "/dev/dri/intel-igpu")
hl.env("VK_DRIVER_FILES", "/usr/share/vulkan/icd.d/intel_icd.json")
hl.env("__EGL_VENDOR_LIBRARY_FILENAMES", "/usr/share/glvnd/egl_vendor.d/50_mesa.json")
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("GTK_THEME", "Graphite-Dark")
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("XMODIFIERS", "@im=fcitx")
hl.env("QT_IM_MODULES", "wayland;fcitx;ibus")

-----------------
-- Binds
-----------------

bind_exec("XF86MonBrightnessUp", "brightnessctl set 10%+", { repeating = true })
bind_exec("SHIFT + XF86MonBrightnessUp", "brightnessctl set 1%+", { repeating = true })
bind_exec("XF86MonBrightnessDown", "brightnessctl set 10%-", { repeating = true })
bind_exec("SHIFT + XF86MonBrightnessDown", "brightnessctl set 1%-", { repeating = true })

bind_exec("XF86AudioRaiseVolume", scripts_path .. "/adjust-volume.sh sink 5%+", { repeating = true })
bind_exec("XF86AudioLowerVolume", scripts_path .. "/adjust-volume.sh sink 5%-", { repeating = true })
bind_exec("SHIFT + XF86AudioRaiseVolume", scripts_path .. "/adjust-volume.sh sink 1%+", { repeating = true })
bind_exec("SHIFT + XF86AudioLowerVolume", scripts_path .. "/adjust-volume.sh sink 1%-", { repeating = true })
bind_exec("XF86AudioMute", scripts_path .. "/mute-volume.sh sink toggle", { repeating = true })

bind_exec("ALT + XF86AudioRaiseVolume", scripts_path .. "/adjust-volume.sh source 5%+", { repeating = true })
bind_exec("ALT + XF86AudioLowerVolume", scripts_path .. "/adjust-volume.sh source 5%-", { repeating = true })
bind_exec("ALT + XF86AudioMute", scripts_path .. "/mute-volume.sh source toggle", { repeating = true })

bind_exec(main_mod .. " + S", "hyprlock &")
bind_exec(main_mod .. " + SHIFT + S", "systemctl suspend-then-hibernate")
bind_exec(main_mod .. " + CTRL + SHIFT + S", "systemctl hibernate")

bind_exec(main_mod .. " + Print", "hyprshot -z -m region -o ~/Downloads/")
bind_exec(main_mod .. " + SHIFT + Print", "hyprshot -z -m region --clipboard-only")
bind_exec(main_mod .. " + CTRL + Print", "hyprshot -z -m output -o ~/Downloads/")
bind_exec(main_mod .. " + CTRL + SHIFT + Print", "hyprshot -z -m output --clipboard-only")

bind_exec("switch:off:Lid Switch", "systemctl hibernate", { locked = true })

bind_exec("XF86AudioPlay", "playerctl play-pause", { locked = true })
bind_exec("XF86AudioNext", "playerctl next", { locked = true })
bind_exec("XF86AudioPrev", "playerctl previous", { locked = true })

bind(main_mod .. " + M", hl.dsp.workspace.toggle_special("stash"))

bind(main_mod .. " + CTRL + SHIFT + M", hl.dsp.exit())
bind_exec(main_mod .. " + SHIFT + M", "pypr toggle_special stash")
bind(main_mod .. " + CTRL + SHIFT + R", hl.dsp.force_renderer_reload())

bind(main_mod .. " + C", hl.dsp.window.close())
bind(main_mod .. " + V", hl.dsp.window.float({ action = "toggle" }))
bind(main_mod .. " + SHIFT + V", hl.dsp.window.pseudo())
bind_exec(main_mod .. " + R", "wofi --show drun")
bind(main_mod .. " + W", hl.dsp.layout("togglesplit"))

bind_exec(main_mod .. " + Q", "kitty")
bind_exec(main_mod .. " + SHIFT + Q", "pypr toggle term")
bind_exec(main_mod .. " + O", "rofi -show drun -theme " .. rofi_path)
bind_exec(main_mod .. " + SHIFT + O", "pypr menu")
bind_exec(main_mod .. " + E", file_manager)

bind_exec(main_mod .. " + B", "brave")
bind_exec(main_mod .. " + SHIFT + B", "brave --incognito")

bind_exec("CTRL + ALT + V", "~/bin/clipselect")
bind_exec("CTRL + ALT + N", "python3 ~/.config/hypr/scripts/dunst-to-rofi-history.py")

bind(main_mod .. " + U", hl.dsp.window.pin())

bind(main_mod .. " + N", hl.dsp.focus({ workspace = "r+1" }))
bind(main_mod .. " + P", hl.dsp.focus({ workspace = "r-1" }))
bind(main_mod .. " + SHIFT + N", hl.dsp.window.move({ workspace = "r+1" }))
bind(main_mod .. " + SHIFT + P", hl.dsp.window.move({ workspace = "r-1" }))

bind(main_mod .. " + F", hl.dsp.window.fullscreen({ mode = "maximized" }))
bind(main_mod .. " + SHIFT + F", hl.dsp.window.fullscreen({ mode = "fullscreen" }))
-- Toggle fake (client-only) fullscreen. The Lua API's action="toggle" is a no-op
-- in 0.55.1 (it just sets, never flips), so we read the state and dispatch the opposite.
-- Once the upstream toggle fix ships in a release, replace this with the one-liner below:
--   bind(main_mod .. " + CTRL + SHIFT + F", hl.dsp.window.fullscreen_state({ internal = -1, client = 2, action = "toggle" }))
-- Fix: https://github.com/hyprwm/Hyprland/commit/c7b72790bd63172f04ee86784d4cb2a400532927 (#7288)
bind_exec(main_mod .. " + CTRL + SHIFT + F", [[bash -c 'if [ "$(hyprctl activewindow -j | jq -r .fullscreenClient)" = "2" ]; then hyprctl dispatch "hl.dsp.window.fullscreen_state({internal=-1, client=0})"; else hyprctl dispatch "hl.dsp.window.fullscreen_state({internal=-1, client=2})"; fi']])

bind(main_mod .. " + H", dispatch_many(
    hl.dsp.focus({ direction = "l" }),
    hl.dsp.window.alter_zorder({ mode = "top" })
))
bind(main_mod .. " + L", dispatch_many(
    hl.dsp.focus({ direction = "r" }),
    hl.dsp.window.alter_zorder({ mode = "top" })
))
bind(main_mod .. " + K", dispatch_many(
    hl.dsp.focus({ direction = "u" }),
    hl.dsp.window.alter_zorder({ mode = "top" })
))
bind(main_mod .. " + J", dispatch_many(
    hl.dsp.focus({ direction = "d" }),
    hl.dsp.window.alter_zorder({ mode = "top" })
))

bind(main_mod .. " + SHIFT + H", hl.dsp.window.move({ direction = "l" }))
bind(main_mod .. " + SHIFT + L", hl.dsp.window.move({ direction = "r" }))
bind(main_mod .. " + SHIFT + K", hl.dsp.window.move({ monitor = "u" }))
bind(main_mod .. " + SHIFT + J", hl.dsp.window.move({ monitor = "d" }))

bind(main_mod .. " + ALT + H", hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
bind(main_mod .. " + ALT + L", hl.dsp.window.resize({ x = 10, y = 0, relative = true }), { repeating = true })
bind(main_mod .. " + ALT + K", hl.dsp.window.resize({ x = 0, y = -10, relative = true }), { repeating = true })
bind(main_mod .. " + ALT + J", hl.dsp.window.resize({ x = 0, y = 10, relative = true }), { repeating = true })

bind(main_mod .. " + grave", hl.dsp.window.cycle_next())
bind(main_mod .. " + SHIFT + grave", hl.dsp.window.cycle_next({ next = false }))
bind(main_mod .. " + CTRL + grave", hl.dsp.window.cycle_next({ floating = true }))
bind(main_mod .. " + CTRL + SHIFT + grave", hl.dsp.window.cycle_next({ next = false, floating = true }))

bind(main_mod .. " + Tab", hl.dsp.group.next())
bind(main_mod .. " + SHIFT + Tab", hl.dsp.group.prev())

local function group_mode_action(dispatcher)
    return dispatch_many(dispatcher, hl.dsp.submap("reset"))
end

local function enter_group_mode()
    hl.dispatch(hl.dsp.submap("group-entry"))
    hl.timer(function()
        hl.dispatch(hl.dsp.submap("group"))
    end, { timeout = 10, type = "oneshot" })
end

bind(main_mod .. " + G", enter_group_mode)

hl.define_submap("group-entry", "reset", function()
    bind("escape", hl.dsp.submap("reset"))
end)

hl.define_submap("group", "reset", function()
    bind("G", group_mode_action(hl.dsp.group.toggle()))
    bind(main_mod .. " + G", group_mode_action(hl.dsp.group.toggle()))

    bind("O", group_mode_action(hl.dsp.window.move({ out_of_group = true })))
    bind(main_mod .. " + O", group_mode_action(hl.dsp.window.move({ out_of_group = true })))

    bind("B", group_mode_action(hl.dsp.group.lock_active({ action = "toggle" })))
    bind(main_mod .. " + B", group_mode_action(hl.dsp.group.lock_active({ action = "toggle" })))

    bind("H", group_mode_action(hl.dsp.window.move({ into_group = "l" })))
    bind(main_mod .. " + H", group_mode_action(hl.dsp.window.move({ into_group = "l" })))

    bind("J", group_mode_action(hl.dsp.window.move({ into_group = "d" })))
    bind(main_mod .. " + J", group_mode_action(hl.dsp.window.move({ into_group = "d" })))

    bind("K", group_mode_action(hl.dsp.window.move({ into_group = "u" })))
    bind(main_mod .. " + K", group_mode_action(hl.dsp.window.move({ into_group = "u" })))

    bind("L", group_mode_action(hl.dsp.window.move({ into_group = "r" })))
    bind(main_mod .. " + L", group_mode_action(hl.dsp.window.move({ into_group = "r" })))

    bind("escape", hl.dsp.submap("reset"))
end)

for i = 1, 10 do
    local key = tostring(i % 10)
    bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
    bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

bind(main_mod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
bind(main_mod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
