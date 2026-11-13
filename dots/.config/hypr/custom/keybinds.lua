hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Invert the placement of all managed workspaces between the two monitors.
hl.bind("SUPER + SHIFT + F10", function()
    require("custom.workspaces").toggle()
end, { description = "Workspaces: Invert monitor assignments" })
