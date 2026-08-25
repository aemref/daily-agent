import AppKit
import SwiftUI

@MainActor
final class FloatingPanelController: ObservableObject {
    private let store: TaskStore
    private var panel: NSPanel?

    init(store: TaskStore) {
        self.store = store
    }

    func show() {
        if panel == nil {
            createPanel()
        }
        positionAtRightEdge()
        panel?.orderFront(nil)
    }

    func close() {
        panel?.orderOut(nil)
    }

    private func createPanel() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 480),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isFloatingPanel = false
        panel.level = .normal
        panel.collectionBehavior = [.canJoinAllSpaces]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.hasShadow = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.becomesKeyOnlyIfNeeded = true

        self.panel = panel
        showExpandedContent()
    }

    private func showExpandedContent() {
        guard let panel else { return }
        let view = DashboardView(
            store: store,
            isFloating: true,
            onProfileTap: { [weak self] in self?.collapse() },
            onCollapse: { [weak self] in self?.collapse() },
            onClose: { [weak self] in self?.close() }
        )
        panel.isMovableByWindowBackground = true
        panel.contentView = NSHostingView(rootView: view.clipShape(RoundedRectangle(cornerRadius: 18)))
        resize(width: 320, height: 480)
    }

    private func collapse() {
        guard let panel else { return }
        let view = CompactPetView(
            store: store,
            onExpand: { [weak self] in self?.showExpandedContent() }
        )
        panel.isMovableByWindowBackground = false
        panel.contentView = NSHostingView(rootView: view)
        resize(width: 76, height: 76)
    }

    private func resize(width: CGFloat, height: CGFloat) {
        guard let panel else { return }
        let maxX = panel.frame.maxX
        let maxY = panel.frame.maxY
        panel.setFrame(
            NSRect(x: maxX - width, y: maxY - height, width: width, height: height),
            display: true,
            animate: true
        )
    }

    private func positionAtRightEdge() {
        guard let panel, let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        panel.setFrameOrigin(
            NSPoint(
                x: visible.maxX - panel.frame.width - 14,
                y: visible.midY - panel.frame.height / 2
            )
        )
    }
}
