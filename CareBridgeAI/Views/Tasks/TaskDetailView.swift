import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let task: CareTask
    let onToggleCompletion: () -> Void
    let onDelete: () -> Void

    private var tint: Color {
        task.type == .routine ? AppTheme.primaryGreen : AppTheme.warningYellow
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 22) {
                        headerCard

                        detailCard

                        completionButton

                        deleteButton
                    }
                    .padding(24)
                }
            }
            .navigationTitle(appLanguage.text(en: "Task Details", zhTW: "任務詳細資料"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Close", zhTW: "關閉")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var completionButton: some View {
        Button {
            onToggleCompletion()
            dismiss()
        } label: {
            HStack {
                Image(systemName: task.isDone ? "arrow.uturn.backward.circle.fill" : "checkmark.circle.fill")
                Text(
                    task.isDone
                        ? appLanguage.text(en: "Mark as Incomplete", zhTW: "標記為未完成")
                        : appLanguage.text(en: "Mark as Done", zhTW: "標記為完成")
                )
                    .fontWeight(.bold)
            }
            .foregroundStyle(task.isDone ? AppTheme.warningYellow : .white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(task.isDone ? Color.white : AppTheme.primaryGreen)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }

    private var headerCard: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 82, height: 82)

                Image(systemName: taskIcon)
                    .font(.system(size: 38))
                    .foregroundStyle(tint)
            }

            LocalizedDataText(text: task.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(task.type.displayName(appLanguage))
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(tint)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(tint.opacity(0.12))
                .clipShape(Capsule())
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var detailCard: some View {
        VStack(spacing: 14) {
            TaskDetailRow(
                icon: "clock.fill",
                title: task.type == .routine
                    ? appLanguage.text(en: "Reminder Time", zhTW: "提醒時間")
                    : appLanguage.text(en: "Date & Time", zhTW: "日期與時間"),
                value: task.type == .routine
                    ? task.dueDate.formatted(date: .omitted, time: .shortened)
                    : task.dueDate.formatted(date: .numeric, time: .shortened),
                tint: tint
            )
            
            TaskDetailRow(
                icon: "bell.fill",
                title: appLanguage.text(en: "Notification", zhTW: "通知"),
                value: task.type == .routine
                    ? appLanguage.text(en: "Scheduled by repeat weekdays", zhTW: "依重複星期排程")
                    : appLanguage.text(en: "Scheduled for the selected date", zhTW: "依選定日期排程"),
                tint: tint
            )

            TaskDetailRow(
                icon: task.isDone ? "checkmark.circle.fill" : "circle",
                title: appLanguage.text(en: "Completion Status", zhTW: "完成狀態"),
                value: task.isDone
                    ? appLanguage.text(en: "Done", zhTW: "已完成")
                    : appLanguage.text(en: "Not Done", zhTW: "未完成"),
                tint: task.isDone ? AppTheme.primaryGreen : tint
            )

            if task.type == .routine {
                TaskDetailRow(
                    icon: "repeat",
                    title: appLanguage.text(en: "Repeat Weekdays", zhTW: "重複星期"),
                    value: task.repeatDescription(appLanguage),
                    tint: tint
                )
            }

            TaskDetailRow(
                icon: "doc.text.fill",
                title: appLanguage.text(en: "Notes", zhTW: "備註"),
                value: task.note.isEmpty
                    ? appLanguage.text(en: "No notes", zhTW: "無備註")
                    : task.note,
                tint: tint
            )
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            onDelete()
            dismiss()
        } label: {
            HStack {
                Image(systemName: "trash.fill")
                Text(appLanguage.text(en: "Delete Task", zhTW: "刪除任務"))
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(AppTheme.dangerRed)
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
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

struct TaskDetailRow: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                LocalizedDataText(text: value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TaskDetailView(
        task: CareTask(
            title: "Take medication before breakfast",
            note: "Amlodipine 5 mg for blood pressure",
            dueDate: Date(),
            type: .routine,
            repeatWeekdays: Weekday.allCases
        ),
        onToggleCompletion: {},
        onDelete: {}
    )
}
