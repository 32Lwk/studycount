import SwiftData
import SwiftUI

struct MaterialListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Material.sortOrder) private var materials: [Material]
    @State private var showEditor = false
    @State private var editing: Material?

    private var visible: [Material] {
        materials.sorted { $0.sortOrder < $1.sortOrder }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(visible) { m in
                    Button {
                        editing = m
                    } label: {
                        HStack {
                            MaterialThumbView(fileName: m.coverImageFileName)
                            VStack(alignment: .leading) {
                                Text(m.name)
                                if m.isArchived {
                                    Text("アーカイブ")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: archiveAt)
            }
            .navigationTitle("教材")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showEditor = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showEditor) {
                MaterialEditorView(material: nil)
            }
            .sheet(item: $editing) { m in
                MaterialEditorView(material: m)
            }
        }
    }

    private func archiveAt(offsets: IndexSet) {
        for i in offsets {
            visible[i].isArchived = true
        }
        WidgetSync.reload()
    }
}

private struct MaterialThumbView: View {
    var fileName: String?

    var body: some View {
        Group {
            if let name = fileName,
               let ui = UIImage(contentsOfFile: ImageStorage.fileURL(forStoredFileName: name).path) {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "book.closed")
                    .foregroundStyle(.secondary)
            }
        }
        .frame(width: 44, height: 56)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
