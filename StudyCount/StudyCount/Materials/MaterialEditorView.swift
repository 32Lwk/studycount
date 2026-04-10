import PhotosUI
import SwiftData
import SwiftUI
import UIKit

struct MaterialEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var material: Material?

    @State private var name = ""
    @State private var isArchived = false
    @State private var coverFileName: String?
    @State private var isbnInput = ""
    @State private var isFetching = false
    @State private var fetchMessage: String?
    @State private var photoItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var showISBNPrivacy = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic") {
                    TextField("Title", text: $name)
                    Toggle("Archived", isOn: $isArchived)
                }
                Section("Cover image") {
                    HStack {
                        coverPreview
                        PhotosPicker("Photos", selection: $photoItem, matching: .images)
                        Button("Camera") { showCamera = true }
                    }
                    if coverFileName == nil {
                        Text("Add a cover to spot materials faster in the list.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                Section {
                    Text("ISBN is sent once to openBD per lookup. No automatic fallback to other APIs.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("ISBN", text: $isbnInput)
                        .keyboardType(.numbersAndPunctuation)
                    Button {
                        showISBNPrivacy = true
                    } label: {
                        Label("Lookup with openBD", systemImage: "barcode.viewfinder")
                    }
                    .disabled(isbnInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFetching)
                    if isFetching { ProgressView() }
                    if let fetchMessage { Text(fetchMessage).font(.caption).foregroundStyle(.secondary) }
                }
            }
            .navigationTitle(material == nil ? "Add material" : "Edit material")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear(perform: load)
            .onChange(of: photoItem) { _, new in
                Task { await loadPhoto(new) }
            }
            .sheet(isPresented: $showCamera) {
                CameraPicker { image in
                    if let image {
                        Task { await saveImage(image) }
                    }
                }
            }
            .alert("ISBN & openBD", isPresented: $showISBNPrivacy) {
                Button("Cancel", role: .cancel) {}
                Button("Send & import") {
                    Task { await fetchOpenBD() }
                }
            } message: {
                Text("The ISBN you entered will be sent to openBD servers. Network required.")
            }
        }
    }

    @ViewBuilder
    private var coverPreview: some View {
        if let name = coverFileName,
           let ui = UIImage(contentsOfFile: ImageStorage.fileURL(forStoredFileName: name).path) {
            Image(uiImage: ui)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.secondarySystemFill))
                .frame(width: 56, height: 72)
                .overlay { Image(systemName: "photo").foregroundStyle(.secondary) }
        }
    }

    private func load() {
        guard let m = material else { return }
        name = m.name
        isArchived = m.isArchived
        coverFileName = m.coverImageFileName
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let m = material {
            m.name = trimmed
            m.isArchived = isArchived
            m.coverImageFileName = coverFileName
        } else {
            let maxOrder = (try? modelContext.fetch(FetchDescriptor<Material>()))?.map(\.sortOrder).max() ?? 0
            let m = Material(name: trimmed, sortOrder: maxOrder + 1, isArchived: isArchived, coverImageFileName: coverFileName)
            modelContext.insert(m)
        }
        WidgetSync.reload()
    }

    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await saveImage(image)
    }

    @MainActor
    private func saveImage(_ image: UIImage) async {
        do {
            if let old = coverFileName { ImageStorage.deleteIfExists(fileName: old) }
            let fn = try ImageStorage.saveResizedImage(image)
            coverFileName = fn
        } catch {
            fetchMessage = error.localizedDescription
        }
    }

    private func fetchOpenBD() async {
        isFetching = true
        fetchMessage = nil
        defer { isFetching = false }
        do {
            let info = try await OpenBDClient.fetchWithRetry(isbn: isbnInput)
            await MainActor.run {
                if let t = info.title, !t.isEmpty { name = t }
            }
            if let url = info.coverImageURL {
                let data = try await OpenBDClient.downloadCover(from: url)
                if let img = UIImage(data: data) {
                    await saveImage(img)
                }
            } else {
                await MainActor.run {
                    fetchMessage = "No cover URL. Add an image from Photos or Camera."
                }
            }
        } catch {
            await MainActor.run {
                fetchMessage = error.localizedDescription
            }
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage?) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let p = UIImagePickerController()
        p.sourceType = .camera
        p.delegate = context.coordinator
        return p
    }

    func updateUIViewController(_: UIImagePickerController, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(_ parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_: UIImagePickerController) {
            parent.onImage(nil)
            parent.dismiss()
        }

        func imagePickerController(_: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            let img = info[.originalImage] as? UIImage
            parent.onImage(img)
            parent.dismiss()
        }
    }
}
