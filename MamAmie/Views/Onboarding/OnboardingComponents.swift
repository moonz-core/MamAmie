import SwiftUI

struct OnboardingProgressView: View {
    let currentStep: Int
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(currentStep) of \(totalSteps)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                Spacer()
                Text("25 Questions Total")
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.primary.opacity(0.10))
                    Capsule()
                        .fill(Color("AccentColor"))
                        .frame(width: proxy.size.width * CGFloat(min(currentStep, totalSteps)) / CGFloat(totalSteps))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress, step \(currentStep) of \(totalSteps)")
    }
}

struct OnboardingCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

struct OnboardingPrimaryButton: View {
    let title: String
    let systemImage: String
    let isDisabled: Bool
    let action: () -> Void

    init(title: String, systemImage: String = "arrow.right", isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 15)
        }
        .buttonStyle(.borderedProminent)
        .tint(Color("AccentColor"))
        .disabled(isDisabled)
    }
}

struct OnboardingSkipButton: View {
    var title: String = "Skip for now"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingBackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Back", systemImage: "chevron.left")
                .font(.subheadline.weight(.medium))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
    }
}

struct OnboardingSelectableCard: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                if let icon {
                    Image(systemName: icon)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Color("AccentColor") : .secondary)
                        .frame(width: 40, height: 40)
                        .background(isSelected ? Color("AccentColor").opacity(0.12) : Color(.tertiarySystemFill))
                        .clipShape(Circle())
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("AccentColor") : Color(.tertiaryLabel))
            }
            .padding(14)
            .background(isSelected ? Color("AccentColor").opacity(0.08) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color("AccentColor").opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingMultiSelectCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("AccentColor") : .secondary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color("AccentColor").opacity(0.12) : Color(.tertiarySystemFill))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(isSelected ? Color("AccentColor") : Color(.tertiaryLabel))
            }
            .padding(14)
            .background(isSelected ? Color("AccentColor").opacity(0.08) : Color(.secondarySystemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(isSelected ? Color("AccentColor").opacity(0.35) : Color.clear, lineWidth: 1.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct DateSelectionRow: View {
    let title: String
    let value: Date?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color("AccentColor"))
                    .frame(width: 36, height: 36)
                    .background(Color("AccentColor").opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(value?.formatted(date: .long, time: .omitted) ?? "Choose a date")
                        .font(.caption)
                        .foregroundStyle(value == nil ? Color("AccentColor") : Color(.secondaryLabel))
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingSectionHeader: View {
    var questionNumber: Int? = nil
    var totalQuestions: Int = 25
    let title: String
    var subtitle: String? = nil
    var isOptional: Bool = false
    var isSkipped: Bool = false
    var onSkip: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .center, spacing: 6) {
                if let questionNumber {
                    Text("Question \(questionNumber) of \(totalQuestions)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(isSkipped ? Color.secondary : Color("AccentColor"))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(isSkipped ? Color(.tertiarySystemFill) : Color("AccentColor").opacity(0.12))
                        .clipShape(Capsule())
                }

                if isOptional {
                    Text("Optional")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                }

                Spacer()

                if let onSkip {
                    Button(action: onSkip) {
                        HStack(spacing: 4) {
                            if isSkipped {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.caption2)
                                Text("Answer")
                            } else {
                                Image(systemName: "forward.fill")
                                    .font(.caption2)
                                Text("Skip question")
                            }
                        }
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(isSkipped ? Color("AccentColor") : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(isSkipped ? Color("AccentColor").opacity(0.12) : Color(.tertiarySystemFill))
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isSkipped ? .secondary : .primary)

            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if isSkipped {
                HStack(spacing: 4) {
                    Image(systemName: "slash.circle")
                        .font(.caption2)
                    Text("Skipped · You can answer this later")
                        .font(.caption2)
                }
                .foregroundStyle(.secondary)
                .padding(.top, 2)
            }
        }
    }
}

struct OnboardingChip: View {
    let title: String
    var icon: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color("AccentColor").opacity(0.16) : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? Color("AccentColor") : Color.primary)
            .overlay(
                Capsule()
                    .stroke(isSelected ? Color("AccentColor") : Color(.separator), lineWidth: 1)
            )
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct OnboardingNumberStepper: View {
    let title: String
    var subtitle: String? = nil
    @Binding var value: Int
    let range: ClosedRange<Int>

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button {
                    if value > range.lowerBound { value -= 1 }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value > range.lowerBound ? Color("AccentColor") : Color(.tertiaryLabel))
                }
                .disabled(value <= range.lowerBound)

                Text("\(value)")
                    .font(.headline)
                    .frame(minWidth: 24, alignment: .center)

                Button {
                    if value < range.upperBound { value += 1 }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(value < range.upperBound ? Color("AccentColor") : Color(.tertiaryLabel))
                }
                .disabled(value >= range.upperBound)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

