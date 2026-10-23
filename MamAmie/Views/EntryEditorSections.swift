import PhotosUI
import SwiftUI

extension EntryEditorView {
    var dateSection: some View {
        Section {
            DatePicker("Date", selection: $form.date, displayedComponents: [.date])

            Toggle("Add a time", isOn: $form.includesTime)

            if form.includesTime {
                DatePicker("Time", selection: $form.time, displayedComponents: [.hourAndMinute])
            }
        } header: {
            Text("When")
        } footer: {
            Text("Dates stay tied to your local calendar day. A time is optional.")
        }
    }

    @ViewBuilder
    var categoryFields: some View {
        switch category {
        case .medication: medicationFields
        case .appointment: appointmentFields
        case .test: testFields
        case .symptom: symptomFields
        case .food: foodFields
        case .journal: journalFields
        case .photo: photoFields
        case .milestone: milestoneFields
        case .task: taskFields
        }
    }

    private var medicationFields: some View {
        Group {
            Section("Medication or supplement") {
                TextField("Name", text: $form.title)
                TextField("Dose (as instructed)", text: $form.dose)
                TextField("Instructions", text: $form.instructions, axis: .vertical)
                    .lineLimit(2...4)
                TextField("Schedule or recurrence", text: $form.recurrence)
                TextField("Notes", text: $form.notes, axis: .vertical)
                    .lineLimit(3...6)
            }

            Section {
                Text("MamAmie records the instructions you enter. It does not prescribe medication or change a treatment plan.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var appointmentFields: some View {
        Section("Appointment") {
            TextField("Appointment title", text: $form.title)
            TextField("Doctor or clinic", text: $form.clinicianOrClinic)
            TextField("Location", text: $form.location)
            Picker("Status", selection: $form.appointmentStatus) {
                ForEach(AppointmentStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            TextField("Questions to ask", text: $form.questions, axis: .vertical)
                .lineLimit(3...7)
            TextField("Notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    private var testFields: some View {
        Section("Test or report") {
            TextField("Test or report name", text: $form.title)
            Picker("Report status", selection: $form.reportStatus) {
                ForEach(ReportStatus.allCases) { status in
                    Text(status.displayName).tag(status)
                }
            }
            Toggle("Add a follow-up date", isOn: $form.includesFollowUpDate)
            if form.includesFollowUpDate {
                DatePicker("Follow-up date", selection: $form.followUpDate, displayedComponents: [.date])
            }
            TextField("Notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    private var symptomFields: some View {
        Section("How are you feeling?") {
            TextField("Symptom or experience", text: $form.title)
            Picker("Severity", selection: $form.symptomSeverity) {
                ForEach(SymptomSeverity.allCases) { severity in
                    Text(severity.displayName).tag(severity)
                }
            }
            TextField("Duration, if known", text: $form.duration)
            Toggle("I want to discuss this with my healthcare professional", isOn: $form.discussWithClinician)
            TextField("Personal notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    private var foodFields: some View {
        Section("Food and nutrition") {
            Picker("Meal", selection: $form.meal) {
                ForEach(MealCategory.allCases) { meal in
                    Text(meal.displayName).tag(meal)
                }
            }
            TextField("Food", text: $form.title)
            TextField("Ingredients", text: $form.ingredients, axis: .vertical)
                .lineLimit(2...5)
            TextField("Approximate portion", text: $form.portion)
            TextField("Notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    private var journalFields: some View {
        Section("Personal journal") {
            TextField("Title", text: $form.title)
            TextField("How are you feeling? (optional)", text: $form.mood)
            TextField("Write anything you want to remember", text: $form.notes, axis: .vertical)
                .lineLimit(7...14)
        }
    }

    private var photoFields: some View {
        Section("Photograph or attachment") {
            TextField("Title", text: $form.title)
            TextField("Caption or notes", text: $form.notes, axis: .vertical)
                .lineLimit(4...8)
        }
    }

    private var milestoneFields: some View {
        Section("Milestone") {
            TextField("What happened?", text: $form.title)
            Toggle("This is a personal milestone", isOn: $form.isPersonalMilestone)
            TextField("Notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    private var taskFields: some View {
        Section("Task or reminder") {
            TextField("Task", text: $form.title)
            Toggle("Completed", isOn: $form.taskCompleted)
            TextField("Notes", text: $form.notes, axis: .vertical)
                .lineLimit(3...7)
        }
    }

    var attachmentSection: some View {
        Section {
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Label(
                    selectedPhotoData == nil ? "Choose a photo" : "Choose a different photo",
                    systemImage: "photo.badge.plus"
                )
            }

            if let selectedPhotoData {
                VStack(alignment: .leading, spacing: 8) {
                    SelectedPhotoPreview(data: selectedPhotoData, reloadID: photoPreviewID)
                        .frame(maxHeight: 180)

                    Button("Remove selected photo", role: .destructive) {
                        self.selectedPhotoData = nil
                        self.selectedPhotoItem = nil
                    }
                    .font(.subheadline)
                }
            } else if let existingAttachment = existingEntry?.attachments.first {
                AttachmentThumbnail(reference: existingAttachment, store: store)
                    .frame(maxHeight: 180)
            }
        } header: {
            Text("Attachment (optional)")
        } footer: {
            Text("Photos stay in MamAmie's private local application storage. They are not uploaded.")
        }
    }
}
