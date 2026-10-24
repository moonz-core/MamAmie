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
                case .stage:
                    OnboardingStageView(stage: $draft.stage, onContinue: goForward, onBack: goBack)
                case .dates:
                    OnboardingDatesView(draft: $draft, onContinue: goForward, onBack: goBack)
                case .personalization:
                    OnboardingPersonalizationView(draft: $draft, onContinue: goForward, onBack: goBack)
                case .summary:
                    OnboardingSummaryView(draft: draft, onFinish: finish, onBack: goBack)
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
        guard let profile = draft.makeProfile(), store.save(profile) else { return }
        onFinished()
    }
}

private enum OnboardingStep: Int, CaseIterable {
    case welcome
    case stage
    case dates
    case personalization
    case summary

    static let totalSteps = 4

    var progressNumber: Int {
        switch self {
        case .welcome: return 1
        case .stage: return 1
        case .dates: return 2
        case .personalization: return 3
        case .summary: return 4
        }
    }

    var next: OnboardingStep? {
        switch self {
        case .welcome: return .stage
        case .stage: return .dates
        case .dates: return .personalization
        case .personalization: return .summary
        case .summary: return nil
        }
    }

    var previous: OnboardingStep? {
        switch self {
        case .welcome: return nil
        case .stage: return .welcome
        case .dates: return .stage
        case .personalization: return .dates
        case .summary: return .personalization
        }
    }
}
