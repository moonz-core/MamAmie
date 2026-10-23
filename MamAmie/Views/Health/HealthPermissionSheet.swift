import SwiftUI

public struct HealthPermissionSheet: View {
    @ObservedObject public var viewModel: ConnectedHealthViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: ConnectedHealthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(Color("AccentColor"))

                        Text("Connect Apple Health")
                            .font(.largeTitle.bold())
                            .foregroundStyle(Color("AccentColor"))

                        Text("MamAmie connects with your Apple Watch and compatible devices to give you clear, reassuring visibility into your maternal health trends.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Privacy notice box
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "lock.shield.fill")
                            .font(.title3)
                            .foregroundStyle(Color("AccentColor"))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Your health privacy comes first")
                                .font(.subheadline.weight(.semibold))

                            Text("MamAmie requests read-only access. Measurements are processed privately on your iPhone and are never sold or shared with advertisers.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(16)
                    .background(Color("AccentColor").opacity(0.10))
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                    // Metric explanations
                    VStack(alignment: .leading, spacing: 14) {
                        Text("What we request & why:")
                            .font(.headline)

                        ForEach(HealthMetricType.allCases) { metric in
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: metric.iconName)
                                    .font(.subheadline)
                                    .foregroundStyle(metric.iconTintColor)
                                    .frame(width: 32, height: 32)
                                    .background(metric.iconTintColor.opacity(0.12))
                                    .clipShape(Circle())

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(metric.title)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(.primary)

                                    Text(metric.permissionRationale)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }

                    // Primary Action
                    VStack(spacing: 12) {
                        Button {
                            Task {
                                await viewModel.connectToAppleHealth()
                                dismiss()
                            }
                        } label: {
                            HStack {
                                Text("Continue with Apple Health")
                                    .font(.headline)
                                Image(systemName: "arrow.right")
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color("AccentColor"))
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }

                        Button {
                            dismiss()
                        } label: {
                            Text("Maybe Later")
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(.secondary)
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}
