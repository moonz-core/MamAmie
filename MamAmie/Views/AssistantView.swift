import SwiftUI

struct AssistantView: View {
    @ObservedObject var api: AssistantAPIClient
    var onboardingStore: OnboardingStore? = nil
    var foodDiaryStore: FoodDiaryStore? = nil

    @StateObject private var gemini = GeminiChatService.shared

    @State private var input = ""
    @State private var showingApiKeySheet = false
    @State private var showingContextDetails = false
    @State private var showingClearAlert = false
    @State private var showingTriage = false
    @State private var showingReport = false

    private let suggestedPrompts = [
        "🥗 Is what I ate today balanced for my baby?",
        "🍳 What should I eat for dinner based on my meals today?",
        "🤰 How is my baby developing at my current stage?",
        "⚡ Safe exercises & natural energy boosters for today",
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Active Maternal Context Header Bar
                activeContextBar

                // Chat Messages Thread
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Empty state prompts
                            if gemini.messages.count <= 1 {
                                promptSuggestionsView
                            }

                            // Message Stream
                            ForEach(gemini.messages) { message in
                                messageRow(message)
                                    .id(message.id)
                            }

                            // Typing Indicator
                            if gemini.isGenerating {
                                typingIndicator
                                    .id("typing-indicator")
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                    .onChange(of: gemini.messages.count) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: gemini.isGenerating) { _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Input Bar
                chatInputBar
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ask MamAmie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showingApiKeySheet = true
                        } label: {
                            Label(gemini.hasApiKey ? "Gemini API Settings" : "Configure Gemini API Key", systemImage: "key.fill")
                        }

                        Button {
                            showingContextDetails = true
                        } label: {
                            Label("View Context Sent to AI", systemImage: "info.circle")
                        }

                        Divider()

                        Button {
                            showingTriage = true
                        } label: {
                            Label("Check a symptom", systemImage: "cross.case")
                        }

                        Button {
                            showingReport = true
                        } label: {
                            Label("Explain report text", systemImage: "doc.text.magnifyingglass")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingClearAlert = true
                        } label: {
                            Label("Clear chat history", systemImage: "trash")
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(Color("AccentColor"))
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                    .accessibilityLabel("Chat options")
                }
            }
            .sheet(isPresented: $showingApiKeySheet) {
                GeminiApiKeySheet(gemini: gemini)
            }
            .sheet(isPresented: $showingContextDetails) {
                MaternalContextDetailSheet(
                    snapshot: gemini.buildContextSnapshot(
                        profile: onboardingStore?.profile,
                        meals: foodDiaryStore?.meals ?? []
                    )
                )
            }
            .sheet(isPresented: $showingTriage) {
                AssistantTriageSheet(api: api, stage: onboardingStore?.profile?.stage.rawValue ?? "pregnant")
            }
            .sheet(isPresented: $showingReport) {
                AssistantReportSheet(api: api, stage: onboardingStore?.profile?.stage.rawValue ?? "pregnant")
            }
            .alert("Clear Chat History?", isPresented: $showingClearAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    gemini.clearHistory()
                }
            } message: {
                Text("This will remove all current messages and restart the conversation.")
            }
            .onAppear {
                gemini.refreshApiKey()
            }
        }
    }

    // MARK: - Active Context Bar

    private var activeContextBar: some View {
        let snapshot = gemini.buildContextSnapshot(
            profile: onboardingStore?.profile,
            meals: foodDiaryStore?.meals ?? []
        )

        return Button {
            showingContextDetails = true
        } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)

                Text("Context Active:")
                    .font(.caption.bold())
                    .foregroundStyle(.primary)

                // Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        if let week = snapshot.gestationalWeekText {
                            contextChip(icon: "heart.fill", text: week)
                        } else {
                            contextChip(icon: "heart.fill", text: snapshot.stageName)
                        }

                        if let due = snapshot.dueDateText {
                            contextChip(icon: "calendar", text: "Due \(due)")
                        }

                        if snapshot.todaysMealCount > 0 {
                            contextChip(
                                icon: "fork.knife",
                                text: "\(snapshot.todaysMealCount) meals (\(snapshot.todaysCaloriesText ?? ""))"
                            )
                        } else {
                            contextChip(icon: "fork.knife", text: "No meals today")
                        }
                    }
                }

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            .overlay(Divider(), alignment: .bottom)
        }
        .buttonStyle(.plain)
    }

    private func contextChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundStyle(Color("AccentColor"))
            Text(text)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(.tertiarySystemGroupedBackground), in: Capsule())
    }

    // MARK: - API Key Missing Banner

    private var apiKeyBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Connect Google Gemini")
                        .font(.headline)
                    Text("Powered by Gemini 1.5 Flash for personalized maternal support.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            Button {
                showingApiKeySheet = true
            } label: {
                HStack {
                    Image(systemName: "key.fill")
                    Text("Configure Gemini API Key")
                        .font(.subheadline.bold())
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .foregroundStyle(.white)
                .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color("AccentColor").opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Prompt Suggestions

    private var promptSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Suggestions for you today:")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            ForEach(suggestedPrompts, id: \.self) { prompt in
                Button {
                    sendCustomPrompt(prompt)
                } label: {
                    HStack {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 8)
    }

    // MARK: - Message Row

    private func messageRow(_ message: GeminiChatMessage) -> some View {
        HStack(alignment: .top, spacing: 10) {
            if message.role == .model {
                // MamAmie Avatar
                ZStack {
                    Circle()
                        .fill(Color("AccentColor").opacity(0.12))
                        .frame(width: 32, height: 32)

                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color("AccentColor").opacity(0.2), lineWidth: 1))
                }
            } else {
                Spacer(minLength: 40)
            }

            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.isEmergency, let action = message.emergencyAction {
                    // Urgent Emergency Warning Card
                    emergencyCard(action)
                }

                // Message Body
                Text(.init(message.text))
                    .font(.subheadline)
                    .foregroundStyle(message.role == .user ? .white : .primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        message.role == .user ?
                        Color("AccentColor") :
                        Color(.secondarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .textSelection(.enabled)

                // Timestamp
                Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if message.role == .user {
                // User Avatar
                ZStack {
                    Circle()
                        .fill(Color("AccentColor"))
                        .frame(width: 32, height: 32)
                    Image(systemName: "person.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.white)
                }
            } else {
                Spacer(minLength: 40)
            }
        }
    }

    // MARK: - Emergency Card

    private func emergencyCard(_ action: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.white)
                Text("Urgent Medical Attention Advised")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
            }
            Text(action)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.95))
        }
        .padding(12)
        .background(Color(red: 0.75, green: 0.15, blue: 0.15), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Typing Indicator

    private var typingIndicator: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color("AccentColor").opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color("AccentColor"))
            }

            HStack(spacing: 6) {
                DotPulseAnimation()
                Text("MamAmie is thinking with Gemini…")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))

            Spacer()
        }
    }

    // MARK: - Chat Input Bar

    private var chatInputBar: some View {
        VStack(spacing: 6) {
            HStack(alignment: .bottom, spacing: 10) {
                TextField("Ask MamAmie about symptoms, foods, dates…", text: $input, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(
                            canSend ? Color("AccentColor") : Color.secondary.opacity(0.4)
                        )
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
            }

            Text("MamAmie answers are educational and incorporate your live pregnancy & food context.")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var canSend: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !gemini.isGenerating
    }

    private func sendMessage() {
        let query = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        input = ""

        Task {
            await gemini.sendMessage(
                query,
                profile: onboardingStore?.profile,
                meals: foodDiaryStore?.meals ?? []
            )
        }
    }

    private func sendCustomPrompt(_ prompt: String) {
        input = prompt
        sendMessage()
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let last = gemini.messages.last {
            withAnimation(.easeOut(duration: 0.25)) {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

// MARK: - Dot Pulse Animation

private struct DotPulseAnimation: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color("AccentColor"))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.0 : 0.4)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Gemini API Key Settings Sheet

private struct GeminiApiKeySheet: View {
    @ObservedObject var gemini: GeminiChatService
    @Environment(\.dismiss) private var dismiss

    @State private var keyInput = ""
    @State private var isTesting = false
    @State private var testResult: String?
    @State private var testSuccess: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Google Gemini Integration")
                            .font(.headline)
                        Text("Enter your Google Gemini API key to enable live AI responses. The key is stored locally on your device.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)

                    SecureField("Paste Gemini API Key", text: $keyInput)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    if gemini.isLoadedFromEnvironment {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(.green)
                            Text("Loaded from environment variable (GEMINI_API_KEY)")
                                .font(.caption2.bold())
                                .foregroundStyle(.green)
                        }
                        .padding(.vertical, 2)
                    }

                    if let result = testResult {
                        HStack(spacing: 8) {
                            Image(systemName: testSuccess ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                                .foregroundStyle(testSuccess ? .green : .red)
                            Text(result)
                                .font(.caption)
                                .foregroundStyle(testSuccess ? .green : .red)
                        }
                    }

                    Button {
                        testAndSave()
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isTesting ? "Verifying…" : "Save & Verify Key")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .foregroundStyle(.white)
                        .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .disabled(isTesting || keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    Button {
                        let key = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !key.isEmpty {
                            gemini.setApiKey(key)
                            dismiss()
                        }
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle")
                            Text("Save Key & Close")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if gemini.hasApiKey {
                        Button("Remove Saved Key", role: .destructive) {
                            gemini.clearApiKey()
                            keyInput = ""
                            testResult = nil
                        }
                    }
                } header: {
                    Text("API Key Configuration")
                }

                Section {
                    Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                        HStack {
                            Image(systemName: "safari")
                            Text("Get a Free Gemini Key at Google AI Studio")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                        }
                        .font(.subheadline)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("1. Sign in to Google AI Studio with your Google account.")
                        Text("2. Click 'Create API key' in Google AI Studio.")
                        Text("3. Copy the key and paste it above.")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                } header: {
                    Text("How to get a key")
                }
            }
            .navigationTitle("Gemini Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                keyInput = gemini.activeApiKey
            }
        }
    }

    private func testAndSave() {
        let key = keyInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return }
        // Always save immediately to local storage so user is never blocked
        gemini.setApiKey(key)
        isTesting = true
        testResult = nil

        Task {
            let res = await gemini.testApiKey(key)
            await MainActor.run {
                isTesting = false
                testSuccess = res.success
                testResult = res.message
                if res.success {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Maternal Context Detail Sheet

private struct MaternalContextDetailSheet: View {
    let snapshot: MaternalContextSnapshot
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Here is the exact real-time snapshot of your pregnancy dates and recent food intake included with your message to Gemini:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    VStack(alignment: .leading, spacing: 12) {
                        Text(snapshot.fullContextString)
                            .font(.system(.caption, design: .monospaced))
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(16)
            }
            .navigationTitle("Live AI Context")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

// MARK: - Legacy Helper Sheets for Symptom Triage & Report Explanation

private struct AssistantResponseCard: View {
    let response: AssistantAIResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if response.safetyEscalation {
                Label("Urgent professional assessment", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline).foregroundStyle(.white)
            }
            Text(response.answer)
                .font(.subheadline)
                .foregroundStyle(response.safetyEscalation ? .white : .primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            response.safetyEscalation ? Color(red: 0.63, green: 0.20, blue: 0.16) : Color(.secondarySystemGroupedBackground),
            in: RoundedRectangle(cornerRadius: 14)
        )
    }
}

private struct AssistantTriageSheet: View {
    @ObservedObject var api: AssistantAPIClient
    let stage: String
    @Environment(\.dismiss) private var dismiss
    @State private var symptoms = ""
    @State private var response: AssistantAIResponse?
    @State private var localWarning: String?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Describe what you are experiencing. If it feels like an emergency, seek urgent care immediately.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $symptoms).frame(minHeight: 110)
                } header: { Text("Symptom check") }

                if let localWarning {
                    Section {
                        Text(localWarning)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color(red: 0.63, green: 0.20, blue: 0.16), in: RoundedRectangle(cornerRadius: 10))
                    }
                }

                if let response {
                    Section { AssistantResponseCard(response: response) }
                }

                if let error {
                    Section { Text(error).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle("Check a Symptom")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check") { check() }
                        .disabled(symptoms.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || api.isBusy)
                }
            }
        }
    }

    private func check() {
        let input = symptoms.trimmingCharacters(in: .whitespacesAndNewlines)
        response = nil; error = nil
        if let warning = AssistantSafetyScreening.emergencyMessage(for: "I have \(input)") {
            localWarning = warning
            return
        }
        localWarning = nil
        Task {
            do { response = try await api.triage(input, stage: stage) }
            catch { self.error = "Could not reach the server for symptom triage. If symptoms persist or worsen, contact your doctor." }
        }
    }
}

private struct AssistantReportSheet: View {
    @ObservedObject var api: AssistantAPIClient
    let stage: String
    @Environment(\.dismiss) private var dismiss
    @State private var reportText = ""
    @State private var question = "What do these terms mean?"
    @State private var externalConsent = false
    @State private var response: AssistantAIResponse?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("Paste readable lab or clinic report text to get plain-language educational explanations.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $reportText).frame(minHeight: 140)
                    TextField("What would you like explained?", text: $question, axis: .vertical).lineLimit(2...4)
                } header: { Text("Report text") }

                if let response { Section { AssistantResponseCard(response: response) } }
                if let error { Section { Text(error).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Explain a Report")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Explain") { explain() }
                        .disabled(reportText.count < 10 || question.count < 2 || api.isBusy)
                }
            }
        }
    }

    private func explain() {
        response = nil; error = nil
        Task {
            do { response = try await api.explainReport(reportText, question: question, stage: stage, externalConsent: externalConsent) }
            catch { self.error = error.localizedDescription }
        }
    }
}
