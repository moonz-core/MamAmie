import HealthKit
import SwiftUI

// MARK: - Q4: Health Conditions & Allergies
struct OnboardingHealthConditionsView: View {
    @Binding var healthNotes: String
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    private let commonSuggestions = [
        "None",
        "Gestational Diabetes",
        "Thyroid condition",
        "Asthma",
        "Lactose intolerance",
        "Nut allergy",
        "Gluten sensitivity",
        "Penicillin allergy"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Health & allergies")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("Do you have any existing health conditions or allergies you'd like MamAmie to know about?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Common tags")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                FlowLayout(spacing: 8) {
                    ForEach(commonSuggestions, id: \.self) { suggestion in
                        Button {
                            toggleSuggestion(suggestion)
                        } label: {
                            Text(suggestion)
                                .font(.caption.weight(.medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(isTagSelected(suggestion) ? Color("AccentColor").opacity(0.15) : Color(.secondarySystemBackground))
                                .foregroundStyle(isTagSelected(suggestion) ? Color("AccentColor") : Color.primary)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            OnboardingCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Details (optional)")
                        .font(.subheadline.weight(.semibold))

                    TextField("e.g. Mild asthma, seasonal pollen allergy (optional)", text: $healthNotes, axis: .vertical)
                        .lineLimit(3...5)
                        .padding(10)
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }

            OnboardingCard {
                HStack(spacing: 10) {
                    Image(systemName: "hand.raised.shield")
                        .foregroundStyle(Color("AccentColor"))
                    Text("MamAmie uses this only for personalized cautions. MamAmie never diagnoses medical conditions or prescribes medications.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isDisabled: false,
                    action: onContinue
                )

                if healthNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    OnboardingSkipButton(title: "Skip for now", action: onSkip)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private func isTagSelected(_ tag: String) -> Bool {
        if tag == "None" {
            return healthNotes.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "none"
        }
        return healthNotes.localizedCaseInsensitiveContains(tag)
    }

    private func toggleSuggestion(_ tag: String) {
        if tag == "None" {
            healthNotes = "None"
            return
        }
        var current = healthNotes
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0.lowercased() != "none" }

        if let index = current.firstIndex(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            current.remove(at: index)
        } else {
            current.append(tag)
        }
        healthNotes = current.joined(separator: ", ")
    }
}

// MARK: - Q5: Dietary Preference
struct OnboardingDietView: View {
    @Binding var selectedDiet: DietaryPreference?
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Dietary preference")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("What best describes your dietary preference? This helps our food scanner and meal logs provide appropriate insights.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(DietaryPreference.allCases) { diet in
                        OnboardingSelectableCard(
                            title: diet.title,
                            subtitle: diet.subtitle,
                            icon: diet.iconName,
                            isSelected: selectedDiet == diet
                        ) {
                            selectedDiet = diet
                        }
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isDisabled: false,
                    action: onContinue
                )

                if selectedDiet == nil {
                    OnboardingSkipButton(title: "Skip for now", action: onSkip)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }
}

// MARK: - Q6: Connect Smartwatch or Apple Health
struct OnboardingAppleHealthView: View {
    @Binding var isConnected: Bool
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    @State private var isConnecting = false
    @State private var connectErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Connected Health")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("Would you like to connect your smartwatch or Apple Health?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 14) {
                OnboardingCard {
                    HStack(spacing: 14) {
                        Image(systemName: "applewatch.radiowaves.left.and.right")
                            .font(.system(size: 34))
                            .foregroundStyle(Color("AccentColor"))
                            .frame(width: 52, height: 52)
                            .background(Color("AccentColor").opacity(0.12))
                            .clipShape(Circle())

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Apple Watch & Health Data")
                                .font(.headline)
                            Text("Compatible devices may provide measurements such as heart rate, resting vitals, blood oxygen, sleep, and daily activity.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                OnboardingCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Availability & Safety Notice", systemImage: "info.circle")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color("AccentColor"))

                        Text("Actual availability depends on the device and connected data sources. Permissions are requested only when you choose to connect, and only for required read data types.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("Smartwatch readings do not establish the mother’s or baby’s health, and are not a substitute for clinical diagnostics.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                if isConnected {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.headline)
                        Text("Apple Health connected successfully")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }

            Spacer()

            VStack(spacing: 12) {
                if !isConnected {
                    Button {
                        connectHealthKit()
                    } label: {
                        HStack(spacing: 8) {
                            if isConnecting {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "heart.fill")
                            }
                            Text(isConnecting ? "Connecting…" : "Connect Apple Health")
                        }
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))
                    .disabled(isConnecting)

                    OnboardingSkipButton(title: "Maybe later", action: onSkip)
                } else {
                    OnboardingPrimaryButton(
                        title: "Continue",
                        systemImage: "arrow.right",
                        isDisabled: false,
                        action: onContinue
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private func connectHealthKit() {
        isConnecting = true
        connectErrorMessage = nil

        Task {
            let service = HealthKitService()
            do {
                let success = try await service.requestAuthorization()
                await MainActor.run {
                    isConnecting = false
                    isConnected = success
                    if success {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                            onContinue()
                        }
                    } else {
                        onContinue()
                    }
                }
            } catch {
                await MainActor.run {
                    isConnecting = false
                    isConnected = false
                    onContinue()
                }
            }
        }
    }
}

// MARK: - Q7: Reminders
struct OnboardingRemindersView: View {
    @Binding var selectedReminders: Set<OnboardingReminderType>
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            OnboardingBackButton(action: onBack)

            VStack(alignment: .leading, spacing: 8) {
                Text("Which reminders would you like?")
                    .font(.largeTitle.bold())
                    .foregroundStyle(Color("AccentColor"))

                Text("Select any reminders you'd like to receive. All reminders are optional and can be adjusted anytime.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            ScrollView(showsIndicators: false) {
                VStack(spacing: 10) {
                    ForEach(OnboardingReminderType.allCases) { reminder in
                        OnboardingMultiSelectCard(
                            title: reminder.title,
                            subtitle: reminder.subtitle,
                            icon: reminder.iconName,
                            isSelected: selectedReminders.contains(reminder)
                        ) {
                            toggleReminder(reminder)
                        }
                    }

                    OnboardingCard {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.shield")
                                .foregroundStyle(Color("AccentColor"))
                            Text("Medication reminders must use schedules entered or confirmed by you, not AI-generated prescriptions.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Spacer()

            VStack(spacing: 12) {
                OnboardingPrimaryButton(
                    title: "Continue",
                    systemImage: "arrow.right",
                    isDisabled: false,
                    action: onContinue
                )

                if selectedReminders.isEmpty {
                    OnboardingSkipButton(title: "Skip for now", action: onSkip)
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    private func toggleReminder(_ reminder: OnboardingReminderType) {
        if selectedReminders.contains(reminder) {
            selectedReminders.remove(reminder)
        } else {
            selectedReminders.insert(reminder)
        }
    }
}

// MARK: - FlowLayout Helper for Tags
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 300
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > width && currentX > 0 {
                height += rowHeight + spacing
                currentX = 0
                rowHeight = 0
            }
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var currentX = bounds.minX
        var currentY = bounds.minY
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                currentY += rowHeight + spacing
                currentX = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: .unspecified)
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
