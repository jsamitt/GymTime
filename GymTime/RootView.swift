import SwiftUI
import SwiftData

struct RootView: View {
    @State private var tab: Tab = .train

    enum Tab: Hashable { case train, library, history, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            GT.bg.ignoresSafeArea()

            Group {
                switch tab {
                case .train: HomeView()
                case .library: LibraryView()
                case .history: HistoryView()
                case .settings: SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, 76) // room for tab bar

            GTTabBar(active: $tab)
        }
        .ignoresSafeArea(.keyboard)
    }
}

struct GTTabBar: View {
    @Binding var active: RootView.Tab

    var body: some View {
        HStack(spacing: 0) {
            tab(.train,    icon: "dumbbell",            label: "TRAIN")
            tab(.library,  icon: "square.grid.2x2",     label: "LIBRARY")
            tab(.history,  icon: "clock.arrow.circlepath", label: "HISTORY")
            tab(.settings, icon: "gearshape",            label: "SETTINGS")
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
        .padding(.bottom, 30)
        .background(
            GT.bg.opacity(0.88)
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) {
                    Rectangle().fill(GT.line).frame(height: 1)
                }
        )
    }

    @ViewBuilder
    private func tab(_ t: RootView.Tab, icon: String, label: String) -> some View {
        let on = active == t
        Button {
            active = t
        } label: {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .regular))
                Text(label)
                    .font(.gtMono(9.5, weight: .semibold))
                    .tracking(0.8)
            }
            .foregroundColor(on ? GT.lime : GT.ink3)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootView()
        .modelContainer(for: [
            Exercise.self, WorkoutTemplate.self, TemplateExercise.self,
            Session.self, ExerciseLog.self, SetLog.self, AppSettings.self
        ], inMemory: true)
}
