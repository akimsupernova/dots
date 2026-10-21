local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})

-- Layer namespaces come from WlrLayershell.namespace in the Quickshell config

hl.layer_rule({
    name  = "namecard",
    match = { namespace = "^Glassveil Shell Namecard$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 85%",
})

hl.layer_rule({
    name  = "shell-glass",
    match = { namespace = "^Glassveil Shell (Wallpaper|Monitor Settings|Emoji|OSD|OSD Brightness|Welcome)$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 85%",
})

hl.layer_rule({
    name  = "shell-glass-fullscreen",
    match = { namespace = "^Glassveil Shell (Cheatsheet|Launcher|Power|Polkit)$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "fade",
})

hl.layer_rule({
    name  = "glassveil-sidebar",
    match = { namespace = "^Glassveil Shell (Sidebar|Notifications)$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "slide right",
})
