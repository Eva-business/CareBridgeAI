import SwiftUI

enum TaskPageTab: String, CaseIterable, Identifiable {
    case calendar = "Calendar"
    case routine = "Routine Tasks"

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .calendar:
            return language.text(en: "Calendar", zhTW: "日程行事曆")
        case .routine:
            return language.text(en: "Routine Tasks", zhTW: "常態任務")
        }
    }
}

struct TasksView: View {
    @Environment(\.appLanguage) private var appLanguage

    let draft: CareRecipientDraft
    @Binding var tasks: [CareTask]

    @State private var selectedTab: TaskPageTab = .calendar
    @State private var selectedDate = Date()
    @State private var showingAddTemporaryTask = false
    @State private var showingAddRoutineTask = false
    @State private var selectedTaskForDetail: CareTask?

    private var selectedDateTasks: [CareTask] {
        tasks
            .filter { task in
                task.occurs(on: selectedDate)
            }
            .sorted {
                Calendar.current.component(.hour, from: $0.dueDate) == Calendar.current.component(.hour, from: $1.dueDate)
                ? Calendar.current.component(.minute, from: $0.dueDate) < Calendar.current.component(.minute, from: $1.dueDate)
                : Calendar.current.component(.hour, from: $0.dueDate) < Calendar.current.component(.hour, from: $1.dueDate)
            }
    }

    private var routineTasks: [CareTask] {
        tasks
            .filter { $0.type == .routine }
            .sorted { $0.dueDate < $1.dueDate }
    }

