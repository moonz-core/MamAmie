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
    @State private var gallerySavedToast = false
    @State private var showSamplePicker = false

    private var todayMeals: [FoodMeal] { store.meals() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection
                    actionButtons
                    sampleMealsSection
                    diarySummaryRow

                    if let latest = store.meals.first {
                        recentMealSection(latest)
                    }

                    if todayMeals.isEmpty {
                        emptyDiaryMessage
                    }

                    footerDisclaimer
                }
                .padding(20)
            }
            .background(Color(.systemBackground))
            .navigationTitle("Food Scanner").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Add a meal photo", isPresented: $showPhotoOptions, titleVisibility: .visible) {
                Button {
                    showPhotoPicker = true
                } label: {
                    Label("Choose from photo library", systemImage: "photo")
                }

                Button {
                    if UIImagePickerController.isSourceTypeAvailable(.camera) {
                        showCamera = true
                    } else {
                        // Simulator friendly: simulate camera capture using sample image
                        if let img = UIImage(named: "sample_spinach_dal") {
                            photo = img
                            showEditor = true
                        } else {
                            showCameraUnavailable = true
                        }
                    }
                } label: {
                    Label(
                        UIImagePickerController.isSourceTypeAvailable(.camera) ? "Take a photo" : "Simulate camera photo (Test meal)",
                        systemImage: "camera"
                    )
                }

                Button {
                    showSamplePicker = true
                } label: {
                    Label("Try a sample maternal meal", systemImage: "sparkles")
                }

                Button {
                    saveSampleMealsToPhotos()
                } label: {
                    Label("Save 3 sample meals to photo library", systemImage: "square.and.arrow.down")
                }

                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Photograph the whole plate in good light, or pick a sample meal for quick testing on Simulator.")
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
                    await MainActor.run {
                        isLoadingPhoto = false
                        photo = resized(image)
                        showEditor = true
                    }
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
            .sheet(isPresented: $showDashboard) {
                FoodDailyDashboardView(store: store, assistantAPI: assistantAPI)
            }
            .sheet(isPresented: $showSamplePicker) {
                sampleMealsSheetView
            }
            .alert("Camera unavailable", isPresented: $showCameraUnavailable) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Camera is not available on Simulator. You can use the Sample Meals or Photo Library.")
            }
            .photosPicker(isPresented: $showPhotoPicker, selection: $selectedPhoto, matching: .images)
            .alert("Could not load photo", isPresented: $photoLoadFailed) {
                Button("OK", role: .cancel) { selectedPhoto = nil }
            } message: {
                Text("Choose another image or enter the meal manually.")
            }
            .overlay {
                if isLoadingPhoto {
                    ProgressView("Loading selected photo…")
                        .padding(20)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
                }
            }
            .alert("Photos Saved", isPresented: $gallerySavedToast) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Saved 3 high-quality maternal meal photos to your device Photo Library! You can now choose them from the Photos picker.")
            }
            .alert("Diary issue", isPresented: Binding(get: { store.errorMessage != nil }, set: { if !$0 { store.errorMessage = nil } })) {
                Button("OK", role: .cancel) { store.errorMessage = nil }
            } message: { Text(store.errorMessage ?? "") }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MATERNAL FOOD & NUTRITION")
                .font(.caption.weight(.bold)).tracking(1.2)
                .foregroundStyle(Color("AccentColor"))
            Text("Nourish your journey.")
                .font(.largeTitle.bold()).foregroundStyle(Color("AccentColor"))
            Text("AI scans every meal for calories, protein, iron, folate, calcium & gives supplement recommendations.")
                .font(.subheadline).foregroundStyle(.secondary)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                showPhotoOptions = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "camera.viewfinder").font(.title2)
                        .frame(width: 48, height: 48).background(.white.opacity(0.18)).clipShape(Circle())
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Scan meal photo").font(.headline)
                        Text("Photo library, camera or sample meal").font(.caption).opacity(0.9)
                    }
                    Spacer()
                    Image(systemName: "arrow.right").font(.headline)
                }
                .foregroundStyle(.white).padding(18)
                .background(Color("AccentColor"), in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain)

            Button {
                photo = nil
                showEditor = true
            } label: {
                Label("Enter a meal manually (Text AI Scan)", systemImage: "square.and.pencil")
                    .font(.subheadline.weight(.semibold)).foregroundStyle(Color("AccentColor"))
                    .frame(maxWidth: .infinity).padding(15)
                    .background(Color("AccentColor").opacity(0.08), in: RoundedRectangle(cornerRadius: 15))
            }.buttonStyle(.plain)
        }
    }

    // MARK: - Sample Meals Section (Simulator Friendly)
    private var sampleMealsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color("AccentColor"))
                    Text("TRY SAMPLE MATERNAL MEALS")
                        .font(.caption2.weight(.bold)).tracking(1)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    saveSampleMealsToPhotos()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save to Gallery")
                    }
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Color("AccentColor"))
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(MaternalFoodAIService.sampleMeals) { meal in
                        Button {
                            if let img = UIImage(named: meal.imageName) {
                                photo = img
                                showEditor = true
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                if let img = UIImage(named: meal.imageName) {
                                    Image(uiImage: img)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 170, height: 110)
                                        .clipped()
                                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                } else {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(.systemGray5))
                                        .frame(width: 170, height: 110)
                                }

                                Text(meal.name)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.primary)
                                    .lineLimit(1)

                                Text(meal.subtitle)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 170)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var sampleMealsSheetView: some View {
        NavigationStack {
            List(MaternalFoodAIService.sampleMeals) { meal in
                Button {
                    if let img = UIImage(named: meal.imageName) {
                        photo = img
                        showSamplePicker = false
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            showEditor = true
                        }
                    }
                } label: {
                    HStack(spacing: 14) {
                        if let img = UIImage(named: meal.imageName) {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipped()
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(meal.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.primary)
                            Text(meal.subtitle)
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Color("AccentColor"))
                            Text(meal.description)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Sample Maternal Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { showSamplePicker = false }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Save All to Gallery") {
                        saveSampleMealsToPhotos()
                    }
                    .font(.caption.weight(.semibold))
                }
            }
        }
    }

    private func saveSampleMealsToPhotos() {
        MaternalFoodAIService.saveSamplePhotosToDeviceGallery { count in
            if count > 0 {
                gallerySavedToast = true
            }
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
            Text("Your diary is just getting started. Add meals as you go; AI will identify nutrient strengths and missing pregnancy gaps.")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(14).background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var footerDisclaimer: some View {
        Text("AI nutritional estimates and supplement recommendations are powered by Google Gemini and aligned with standard pregnancy dietary references (ACOG/WHO). Always consult your OB/GYN or midwife before introducing new high-dose supplements.")
            .font(.caption2).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder private func mealThumbnail(_ data: Data?) -> some View {
        if let data, let image = UIImage(data: data) {
            Image(uiImage: image).resizable().scaledToFill().frame(width: 48, height: 48).clipShape(RoundedRectangle(cornerRadius: 10))
        } else {
            Image(systemName: "fork.knife").font(.title3).foregroundStyle(Color("AccentColor"))
                .frame(width: 48, height: 48).background(Color("AccentColor").opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func resized(_ image: UIImage) -> UIImage {
        let maxDimension: CGFloat = 1024
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else { return image }
        let scale = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
