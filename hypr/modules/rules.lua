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

hl.layer_rule({
    name  = "namecard",
    match = { namespace = "^akim-namecard(-picker)?$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 85%",
})

hl.layer_rule({
    name  = "shell-glass",
    match = { namespace = "^akim-(wallpaper-picker|monitor-settings|emoji-picker|osd|osd-brightness)$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "popin 85%",
})

hl.layer_rule({
    name  = "shell-glass-fullscreen",
    match = { namespace = "^akim-(cheatsheet|launcher|power|polkit)$" },

    blur         = true,
    ignore_alpha = 0.05,
    animation    = "fade",
})
