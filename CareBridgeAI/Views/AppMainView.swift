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
            _memos = State(initialValue: englishContent.memos)
            _profilePhoto = State(
                initialValue: ProfilePhotoStore(imageData: englishContent.profilePhotoData)
            )
        } else {
            _draft = State(initialValue: draft)
        }
        _currentUser = State(initialValue: currentUser)
        self.onLogout = onLogout
    }

    private static func englishContentSnapshot(_ snapshot: CareContentSnapshot) -> CareContentSnapshot {
        CareContentSnapshot(
            draft: snapshot.draft,
            records: snapshot.records.map(englishRecord),
            tasks: snapshot.tasks.map(englishTask),
            memos: snapshot.memos.map(englishMemo),
            profilePhotoData: snapshot.profilePhotoData
        )
    }

    private static func normalizedDemoContentSnapshot(_ snapshot: CareContentSnapshot) -> CareContentSnapshot {
        guard snapshot.containsLegacyDemoText else {
            return englishContentSnapshot(snapshot)
        }

        return demoContentSnapshot(
            draft: snapshot.draft,
            profilePhotoData: snapshot.profilePhotoData
        )
    }

    private static func demoContentSnapshot(
        draft: CareRecipientDraft,
        profilePhotoData: Data? = nil
    ) -> CareContentSnapshot {
        CareContentSnapshot(
            draft: draft,
            records: demoRecords,
            tasks: demoTasks,
            memos: demoMemos,
            profilePhotoData: profilePhotoData
        )
    }

    private static func englishRecord(_ record: CareRecord) -> CareRecord {
        var next = record
        let content = record.content.careBridgeEnglishCareTextValue
        next.content = content.containsCareBridgeCJKText ? "Care detail recorded." : content
        next.createdBy = record.createdBy.careBridgeEnglishCareTextValue
        if next.createdBy.containsCareBridgeCJKText {
            next.createdBy = "Caregiver"
        }
        return next
    }

    private static func englishTask(_ task: CareTask) -> CareTask {
        var next = task
        let title = task.title.careBridgeEnglishCareTextValue
        let note = task.note.careBridgeEnglishCareTextValue
        next.title = title.containsCareBridgeCJKText ? "Care Task" : title
        next.note = note.containsCareBridgeCJKText ? "" : note
        return next
    }

    private static func englishMemo(_ memo: Memo) -> Memo {
        var next = memo
        let content = memo.content.careBridgeEnglishCareTextValue
        next.content = content.containsCareBridgeCJKText ? "Personal care note." : content
        return next
    }

    private static var demoRecords: [CareRecord] {
        [
            CareRecord(
                content: "Breakfast: finished oatmeal, banana slices, and 250 ml of warm water. Appetite was slightly lower than usual but no choking was observed.",
                category: .food,
                condition: .normal,
                createdAt: todayAt(hour: 7, minute: 45),
                createdBy: "Morning Caregiver"
            ),
            CareRecord(
                content: "Blood pressure was 132/78 mmHg before morning medication. Amlodipine 5 mg was taken at 08:10 with no dizziness or nausea reported.",
                category: .medicine,
                condition: .good,
                createdAt: todayAt(hour: 8, minute: 12),
                createdBy: "Morning Caregiver"
            ),
            CareRecord(
                content: "Bowel movement at 09:05. Stool was soft and formed. No abdominal pain was reported.",
                category: .bowel,
                condition: .good,
                createdAt: todayAt(hour: 9, minute: 8),
                createdBy: "Morning Caregiver"
            ),
            CareRecord(
                content: "Mood was calm after a video call with family. Participated in light conversation and followed simple instructions well.",
                category: .mood,
                condition: .good,
                createdAt: todayAt(hour: 10, minute: 35),
                createdBy: "Family Member"
            ),
            CareRecord(
                content: "Lunch: ate about 70% of rice, steamed fish, and vegetables. Drank another 200 ml of water. Continue encouraging fluids in the afternoon.",
                category: .food,
                condition: .normal,
                createdAt: todayAt(hour: 12, minute: 40),
                createdBy: "Day Caregiver"
            ),
            CareRecord(
                content: "Completed 15 minutes of seated leg exercises. Mild knee stiffness was noted, but pain did not increase.",
                category: .custom,
                condition: .normal,
                createdAt: todayAt(hour: 15, minute: 20),
                createdBy: "Day Caregiver"
            )
        ]
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

    private static var demoMemos: [Memo] {
        [
            Memo(
                content: "Prefers warm water and soft foods when appetite is low.",
                createdAt: todayAt(hour: 7, minute: 20)
            ),
            Memo(
                content: "Family video calls usually improve mood in the morning.",
                createdAt: todayAt(hour: 10, minute: 0)
            ),
            Memo(
                content: "Check knee stiffness before starting afternoon exercises.",
                createdAt: todayAt(hour: 14, minute: 30)
            )
        ]
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
    
    @State private var memos: [Memo] = Self.demoMemos
    
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
            let result = await CareAIService.summarize(records)
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
