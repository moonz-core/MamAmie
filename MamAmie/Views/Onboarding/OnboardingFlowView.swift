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
                OnboardingProgressView(
                    currentStep: step.progressNumber,
                    totalSteps: OnboardingStep.totalSteps
                )
                .padding(.horizontal, 24)
                .padding(.top, 14)
                .padding(.bottom, 6)
            }

            Group {
                switch step {
                case .welcome:
                    OnboardingWelcomeView(onContinue: goForward)

                case .aboutYou:
                    OnboardingScreen1AboutYouView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .journey:
                    OnboardingScreen2JourneyView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .history:
                    OnboardingScreen3HistoryView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .health:
                    OnboardingScreen4HealthView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .nutrition:
                    OnboardingScreen5NutritionView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .connectedHealth:
                    OnboardingScreen6ConnectedHealthView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .reminders:
                    OnboardingScreen7RemindersView(
                        draft: $draft,
                        onContinue: goForward,
                        onBack: goBack,
                        onSkip: goForward
                    )

                case .review:
                    OnboardingSummaryView(
                        draft: $draft,
                        onFinish: finish,
                        onBack: goBack,
                        onEditStep: { stepNumber in
                            jumpTo(stepNumber: stepNumber)
                        }
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

    private func jumpTo(stepNumber: Int) {
        guard let target = OnboardingStep.from(progressNumber: stepNumber) else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            step = target
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
    case aboutYou
    case journey
    case history
    case health
    case nutrition
    case connectedHealth
    case reminders
    case review

    static let totalSteps = 8

    var progressNumber: Int {
        switch self {
        case .welcome: return 1
        case .aboutYou: return 1
        case .journey: return 2
        case .history: return 3
        case .health: return 4
        case .nutrition: return 5
        case .connectedHealth: return 6
        case .reminders: return 7
        case .review: return 8
        }
    }

    static func from(progressNumber: Int) -> OnboardingStep? {
        switch progressNumber {
        case 1: return .aboutYou
        case 2: return .journey
        case 3: return .history
        case 4: return .health
        case 5: return .nutrition
        case 6: return .connectedHealth
        case 7: return .reminders
        case 8: return .review
        default: return nil
        }
    }

    var next: OnboardingStep? {
        switch self {
        case .welcome: return .aboutYou
        case .aboutYou: return .journey
        case .journey: return .history
        case .history: return .health
        case .health: return .nutrition
        case .nutrition: return .connectedHealth
        case .connectedHealth: return .reminders
        case .reminders: return .review
        case .review: return nil
        }
    }

    var previous: OnboardingStep? {
        switch self {
        case .welcome: return nil
        case .aboutYou: return .welcome
        case .journey: return .aboutYou
        case .history: return .journey
        case .health: return .history
        case .nutrition: return .health
        case .connectedHealth: return .nutrition
        case .reminders: return .connectedHealth
        case .review: return .reminders
        }
    }
}
