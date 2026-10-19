import QtQuick

Item {
    id: page

    property bool active: false
    property int index: 0
    property int current: 0
    property real t: 0
    property real slide: 34

    function st(i) {
        const v = Math.max(0, Math.min(1, (t - i * 0.09) / 0.5))
        return 1 - Math.pow(1 - v, 3)
    }
    function replay(delay) {
        t = 0
        anim.stop()
        pause.duration = delay ?? 0
        anim.restart()
    }

    visible: opacity > 0.01
    opacity: active ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

    x: active ? 0 : (index < current ? -slide : slide)
    Behavior on x { NumberAnimation { duration: 430; easing.type: Easing.OutCubic } }

    onActiveChanged: if (active) replay(60)

    SequentialAnimation {
        id: anim
        PauseAnimation { id: pause; duration: 0 }
        NumberAnimation { target: page; property: "t"; from: 0; to: 1; duration: 950 }
    }
}
