import SwiftData
import SwiftUI

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudySession.recordDate, order: .reverse) private var sessions: [StudySession]
    @State private var search = ""
    @State private var showEditor = false
    @State private var sessionToEdit: StudySession?

    private var filtered: [StudySession] {
        let q = search.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !q.isEmpty else { return sessions }
        return sessions.filter { s in
            if s.memo.lowercased().contains(q) { return true }
            if let m = s.material, m.name.lowercased().contains(q) { return true }
            if s.tags.contains(where: { $0.name.lowercased().contains(q) }) { return true }
            return false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filtered.isEmpty {
                    ContentUnavailableView(
                        "記録がありません",
                        systemImage: "clock",
                        description: Text("右上の + から勉強時間を追加できます。")
                    )
                } else {
                    List {
                        ForEach(filtered) { session in
                            Button {
                                sessionToEdit = session
                            } label: {
                                SessionRowView(session: session)
                            }
                        }
                        .onDelete(perform: deleteAt)
                    }
                }
            }
            .navigationTitle("記録")
            .searchable(text: $search, prompt: "メモ・教材・タグ")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showEditor) {
                SessionEditorView(existing: nil)
            }
            .sheet(item: $sessionToEdit) { s in
                SessionEditorView(existing: s)
            }
        }
    }

    private func deleteAt(offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(filtered[i])
        }
        WidgetSync.reload()
    }
}

private struct SessionRowView: View {
    let session: StudySession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.recordDate, style: .date)
                Spacer()
                Text("\(session.durationMinutes) 分")
                    .fontWeight(.semibold)
            }
            if let m = session.material {
                Text(m.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if !session.tags.isEmpty {
                Text(session.tags.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if !session.memo.isEmpty {
                Text(session.memo)
                    .font(.caption)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
