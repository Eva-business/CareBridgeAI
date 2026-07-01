import SwiftUI

struct AppMainView: View {
    @State private var draft: CareRecipientDraft
    @State private var currentUser: Caregiver
    @State private var profilePhoto = ProfilePhotoStore()
    @StateObject private var accountStore = CareAccountStore.shared
    @State private var showingChat = false
    @State private var aiSummary = CareAIService.generateSummary()
    @State private var currentStatus: CareStatus = .good
    @State private var summaryUsesOnDeviceModel = false
    
    let onLogout: () -> Void
    
    init(
        draft: CareRecipientDraft,
        currentUser: Caregiver,
        onLogout: @escaping () -> Void
    ) {
        if let savedContent = CareAccountStore.shared.loadCareContent(for: draft.careRecipientID) {
            let englishContent = Self.normalizedDemoContentSnapshot(savedContent)
            _draft = State(initialValue: englishContent.draft)
            _records = State(initialValue: englishContent.records)
            _tasks = State(initialValue: englishContent.tasks)
            _memos = State(
                initialValue: Self.memosWithLegacyOwner(
                    englishContent.memos,
                    ownerID: currentUser.id
                )
            )
            _profilePhoto = State(
                initialValue: ProfilePhotoStore(imageData: englishContent.profilePhotoData)
            )
        } else {
            _draft = State(initialValue: draft)
            _memos = State(initialValue: Self.demoMemos(ownerID: currentUser.id))
        }
        _currentUser = State(initialValue: currentUser)
        self.onLogout = onLogout
    }

    private static func normalizedDemoContentSnapshot(_ snapshot: CareContentSnapshot) -> CareContentSnapshot {
        normalizedBundledDemoConditions(in: snapshot)
    }

    private static func normalizedBundledDemoConditions(
        in snapshot: CareContentSnapshot
    ) -> CareContentSnapshot {
        var normalized = snapshot
        normalized.records = snapshot.records.map { record in
            if record.content == bundledMissedMedicationDemoContent {
                var updated = record
                updated.content = bundledExerciseDemoContent
                updated.category = .custom
                updated.condition = .normal
                return updated
            }

            if record.content == bundledExerciseDemoContent {
                var updated = record
                updated.category = .custom
                updated.condition = .normal
                return updated
            }

            guard record.condition == .normal,
                  bundledStableDemoRecordContents.contains(record.content)
            else {
                return record
            }

            var updated = record
            updated.condition = .good
            return updated
        }
        normalized.records = normalized.records.map(normalizedPersistedRecord)

        if isBundledDemoRecordSet(normalized.records) {
            normalized.records = demoRecords
        }

        return normalized
    }

    nonisolated private static func normalizedPersistedRecord(_ record: CareRecord) -> CareRecord {
        var updated = record
        let categories = KeywordFallbackCareSemanticAnalyzer.classifyCategories(
            record.content,
            language: .zhTW
        )

        if categories.contains(.medicine) {
            updated.category = .medicine
        }

        if record.condition == .normal,
           KeywordFallbackCareSemanticAnalyzer.inferCondition(from: record.content, language: .zhTW) == .good {
            updated.condition = .good
        }

        return updated
    }

    private static func isBundledDemoRecordSet(_ records: [CareRecord]) -> Bool {
        let contents = Set(records.map(\.content))
        return !contents.isEmpty && contents.isSubset(of: bundledDemoRecordContents)
    }

    private static let bundledStableDemoRecordContents: Set<String> = [
        "Breakfast: finished oatmeal, banana slices, and 250 ml of warm water. Appetite was slightly lower than usual but no choking was observed.",
        "Lunch: ate about 70% of rice, steamed fish, and vegetables. Drank another 200 ml of water. Continue encouraging fluids in the afternoon."
    ]

    private static let bundledExerciseDemoContent =
        "Completed 15 minutes of seated leg exercises. Mild knee stiffness was noted, but pain did not increase."

    private static let bundledMissedMedicationDemoContent =
        "The afternoon medication was missed before the meal. Please confirm the next dose with the caregiver and avoid taking a double dose."

    private static let bundledDemoRecordContents: Set<String> = [
        "Breakfast: finished oatmeal, banana slices, and 250 ml of warm water. Appetite was slightly lower than usual but no choking was observed.",
        "Blood pressure was 132/78 mmHg before morning medication. Amlodipine 5 mg was taken at 08:10 with no dizziness or nausea reported.",
        "Bowel movement at 09:05. Stool was soft and formed. No abdominal pain was reported.",
        "Mood was calm after a video call with family. Participated in light conversation and followed simple instructions well.",
        "Lunch: ate about 70% of rice, steamed fish, and vegetables. Drank another 200 ml of water. Continue encouraging fluids in the afternoon.",
        bundledExerciseDemoContent,
        bundledMissedMedicationDemoContent
    ]

