import SwiftUI
import SwiftData
import CloudKit

struct RootView: View {
    @State private var tab: Tab = .train
    @ObservedObject private var sync = PhoneSyncStatusHolder.shared
    @State private var showSyncDetail = false

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
        .overlay(alignment: .topTrailing) {
            syncBadge
                .padding(.top, 60)
                .padding(.trailing, 12)
        }
        .sheet(isPresented: $showSyncDetail) { syncDetailSheet }
    }

    @ViewBuilder
    private var syncBadge: some View {
        Button { showSyncDetail = true } label: {
            switch sync.status {
            case .cloudKit:
                Label("iCloud", systemImage: "icloud.fill")
                    .font(.gtMono(10))
                    .foregroundColor(GT.lime)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(GT.bg.opacity(0.8)))
                    .overlay(Capsule().stroke(GT.lime.opacity(0.4), lineWidth: 1))
            case .localOnly:
                Label("LOCAL", systemImage: "icloud.slash")
                    .font(.gtMono(10))
                    .foregroundColor(.red)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Capsule().fill(GT.bg.opacity(0.8)))
                    .overlay(Capsule().stroke(Color.red.opacity(0.6), lineWidth: 1))
            }
        }
    }

    private var syncDetailSheet: some View {
        SyncDetailView(status: sync.status)
    }
}

struct SyncDetailView: View {
    let status: PhoneSyncStatus
    @State private var accountStatus = "checking…"
    @State private var userID = "checking…"
    @State private var containerProbe = "probing…"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Sync Status").font(.title2.bold())

                Group {
                    row("ModelContainer",
                        value: {
                            if case .cloudKit = status { return "CloudKit OK" }
                            return "LOCAL-ONLY (failed)"
                        }())

                    row("iCloud Account", value: accountStatus)
                    row("iCloud User ID", value: userID)
                    row("Container Probe", value: containerProbe)
                }

                if case .localOnly(let msg) = status {
                    Divider()
                    Text("Init Error").font(.headline)
                    Text(msg)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding()
        }
        .task { await probe() }
    }

    @ViewBuilder
    private func row(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
        }
    }

    private func probe() async {
        let container = CKContainer(identifier: "iCloud.com.jsamitt.GymTime")
        do {
            let s = try await container.accountStatus()
            accountStatus = {
                switch s {
                case .available: return "available"
                case .noAccount: return "noAccount"
                case .restricted: return "restricted"
                case .couldNotDetermine: return "couldNotDetermine"
                case .temporarilyUnavailable: return "temporarilyUnavailable"
                @unknown default: return "unknown(\(s.rawValue))"
                }
            }()
        } catch {
            accountStatus = "error: \(error.localizedDescription)"
        }
        do {
            let id = try await container.userRecordID()
            userID = id.recordName
        } catch {
            userID = "error: \(error.localizedDescription)"
        }
        do {
            let zones = try await container.privateCloudDatabase.allRecordZones()
            let names = zones.map { $0.zoneID.zoneName }
            if names.isEmpty {
                containerProbe = "reachable, 0 zones (SwiftData never uploaded)"
            } else {
                containerProbe = "zones: \(names.joined(separator: ", "))"
            }
        } catch {
            containerProbe = "error: \(error.localizedDescription)"
        }
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
