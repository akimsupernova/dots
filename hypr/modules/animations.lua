hl.config({
    animations = {
        enabled = true,
    },
})

hl.curve("smooth",   { type = "bezier", points = { {0.22, 1}, {0.36, 1} } })
hl.curve("easeInOut",{ type = "bezier", points = { {0.42, 0}, {0.58, 1} } })
hl.curve("easeOut",  { type = "bezier", points = { {0.16, 1}, {0.3, 1} } })
hl.curve("easeIn",   { type = "bezier", points = { {0.7, 0}, {0.84, 0} } })
hl.curve("linear",   { type = "bezier", points = { {0, 0}, {1, 1} } })

hl.animation({ leaf = "global", enabled = true, speed = 3, bezier = "smooth" })

hl.animation({ leaf = "windows",     enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "windowsIn",   enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "windowsOut",  enabled = true, speed = 3, bezier = "easeIn" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 3, bezier = "easeInOut" })

hl.animation({ leaf = "border", enabled = true, speed = 3, bezier = "smooth" })

hl.animation({ leaf = "fade",    enabled = true, speed = 3, bezier = "easeInOut" })
hl.animation({ leaf = "fadeIn",  enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 3, bezier = "easeIn" })

hl.animation({ leaf = "layers",        enabled = true, speed = 3, bezier = "smooth" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 3, bezier = "easeIn", style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 3, bezier = "easeOut" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 3, bezier = "easeIn" })

hl.animation({ leaf = "workspaces",       enabled = true, speed = 3, bezier = "easeInOut", style = "slide" })
hl.animation({ leaf = "workspacesIn",     enabled = true, speed = 3, bezier = "easeOut",   style = "slide" })
hl.animation({ leaf = "workspacesOut",    enabled = true, speed = 3, bezier = "easeIn",    style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3, bezier = "easeInOut", style = "slidevert" })

hl.animation({ leaf = "zoomFactor", enabled = true, speed = 3, bezier = "smooth" })
