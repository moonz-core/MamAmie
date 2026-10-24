import SwiftUI

struct OnboardingFlowView: View {
    @ObservedObject var store: OnboardingStore
    let onFinished: () -> Void

    @State private var step: OnboardingStep = .welcome
    @State private var draft: OnboardingDraft

    init(store: OnboardingStore, onFinished: @escaping () -> Void) {
        self.store = store
        self.onFinished = onFinished
        _draft = State(initialValue: OnboardingDraft(profile: store.profile))
    }

    var body: some View {
        VStack(spacing: 0) {
            if step != .welcome {
                OnboardingProgressView(currentStep: step.progressNumber, totalSteps: OnboardingStep.totalSteps)
                    .padding(.horizontal, 24)
                    .padding(.top, 14)
            }

            Group {
                switch step {
                case .welcome:
                    OnboardingWelcomeView(onContinue: goForward)

                case .name:
                    OnboardingNameView(
                        name: $draft.displayName,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .stage:
                    OnboardingStageView(
                        stage: $draft.stage,
                        onContinue: goForward,
                        onBack: goBack
                    )

                case .dates:
                    OnboardingDatesView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack
                    )

                case .healthAndAllergies:
                    OnboardingHealthConditionsView(
                        healthNotes: $draft.healthConditionsAndAllergies,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .diet:
                    OnboardingDietView(
                        selectedDiet: $draft.dietaryPreference,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .appleHealth:
                    OnboardingAppleHealthView(
                        isConnected: $draft.connectedAppleHealth,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .reminders:
                    OnboardingRemindersView(
                        selectedReminders: $draft.selectedReminders,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .summary:
                    OnboardingSummaryView(
                        draft: $draft,
                        onFinish: finish,
                        onBack: goBack
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .alert(
            "Couldn't save setup",
            isPresented: Binding(
                get: { store.saveErrorMessage != nil },
                set: { if !$0 { store.clearError() } }
            )
        ) {
            Button("OK", role: .cancel) { store.clearError() }
        } message: {
            Text(store.saveErrorMessage ?? "Please try again.")
        }
        .onAppear {
            step = .welcome
            draft = OnboardingDraft(profile: store.profile)
        }
    }

    private func goForward() {
        guard let next = step.next else {
            finish()
            return
        }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = next
        }
    }

    private func goBack() {
        guard let previous = step.previous else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = previous
        }
    }

    private func finish() {
        draft.acceptedPrivacy = true
        guard let profile = draft.makeProfile(), store.save(profile) else { return }
        onFinished()
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case name
    case stage
    case dates
    case healthAndAllergies
    case diet
    case appleHealth
    case reminders
    case summary

    static let totalSteps = 8

    var progressNumber: Int {
        switch self {
        case .welcome: return 1
        case .name: return 1
        case .stage: return 2
        case .dates: return 3
        case .healthAndAllergies: return 4
        case .diet: return 5
        case .appleHealth: return 6
        case .reminders: return 7
        case .summary: return 8
        }
    }

    var next: OnboardingStep? {
        switch self {
        case .welcome: return .name
        case .name: return .stage
        case .stage: return .dates
        case .dates: return .healthAndAllergies
        case .healthAndAllergies: return .diet
        case .diet: return .appleHealth
        case .appleHealth: return .reminders
        case .reminders: return .summary
        case .summary: return nil
        }
    }

    var previous: OnboardingStep? {
        switch self {
        case .welcome: return nil
        case .name: return .welcome
        case .stage: return .name
        case .dates: return .stage
        case .healthAndAllergies: return .dates
        case .diet: return .healthAndAllergies
        case .appleHealth: return .diet
        case .reminders: return .appleHealth
        case .summary: return .reminders
        }
    }
}
