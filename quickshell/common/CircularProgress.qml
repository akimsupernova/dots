import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real size: 16
    property real lineWidth: 2
    property real value: 0
    property color colPrimary: Theme.accent1
    property color colTrack: Theme.surface
    property real gapAngle: 20

    implicitWidth: size
    implicitHeight: size

    readonly property real degree: Math.max(0, Math.min(1, isNaN(value) ? 0 : value)) * 360
    readonly property real arcRadius: size / 2 - lineWidth

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.colTrack
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: -90 - root.gapAngle
                sweepAngle: -Math.max(0, 360 - root.degree - 2 * root.gapAngle)
            }
        }
        ShapePath {
            strokeColor: root.degree > 1 ? root.colPrimary : "transparent"
            strokeWidth: root.lineWidth
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.arcRadius
                radiusY: root.arcRadius
                startAngle: -90
                sweepAngle: root.degree
            }
        }
    }
}
