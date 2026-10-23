import SwiftUI

private struct AssistantChatMessage: Identifiable {
    let id = UUID()
    var question: String
    var response: AssistantAIResponse?
    var localSafetyMessage: String?
    var errorMessage: String?
}

struct AssistantView: View {
    @StateObject private var api = AssistantAPIClient()
    @State private var isCreatingAccount = false
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?
    @State private var input = ""
    @State private var stage = "pregnant"
    @State private var externalConsent = false
    @State private var messages: [AssistantChatMessage] = []
    @State private var showingTriage = false
    @State private var showingReport = false

    private let suggestedQuestions = [
        "What happens during antenatal visits?",
        "What does a prenatal screening test mean?",
        "Suggest iron-rich vegetarian foods.",
        "How can I get breastfeeding support?",
    ]

    var body: some View {
        NavigationStack {
            Group {
                if api.isSignedIn {
                    assistantChat
                } else {
                    signInForm
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Ask MamAmie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if api.isSignedIn {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button { showingReport = true } label: { Label("Explain report text", systemImage: "doc.text.magnifyingglass") }
                            Button { showingTriage = true } label: { Label("Check a symptom", systemImage: "cross.case") }
                            Button(role: .destructive) { api.signOut(); messages = [] } label: {
                                Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: { Image(systemName: "ellipsis.circle") }
                        .accessibilityLabel("Assistant options")
                    }
                }
            }
            .sheet(isPresented: $showingTriage) {
                AssistantTriageSheet(api: api, stage: stage)
            }
            .sheet(isPresented: $showingReport) {
                AssistantReportSheet(api: api, stage: stage)
            }
            .alert("MamAmie assistant", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
                Button("OK", role: .cancel) { errorMessage = nil }
            } message: { Text(errorMessage ?? "") }
        }
    }

    private var signInForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 34)).foregroundStyle(Color("AccentColor"))
                    Text("Carefully grounded answers")
                        .font(.title2.bold()).foregroundStyle(Color("AccentColor"))
                    Text("Ask about pregnancy, postpartum recovery, breastfeeding, and newborn care. Answers show the sources used and their review status.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }

                VStack(spacing: 14) {
                    TextField("Secure MamAmie server (HTTPS URL)", text: $api.serverAddress)
                        .textInputAutocapitalization(.never).keyboardType(.URL).autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    if isCreatingAccount {
                        TextField("Your name", text: $fullName).textContentType(.name).textFieldStyle(.roundedBorder)
                    }
                    TextField("Email address", text: $email).textContentType(.emailAddress)
                        .keyboardType(.emailAddress).textInputAutocapitalization(.never).autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                    SecureField("Password", text: $password).textContentType(isCreatingAccount ? .newPassword : .password)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        Task {
                            do {
                                if isCreatingAccount {
                                    try await api.registerAndSignIn(name: fullName, email: email, password: password)
                                } else {
                                    try await api.signIn(email: email, password: password)
                                }
                                password = ""
                            } catch { errorMessage = error.localizedDescription }
                        }
                    } label: {
                        HStack {
                            if api.isBusy { ProgressView().tint(.white) }
                            Text(isCreatingAccount ? "Create account and continue" : "Sign in")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity).padding(14).foregroundStyle(.white)
                        .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(api.isBusy || email.isEmpty || password.count < 8 || (isCreatingAccount && fullName.count < 2))

                    Button(isCreatingAccount ? "I already have an account" : "Create an account") {
                        isCreatingAccount.toggle()
                    }.font(.subheadline.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                }
                .padding(18).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 20))

                Label("Your session token is kept in iOS Keychain. Questions are not saved in the app’s conversation history. The backend stores a one-way question digest and safety flag for audit; pasted report text is not persisted.", systemImage: "lock.shield")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
                Text("The built-in source notes and symptom rules are demonstration material and have not been clinically reviewed. MamAmie is educational and cannot diagnose or rule out a condition.")
                    .font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
            }.padding(20)
        }
    }

    private var assistantChat: some View {
        VStack(spacing: 0) {
            HStack {
                Picker("Care stage", selection: $stage) {
                    Text("Planning").tag("planning")
                    Text("Pregnancy").tag("pregnant")
                    Text("Postpartum").tag("postpartum")
                    Text("Newborn care").tag("newborn")
                }.pickerStyle(.menu)
                Spacer()
                Button { showingTriage = true } label: {
                    Label("Check a symptom", systemImage: "cross.case.fill")
                        .font(.caption.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                }
            }.padding(.horizontal, 16).padding(.vertical, 10)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 16) {
                        if messages.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("What would you like to understand?").font(.title3.bold())
                                Text("I’ll show the source passages and say when the indexed evidence is not enough.")
                                    .font(.subheadline).foregroundStyle(.secondary)
                                ForEach(suggestedQuestions, id: \.self) { question in
                                    Button { input = question } label: {
                                        HStack {
                                            Text(question).font(.subheadline).multilineTextAlignment(.leading)
                                            Spacer()
                                            Image(systemName: "arrow.up.left").font(.caption).foregroundStyle(.secondary)
                                        }
                                        .padding(13).background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 14))
                                    }.buttonStyle(.plain).foregroundStyle(.primary)
                                }
                            }.padding(.top, 14)
                        }

                        ForEach(messages) { message in
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(message.question).font(.subheadline).padding(13)
                                    .foregroundStyle(.white).background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 16))
                                if let localMessage = message.localSafetyMessage {
                                    emergencyCard(localMessage)
                                } else if let response = message.response {
                                    AssistantResponseCard(response: response)
                                } else if let error = message.errorMessage {
                                    Text(error).font(.subheadline).foregroundStyle(.secondary)
                                        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
                                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
                                } else {
                                    ProgressView("Checking sources…").font(.caption).frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }.id(message.id)
                        }
                    }.padding(16)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last { withAnimation { proxy.scrollTo(last.id, anchor: .bottom) } }
                }
            }

            VStack(spacing: 10) {
                Toggle(isOn: $externalConsent) {
                    Text("Allow this question to be sent to the configured AI provider")
                        .font(.caption).foregroundStyle(.secondary)
                }.tint(Color("AccentColor"))
                HStack(alignment: .bottom, spacing: 10) {
                    TextField("Ask a question", text: $input, axis: .vertical)
                        .lineLimit(1...4).textFieldStyle(.roundedBorder)
                        .submitLabel(.send).onSubmit { sendQuestion() }
                    Button(action: sendQuestion) {
                        Image(systemName: "arrow.up.circle.fill").font(.system(size: 34)).foregroundStyle(Color("AccentColor"))
                    }
                    .accessibilityLabel("Send question")
                    .disabled(api.isBusy || input.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
                }
                Text("External processing is off unless you opt in. If enabled, the backend still needs an AI provider and valid credentials.")
                    .font(.caption2).foregroundStyle(.secondary).frame(maxWidth: .infinity, alignment: .leading)
            }.padding(12).background(Color(.secondarySystemGroupedBackground))
        }
    }

    private func sendQuestion() {
        let question = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard question.count >= 2, !api.isBusy else { return }
        input = ""
        if let warning = AssistantSafetyScreening.emergencyMessage(for: question) {
            messages.append(AssistantChatMessage(question: question, response: nil, localSafetyMessage: warning, errorMessage: nil))
            return
        }
        let message = AssistantChatMessage(question: question, response: nil, localSafetyMessage: nil, errorMessage: nil)
        messages.append(message)
        Task {
            do {
                let response = try await api.ask(question, stage: stage, externalConsent: externalConsent)
                updateMessage(id: message.id, response: response, error: nil)
            } catch {
                updateMessage(id: message.id, response: nil, error: error.localizedDescription)
            }
        }
    }

    private func updateMessage(id: UUID, response: AssistantAIResponse?, error: String?) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        messages[index].response = response
        messages[index].errorMessage = error
    }

    private func emergencyCard(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Seek urgent care now", systemImage: "exclamationmark.triangle.fill")
                .font(.headline).foregroundStyle(.white)
            Text(text).font(.subheadline).foregroundStyle(.white)
            Text("On-device demonstration warning screen · not clinically reviewed")
                .font(.caption2).foregroundStyle(.white.opacity(0.86))
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(Color(red: 0.63, green: 0.20, blue: 0.16), in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
    }
}

