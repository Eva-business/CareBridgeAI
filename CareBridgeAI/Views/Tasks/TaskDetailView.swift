import SwiftUI

struct TaskDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let task: CareTask
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

                        deleteButton
                    }
                    .padding(24)
                }
            }
            .navigationTitle("任務詳情")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("關閉") {
                        dismiss()
                    }
                }
            }
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

            Text(task.title)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text(task.type.rawValue)
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
                title: task.type == .routine ? "提醒時間" : "日期與時間",
                value: task.type == .routine
                    ? task.dueDate.formatted(date: .omitted, time: .shortened)
                    : task.dueDate.formatted(date: .numeric, time: .shortened),
                tint: tint
            )
            
            TaskDetailRow(
                icon: "bell.fill",
                title: "提醒通知",
                value: task.type == .routine ? "已依重複星期排定通知" : "已依指定日期排定通知",
                tint: tint
            )

            if task.type == .routine {
                TaskDetailRow(
                    icon: "repeat",
                    title: "重複星期",
                    value: task.repeatDescription,
                    tint: tint
                )
            }

            TaskDetailRow(
                icon: "doc.text.fill",
                title: "備註",
                value: task.note.isEmpty ? "無備註" : task.note,
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
                Text("刪除任務")
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
        if task.title.contains("藥") {
            return "pills.fill"
        } else if task.title.contains("血壓") || task.title.contains("量") {
            return "heart.text.square.fill"
        } else if task.title.contains("吃") || task.title.contains("飲") {
            return "fork.knife"
        } else if task.title.contains("復健") {
            return "figure.walk"
        } else if task.title.contains("回診") || task.title.contains("醫") {
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

                Text(value)
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
            title: "早餐前吃藥",
            note: "降血壓藥 Amlodipine 5mg",
            dueDate: Date(),
            type: .routine,
            repeatWeekdays: Weekday.allCases
        ),
        onDelete: {}
    )
}
