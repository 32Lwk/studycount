import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \StudyTask.sortOrder) private var tasks: [StudyTask]
    @State private var showNew = false
    @State private var draftTitle = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(sortedTasks) { t in
                    TaskRowView(task: t)
                }
                .onDelete(perform: deleteAt)
            }
            .navigationTitle("タスク")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showNew) {
                NavigationStack {
                    Form {
                        TextField("タイトル", text: $draftTitle)
                    }
                    .navigationTitle("新しいタスク")
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("キャンセル") {
                                draftTitle = ""
                                showNew = false
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("追加") {
                                addTask()
                                showNew = false
                            }
                            .disabled(draftTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }

    private var sortedTasks: [StudyTask] {
        tasks.sorted {
            if $0.isCompleted != $1.isCompleted { return !$0.isCompleted }
            if $0.priority != $1.priority { return $0.priority > $1.priority }
            return $0.sortOrder < $1.sortOrder
        }
    }

    private func addTask() {
        let title = draftTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        let next = (tasks.map(\.sortOrder).max() ?? 0) + 1
        let t = StudyTask(title: title, sortOrder: next)
        modelContext.insert(t)
        draftTitle = ""
        WidgetSync.reload()
    }

    private func deleteAt(offsets: IndexSet) {
        for i in offsets {
            modelContext.delete(sortedTasks[i])
        }
        WidgetSync.reload()
    }
}

private struct TaskRowView: View {
    @Bindable var task: StudyTask

    var body: some View {
        HStack(alignment: .top) {
            Toggle("", isOn: $task.isCompleted)
                .labelsHidden()
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                if let d = task.dueDate {
                    Text(d, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let m = task.linkedMaterial {
                    Text(m.name)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
