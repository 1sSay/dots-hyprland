-- Run: lua tests/workspaces.lua [path/to/custom/workspaces.lua]
local source = arg[1] or "dots/.config/hypr/custom/workspaces.lua"
-- Isolate persisted preference from the real desktop.
local state_dir = os.tmpname()
os.remove(state_dir)
local getenv = os.getenv
os.getenv = function(name)
    if name == "XDG_STATE_HOME" then return state_dir end
    return getenv(name)
end
local events, timers, rules, moves = {}, {}, {}, {}
local monitors, workspaces = {}, {}
hl = {
    get_monitors = function() return monitors end,
    get_workspaces = function() return workspaces end,
    workspace_rule = function(rule) rules[tonumber(rule.workspace)] = rule end,
    on = function(event, callback) events[event] = callback end,
    timer = function(callback)
        local timer = { enabled = true, callback = callback }
        function timer:set_enabled(enabled) self.enabled = enabled end
        timers[#timers + 1] = timer
        return timer
    end,
    dsp = { workspace = { move = function(spec) return spec end } },
    dispatch = function(spec) moves[#moves + 1] = spec end,
}
local function monitor(name, enabled, mirror)
    return { name = name, enabled = enabled ~= false, is_mirror = mirror or false }
end
local function flush()
    local queued = timers
    timers = {}
    for _, timer in ipairs(queued) do
        if timer.enabled then timer.callback() end
    end
end
local function expect(first, second)
    for id = 1, 10 do
        local target = (id >= 4 and id <= 6) and second or first
        assert(rules[id].monitor == target, "wrong placement for " .. id)
        assert(rules[id].persistent)
        assert(rules[id].default == (id == 1 or (id == 4 and first ~= second)))
    end
end
local module = dofile(source)
monitors = { monitor("HDMI-A-1"), monitor("eDP-1") }
workspaces = {
    { id = 4, monitor = monitors[2] },
    { id = 1, monitor = monitors[1] },
    { id = 11, monitor = monitors[1] },
    { id = -1, special = true, monitor = monitors[1] },
}
flush()
expect("eDP-1", "HDMI-A-1")
assert(#moves == 2 and moves[1].workspace == 4 and moves[2].workspace == 1)

-- Inversion changes all rules and moves every existing managed workspace.
workspaces, moves = {}, {}
for id = 1, 10 do
    workspaces[id] = { id = id, monitor = { name = rules[id].monitor } }
end
module.toggle()
expect("HDMI-A-1", "eDP-1")
assert(#moves == 10)

-- Reloading the module reads the saved preference.
events["config.unload"]()
module = dofile(source)
flush()
expect("HDMI-A-1", "eDP-1")
module.toggle()
expect("eDP-1", "HDMI-A-1")

-- A burst of hotplug events should produce one reconciliation.
monitors, workspaces, moves = { monitor("eDP-1") }, {}, {}
events["monitor.removed"]()
events["monitor.layout_changed"]()
local calls = 0
hl.get_monitors = function() calls = calls + 1; return monitors end
flush()
assert(calls == 1)
expect("eDP-1", "eDP-1")
module.toggle() -- No-op on a single output, including the saved preference.
monitors = { monitor("eDP-1"), monitor("HDMI-A-1") }
events["monitor.added"]()
flush()
expect("eDP-1", "HDMI-A-1")
module.toggle()
monitors = { monitor("eDP-1") }
events["monitor.removed"]()
flush()
expect("eDP-1", "eDP-1")
monitors = { monitor("eDP-1"), monitor("HDMI-A-1") }
events["monitor.added"]()
flush()
expect("HDMI-A-1", "eDP-1")
module.toggle()

monitors = { monitor("HDMI-A-1") }
events["config.reloaded"]()
flush()
expect("HDMI-A-1", "HDMI-A-1")

monitors = { monitor("DP-2"), monitor("DP-1"), monitor("eDP-1", false), monitor("HDMI-A-1", true, true) }
events["monitor.added"]()
flush()
expect("DP-1", "DP-2")

monitors = {}
events["monitor.removed"]()
flush()
events["hyprland.start"]()
events["config.unload"]()
calls = 0
flush()
assert(calls == 0)
os.getenv = getenv
os.remove(state_dir .. "/hyprland-workspace-layout")
assert(os.execute("rmdir '" .. state_dir .. "'"))
print("Workspace topology tests passed")