    private static var demoRecords: [CareRecord] {
        [
            demoRecord(day: 30, hour: 8, minute: 0, template: .breakfast),
            demoRecord(day: 30, hour: 9, minute: 10, template: .medicine),
            demoRecord(day: 30, hour: 15, minute: 30, template: .mood),
            demoRecord(day: 1, hour: 8, minute: 0, template: .breakfast),
            demoRecord(day: 1, hour: 9, minute: 10, template: .medicine),
            demoRecord(day: 1, hour: 15, minute: 30, template: .mood),
            demoRecord(day: 2, hour: 8, minute: 0, template: .breakfast),
            demoRecord(day: 2, hour: 9, minute: 10, template: .medicine),
            demoRecord(day: 2, hour: 15, minute: 30, template: .mood)
        ]
    }

    private enum DemoRecordTemplate {
        case breakfast
        case medicine
        case mood
    }

    private static func demoRecord(
        day: Int,
        hour: Int,
        minute: Int,
        template: DemoRecordTemplate
    ) -> CareRecord {
        switch template {
        case .breakfast:
            return CareRecord(
                content: "早餐吃完半碗燕麥粥、一顆水煮蛋，喝溫水 250 ml，沒有嗆咳。",
                category: .food,
                condition: .good,
                createdAt: demoDate(day: day, hour: hour, minute: minute),
                createdBy: "早班照護者"
            )

        case .medicine:
            return CareRecord(
                content: "早餐後已服用降血壓藥 1 顆，服藥後 30 分鐘無頭暈或噁心。",
                category: .medicine,
                condition: .good,
                createdAt: demoDate(day: day, hour: hour, minute: minute),
                createdBy: "早班照護者"
            )

        case .mood:
            return CareRecord(
                content: "下午精神穩定，和家人視訊後情緒放鬆，能主動回應簡單對話。",
                category: .mood,
                condition: .good,
                createdAt: demoDate(day: day, hour: hour, minute: minute),
                createdBy: "家屬"
            )
        }
    }

    private static func demoDate(day: Int, hour: Int, minute: Int) -> Date {
        DateComponents(
            calendar: Calendar.current,
            year: 2026,
            month: day == 30 ? 6 : 7,
            day: day,
            hour: hour,
            minute: minute
        ).date ?? Date()
    }

    private static var demoTasks: [CareTask] {
        [
            CareTask(
                title: "Morning blood pressure check",
                note: "Record systolic, diastolic, and any dizziness before medication.",
                dueDate: todayAt(hour: 8, minute: 0),
                type: .routine,
                repeatWeekdays: Weekday.allCases
            ),
            CareTask(
                title: "Give morning medication",
                note: "Amlodipine 5 mg after breakfast. Confirm swallowing before leaving.",
                dueDate: todayAt(hour: 8, minute: 10),
                type: .routine,
                repeatWeekdays: Weekday.allCases
            ),
            CareTask(
                title: "Hydration reminder",
                note: "Offer 200 ml warm water. Use small sips if appetite is low.",
                dueDate: todayAt(hour: 13, minute: 30),
                type: .routine,
                repeatWeekdays: Weekday.allCases
            ),
            CareTask(
                title: "Seated leg exercises",
                note: "15 minutes. Stop if knee pain increases.",
                dueDate: todayAt(hour: 15, minute: 0),
                type: .routine,
                repeatWeekdays: [.monday, .wednesday, .friday]
            ),
            CareTask(
                title: "Cardiology follow-up",
                note: "Bring blood pressure log and current medication list.",
                dueDate: todayAt(hour: 10, minute: 30),
                type: .temporary
            ),
            CareTask(
                title: "Evening medication check",
                note: "Confirm pill box compartment is empty before bedtime.",
                dueDate: todayAt(hour: 20, minute: 30),
                type: .routine,
                repeatWeekdays: Weekday.allCases
            )
        ]
    }

    private static func demoMemos(ownerID: UUID? = nil) -> [Memo] {
        [
            Memo(
                ownerID: ownerID,
                content: "Prefers warm water and soft foods when appetite is low.",
                createdAt: todayAt(hour: 7, minute: 20)
            ),
            Memo(
                ownerID: ownerID,
                content: "Family video calls usually improve mood in the morning.",
                createdAt: todayAt(hour: 10, minute: 0)
            ),
            Memo(
                ownerID: ownerID,
                content: "Check knee stiffness before starting afternoon exercises.",
                createdAt: todayAt(hour: 14, minute: 30)
            )
        ]
    }

