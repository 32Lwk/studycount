import SwiftData
import SwiftUI

struct SessionEditorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    /// `nil` で新規、値があれば編集
    var existing: StudySession?

    @Query(sort: \Material.sortOrder) private var materials: [Material]
    @Query(sort: \Tag.sortOrder) private var tags: [Tag]

    @State private var recordDate = Date()
    @State private var durationMinutes = 30
    @State private var memo = ""
    @State private var selectedMaterial: Material?
    @State private var selectedTagIDs: Set<PersistentIdentifier> = []

    private var activeMaterials: [Material] {
        materials.filter { !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            Form {
                DatePicker("日付", selection: $recordDate, displayedComponents: [.date, .hourAndMinute])
                Stepper("時間（分）: \(durationMinutes)", value: $durationMinutes, in: 1 ... 24 * 60, step: 5)
                Picker("教材", selection: $selectedMaterial) {
                    Text("なし").tag(Optional<Material>.none)
                    ForEach(activeMaterials) { m in
                        Text(m.name).tag(Optional(m))
                    }
                }
                Section("タグ") {
                    ForEach(tags) { t in
                        Toggle(isOn: Binding(
                            get: { selectedTagIDs.contains(t.persistentModelID) },
                            set: { on in
                                if on { selectedTagIDs.insert(t.persistentModelID) }
                                else { selectedTagIDs.remove(t.persistentModelID) }
                            }
                        )) {
                            Text(t.name)
                        }
                    }
                }
                Section("メモ") {
                    TextField("メモ", text: $memo, axis: .vertical)
                        .lineLimit(3 ... 8)
                }
            }
            .navigationTitle(existing == nil ? "記録を追加" : "記録を編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        save()
                        dismiss()
                    }
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let s = existing else { return }
        recordDate = s.recordDate
        durationMinutes = s.durationMinutes
        memo = s.memo
        selectedMaterial = s.material
        selectedTagIDs = Set(s.tags.map(\.persistentModelID))
    }

    private func save() {
        let tagObjs = tags.filter { selectedTagIDs.contains($0.persistentModelID) }
        if let s = existing {
            s.recordDate = recordDate
            s.durationMinutes = durationMinutes
            s.memo = memo
            s.material = selectedMaterial
            s.tags = tagObjs
        } else {
            let s = StudySession(
                recordDate: recordDate,
                durationMinutes: durationMinutes,
                memo: memo,
                material: selectedMaterial,
                tags: tagObjs
            )
            modelContext.insert(s)
        }
        WidgetSync.reload()
    }
}
