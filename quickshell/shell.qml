import Quickshell
import qs.modules.bar
import qs.modules.cheatsheet
import qs.modules.launcher
import qs.modules.monitors
import qs.modules.osd
import qs.modules.wallpaper
import qs.modules.clock
import qs.modules.polkit
import qs.modules.emoji
import qs.modules.power

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    WallpaperPicker {}
    Monitors {}
    Cheatsheet {}
    VolumeOsd {}
    Launcher {}
    ClockWidget {}
    Polkit {}
    EmojiPicker {}
    PowerMenu {}
}
