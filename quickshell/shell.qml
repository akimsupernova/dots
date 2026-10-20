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
import qs.modules.namecard
import qs.modules.welcome
import qs.modules.sidebar
import qs.modules.notifications
import qs.modules.lock

ShellRoot {
    Variants {
        model: Quickshell.screens
        Bar {}
    }

    WallpaperPicker {}
    Monitors {}
    Cheatsheet {}
    VolumeOsd {}
    BrightnessOsd {}
    Launcher {}
    ClockWidget {}
    Polkit {}
    EmojiPicker {}
    PowerMenu {}
    NameCard {}
    Welcome {}
    Sidebar {}
    NotificationPopups {}
    Lock {}
}

