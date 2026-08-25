import SwiftUI

struct PetAvatar: View {
    let progress: Double
    var size: CGFloat = 52

    private var face: String {
        switch progress {
        case 1: "checkmark"
        case 0.66...: "sparkles"
        case 0.33...: "chevron.up"
        default: "ellipsis"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.45, green: 0.25, blue: 0.85), .indigo],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .indigo.opacity(0.25), radius: 8, y: 4)

            HStack(spacing: size * 0.12) {
                Circle().fill(.white).frame(width: size * 0.12, height: size * 0.12)
                Circle().fill(.white).frame(width: size * 0.12, height: size * 0.12)
            }
            .offset(y: -size * 0.08)

            Image(systemName: face)
                .font(.system(size: size * 0.16, weight: .bold))
                .foregroundStyle(.white.opacity(0.92))
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Codex Pet")
    }
}

struct CompactPetView: View {
    @ObservedObject var store: TaskStore
    let onExpand: () -> Void

    var body: some View {
        Button(action: onExpand) {
            VStack(spacing: 6) {
                PetAvatar(progress: store.progress, size: 54)
                Text("\(store.completedCount)/\(store.tasks.count)")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)
            }
            .padding(10)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 22))
            .overlay {
                RoundedRectangle(cornerRadius: 22)
                    .stroke(.white.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
        .help("Bugünün görevlerini aç")
    }
}
