import SwiftUI

public struct HealthSourceSettingsSheet: View {
    @ObservedObject public var viewModel: ConnectedHealthViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: ConnectedHealthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: "applewatch")
                            .font(.title2)
                            .foregroundStyle(Color("AccentColor"))
                            .frame(width: 40, height: 40)
                            .background(Color("AccentColor").opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Apple Health Integration")
                                .font(.headline)

                            Text(statusSubtitle)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        statusBadge
                    }
                    .padding(.vertical, 4)

                    if let syncDate = viewModel.lastSyncDate {
                        HStack {
                            Text("Last Synced")
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(syncDate.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline.weight(.medium))
                        }
                    }
                } header: {
                    Text("Connection Status")
                }

                Section {
                    Toggle(isOn: Binding(
                        get: { viewModel.isDemoMode },
                        set: { enable in
                            Task {
                                if enable {
                                    await viewModel.enableDemoMode()
                                } else {
                                    await viewModel.disableDemoMode()
                                }
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sample Demonstration Mode")
                                .font(.headline)

                            Text("Allows previewing realistic maternal health trends when running in Simulator or without a physical Apple Watch.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tint(Color("AccentColor"))
                } header: {
                    Text("Developer & Reviewer Tools")
                } footer: {
                    Text("Sample data is always explicitly watermarked and will never be confused with actual medical records.")
                }

                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Apple Health Privacy Architecture")
                            .font(.subheadline.weight(.semibold))

                        Text("To protect your privacy, Apple does not allow third-party apps to directly see whether you toggled individual permissions off or simply have no recorded measurements yet.")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("You can review or adjust granular access to Heart Rate, Steps, Blood Oxygen, and Sleep at any time:")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text("1. Open iPhone Settings\n2. Scroll to Health > Data Access & Devices\n3. Tap MamAmie to customize read permissions")
                            .font(.caption.monospaced())
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(Color(.tertiarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                Text("Open iOS Settings")
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color("AccentColor"))
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Managing Permissions")
                }
            }
            .navigationTitle("Connected Sources")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var statusSubtitle: String {
        switch viewModel.connectionState {
        case .connected:
            return "Active & Synchronized"
        case .notConfigured:
            return "Ready to connect"
        case .connecting:
            return "Authorizing with iOS..."
        case .restricted:
            return "Permission restricted"
        case .unsupported:
            return "HealthKit not available on device"
        case .demoMode:
            return "Simulated demonstration data"
        }
    }

    @ViewBuilder
    private var statusBadge: some View {
        switch viewModel.connectionState {
        case .connected:
            Text("Connected")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.15))
                .foregroundStyle(.green)
                .clipShape(Capsule())
        case .demoMode:
            Text("Demo")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color("AccentColor").opacity(0.15))
                .foregroundStyle(Color("AccentColor"))
                .clipShape(Capsule())
        case .restricted:
            Text("Restricted")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.orange.opacity(0.15))
                .foregroundStyle(.orange)
                .clipShape(Capsule())
        case .unsupported:
            Text("Unavailable")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.gray.opacity(0.15))
                .foregroundStyle(.gray)
                .clipShape(Capsule())
        default:
            Text("Not Connected")
                .font(.caption.weight(.bold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .foregroundStyle(.secondary)
                .clipShape(Capsule())
        }
    }
}
