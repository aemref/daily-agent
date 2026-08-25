import AppKit
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class RoadmapSetupViewModel: ObservableObject {
    enum SourceMode: String, CaseIterable, Identifiable {
        case paste = "Metin"
        case pdf = "PDF"

        var id: String { rawValue }
    }

    @Published var sourceMode: SourceMode = .paste
    @Published var sourceText = ""
    @Published var selectedPDFName: String?
    @Published var preferences = SchedulePreferences()
    @Published var generatedRoadmap: GeneratedRoadmap?
    @Published var isGenerating = false
    @Published var errorMessage: String?
    @Published var environmentStatus: String?

    init() {
        refreshEnvironmentStatus()
    }

    func refreshEnvironmentStatus() {
        do {
            let environment = try EnvironmentLoader.load()
            environmentStatus = "Hazır • \(environment.model) • \(environment.sourceDescription)"
            errorMessage = nil
        } catch {
            environmentStatus = nil
            errorMessage = error.localizedDescription
        }
    }

    func choosePDF() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.message = "Roadmap veya hedef dokümanını seç"

        guard panel.runModal() == .OK, let url = panel.url else { return }

        do {
            sourceText = try DocumentImporter.extractText(from: url)
            selectedPDFName = url.lastPathComponent
            sourceMode = .pdf
            generatedRoadmap = nil
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func generate() async {
        isGenerating = true
        errorMessage = nil
        generatedRoadmap = nil
        defer { isGenerating = false }

        do {
            let cleanedText = try DocumentImporter.validatePastedText(sourceText)
            let environment = try EnvironmentLoader.load()
            let client = OpenAIPlanningClient(environment: environment)
            generatedRoadmap = try await client.generateRoadmap(
                sourceText: cleanedText,
                preferences: preferences
            )
            environmentStatus = "Hazır • \(environment.model)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct RoadmapSetupView: View {
    @ObservedObject var store: TaskStore
    @StateObject private var model = RoadmapSetupViewModel()

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if let roadmap = model.generatedRoadmap {
                preview(roadmap)
            } else {
                setupForm
            }
        }
        .frame(width: 430, height: 620)
        .background(.regularMaterial)
    }

    private var header: some View {
        HStack(spacing: 12) {
            PetAvatar(progress: model.generatedRoadmap == nil ? 0 : 1, size: 48)
            VStack(alignment: .leading, spacing: 3) {
                Text("Daily Agent")
                    .font(.headline)
                Text("Dokümanını bir yıllık çalışma planına dönüştür.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Çık") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
            .foregroundStyle(.secondary)
        }
        .padding(16)
    }

    private var setupForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                apiStatus

                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Kaynağını ekle")
                        .font(.subheadline.bold())

                    Picker("Kaynak", selection: $model.sourceMode) {
                        ForEach(RoadmapSetupViewModel.SourceMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    if model.sourceMode == .pdf {
                        Button {
                            model.choosePDF()
                        } label: {
                            Label(
                                model.selectedPDFName ?? "PDF dosyası seç",
                                systemImage: "doc.badge.plus"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    TextEditor(text: $model.sourceText)
                        .font(.system(.caption, design: .rounded))
                        .frame(minHeight: 175)
                        .padding(6)
                        .scrollContentBackground(.hidden)
                        .background(.primary.opacity(0.045), in: RoundedRectangle(cornerRadius: 10))
                        .overlay(alignment: .topLeading) {
                            if model.sourceText.isEmpty {
                                Text("Roadmap, öğrenme hedefi veya proje kapsamını buraya yapıştır...")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                                    .padding(12)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(alignment: .bottomTrailing) {
                            sendButton.padding(10)
                        }

                    Text("PDF cihazda metne dönüştürülür; sağ alttaki gönder butonu planı oluşturur.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("2. Çalışacağın günleri seç")
                        .font(.subheadline.bold())

                    HStack(spacing: 6) {
                        ForEach(Self.weekdays, id: \.number) { weekday in
                            weekdayButton(weekday)
                        }
                    }

                    Text("1 yıl • 52 hafta • haftada \(model.preferences.daysPerWeek) çalışma günü")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)

                    Text("Görevler yalnızca seçtiğin günlere eşit şekilde dağıtılır.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                .padding(12)
                .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))

                if let error = model.errorMessage {
                    Label(error, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.red.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                }

                if model.isGenerating {
                    Label("Bir yıllık roadmap oluşturuluyor...", systemImage: "sparkles")
                        .font(.caption.bold())
                        .foregroundStyle(.indigo)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(16)
        }
    }

    private var apiStatus: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: model.environmentStatus == nil ? "key.slash" : "key.fill")
                .foregroundStyle(model.environmentStatus == nil ? .orange : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(model.environmentStatus ?? "OpenAI API anahtarı gerekli")
                    .font(.caption.bold())
                Text("Proje kökündeki .env dosyasında OPENAI_API_KEY kullanılır.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Yenile") { model.refreshEnvironmentStatus() }
                .buttonStyle(.borderless)
                .font(.caption)
        }
        .padding(10)
        .background(.primary.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
    }

    private func preview(_ roadmap: GeneratedRoadmap) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 5) {
                Text(roadmap.title)
                    .font(.title3.bold())
                Text(roadmap.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }

            HStack {
                metric("\(roadmap.durationWeeks)", "hafta")
                metric("\(roadmap.weeks.count)", "plan bölümü")
                metric("\(roadmap.taskCount)", "görev")
                metric("\(roadmap.selectedWeekdays?.count ?? roadmap.daysPerWeek ?? 0)", "gün / hafta")
            }

            Text("Plan önizlemesi")
                .font(.subheadline.bold())

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(roadmap.weeks, id: \.weekNumber) { week in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\(week.weekNumber)")
                                .font(.caption.monospacedDigit().bold())
                                .frame(width: 28, height: 28)
                                .background(.indigo.opacity(0.12), in: Circle())
                                .foregroundStyle(.indigo)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(week.theme).font(.caption.bold())
                                Text(week.outcome)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(week.tasks.count) görev • \(week.milestone)")
                                    .font(.caption2.bold())
                                    .foregroundStyle(.indigo)
                            }
                            Spacer()
                        }
                        .padding(9)
                        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                    }
                }
            }

            HStack {
                Button("Geri dön") {
                    model.generatedRoadmap = nil
                }
                .buttonStyle(.bordered)

                Button {
                    store.activate(roadmap)
                } label: {
                    Label("Planı başlat", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.headline.monospacedDigit())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(.indigo.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
    }

    private var sendButton: some View {
        Button {
            Task { await model.generate() }
        } label: {
            Group {
                if model.isGenerating {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: "paperplane.fill")
                }
            }
            .frame(width: 34, height: 34)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.circle)
        .disabled(
            model.isGenerating
                || model.sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                || model.preferences.selectedWeekdays.isEmpty
        )
        .help("Bir yıllık planı oluştur")
    }

    private func weekdayButton(_ weekday: (number: Int, shortName: String)) -> some View {
        let isSelected = model.preferences.selectedWeekdays.contains(weekday.number)
        return Button(weekday.shortName) {
            if isSelected {
                guard model.preferences.selectedWeekdays.count > 1 else { return }
                model.preferences.selectedWeekdays.remove(weekday.number)
            } else {
                model.preferences.selectedWeekdays.insert(weekday.number)
            }
        }
        .buttonStyle(.plain)
        .font(.caption.bold())
        .foregroundStyle(isSelected ? .white : .secondary)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
            isSelected ? Color.indigo : Color.primary.opacity(0.06),
            in: RoundedRectangle(cornerRadius: 9)
        )
    }

    private static let weekdays: [(number: Int, shortName: String)] = [
        (1, "Pzt"), (2, "Sal"), (3, "Çar"), (4, "Per"),
        (5, "Cum"), (6, "Cmt"), (7, "Paz")
    ]
}
