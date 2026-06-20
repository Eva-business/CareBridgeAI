import SwiftUI

struct AppMainView: View {
    @State private var draft: CareRecipientDraft
    @State private var currentUser: Caregiver
    @State private var profilePhoto = ProfilePhotoStore()
    @StateObject private var accountStore = CareAccountStore.shared
    @State private var showingChat = false
    
    let onLogout: () -> Void
    
    init(
        draft: CareRecipientDraft,
        currentUser: Caregiver,
        onLogout: @escaping () -> Void
    ) {
        _draft = State(initialValue: draft)
        _currentUser = State(initialValue: currentUser)
        self.onLogout = onLogout
    }
    
    @State private var records: [CareRecord] = [
        CareRecord(
            content: "早餐吃了半碗粥，食慾尚可。",
            category: .food,
            condition: .good
        ),
        CareRecord(
            content: "今日 08:00 排便正常。",
            category: .bowel,
            condition: .good
        ),
        CareRecord(
            content: "情緒穩定，上午有進行散步 20 分鐘。",
            category: .mood,
            condition: .good
        ),
        CareRecord(
            content: "已按時服藥，無異常反應。",
            category: .medicine,
            condition: .good
        )
    ]
    
    @State private var tasks: [CareTask] = [
        CareTask(
            title: "早餐前吃藥",
            note: "降血壓藥 Amlodipine 5mg",
            dueDate: Calendar.current.date(bySettingHour: 7, minute: 30, second: 0, of: Date()) ?? Date(),
            type: .routine,
            repeatWeekdays: Weekday.allCases
        ),
        CareTask(
            title: "量血壓",
            note: "血壓記錄",
            dueDate: Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .routine,
            repeatWeekdays: Weekday.allCases
        ),
        CareTask(
            title: "午餐後飲水",
            note: "提醒補充溫開水",
            dueDate: Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .routine,
            repeatWeekdays: Weekday.allCases
        ),
        CareTask(
            title: "睡前復健",
            note: "關節活動練習",
            dueDate: Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .routine,
            repeatWeekdays: [.monday, .wednesday, .friday]
        ),
        CareTask(
            title: "回診：心臟內科",
            note: "健檢診所 / 張醫師",
            dueDate: Calendar.current.date(bySettingHour: 10, minute: 30, second: 0, of: Date()) ?? Date(),
            type: .temporary
        ),
        CareTask(
            title: "復健課程",
            note: "物理治療中心",
            dueDate: Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date(),
            type: .temporary
        )
    ]
    
    @State private var memos: [Memo] = [
        Memo(content: "晚上容易腿部抽筋，睡前記得按摩與熱敷。"),
        Memo(content: "下週二回診，記得攜帶健保卡與目前用藥清單。")
    ]
    
    private var aiSummary: String {
        CareAIService.generateSummary(from: records)
    }
    
    private var currentStatus: CareStatus {
        CareAIService.generateStatus(from: aiSummary)
    }
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            TabView {
                HomeView(
                    draft: draft,
                    profilePhoto: profilePhoto,
                    status: currentStatus,
                    aiSummary: aiSummary,
                    tasks: $tasks,
                    memos: $memos
                )
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("首頁")
                }
                
                RecordsView(
                    draft: draft,
                    records: $records
                )
                .tabItem {
                    Image(systemName: "square.and.pencil")
                    Text("紀錄")
                }
                
                TasksView(
                    draft: draft,
                    tasks: $tasks
                )
                .tabItem {
                    Image(systemName: "calendar")
                    Text("任務")
                }
                
                ProfileView(
                    draft: $draft,
                    currentUser: currentUser,
                    profilePhoto: $profilePhoto,
                    onLogout: onLogout
                )
                .tabItem {
                    Image(systemName: "person.text.rectangle")
                    Text("檔案")
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
                
                if !accountStore.chatMessages(for: draft.careRecipientID).isEmpty {
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
    
    #Preview {
        AppMainView(
            draft: CareRecipientDraft(),
            currentUser: Caregiver(
                name: "主要管理者",
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
