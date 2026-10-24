import SwiftUI

// MARK: - Screen 3: Pregnancy History
struct OnboardingScreen3HistoryView: View {
    @Binding var draft: OnboardingDraft
    let onContinue: () -> Void
    let onBack: () -> Void
    let onSkip: () -> Void

    private let commonComplications = [
        "None",
        "Gestational diabetes",
        "Pre-eclampsia",
        "Preterm birth (< 37 weeks)",
        "C-section delivery",
        "High blood pressure",
        "Low birth weight",
        "Prefer not to say"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerBar

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    titleSection

                    // Question 9: First pregnancy?
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 9,
                                title: "Is this your first pregnancy?",
                                subtitle: "Helps us avoid redundant questions.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(9),
                                onSkip: { draft.toggleSkipQuestion(9) }
                            )

                            if !draft.skippedQuestions.contains(9) {
                                HStack(spacing: 12) {
                                    OnboardingChip(
                                        title: "Yes, first pregnancy",
                                        icon: "sparkles",
                                        isSelected: draft.isFirstPregnancy == true
                                    ) {
                                        draft.isFirstPregnancy = true
                                        draft.totalPregnancies = 1
                                        draft.previousBirths = 0
                                    }

                                    OnboardingChip(
                                        title: "No, previously pregnant",
                                        icon: "arrow.counterclockwise",
                                        isSelected: draft.isFirstPregnancy == false
                                    ) {
                                        draft.isFirstPregnancy = false
                                    }
                                }
                            }
                        }
                    }

                    // Question 10 & 11: Total pregnancies & previous births (shown if not first pregnancy or unsure)
                    if draft.isFirstPregnancy == false {
                        OnboardingCard {
                            VStack(alignment: .leading, spacing: 14) {
                                OnboardingSectionHeader(
                                    questionNumber: 10,
                                    title: "Total pregnancies (Gravida)",
                                    subtitle: "Including your current pregnancy",
                                    isOptional: true,
                                    isSkipped: draft.skippedQuestions.contains(10),
                                    onSkip: { draft.toggleSkipQuestion(10) }
                                )

                                if !draft.skippedQuestions.contains(10) {
                                    OnboardingNumberStepper(
                                        title: "Total count",
                                        value: $draft.totalPregnancies,
                                        range: 1...15
                                    )
                                }

                                Divider()

                                OnboardingSectionHeader(
                                    questionNumber: 11,
                                    title: "Previous births (Para)",
                                    subtitle: "Number of deliveries",
                                    isOptional: true,
                                    isSkipped: draft.skippedQuestions.contains(11),
                                    onSkip: { draft.toggleSkipQuestion(11) }
                                )

                                if !draft.skippedQuestions.contains(11) {
                                    OnboardingNumberStepper(
                                        title: "Births count",
                                        value: $draft.previousBirths,
                                        range: 0...15
                                    )
                                }
                            }
                        }
                    }

                    // Question 12: Expecting one baby or multiples? (Relevant for pregnant stage)
                    if draft.stage == .pregnant || draft.stage == nil {
                        OnboardingCard {
                            VStack(alignment: .leading, spacing: 10) {
                                OnboardingSectionHeader(
                                    questionNumber: 12,
                                    title: "Are you expecting one baby or multiples?",
                                    subtitle: "Multiple pregnancies involve distinct milestone tracking.",
                                    isOptional: true,
                                    isSkipped: draft.skippedQuestions.contains(12),
                                    onSkip: { draft.toggleSkipQuestion(12) }
                                )

                                if !draft.skippedQuestions.contains(12) {
                                    FlowLayout(spacing: 8) {
                                        ForEach(MultiplePregnancyType.allCases) { type in
                                            OnboardingChip(
                                                title: type.title,
                                                isSelected: draft.multiplePregnancyType == type
                                            ) {
                                                draft.multiplePregnancyType = type
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Question 13: Previous complications or notes (sensitive & optional)
                    OnboardingCard {
                        VStack(alignment: .leading, spacing: 10) {
                            OnboardingSectionHeader(
                                questionNumber: 13,
                                title: "Previous complications or birth history",
                                subtitle: "Sensitive & optional. Used only to tailor relevant health precautions.",
                                isOptional: true,
                                isSkipped: draft.skippedQuestions.contains(13),
                                onSkip: { draft.toggleSkipQuestion(13) }
                            )

                            if !draft.skippedQuestions.contains(13) {
                                FlowLayout(spacing: 8) {
                                    ForEach(commonComplications, id: \.self) { comp in
                                        OnboardingChip(
                                            title: comp,
                                            isSelected: isComplicationSelected(comp)
                                        ) {
                                            toggleComplication(comp)
                                        }
                                    }
                                }

                                TextField("Any specific notes (optional)", text: $draft.previousComplicationsNotes)
                                    .padding(10)
                                    .background(Color(.systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color(.separator), lineWidth: 1))
                            }
                        }
                    }

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            footerActions
        }
    }

    private var headerBar: some View {
        HStack {
            OnboardingBackButton(action: onBack)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
    }

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Pregnancy History")
                .font(.largeTitle.bold())
                .foregroundStyle(Color("AccentColor"))
            Text("Understanding your reproductive background allows MamAmie to provide considerate, personalized care.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var footerActions: some View {
        VStack(spacing: 10) {
            OnboardingPrimaryButton(
                title: "Continue",
                systemImage: "arrow.right",
                isDisabled: false,
                action: onContinue
            )

            OnboardingSkipButton(title: "Skip this section", action: onSkip)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color(.systemBackground))
    }

    private func isComplicationSelected(_ tag: String) -> Bool {
        if tag == "None" || tag == "Prefer not to say" {
            return draft.previousComplicationsNotes.contains(tag)
        }
        return draft.previousComplicationsNotes.localizedCaseInsensitiveContains(tag)
    }

    private func toggleComplication(_ tag: String) {
        if tag == "None" || tag == "Prefer not to say" {
            draft.previousComplicationsNotes = tag
            return
        }
        var current = draft.previousComplicationsNotes
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && $0 != "None" && $0 != "Prefer not to say" }

        if let index = current.firstIndex(where: { $0.caseInsensitiveCompare(tag) == .orderedSame }) {
            current.remove(at: index)
        } else {
            current.append(tag)
        }
        draft.previousComplicationsNotes = current.joined(separator: ", ")
    }
}

// FlowLayout helper
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
