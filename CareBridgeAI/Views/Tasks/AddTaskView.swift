import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    let fixedType: CareTaskType
    let defaultDate: Date
    let onSave: (CareTask) -> Void

    @State private var title = ""
    @State private var note = ""
    @State private var dueDate: Date
    @State private var selectedWeekdays: Set<Weekday> = Set(Weekday.allCases)

    init(
        fixedType: CareTaskType,
        defaultDate: Date,
        onSave: @escaping (CareTask) -> Void
    ) {
        self.fixedType = fixedType
        self.defaultDate = defaultDate
        self.onSave = onSave

        let calendar = Calendar.current
        let defaultHour = calendar.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: defaultDate
        ) ?? defaultDate

        _dueDate = State(initialValue: defaultHour)
    }

    private var canSave: Bool {
        let hasTitle = !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

        if fixedType == .routine {
            return hasTitle && !selectedWeekdays.isEmpty
        } else {
            return hasTitle
        }
    }

    private var pageTitle: String {
        fixedType == .routine ? "新增常態任務" : "新增任務"
    }

    private var datePickerComponents: DatePickerComponents {
        fixedType == .routine ? [.hourAndMinute] : [.date, .hourAndMinute]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 18) {
                            FormTextField(
                                title: "任務名稱",
                                placeholder: fixedType == .routine ? "例如：早餐前吃藥、量血壓" : "例如：回診、復健、家人探訪",
                                text: $title
                            )

                            taskTypeInfo

                            if fixedType == .routine {
                                weekdaySelection
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text(fixedType == .routine ? "提醒時間" : "日期與時間")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                DatePicker(
                                    fixedType == .routine ? "選擇時間" : "選擇日期時間",
                                    selection: $dueDate,
                                    displayedComponents: datePickerComponents
                                )
                                .datePickerStyle(.compact)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("備註")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)

                                TextEditor(text: $note)
                                    .frame(height: 110)
                                    .padding(8)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                    .overlay(alignment: .topLeading) {
                                        if note.isEmpty {
                                            Text("例如：飯後服用、攜帶健保卡、注意血壓")
                                                .font(.subheadline)
                                                .foregroundStyle(.gray.opacity(0.65))
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 16)
                                                .allowsHitTesting(false)
                                        }
                                    }
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.68))
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                    }
                    .padding(24)
                }
            }
            .navigationTitle(pageTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveTask()
                    }
                    .fontWeight(.bold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private var taskTypeInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("任務類型")
                .font(.subheadline)
                .fontWeight(.semibold)

            HStack {
                Image(systemName: fixedType == .routine ? "repeat" : "calendar.badge.clock")
                    .foregroundStyle(fixedType == .routine ? AppTheme.primaryGreen : AppTheme.warningYellow)

                VStack(alignment: .leading, spacing: 3) {
                    Text(fixedType.rawValue)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(fixedType == .routine ? "可選擇星期幾重複提醒" : "只在指定日期提醒一次")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var weekdaySelection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("重複星期")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Button {
                    toggleEveryday()
                } label: {
                    Text(selectedWeekdays.count == 7 ? "清除" : "每天")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                }
            }

            HStack(spacing: 8) {
                ForEach(Weekday.allCases) { weekday in
                    Button {
                        toggleWeekday(weekday)
                    } label: {
                        Text(weekday.shortName)
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundStyle(selectedWeekdays.contains(weekday) ? .white : AppTheme.primaryGreen)
                            .frame(width: 38, height: 38)
                            .background(
                                selectedWeekdays.contains(weekday)
                                ? AppTheme.primaryGreen
                                : AppTheme.lightGreen
                            )
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
            }

            Text(repeatPreviewText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var repeatPreviewText: String {
        let sortedDays = selectedWeekdays.sorted { $0.rawValue < $1.rawValue }

        if sortedDays.isEmpty {
            return "請至少選擇一天"
        }

        if sortedDays.count == 7 {
            return "將會每天提醒"
        }

        let days = sortedDays.map { $0.fullName }.joined(separator: "、")
        return "將會在 \(days) 提醒"
    }

    private func toggleWeekday(_ weekday: Weekday) {
        if selectedWeekdays.contains(weekday) {
            selectedWeekdays.remove(weekday)
        } else {
            selectedWeekdays.insert(weekday)
        }
    }

    private func toggleEveryday() {
        if selectedWeekdays.count == 7 {
            selectedWeekdays.removeAll()
        } else {
            selectedWeekdays = Set(Weekday.allCases)
        }
    }

    private func saveTask() {
        let newTask = CareTask(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            dueDate: dueDate,
            type: fixedType,
            isDone: false,
            repeatWeekdays: fixedType == .routine
                ? selectedWeekdays.sorted { $0.rawValue < $1.rawValue }
                : []
        )

        onSave(newTask)
        dismiss()
    }
}

#Preview {
    AddTaskView(
        fixedType: .routine,
        defaultDate: Date()
    ) { _ in }
}
