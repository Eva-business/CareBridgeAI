import Foundation

enum CareTaskType: String, CaseIterable, Identifiable, Codable {
    case routine = "常態任務"
    case temporary = "非常態任務"

    var id: String { rawValue }
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
        switch self {
        case .sunday:
            return "日"
        case .monday:
            return "一"
        case .tuesday:
            return "二"
        case .wednesday:
            return "三"
        case .thursday:
            return "四"
        case .friday:
            return "五"
        case .saturday:
            return "六"
        }
    }

    var fullName: String {
        switch self {
        case .sunday:
            return "星期日"
        case .monday:
            return "星期一"
        case .tuesday:
            return "星期二"
        case .wednesday:
            return "星期三"
        case .thursday:
            return "星期四"
        case .friday:
            return "星期五"
        case .saturday:
            return "星期六"
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
        guard type == .routine else {
            return dueDate.formatted(date: .numeric, time: .shortened)
        }

        if repeatWeekdays.isEmpty {
            return "未設定重複日"
        }

        if repeatWeekdays.count == 7 {
            return "每天 \(dueDate.formatted(date: .omitted, time: .shortened))"
        }

        let days = repeatWeekdays
            .sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: "、")

        return "每週\(days) \(dueDate.formatted(date: .omitted, time: .shortened))"
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
}
