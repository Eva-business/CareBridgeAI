import SwiftUI

struct HomeView: View {
    let draft: CareRecipientDraft
    let profilePhoto: ProfilePhotoStore
    let status: CareStatus

    let aiSummary: String
    @Binding var tasks: [CareTask]
    @Binding var memos: [Memo]

    @State private var isMemoExpanded = false
    @State private var newMemoText = ""

    private var nextTask: CareTask? {
        tasks
            .filter { !$0.isDone }
            .sorted { $0.dueDate < $1.dueDate }
            .first
    }

    private var todayTasks: [CareTask] {
        tasks.sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MainHeaderView(
                            title: "首頁",
                            subtitle: "\(draft.name.isEmpty ? "被照護者" : draft.name) 的今日狀態"
                        )

                        recipientCard

                        statusAndSummaryCard

                        nextTaskCard

                        memoCard

                        todayTimelineCard
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private var recipientCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(AppTheme.lightGreen)
                    .frame(width: 66, height: 66)

                if let image = profilePhoto.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 66, height: 66)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(AppTheme.primaryGreen)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(draft.name.isEmpty ? "被照護者" : draft.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(draft.gender)
                        .font(.caption)
                        .foregroundStyle(AppTheme.primaryGreen)
                }

                Text(recipientSubtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var recipientSubtitle: String {
        let relationship = draft.relationship.isEmpty ? "家人" : draft.relationship
        return "\(relationship)・今日照護總覽"
    }

    private var statusAndSummaryCard: some View {
        HStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("今日狀態")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.16))
                        .frame(width: 96, height: 96)

                    Image(systemName: status.icon)
                        .font(.system(size: 48))
                        .foregroundStyle(status.color)
                }

                Text(status.rawValue)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(status.color)

                Text(status.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 120)

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppTheme.primaryGreen)

                    Text("AI 交接摘要")
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Text("過去 24 小時")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(aiSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                Button {
                    print("查看完整摘要")
                } label: {
                    HStack(spacing: 4) {
                        Text("查看完整摘要")
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryGreen)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var nextTaskCard: some View {
        HomeCardView(title: "下一個任務", icon: "list.bullet.rectangle.fill") {
            if let nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextTask.dueDate.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)

                    Text(nextTask.title)
                        .font(.headline)

                    if !nextTask.note.isEmpty {
                        Text(nextTask.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(nextTask.type.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(AppTheme.lightGreen)
                        .clipShape(Capsule())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("目前沒有待辦任務")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var memoCard: some View {
        HomeCardView(title: "個人備忘", icon: "note.text") {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        isMemoExpanded.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memos.isEmpty ? "尚無備忘" : "\(memos.count) 則備忘")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            Text(memos.first?.content ?? "點擊新增個人備忘")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(2)
                        }

                        Spacer()

                        Image(systemName: isMemoExpanded ? "chevron.up" : "chevron.down")
                            .foregroundStyle(AppTheme.primaryGreen)
                    }
                }
                .buttonStyle(.plain)

                if isMemoExpanded {
                    VStack(spacing: 12) {
                        HStack {
                            TextField("新增個人備忘", text: $newMemoText)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(AppTheme.background)
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            Button {
                                addMemo()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                    .frame(width: 42, height: 42)
                                    .background(AppTheme.primaryGreen)
                                    .clipShape(Circle())
                            }
                            .disabled(newMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .opacity(newMemoText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1)
                        }

                        if memos.isEmpty {
                            Text("目前沒有備忘，可以在上方新增。")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(memos) { memo in
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "star.fill")
                                            .foregroundStyle(AppTheme.warningYellow)
                                            .font(.caption)

                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(memo.content)
                                                .font(.subheadline)

                                            Text(memo.createdAt.formatted(date: .numeric, time: .shortened))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }

                                        Spacer()

                                        Button {
                                            deleteMemo(memo)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundStyle(AppTheme.dangerRed)
                                        }
                                    }
                                    .padding()
                                    .background(AppTheme.background)
                                    .clipShape(RoundedRectangle(cornerRadius: 14))
                                }
                            }
                        }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    private var todayTimelineCard: some View {
        HomeCardView(title: "今日行程", icon: "calendar") {
            if todayTasks.isEmpty {
                Text("今日尚無行程")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(todayTasks.enumerated()), id: \.element.id) { index, task in
                        TimelineRowView(
                            task: task,
                            isLast: index == todayTasks.count - 1
                        )
                    }
                }
            }
        }
    }

    private func addMemo() {
        let trimmed = newMemoText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        memos.insert(Memo(content: trimmed), at: 0)
        newMemoText = ""
    }

    private func deleteMemo(_ memo: Memo) {
        memos.removeAll { $0.id == memo.id }
    }
}

struct TimelineRowView: View {
    let task: CareTask
    let isLast: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(spacing: 0) {
                Circle()
                    .fill(task.type == .routine ? AppTheme.primaryGreen : AppTheme.warningYellow)
                    .frame(width: 12, height: 12)

                if !isLast {
                    Rectangle()
                        .fill(Color.gray.opacity(0.25))
                        .frame(width: 2, height: 38)
                }
            }
            .padding(.top, 4)

            Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 52, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if !task.note.isEmpty {
                    Text(task.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 6)
    }
}

#Preview {
    HomeView(
        draft: CareRecipientDraft(),
        profilePhoto: ProfilePhotoStore(),
        status: .good,
        aiSummary: "今日整體狀況穩定，早餐與午餐皆有正常進食，情緒平穩。",
        tasks: .constant([
            CareTask(title: "社區復健", note: "常態任務", dueDate: Date()),
            CareTask(title: "午餐後藥物", note: "血壓藥", dueDate: Date().addingTimeInterval(7200))
        ]),
        memos: .constant([
            Memo(content: "晚上容易腿部抽筋，睡前記得按摩與熱敷。")
        ])
    )
}
