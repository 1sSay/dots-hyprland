-- Personal workspace placement. Monitor names take priority over connection order.
local preferred = { "eDP-1", "HDMI-A-1" }
local state_dir = os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state")
local state_path = state_dir .. "/hyprland-workspace-layout"
local state_file = io.open(state_path, "r")
local inverted = false
if state_file then
    inverted = state_file:read("*l") == "inverted"
    state_file:close()
end

local function apply(toggle)
    local monitors = {}
    for _, monitor in ipairs(hl.get_monitors()) do
        if monitor.enabled and not monitor.is_mirror then
            monitors[#monitors + 1] = monitor
        end
    end
    local function priority(monitor)
        for i, name in ipairs(preferred) do
            if monitor.name == name then return i end
        end
        return #preferred + 1
    end
    table.sort(monitors, function(a, b)
        local pa, pb = priority(a), priority(b)
        if pa ~= pb then return pa < pb end
        return a.name < b.name
    end)
    if #monitors == 0 then return end

    if toggle then
        -- With one output there is no other monitor to swap with.
        if #monitors < 2 then return end
        local quoted_dir = "'" .. state_dir:gsub("'", "'\\''") .. "'"
        local file = io.open(state_path, "w")
        if not file then
            -- Hyprland may reap the child before os.execute can collect its status.
            -- Opening the file below verifies the directory was actually created.
            os.execute("mkdir -p -- " .. quoted_dir)
            file = assert(io.open(state_path, "w"))
        end
        assert(file:write(inverted and "normal\n" or "inverted\n"))
        file:close()
        inverted = not inverted
    end

    local first = monitors[1].name
    local second = monitors[2] and monitors[2].name or first
    if inverted then first, second = second, first end
    local targets = {}
    for id = 1, 10 do
        local target = (id >= 4 and id <= 6) and second or first
        targets[id] = target
        -- Replaces the previous rule for this workspace; hotplug adds no duplicates.
        hl.workspace_rule({
            workspace = tostring(id),
            monitor = target,
            persistent = true,
            default = id == 1 or (id == 4 and second ~= first),
        })
    end

    -- Rules place new workspaces; existing workspaces also need to be moved.
    for _, workspace in ipairs(hl.get_workspaces()) do
        local target = targets[workspace.id]
        if not workspace.special and target and workspace.monitor
            and workspace.monitor.name ~= target then
            hl.dispatch(hl.dsp.workspace.move({
                workspace = workspace.id,
                monitor = target,
            }))
        end
    end
end

-- Wait for output state and automatic workspace migration to settle after hotplug.
local pending
local function schedule()
    if pending then pending:set_enabled(false) end
    pending = hl.timer(function()
        pending = nil
        apply()
    end, { timeout = 200, type = "oneshot" })
end

hl.on("hyprland.start", schedule)
hl.on("config.reloaded", schedule)
hl.on("monitor.layout_changed", schedule)
hl.on("monitor.added", schedule)
hl.on("monitor.removed", schedule)
hl.on("config.unload", function()
    if pending then pending:set_enabled(false) end
end)
schedule()

return { toggle = function() apply(true) end }