    private var temporaryTasks: [CareTask] {
        tasks
            .filter { $0.type == .temporary }
            .sorted { $0.dueDate < $1.dueDate }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 20) {
                            MainHeaderView(
                                title: appLanguage.text(en: "Schedule & Tasks", zhTW: "日程任務"),
                                subtitle: appLanguage.text(en: "Calendar view and task management", zhTW: "月曆查看與任務列表管理")
                            )

                            taskTopTabs

                            if selectedTab == .calendar {
                                calendarPage
                            } else {
                                routineTaskPage
                            }
                        }
                        .padding(24)
                        .padding(.bottom, 90)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddTemporaryTask) {
                AddTaskView(
                    fixedType: .temporary,
                    defaultDate: selectedDate
                ) { newTask in
                    tasks.append(newTask)
                    NotificationService.shared.scheduleNotification(for: newTask)
                }
            }
            .sheet(isPresented: $showingAddRoutineTask) {
                AddTaskView(
                    fixedType: .routine,
                    defaultDate: Date()
                ) { newTask in
                    tasks.append(newTask)
                    NotificationService.shared.scheduleNotification(for: newTask)
                }
            }
            .sheet(item: $selectedTaskForDetail) { task in
                TaskDetailView(
                    task: task,
                    onToggleCompletion: {
                        toggleTaskCompletion(task)
                        selectedTaskForDetail = nil
                    },
                    onDelete: {
                        deleteTask(task)
                        selectedTaskForDetail = nil
                    }
                )
            }
        }
    }

    private var taskTopTabs: some View {
        HStack(spacing: 0) {
            ForEach(TaskPageTab.allCases) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 10) {
                        Text(tab.title(appLanguage))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedTab == tab ? AppTheme.primaryGreen : .secondary)

                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.primaryGreen : Color.clear)
                            .frame(height: 3)
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 4)
        .background(Color.white.opacity(0.001))
    }

    private var calendarPage: some View {
        VStack(spacing: 20) {
            calendarCard

            selectedDateScheduleCard
        }
    }

    private var routineTaskPage: some View {
        VStack(spacing: 20) {
            routineTaskListCard
        }
    }

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button {
                    changeMonth(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppTheme.primaryGreen)
                }

                Spacer()

                Text(monthTitle)
                    .font(.title2)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    changeMonth(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .foregroundStyle(AppTheme.primaryGreen)
                }

                Button {
                    selectedDate = Date()
                } label: {
                    Text(appLanguage.text(en: "Today", zhTW: "今天"))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(AppTheme.lightGreen)
                        .clipShape(Capsule())
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 12) {
                ForEach(appLanguage.isChinese ? ["日", "一", "二", "三", "四", "五", "六"] : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { weekday in
                    Text(weekday)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                }

                ForEach(calendarDays, id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Color.clear
                            .frame(height: 44)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let dayTasks = tasks.filter {
            $0.occurs(on: date)
        }

        return Button {
            selectedDate = date
        } label: {
            VStack(spacing: 5) {
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.subheadline)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .white : .primary)

                HStack(spacing: 3) {
                    ForEach(0..<min(dayTasks.count, 3), id: \.self) { index in
                        Circle()
                            .fill(dotColor(index))
                            .frame(width: 5, height: 5)
                    }
                }
                .frame(height: 6)
            }
            .frame(height: 44)
            .frame(maxWidth: .infinity)
            .background(
                isSelected
                ? AppTheme.primaryGreen
                : isToday
                    ? AppTheme.lightGreen
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private func dotColor(_ index: Int) -> Color {
        switch index {
        case 0:
            return AppTheme.primaryGreen
        case 1:
            return AppTheme.warningYellow
        default:
            return .purple
        }
    }

    private var selectedDateScheduleCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(appLanguage.text(en: "Schedule for \(selectedDate.formatted(.dateTime.month().day().weekday(.wide)))", zhTW: "\(selectedDate.formatted(.dateTime.month().day().weekday(.wide))) 的行程"))
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(appLanguage.text(en: "Includes routine tasks and one-time tasks for this day", zhTW: "包含常態任務與該日單次任務"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    showingAddTemporaryTask = true
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "plus")
                        Text(appLanguage.text(en: "Add Task", zhTW: "新增任務"))
                    }
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .overlay {
                        Capsule()
                            .stroke(AppTheme.primaryGreen.opacity(0.35), lineWidth: 1)
                    }
                }
            }

            if selectedDateTasks.isEmpty {
                emptyScheduleView
            } else {
                VStack(spacing: 10) {
                    ForEach(selectedDateTasks) { task in
                        CalendarScheduleRowView(
                            task: task,
                            onTap: {
                                selectedTaskForDetail = task
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var emptyScheduleView: some View {
        VStack(spacing: 10) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 42))
                .foregroundStyle(AppTheme.primaryGreen)

            Text(appLanguage.text(en: "No tasks for this day", zhTW: "這一天尚無任務"))
                .font(.headline)

            Text(appLanguage.text(en: "You can add a one-time task here. Manage routine tasks in the task list.", zhTW: "你可以新增單次任務，常態任務則請到任務列表管理。"))
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var routineTaskListCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            taskListHeader(
                title: appLanguage.text(en: "Routine Tasks", zhTW: "常態任務"),
                subtitle: appLanguage.text(en: "Care tasks repeated daily or on fixed days", zhTW: "每天或固定時間重複執行的照護任務"),
                icon: "repeat",
                tint: AppTheme.primaryGreen,
                buttonTitle: appLanguage.text(en: "Add Routine Task", zhTW: "新增常態任務"),
                action: {
                    showingAddRoutineTask = true
                }
            )

            if routineTasks.isEmpty {
                Text(appLanguage.text(en: "No routine tasks yet", zhTW: "目前沒有常態任務"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.background)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(spacing: 10) {
                    ForEach(routineTasks) { task in
                        TaskListRowView(
                            task: task,
                            tint: AppTheme.primaryGreen,
                            onTap: {
                                selectedTaskForDetail = task
                            },
                            onToggleCompletion: {
                                toggleTaskCompletion(task)
                            },
                            onDelete: {
                                deleteTask(task)
                            }
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func taskListHeader(
        title: String,
        subtitle: String,
        icon: String,
        tint: Color,
        buttonTitle: String,
        action: @escaping () -> Void
    ) -> some View {
        HStack(alignment: .top) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(tint)
                    .frame(width: 34, height: 34)
                    .background(tint.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button(action: action) {
                HStack(spacing: 5) {
                    Image(systemName: "plus")
                    Text(buttonTitle)
                }
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .overlay {
                    Capsule()
                        .stroke(tint.opacity(0.4), lineWidth: 1)
                }
            }
        }
    }

    private var monthTitle: String {
        selectedDate.formatted(.dateTime.year().month(.wide))
    }

    private var calendarDays: [Date?] {
        let calendar = Calendar.current

        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedDate),
              let firstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start),
              let lastWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end.addingTimeInterval(-1))
        else {
            return []
        }

        var days: [Date?] = []
        var current = firstWeek.start

        while current < lastWeek.end {
            if calendar.isDate(current, equalTo: selectedDate, toGranularity: .month) {
                days.append(current)
            } else {
                days.append(nil)
            }

            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current.addingTimeInterval(86400)
        }

        return days
    }

    private func changeMonth(_ value: Int) {
        selectedDate = Calendar.current.date(byAdding: .month, value: value, to: selectedDate) ?? selectedDate
    }

    private func deleteTask(_ task: CareTask) {
        NotificationService.shared.cancelNotification(for: task)
        tasks.removeAll { $0.id == task.id }
    }

    private func toggleTaskCompletion(_ task: CareTask) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }

        tasks[index].isDone.toggle()
        if tasks[index].isDone {
            NotificationService.shared.cancelNotification(for: tasks[index])
        } else {
            NotificationService.shared.scheduleNotification(for: tasks[index])
        }
    }
}

struct CalendarScheduleRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let task: CareTask
    let onTap: () -> Void

    private var tint: Color {
        task.type == .routine ? AppTheme.primaryGreen : AppTheme.warningYellow
    }

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                Text(task.dueDate.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.secondary)
                    .frame(width: 48, alignment: .leading)

                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 46, height: 46)

                    Image(systemName: taskIcon)
                        .font(.title3)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 4) {
                    LocalizedDataText(text: task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)

                    if !task.note.isEmpty {
                        LocalizedDataText(text: task.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(task.type == .routine ? task.repeatDescription(appLanguage) : task.type.displayName(appLanguage))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(tint)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var taskIcon: String {
        let normalizedTitle = task.title.careBridgeEnglishTaskDisplayValue.localizedLowercase
        if normalizedTitle.contains("medication") || normalizedTitle.contains("medicine") {
            return "pills.fill"
        } else if normalizedTitle.contains("blood pressure") || normalizedTitle.contains("measure") {
            return "heart.text.square.fill"
        } else if normalizedTitle.contains("eat") || normalizedTitle.contains("drink") || normalizedTitle.contains("meal") {
            return "fork.knife"
        } else if normalizedTitle.contains("rehab") || normalizedTitle.contains("exercise") {
            return "figure.walk"
        } else if normalizedTitle.contains("follow-up") || normalizedTitle.contains("doctor") || normalizedTitle.contains("clinic") {
            return "calendar.badge.clock"
        } else {
            return task.type == .routine ? "repeat" : "calendar"
        }
    }
}

struct TaskListRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let task: CareTask
    let tint: Color
    let onTap: () -> Void
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(tint.opacity(0.14))
                        .frame(width: 48, height: 48)

                    Image(systemName: taskIcon)
                        .font(.title3)
                        .foregroundStyle(tint)
                }

                VStack(alignment: .leading, spacing: 5) {
                    LocalizedDataText(text: task.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .strikethrough(task.isDone)

                    if !task.note.isEmpty {
                        LocalizedDataText(text: task.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(task.repeatDescription(appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Menu {
                    Button {
                        onToggleCompletion()
                    } label: {
                        Label(
                            task.isDone
                                ? appLanguage.text(en: "Mark as Incomplete", zhTW: "標記為未完成")
                                : appLanguage.text(en: "Mark as Done", zhTW: "標記為完成"),
                            systemImage: task.isDone ? "arrow.uturn.backward.circle" : "checkmark.circle"
                        )
                    }

                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label(appLanguage.text(en: "Delete Task", zhTW: "刪除任務"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundStyle(.secondary)
                        .frame(width: 34, height: 34)
                        .contentShape(Rectangle())
                }
            }
            .padding()
            .background(AppTheme.background)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }

    private var taskIcon: String {
        let normalizedTitle = task.title.careBridgeEnglishTaskDisplayValue.localizedLowercase
        if normalizedTitle.contains("medication") || normalizedTitle.contains("medicine") {
            return "pills.fill"
        } else if normalizedTitle.contains("blood pressure") || normalizedTitle.contains("measure") {
            return "heart.text.square.fill"
        } else if normalizedTitle.contains("eat") || normalizedTitle.contains("drink") || normalizedTitle.contains("meal") {
            return "fork.knife"
        } else if normalizedTitle.contains("rehab") || normalizedTitle.contains("exercise") {
            return "figure.walk"
        } else if normalizedTitle.contains("follow-up") || normalizedTitle.contains("doctor") || normalizedTitle.contains("clinic") {
            return "calendar.badge.clock"
        } else {
            return task.type == .routine ? "repeat" : "calendar"
        }
    }
}

#Preview {
    TasksView(
        draft: CareRecipientDraft(),
        tasks: .constant([
            CareTask(title: "Take medication before breakfast", note: "Amlodipine 5 mg for blood pressure", dueDate: Date(), type: .routine),
            CareTask(title: "Measure blood pressure", note: "Blood pressure record", dueDate: Date(), type: .routine),
            CareTask(title: "Follow-up: Cardiology", note: "Health clinic / Dr. Chang", dueDate: Date(), type: .temporary)
        ])
    )
}
