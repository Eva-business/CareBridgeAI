import Foundation

enum CareTaskType: String, CaseIterable, Identifiable, Codable {
    case routine = "常態任務"
    case temporary = "非常態任務"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .routine:
            return "Routine Task"
        case .temporary:
            return "One-time Task"
        }
    }
}

enum Weekday: Int, CaseIterable, Identifiable, Codable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    var shortName: String {
        shortName(.en)
    }

    func shortName(_ language: AppLanguage) -> String {
        switch self {
        case .sunday:
            return language.text(en: "Sun", zhTW: "日")
        case .monday:
            return language.text(en: "Mon", zhTW: "一")
        case .tuesday:
            return language.text(en: "Tue", zhTW: "二")
        case .wednesday:
            return language.text(en: "Wed", zhTW: "三")
        case .thursday:
            return language.text(en: "Thu", zhTW: "四")
        case .friday:
            return language.text(en: "Fri", zhTW: "五")
        case .saturday:
            return language.text(en: "Sat", zhTW: "六")
        }
    }

    var fullName: String {
        fullName(.en)
    }

    func fullName(_ language: AppLanguage) -> String {
        switch self {
        case .sunday:
            return language.text(en: "Sunday", zhTW: "星期日")
        case .monday:
            return language.text(en: "Monday", zhTW: "星期一")
        case .tuesday:
            return language.text(en: "Tuesday", zhTW: "星期二")
        case .wednesday:
            return language.text(en: "Wednesday", zhTW: "星期三")
        case .thursday:
            return language.text(en: "Thursday", zhTW: "星期四")
        case .friday:
            return language.text(en: "Friday", zhTW: "星期五")
        case .saturday:
            return language.text(en: "Saturday", zhTW: "星期六")
        }
    }
}

struct CareTask: Identifiable, Codable {
    let id: UUID
    var title: String
    var note: String
    var dueDate: Date
    var type: CareTaskType
    var isDone: Bool

    // 常態任務使用：選星期幾重複
    // 非常態任務可以保持空陣列
    var repeatWeekdays: [Weekday]

    init(
        id: UUID = UUID(),
        title: String,
        note: String = "",
        dueDate: Date = Date(),
        type: CareTaskType = .routine,
        isDone: Bool = false,
        repeatWeekdays: [Weekday] = []
    ) {
        self.id = id
        self.title = title
        self.note = note
        self.dueDate = dueDate
        self.type = type
        self.isDone = isDone
        self.repeatWeekdays = repeatWeekdays
    }

    var repeatDescription: String {
        repeatDescription(.en)
    }

    func repeatDescription(_ language: AppLanguage) -> String {
        guard type == .routine else {
            return dueDate.formatted(date: .numeric, time: .shortened)
        }

        if repeatWeekdays.isEmpty {
            return language.text(en: "No repeat days set", zhTW: "未設定重複日")
        }

        if repeatWeekdays.count == 7 {
            return language.text(
                en: "Every day at \(dueDate.formatted(date: .omitted, time: .shortened))",
                zhTW: "每天 \(dueDate.formatted(date: .omitted, time: .shortened))"
            )
        }

        let days = repeatWeekdays
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName(language) }
            .joined(separator: (language.isChinese || language.isJapanese) ? "、" : ", ")

        return language.text(
            en: "Every \(days) at \(dueDate.formatted(date: .omitted, time: .shortened))",
            zhTW: "每週\(days) \(dueDate.formatted(date: .omitted, time: .shortened))"
        )
    }

    func occurs(on date: Date) -> Bool {
        let calendar = Calendar.current

        switch type {
        case .temporary:
            return calendar.isDate(dueDate, inSameDayAs: date)

        case .routine:
            let weekdayNumber = calendar.component(.weekday, from: date)

            guard let weekday = Weekday(rawValue: weekdayNumber) else {
                return false
            }

            return repeatWeekdays.contains(weekday)
        }
    }

    func nextOccurrence(after date: Date = Date()) -> Date? {
        let calendar = Calendar.current

        switch type {
        case .temporary:
            return dueDate >= date ? dueDate : nil

        case .routine:
            guard !repeatWeekdays.isEmpty else { return nil }

            let hour = calendar.component(.hour, from: dueDate)
            let minute = calendar.component(.minute, from: dueDate)

            for dayOffset in 0..<8 {
                guard let baseDate = calendar.date(byAdding: .day, value: dayOffset, to: date) else {
                    continue
                }

                let weekdayNumber = calendar.component(.weekday, from: baseDate)
                guard let weekday = Weekday(rawValue: weekdayNumber),
                      repeatWeekdays.contains(weekday),
                      let occurrence = calendar.date(
                        bySettingHour: hour,
                        minute: minute,
                        second: 0,
                        of: baseDate
                      ),
                      occurrence >= date
                else {
                    continue
                }

                return occurrence
            }

            return nil
        }
    }
}