private struct AssistantResponseCard: View {
    let response: AssistantAIResponse
    @State private var showSources = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if response.safetyEscalation {
                Label("Urgent professional assessment", systemImage: "exclamationmark.triangle.fill")
                    .font(.headline).foregroundStyle(.white)
            }
            Text(response.answer).font(.subheadline).fixedSize(horizontal: false, vertical: true)
                .foregroundStyle(response.safetyEscalation ? .white : .primary)
            if !response.citations.isEmpty {
                DisclosureGroup("Sources (\(response.citations.count))", isExpanded: $showSources) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(response.citations) { citation in
                            VStack(alignment: .leading, spacing: 5) {
                                Text(citation.title).font(.subheadline.weight(.semibold))
                                Text(citation.issuingOrganization).font(.caption).foregroundStyle(.secondary)
                                if let section = citation.section { Text(section).font(.caption).foregroundStyle(.secondary) }
                                if let page = citation.pageNumber { Text("Page \(page)").font(.caption).foregroundStyle(.secondary) }
                                Text(citation.summary).font(.caption).fixedSize(horizontal: false, vertical: true)
                                HStack {
                                    Text(citation.reviewStatus.replacingOccurrences(of: "_", with: " ").capitalized)
                                        .font(.caption2.weight(.semibold)).padding(.horizontal, 8).padding(.vertical, 4)
                                        .background(Color.orange.opacity(0.14), in: Capsule())
                                    if let date = citation.publicationDate {
                                        Text("Published \(date)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                    if let date = citation.lastReviewedDate {
                                        Text("Last reviewed \(date)").font(.caption2).foregroundStyle(.secondary)
                                    }
                                }
                                if let url = citation.originalUrl, let link = URL(string: url) {
                                    Link("Open original source", destination: link).font(.caption.weight(.semibold))
                                }
                            }.padding(11).frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12))
                        }
                    }.padding(.top, 8)
                }.font(.subheadline.weight(.semibold)).tint(response.safetyEscalation ? .white : Color("AccentColor"))
            } else {
                Text("No sources were found for this response.").font(.caption).foregroundStyle(.secondary)
            }
            if !response.limitations.isEmpty {
                Text(response.limitations.joined(separator: " ")).font(.caption).foregroundStyle(response.safetyEscalation ? .white.opacity(0.88) : .secondary)
            }
            Text(response.disclaimer).font(.caption2).foregroundStyle(response.safetyEscalation ? .white.opacity(0.86) : .secondary)
        }
        .padding(15).frame(maxWidth: .infinity, alignment: .leading)
        .background(response.safetyEscalation ? Color(red: 0.63, green: 0.20, blue: 0.16) : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
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
                    Text("Describe what is happening now. If it feels like an emergency, seek care immediately; do not wait for this screen.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    TextEditor(text: $symptoms).frame(minHeight: 110)
                } header: { Text("Symptom check") }
                if let localWarning {
                    Section { emergencyText(localWarning) }
                }
                if let response {
                    Section { AssistantResponseCard(response: response) }
                }
                if let error {
                    Section { Text(error).foregroundStyle(.secondary) }
                }
                Section {
                    Text("This screen is a demonstration ruleset, not a clinical protocol. It cannot diagnose or determine that symptoms are safe. Rules have not been clinically reviewed.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Check a symptom").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Check") { check() }.disabled(symptoms.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || api.isBusy)
                }
            }
            .overlay { if api.isBusy { ProgressView("Checking…").padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14)) } }
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
            catch { self.error = "I could not reach the server. I can’t assess or rule out a concern offline. Contact a healthcare professional, and seek urgent care for severe or worsening symptoms." }
        }
    }

    private func emergencyText(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Seek urgent care now", systemImage: "exclamationmark.triangle.fill").font(.headline).foregroundStyle(.white)
            Text(text).font(.subheadline).foregroundStyle(.white)
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(red: 0.63, green: 0.20, blue: 0.16), in: RoundedRectangle(cornerRadius: 14))
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
                    Text("Paste readable text only. Report text stays in this request and is not saved by MamAmie. Images, PDFs, and OCR are not supported here.")
                        .font(.caption).foregroundStyle(.secondary)
                    TextEditor(text: $reportText).frame(minHeight: 150)
                    TextField("What would you like explained?", text: $question, axis: .vertical).lineLimit(2...4)
                } header: { Text("Report text") }
                Section {
                    Toggle("Allow this report text to be sent to the configured AI provider", isOn: $externalConsent)
                    Text("If turned off, local retrieval only uses selected terms. The text is not independently verified and this tool cannot diagnose or decide whether a result is normal.")
                        .font(.caption).foregroundStyle(.secondary)
                } header: { Text("Privacy and limits") }
                if let response { Section { AssistantResponseCard(response: response) } }
                if response != nil {
                    Section {
                        DisclosureGroup("Text you supplied · not independently verified") {
                            Text(reportText).font(.caption).textSelection(.enabled)
                        }
                    }
                }
                if let error { Section { Text(error).foregroundStyle(.secondary) } }
            }
            .navigationTitle("Explain a report").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Explain") { explain() }.disabled(reportText.count < 10 || question.count < 2 || api.isBusy)
                }
            }
            .overlay { if api.isBusy { ProgressView("Finding educational sources…").padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14)) } }
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
