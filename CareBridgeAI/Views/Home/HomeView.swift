import SwiftUI

struct HomeView: View {
    @Environment(\.appLanguage) private var appLanguage

    let draft: CareRecipientDraft
    let profilePhoto: ProfilePhotoStore
    let status: CareStatus

    let aiSummary: String
    let summaryUsesOnDeviceModel: Bool
    @Binding var tasks: [CareTask]
    @Binding var memos: [Memo]

    @State private var isMemoExpanded = false
    @State private var newMemoText = ""
    @State private var showingFullSummary = false

    private var recipientDisplayName: String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return appLanguage.text(en: "Care Recipient", zhTW: "被照護者") }
        if appLanguage.isJapanese {
            return name.containsCareBridgeCJKText ? appLanguage.text(en: "Care Recipient", zhTW: "被照護者") : name
        }
        return appLanguage.isChinese ? name : (name.containsCareBridgeCJKText ? "Care Recipient" : name)
    }

    private var displayedAISummary: String {
        aiSummary.localizedCareText(appLanguage)
    }

    private var nextTask: CareTask? {
        tasks
            .compactMap { task -> (task: CareTask, occurrence: Date)? in
                guard !task.isDone,
                      let occurrence = task.nextOccurrence()
                else {
                    return nil
                }

                return (task, occurrence)
            }
            .sorted { $0.occurrence < $1.occurrence }
            .map(\.task)
            .first
    }

    private var todayTasks: [CareTask] {
        tasks
            .filter { $0.occurs(on: Date()) }
            .sorted {
                let calendar = Calendar.current
                let lhsHour = calendar.component(.hour, from: $0.dueDate)
                let rhsHour = calendar.component(.hour, from: $1.dueDate)

                if lhsHour == rhsHour {
                    return calendar.component(.minute, from: $0.dueDate) < calendar.component(.minute, from: $1.dueDate)
                }

                return lhsHour < rhsHour
            }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MainHeaderView(
                            title: appLanguage.text(en: "Home", zhTW: "首頁"),
                            subtitle: appLanguage.text(
                                en: "Today's status for \(recipientDisplayName)",
                                zhTW: "\(recipientDisplayName) 的今日狀態"
                            )
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
            .dismissKeyboardOnTap()
            .sheet(isPresented: $showingFullSummary) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Label(appLanguage.text(en: "AI Handoff Summary", zhTW: "AI 交接摘要"), systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primaryGreen)

                        Label(status.displayName(appLanguage), systemImage: status.icon)
                            .font(.headline)
                            .foregroundStyle(status.color)

                        LocalizedDataText(text: aiSummary)
                            .font(.body)
                            .lineSpacing(6)

                        Text(summaryUsesOnDeviceModel ? appLanguage.text(en: "Apple Foundation Models - On-device", zhTW: "Apple Foundation Models - 裝置端生成") : appLanguage.text(en: "Smart fallback summary", zhTW: "智慧備援摘要"))
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(AppTheme.background.ignoresSafeArea())
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(appLanguage.text(en: "Done", zhTW: "完成")) { showingFullSummary = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
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
                    Text(recipientDisplayName)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(draft.gender.localizedProfileValue(appLanguage))
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
        let relationship = draft.relationship.isEmpty ? appLanguage.text(en: "Family", zhTW: "家人") : draft.relationship.localizedProfileValue(appLanguage)
        return appLanguage.text(en: "\(relationship) - Today's care overview", zhTW: "\(relationship) - 今日照護總覽")
    }

    private var statusAndSummaryCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.16))
                        .frame(width: 64, height: 64)

                    Image(systemName: status.icon)
                        .font(.system(size: 32))
                        .foregroundStyle(status.color)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(appLanguage.text(en: "Today's Status", zhTW: "今日狀態"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(status.displayName(appLanguage))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(status.color)

                    Text(status.description(appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Divider()

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(AppTheme.primaryGreen)

                        Text(appLanguage.text(en: "AI Handoff Summary", zhTW: "AI 交接摘要"))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)

                        Spacer()
                    }

                    HStack(spacing: 8) {
                        Text(summaryUsesOnDeviceModel ? appLanguage.text(en: "On-device AI", zhTW: "裝置端 AI") : appLanguage.text(en: "Smart fallback", zhTW: "智慧備援"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primaryGreen)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(AppTheme.lightGreen)
                            .clipShape(Capsule())

                        Text(appLanguage.text(en: "Past 24 hours", zhTW: "過去 24 小時"))
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Spacer()
                    }
                }

                LocalizedDataText(text: aiSummary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                Button {
                    showingFullSummary = true
                } label: {
                    HStack(spacing: 4) {
                        Text(appLanguage.text(en: "View full summary", zhTW: "查看完整摘要"))
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
        HomeCardView(title: appLanguage.text(en: "Next Task", zhTW: "下一個任務"), icon: "list.bullet.rectangle.fill") {
            if let nextTask {
                VStack(alignment: .leading, spacing: 8) {
                    Text(nextTask.dueDate.formatted(date: .omitted, time: .shortened))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)

                    LocalizedDataText(text: nextTask.title)
                        .font(.headline)

                    if !nextTask.note.isEmpty {
                        LocalizedDataText(text: nextTask.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(nextTask.type.displayName(appLanguage))
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
                Text(appLanguage.text(en: "No pending tasks", zhTW: "目前沒有待辦任務"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var memoCard: some View {
        HomeCardView(title: appLanguage.text(en: "Personal Notes", zhTW: "個人備忘"), icon: "note.text") {
            VStack(spacing: 12) {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        isMemoExpanded.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(memos.isEmpty ? appLanguage.text(en: "No notes yet", zhTW: "尚無備忘") : appLanguage.text(en: "\(memos.count) note(s)", zhTW: "\(memos.count) 則備忘"))
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)

                            if let firstMemo = memos.first {
                                LocalizedDataText(text: firstMemo.content)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            } else {
                                Text(appLanguage.text(en: "Tap to add a personal note", zhTW: "點擊新增個人備忘"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
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
                            TextField(appLanguage.text(en: "Add a personal note", zhTW: "新增個人備忘"), text: $newMemoText)
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
                            Text(appLanguage.text(en: "No notes yet. Add one above.", zhTW: "目前沒有備忘，可以在上方新增。"))
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
                                            LocalizedDataText(text: memo.content)
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
        HomeCardView(title: appLanguage.text(en: "Today's Schedule", zhTW: "今日行程"), icon: "calendar") {
            if todayTasks.isEmpty {
                Text(appLanguage.text(en: "No schedule for today", zhTW: "今日尚無行程"))
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
    @Environment(\.appLanguage) private var appLanguage

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
                LocalizedDataText(text: task.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                if !task.note.isEmpty {
                    LocalizedDataText(text: task.note)
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
        aiSummary: "Overall status is stable today. Breakfast and lunch intake were normal, and mood was calm.",
        summaryUsesOnDeviceModel: true,
        tasks: .constant([
            CareTask(title: "Community rehab", note: "Routine task", dueDate: Date()),
            CareTask(title: "Medication after lunch", note: "Blood pressure medication", dueDate: Date().addingTimeInterval(7200))
        ]),
        memos: .constant([
            Memo(content: "Leg cramps happen easily at night. Remember massage and warm compress before bed.")
        ])
    )
}
