import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: TaskStore
    @State private var showsResetConfirmation = false
    var isFloating = false
    var onShowFloating: (() -> Void)?
    var onCollapse: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().opacity(0.6)
            taskList
            Divider().opacity(0.6)
            footer
        }
        .frame(width: 320, height: 480)
        .background(.regularMaterial)
        .onAppear { store.refreshIfNeeded() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            PetAvatar(progress: store.progress)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Codex Pet")
                        .font(.headline)
                    Text(store.plan.milestone)
                        .font(.caption2.bold())
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.indigo.opacity(0.12), in: Capsule())
                        .foregroundStyle(.indigo)
                }
                Text("Gün \(store.plan.dayNumber)/\(store.plan.totalDays) • \(store.plan.focus)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                ProgressView(value: store.progress)
                    .tint(store.isDayComplete ? .green : .indigo)
                    .frame(width: 192)
            }

            Spacer(minLength: 0)

            if isFloating {
                VStack(spacing: 4) {
                    Button(action: { onCollapse?() }) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                    }
                    Button(action: { onClose?() }) {
                        Image(systemName: "xmark")
                    }
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.secondary)
            }
        }
        .padding(14)
    }

    private var taskList: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Bugünün görevleri")
                    .font(.subheadline.bold())
                Spacer()
                Text("\(store.completedCount)/\(store.tasks.count)")
                    .font(.caption.monospacedDigit().bold())
                    .foregroundStyle(.secondary)
            }

            ForEach(store.tasks) { task in
                TaskRow(task: task) { completed in
                    store.setCompleted(completed, taskID: task.id)
                }
            }

            if store.tasks.isEmpty {
                Label(
                    "Bugün seçtiğin çalışma günlerinden biri değil.",
                    systemImage: "cup.and.saucer.fill"
                )
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
            }

            Spacer(minLength: 0)

            if store.isDayComplete {
                Label("Bugün tamamlandı. Streak korunuyor!", systemImage: "flame.fill")
                    .font(.caption.bold())
                    .foregroundStyle(.green)
                    .padding(9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
    }

    private var footer: some View {
        HStack(spacing: 10) {
            Label("\(store.currentStreak) gün", systemImage: "flame.fill")
                .font(.caption.bold())
                .foregroundStyle(.orange)

            Spacer()

            if !isFloating {
                Button {
                    onShowFloating?()
                } label: {
                    Label("Kenara sabitle", systemImage: "pin.fill")
                }
                .buttonStyle(.borderless)
            }

            Button("Yeni plan") {
                showsResetConfirmation = true
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)

            Button("Çık") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .confirmationDialog(
            "Mevcut roadmap değiştirilsin mi?",
            isPresented: $showsResetConfirmation
        ) {
            Button("Yeni roadmap oluştur", role: .destructive) {
                store.resetRoadmap()
                onClose?()
            }
            Button("Vazgeç", role: .cancel) {}
        } message: {
            Text("Mevcut roadmap kaldırılır; geçmiş streak kayıtları korunur.")
        }
    }
}

private struct TaskRow: View {
    let task: DailyTask
    let onChange: (Bool) -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Button {
                onChange(!task.isCompleted)
            } label: {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Image(systemName: task.category.symbol)
                .frame(width: 18)
                .foregroundStyle(.indigo)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 5) {
                    Text(task.category.rawValue)
                    if task.estimatedMinutes > 0 {
                        Text("•")
                        Text("\(task.estimatedMinutes) dk")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(10)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
    }
}
