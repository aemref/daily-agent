import SwiftUI

@main
@MainActor
struct CodexPetApp: App {
    @StateObject private var store: TaskStore
    @StateObject private var panelController: FloatingPanelController

    init() {
        let store = TaskStore()
        _store = StateObject(wrappedValue: store)
        _panelController = StateObject(wrappedValue: FloatingPanelController(store: store))
    }

    var body: some Scene {
        MenuBarExtra {
            if store.hasActiveRoadmap {
                DashboardView(
                    store: store,
                    onShowFloating: {
                        panelController.show()
                    }
                )
            } else {
                RoadmapSetupView(store: store)
            }
        } label: {
            Label(
                "Codex Pet - \(store.completedCount)/\(store.tasks.count)",
                systemImage: store.isDayComplete ? "checkmark.circle.fill" : "sparkles"
            )
        }
        .menuBarExtraStyle(.window)
    }
}