    private static func memosWithLegacyOwner(_ memos: [Memo], ownerID: UUID) -> [Memo] {
        memos.map { memo in
            guard memo.ownerID == nil else { return memo }

            var updated = memo
            updated.ownerID = ownerID
            return updated
        }
    }

    private static func todayAt(hour: Int, minute: Int) -> Date {
        Calendar.current.date(
            bySettingHour: hour,
            minute: minute,
            second: 0,
            of: Date()
        ) ?? Date()
    }
    
    @State private var records: [CareRecord] = Self.demoRecords
    
    @State private var tasks: [CareTask] = Self.demoTasks
    
    @State private var memos: [Memo] = []
    
    private var persistenceFingerprint: Data {
        let snapshot = CareContentSnapshot(
            draft: draft,
            records: records,
            tasks: tasks,
            memos: memos,
            profilePhotoData: profilePhoto.imageData
        )
        return (try? JSONEncoder().encode(snapshot)) ?? Data()
    }

    private var tasksNotificationFingerprint: Data {
        (try? JSONEncoder().encode(tasks)) ?? Data()
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView {
                HomeView(
                    draft: draft,
                    profilePhoto: profilePhoto,
                    status: currentStatus,
                    aiSummary: aiSummary,
                    summaryUsesOnDeviceModel: summaryUsesOnDeviceModel,
                    currentUserID: currentUser.id,
                    tasks: $tasks,
                    memos: $memos
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text(currentUser.preferredLanguage.text(en: "Home", zhTW: "首頁"))
                }
                
                RecordsView(
                    draft: draft,
                    records: $records,
                    currentUser: currentUser,
                    recordingLanguage: currentUser.preferredLanguage,
                    onSummaryGenerated: applyAISummary
                )
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text(currentUser.preferredLanguage.text(en: "Records", zhTW: "紀錄"))
                }
                
                TasksView(
                    draft: draft,
                    tasks: $tasks
                )
                .tabItem {
                    Image(systemName: "calendar")
                    Text(currentUser.preferredLanguage.text(en: "Tasks", zhTW: "任務"))
                }
                
                ProfileView(
                    draft: $draft,
                    currentUser: currentUser,
                    profilePhoto: $profilePhoto,
                    onLogout: onLogout
                )
                .tabItem {
                    Image(systemName: "person.text.rectangle")
                    Text(currentUser.preferredLanguage.text(en: "Profile", zhTW: "檔案"))
                }
            }
            .tint(AppTheme.primaryGreen)
            
            floatingChatButton
        }
        .sheet(isPresented: $showingChat) {
            ChatView(
                careRecipientID: draft.careRecipientID,
                currentUser: currentUser
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
        .onReceive(NotificationCenter.default.publisher(for: .openCareBridgeChat)) { _ in
            showingChat = true
        }
        .onAppear {
            persistCareContent()
            NotificationService.shared.syncNotifications(for: tasks)
        }
        .task(id: persistenceFingerprint) {
            let result = await CareAIService.summarize(
                records,
                language: currentUser.preferredLanguage
            )
            applyAISummary(result)
        }
        .onChange(of: persistenceFingerprint) { _, _ in
            persistCareContent()
        }
        .onChange(of: tasksNotificationFingerprint) { _, _ in
            NotificationService.shared.syncNotifications(for: tasks)
        }
        .environment(\.appLanguage, currentUser.preferredLanguage)
    }
    
    private var floatingChatButton: some View {
        Button {
            showingChat = true
        } label: {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.primaryGreen)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                
                if accountStore.hasUnreadChatMessages(
                    for: draft.careRecipientID,
                    currentUserID: currentUser.id
                ) {
                    Circle()
                        .fill(AppTheme.dangerRed)
                        .frame(width: 14, height: 14)
                        .offset(x: 2, y: -2)
                }
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.trailing, 18)
    }

    private func persistCareContent() {
        CareAccountStore.shared.saveCareContent(
            CareContentSnapshot(
                draft: draft,
                records: records,
                tasks: tasks,
                memos: memos,
                profilePhotoData: profilePhoto.imageData
            )
        )
    }

    private func applyAISummary(_ result: CareAISummary) {
        aiSummary = result.text
        currentStatus = result.status
        summaryUsesOnDeviceModel = result.usedOnDeviceModel
    }
    
    #Preview {
        AppMainView(
            draft: CareRecipientDraft(),
            currentUser: Caregiver(
                name: "Main Manager",
                phone: "0912345678",
                email: "manager@example.com",
                password: "12345678",
                role: .mainManager,
                status: .approved,
                isCreator: true,
                preferredLanguage: .zhTW
            ),
            onLogout: {}
        )
    }
}
