import SwiftUI

struct PetAvatar: View {
    let progress: Double
    var size: CGFloat = 52

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var face: String {
        switch progress {
        case 1: "checkmark"
        case 0.66...: "sparkles"
        case 0.33...: "chevron.up"
        default: "ellipsis"
        }
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { timeline in
            let second = timeline.date.timeIntervalSinceReferenceDate
            let bounce = reduceMotion ? 0 : sin(second * 2.4) * size * 0.035
            let tilt = reduceMotion ? 0 : sin(second * 1.35) * 2.2
            let pulse = reduceMotion ? 1 : 1 + sin(second * 2.0) * 0.035
            let blinkPhase = second.truncatingRemainder(dividingBy: 4.2)
            let isBlinking = !reduceMotion && blinkPhase > 4.02

            ZStack {
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.45, green: 0.25, blue: 0.85), .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: (progress >= 1 ? Color.green : Color.indigo).opacity(0.28),
                        radius: 8 * pulse,
                        y: 4
                    )

                HStack(spacing: size * 0.12) {
                    eye(isBlinking: isBlinking)
                    eye(isBlinking: isBlinking)
                }
                .offset(y: -size * 0.08)

                Image(systemName: face)
                    .font(.system(size: size * 0.16, weight: .bold))
                    .foregroundStyle(.white.opacity(0.92))
                    .offset(y: size * 0.18)
                    .scaleEffect(pulse)
            }
            .offset(y: bounce)
            .rotationEffect(.degrees(tilt))
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Codex Pet")
    }

    private func eye(isBlinking: Bool) -> some View {
        Capsule()
            .fill(.white)
            .frame(
                width: size * 0.12,
                height: isBlinking ? max(2, size * 0.025) : size * 0.12
            )
    }
}

struct CompactPetView: View {
    @ObservedObject var store: TaskStore
    let onExpand: () -> Void

    var body: some View {
        PetAvatar(progress: store.progress, size: 64)
            .padding(6)
            .contentShape(RoundedRectangle(cornerRadius: 20))
            .overlay(ProfileDragSurface(onTap: onExpand))
            .help("Taşımak için sürükle, görevleri açmak için tıkla")
            .accessibilityAction(named: "Görevleri aç") {
                onExpand()
            }
    }
}

private struct ProfileDragSurface: NSViewRepresentable {
    let onTap: () -> Void

    func makeNSView(context: Context) -> ProfileDragView {
        let view = ProfileDragView()
        view.onTap = onTap
        return view
    }

    func updateNSView(_ nsView: ProfileDragView, context: Context) {
        nsView.onTap = onTap
    }
}

private final class ProfileDragView: NSView {
    var onTap: (() -> Void)?
    private var mouseDownLocation: NSPoint?
    private var windowOrigin: NSPoint?
    private var moved = false

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        mouseDownLocation = NSEvent.mouseLocation
        windowOrigin = window?.frame.origin
        moved = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard
            let window,
            let mouseDownLocation,
            let windowOrigin
        else { return }

        let current = NSEvent.mouseLocation
        let deltaX = current.x - mouseDownLocation.x
        let deltaY = current.y - mouseDownLocation.y
        moved = moved || hypot(deltaX, deltaY) >= 3

        var target = NSPoint(x: windowOrigin.x + deltaX, y: windowOrigin.y + deltaY)
        if let visible = window.screen?.visibleFrame ?? NSScreen.main?.visibleFrame {
            target.x = min(max(target.x, visible.minX), visible.maxX - window.frame.width)
            target.y = min(max(target.y, visible.minY), visible.maxY - window.frame.height)
        }
        window.setFrameOrigin(target)
    }

    override func mouseUp(with event: NSEvent) {
        if !moved {
            onTap?()
        }
        mouseDownLocation = nil
        windowOrigin = nil
        moved = false
    }
}
