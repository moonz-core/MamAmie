import SwiftUI
import UIKit

struct AttachmentListView: View {
    let entry: CalendarEntry
    @ObservedObject var store: JournalStore
    let onRemove: (AttachmentReference) -> Void

    @ViewBuilder
    var body: some View {
        if !entry.attachments.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("Attachments")
                    .font(.headline)

                ForEach(entry.attachments) { attachment in
                    HStack(spacing: 12) {
                        AttachmentThumbnail(reference: attachment, store: store)
                            .frame(width: 80, height: 80)

                        Text("Private photo")
                            .font(.subheadline)

                        Spacer()

                        Button {
                            onRemove(attachment)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundStyle(.red)
                        }
                        .accessibilityLabel("Remove attachment")
                    }
                    .padding(10)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
    }
}

struct AttachmentThumbnail: View {
    let reference: AttachmentReference
    @ObservedObject var store: JournalStore
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                ZStack {
                    Color(.tertiarySystemFill)
                    Image(systemName: "photo")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .accessibilityLabel("Attachment preview")
        .task(id: reference.id) {
            guard image == nil, let data = store.attachmentData(for: reference) else { return }
            image = AttachmentImageLoader.thumbnail(from: data, maxPixelSize: 600)
        }
    }
}

struct SelectedPhotoPreview: View {
    let data: Data
    let reloadID: UUID
    @State private var image: UIImage? = nil

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 100)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .task(id: reloadID) {
            image = AttachmentImageLoader.thumbnail(from: data, maxPixelSize: 1_000)
        }
    }
}
