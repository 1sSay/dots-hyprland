-- Personal workspace placement. Monitor names take priority over connection order.
local preferred = { "eDP-1", "HDMI-A-1" }

local function apply()
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

    local first = monitors[1].name
    local second = monitors[2] and monitors[2].name or first
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
