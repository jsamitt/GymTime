import SwiftUI
import SwiftData

struct WatchRootView: View {
    @Query(sort: \Session.startedAt, order: .reverse) private var sessions: [Session]
    @Query private var settingsList: [AppSettings]
    @State private var showPicker = false

    private var activeSession: Session? {
        sessions.first { $0.finishedAt == nil }
    }

    private var settings: AppSettings? { settingsList.first }

    var body: some View {
        ZStack {
            GT.bg.ignoresSafeArea()
            if let session = activeSession, let settings {
                WatchActiveSetView(session: session, settings: settings)
            } else {
                waitingState
            }
        }
        .sheet(isPresented: $showPicker) {
            WatchTemplatePicker()
        }
    }

    private var waitingState: some View {
        VStack(spacing: 10) {
            Image(systemName: "dumbbell.fill")
                .font(.system(size: 26))
                .foregroundColor(GT.lime)
            Text("Ready")
                .font(.gtDisplay(18, weight: .semibold))
                .foregroundColor(GT.ink)
            Button { showPicker = true } label: {
                Text("START WORKOUT")
                    .font(.gtDisplay(13, weight: .bold))
                    .tracking(0.4)
                    .foregroundColor(GT.limeInk)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Capsule().fill(GT.lime))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 10)
            Text("or start from iPhone")
                .font(.gtMono(9))
                .tracking(1.0)
                .foregroundColor(GT.ink3)
        }
        .padding(8)
    }
}
