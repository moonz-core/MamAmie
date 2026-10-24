import PhotosUI
import SwiftUI
import UIKit

struct FoodScannerView: View {
    @ObservedObject var store: FoodDiaryStore
    var journalStore: JournalStore? = nil
    var profile: OnboardingProfile? = nil
    @ObservedObject var assistantAPI: AssistantAPIClient
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photo: UIImage?
    @State private var showCamera = false
    @State private var showEditor = false
    @State private var showDashboard = false
    @State private var showPhotoOptions = false
    @State private var showPhotoPicker = false
    @State private var isLoadingPhoto = false
    @State private var photoLoadFailed = false
    @State private var showCameraUnavailable = false

    private var todayMeals: [FoodMeal] { store.meals() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    actionButtons
                    diarySummaryRow

                    if let latest = store.meals.first {
                        recentMealSection(latest)
                    }

                    if todayMeals.isEmpty {
                        emptyDiaryMessage
                    }

                    footerDisclaimer
                }.padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Food scanner").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Add a meal photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button { showPhotoPicker = true } label: {
                    Label("Choose from photo library", systemImage: "photo")
                }
                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) { showCamera = true }
                    else { showCameraUnavailable = true }
                } label: {
                    Label("Take a photo", systemImage: "camera")
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Photograph the whole plate in good light. Avoid including faces or personal documents.")
            }
            .onChange(of: selectedPhoto) { item in
                guard let item else { return }
                isLoadingPhoto = true
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data) else {
                        await MainActor.run { isLoadingPhoto = false; photoLoadFailed = true }
                        return
                    }
                    await MainActor.run { isLoadingPhoto = false; photo = resized(image); showEditor = true }
                }
            }
            .sheet(isPresented: $showCamera) {
                CameraCaptureView { image in
                    photo = resized(image)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showEditor = true }
                }
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showEditor) {
                FoodMealEditorView(
                    store: store,
                    image: photo,
                    journalStore: journalStore,
                    profile: profile,
                    assistantAPI: assistantAPI
                )
            }
            .sheet(isPresented: $showDashboard) { FoodDailyDashboardView(store: store, assistantAPI: assistantAPI) }
            .alert("Camera unavailable", isPresented: $showCameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: { Text("Use photo library or enter the meal manually on this device.") }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .alert("Could not load photo", isPresented: $photoLoadFailed) {
                Button("OK", role: .cancel) { selectedPhoto = nil }
            } message: { Text("Choose another image or enter the meal manually.") }
            .overlay {
                if isLoadingPhoto {
                    ProgressView("Loading selected photo…")
                        .padding(20).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Diary issue", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("FOOD & NUTRITION")
                .font(.caption.weight(.bold)).tracking(1.2)
                .foregroundStyle(Color("AccentColor"))
            Text("Understand every bite.")
                .font(.largeTitle.bold()).foregroundStyle(Color("AccentColor"))
            Text("Keep a thoughtful food diary and see what is known about your meals.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button { showPhotoOptions = true } label: {
                HStack(spacing: 14) {
                    Image(systemName: "camera.viewfinder").font(.title2)
                        .frame(width: 48, height: 48).background(.white.opacity(0.18)).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan your meal").font(.headline)
                        Text("Take or choose a food photo").font(.caption).opacity(0.9)
                    }
                    Spacer()
                    Image(systemName: "arrow.right").font(.headline)
                }
                .foregroundStyle(.white).padding(18)
                .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain)

            Button { photo = nil; showEditor = true } label: {
                Label("Enter a meal manually", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                    .frame(maxWidth: .infinity).padding(15)
                    .background(Color("AccentColor").opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            }.buttonStyle(.plain)
        }
    }

    private var diarySummaryRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Today’s food diary").font(.headline)
                Text("\(todayMeals.count) \(todayMeals.count == 1 ? "meal" : "meals") logged")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Button("Daily summary") { showDashboard = true }
                .font(.caption.weight(.semibold)).foregroundStyle(Color("AccentColor"))
        }
    }

    @ViewBuilder
    private func recentMealSection(_ latest: FoodMeal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("RECENT MEAL").font(.caption2.weight(.bold)).tracking(1).foregroundStyle(.secondary)
            NavigationLink {
                FoodMealDetailView(meal: latest, store: store, assistantAPI: assistantAPI)
            } label: {
                HStack(spacing: 12) {
                    mealThumbnail(latest.imageData)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(latest.name).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        Text(latest.loggedAt, style: .date).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }.padding(12).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
            }.buttonStyle(.plain)
        }
    }

    private var emptyDiaryMessage: some View {
        HStack(spacing: 12) {
            Image(systemName: "leaf").foregroundStyle(Color("AccentColor"))
            Text("Your diary is just getting started. Add meals as you go; an incomplete log is not a measure of your nutrition.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(14).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var footerDisclaimer: some View {
        Text("Photo analysis uses the configured MamAmie AI provider after sign-in. Results are estimates; review foods and portions before saving.")
            .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func mealThumbnail(_ data: Data?) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 54, height: 54).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: "fork.knife.circle.fill").font(.title).foregroundStyle(Color("AccentColor"))
                .frame(width: 54, height: 54).background(Color("AccentColor").opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        }
    }
}

private func resized(_ image: UIImage) -> UIImage {
    let maxDimension: CGFloat = 1400
    let scale = min(1, maxDimension / max(image.size.width, image.size.height))
    guard scale < 1 else { return image }
    let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
    return UIGraphicsImageRenderer(size: size).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
}

private struct CameraCaptureView: UIViewControllerRepresentable {
    var onCapture: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) { }
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraCaptureView
        init(_ parent: CameraCaptureView) { self.parent = parent }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage { parent.onCapture(image) }
            parent.dismiss()
        }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
    }
}
