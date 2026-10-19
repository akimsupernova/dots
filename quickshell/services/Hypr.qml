pragma Singleton
import Quickshell

Singleton {
    function dispatch(expr) {
        Quickshell.execDetached(["hyprctl", "dispatch", expr])
    }
}
