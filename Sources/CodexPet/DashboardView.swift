import SwiftUI

struct DashboardView: View {
    @ObservedObject var store: TaskStore
    @State private var showsResetConfirmation = false
    @State private var selectedTask: DailyTask?
    @State private var showsAddTask = false
    var isFloating = false
    var onShowFloating: (() -> Void)?
    var onProfileTap: (() -> Void)?
    var onCollapse: (() -> Void)?
    var onClose: (() -> Void)?

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header
                Divider().opacity(0.6)
                taskList
                Divider().opacity(0.6)
                footer
            }

            if let selectedTask {
                ModalBackdrop {
                    TaskDetailCard(task: selectedTask) {
                        self.selectedTask = nil
                    }
                }
            }

            if showsAddTask {
                ModalBackdrop {
                    AddTaskCard(
                        onCancel: { showsAddTask = false },
                        onSave: { title, detail, category in
                            store.addTask(title: title, detail: detail, category: category)
                            showsAddTask = false
                        }
                    )
                }
            }
        }
        .frame(width: 320, height: 480)
        .background(.regularMaterial)
        .onAppear { store.refreshIfNeeded() }
    }

    private var header: some View {
        HStack(spacing: 12) {
            if let onProfileTap {
                Button(action: onProfileTap) {
                    PetAvatar(progress: store.progress)
                }
                .buttonStyle(.plain)
                .help("Yalnızca asistanı göster")
            } else {
                PetAvatar(progress: store.progress)
            }

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
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text("Bugünün görevleri")
                        .font(.subheadline.bold())
                    Spacer()
                    Text("\(store.completedCount)/\(store.tasks.count)")
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.secondary)
                    Button {
                        showsAddTask = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.indigo)
                    .help("Yeni görev ekle")
                }

                ForEach(store.tasks) { task in
                    TaskRow(
                        task: task,
                        showsDate: false,
                        onChange: { completed in
                            store.setCompleted(completed, taskID: task.id)
                        },
                        onOpen: { selectedTask = task }
                    )
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

                if !store.overdueTasks.isEmpty {
                    Divider().padding(.vertical, 4)

                    HStack {
                        Label("Dünden kalanlar", systemImage: "clock.arrow.circlepath")
                            .font(.subheadline.bold())
                            .foregroundStyle(.orange)
                        Spacer()
                        Text("\(store.overdueTasks.count)")
                            .font(.caption.monospacedDigit().bold())
                            .foregroundStyle(.orange)
                    }

                    ForEach(store.overdueTasks) { task in
                        TaskRow(
                            task: task,
                            showsDate: true,
                            onChange: { completed in
                                if completed { store.completeOverdue(taskID: task.id) }
                            },
                            onOpen: { selectedTask = task }
                        )
                    }
                }

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
    let showsDate: Bool
    let onChange: (Bool) -> Void
    let onOpen: () -> Void

    var body: some View {
        ZStack {
            Button(action: onOpen) {
                Rectangle()
                    .fill(.clear)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)

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
                        if showsDate, let dateKey = task.scheduledDateKey {
                            Text("•")
                            Label(dateKey, systemImage: "calendar")
                        } else if task.estimatedMinutes > 0 {
                            Text("•")
                            Text("\(task.estimatedMinutes) dk")
                        }
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.caption2.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 5)
            }
            .frame(maxWidth: .infinity, minHeight: 42, alignment: .leading)
            .allowsHitTesting(false)

            HStack {
                Button {
                    onChange(!task.isCompleted)
                } label: {
                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        .font(.title3)
                        .foregroundStyle(task.isCompleted ? .green : .secondary)
                }
                .buttonStyle(.plain)
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding(10)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct ModalBackdrop<Content: View>: View {
    @ViewBuilder let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.28)
            content
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
                .padding(12)
        }
    }
}

private struct TaskDetailCard: View {
    let task: DailyTask
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: task.category.symbol)
                            .font(.title2)
                            .foregroundStyle(.indigo)
                            .frame(width: 42, height: 42)
                            .background(.indigo.opacity(0.1), in: RoundedRectangle(cornerRadius: 11))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.category.rawValue)
                                .font(.caption.bold())
                                .foregroundStyle(.indigo)
                            if let dateKey = task.scheduledDateKey {
                                Label(dateKey, systemImage: "calendar")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }

                    Text(task.title)
                        .font(.title3.bold())
                        .textSelection(.enabled)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Açıklama")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        Text(task.detail)
                            .font(.callout)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let checklist = task.checklist, !checklist.isEmpty {
                        checklistSection(checklist)
                    }

                    if let criteria = task.completionCriteria, !criteria.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Label("Bitti saymak için", systemImage: "checkmark.seal.fill")
                                .font(.subheadline.bold())
                                .foregroundStyle(.green)
                            Text(criteria)
                                .font(.callout)
                                .fixedSize(horizontal: false, vertical: true)
                                .textSelection(.enabled)
                        }
                        .padding(11)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.green.opacity(0.08), in: RoundedRectangle(cornerRadius: 11))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button("Kapat", action: onClose)
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(16)
        .frame(width: 296, height: 452)
    }

    private func checklistSection(_ checklist: [String]) -> some View {
        VStack(alignment: .leading, spacing: 9) {
            Label("Yapılacaklar", systemImage: "checklist")
                .font(.subheadline.bold())

            ForEach(Array(checklist.enumerated()), id: \.offset) { index, item in
                HStack(alignment: .top, spacing: 8) {
                    Text("\(index + 1)")
                        .font(.caption2.bold().monospacedDigit())
                        .foregroundStyle(.white)
                        .frame(width: 20, height: 20)
                        .background(.indigo, in: Circle())
                    Text(item)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                        .textSelection(.enabled)
                }
            }
        }
        .padding(11)
        .background(.indigo.opacity(0.07), in: RoundedRectangle(cornerRadius: 11))
    }
}

private struct AddTaskCard: View {
    let onCancel: () -> Void
    let onSave: (String, String, TaskCategory) -> Void

    @State private var title = ""
    @State private var detail = ""
    @State private var category: TaskCategory = .build

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Yeni görev")
                .font(.title3.bold())

            TextField("Görev başlığı", text: $title)
                .textFieldStyle(.roundedBorder)

            VStack(alignment: .leading, spacing: 6) {
                Text("Açıklama")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                TextEditor(text: $detail)
                    .frame(height: 105)
                    .padding(6)
                    .scrollContentBackground(.hidden)
                    .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 9))
            }

            VStack(alignment: .leading, spacing: 7) {
                Text("Kategori")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 7) {
                    ForEach(TaskCategory.allCases, id: \.self) { option in
                        let isSelected = category == option
                        Button {
                            category = option
                        } label: {
                            Label(option.rawValue, systemImage: option.symbol)
                                .font(.caption.bold())
                                .frame(maxWidth: .infinity, minHeight: 28)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(isSelected ? .white : .primary)
                        .background(
                            isSelected ? Color.indigo : Color.primary.opacity(0.07),
                            in: RoundedRectangle(cornerRadius: 8)
                        )
                    }
                }
            }

            HStack {
                Button("Vazgeç", action: onCancel)
                    .buttonStyle(.bordered)
                Spacer()
                Button("Görevi ekle") {
                    onSave(title, detail, category)
                }
                .buttonStyle(.borderedProminent)
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                )
            }
        }
        .padding(16)
        .frame(width: 296, height: 420)
    }
}
