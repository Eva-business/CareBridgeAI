import SwiftUI
import PhotosUI

enum ProfileSectionItem: String, CaseIterable, Identifiable {
    case basic = "Basic Info"
    case medical = "Medical Info"
    case lifestyle = "Lifestyle"
    case cognitive = "Cognitive & Mood"
    case carePreference = "Care Needs & Preferences"
    case emergency = "Emergency Contacts"
    case medicalUnit = "Medical Providers"
    case files = "Documents & Files"
    case approval = "Join Requests"
    case invite = "Invite Members"

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .basic:
            return language.text(en: "Basic Info", zhTW: "基本資料")
        case .medical:
            return language.text(en: "Medical Info", zhTW: "醫療資訊")
        case .lifestyle:
            return language.text(en: "Lifestyle", zhTW: "生活習慣")
        case .cognitive:
            return language.text(en: "Cognitive & Mood", zhTW: "認知與情緒")
        case .carePreference:
            return language.text(en: "Care Needs & Preferences", zhTW: "照護需求與偏好")
        case .emergency:
            return language.text(en: "Emergency Contacts", zhTW: "緊急聯絡人")
        case .medicalUnit:
            return language.text(en: "Medical Providers", zhTW: "醫療單位")
        case .files:
            return language.text(en: "Documents & Files", zhTW: "文件與檔案")
        case .approval:
            return language.text(en: "Join Requests", zhTW: "加入申請")
        case .invite:
            return language.text(en: "Invite Members", zhTW: "邀請成員")
        }
    }

    func subtitle(_ language: AppLanguage) -> String {
        switch self {
        case .basic:
            return language.text(en: "Name, birthday, gender, contact details, and address", zhTW: "姓名、生日、性別、聯絡方式與地址")
        case .medical:
            return language.text(en: "Medical history, medications, allergies, and surgeries", zhTW: "病史、用藥、過敏與手術紀錄")
        case .lifestyle:
            return language.text(en: "Diet, sleep, exercise, and toileting habits", zhTW: "飲食、睡眠、運動與如廁習慣")
        case .cognitive:
            return language.text(en: "Cognition, mood patterns, and communication ability", zhTW: "認知、情緒模式與溝通能力")
        case .carePreference:
            return language.text(en: "Daily assistance needs, preferences, and restrictions", zhTW: "日常協助需求、偏好與限制")
        case .emergency:
            return language.text(en: "Family and trusted contact details", zhTW: "家人與可信任聯絡人")
        case .medicalUnit:
            return language.text(en: "Hospitals, clinics, physicians, and provider contacts", zhTW: "醫院、診所、醫師與聯絡方式")
        case .files:
            return language.text(en: "Medical reports, test results, and important files", zhTW: "醫療報告、檢驗結果與重要檔案")
        case .approval:
            return language.text(en: "Review join requests from other members", zhTW: "審核其他成員的加入申請")
        case .invite:
            return language.text(en: "Show care account ID, invite link, and QR code", zhTW: "顯示照護帳號 ID、邀請連結與 QR Code")
        }
    }

    var icon: String {
        switch self {
        case .basic:
            return "person.2.fill"
        case .medical:
            return "cross.case.fill"
        case .lifestyle:
            return "figure.walk"
        case .cognitive:
            return "brain.head.profile"
        case .carePreference:
            return "heart.text.square.fill"
        case .emergency:
            return "phone.fill"
        case .medicalUnit:
            return "building.2.fill"
        case .files:
            return "doc.text.fill"
        case .approval:
            return "person.badge.plus.fill"
        case .invite:
            return "qrcode"
        }
    }

    var tint: Color {
        switch self {
        case .basic:
            return AppTheme.primaryGreen
        case .medical:
            return .orange
        case .lifestyle:
            return .brown
        case .cognitive:
            return .blue
        case .carePreference:
            return .green
        case .emergency:
            return .purple
        case .medicalUnit:
            return .teal
        case .files:
            return .yellow
        case .approval:
            return AppTheme.dangerRed
        case .invite:
            return AppTheme.primaryGreen
        }
    }
}

enum CaregiverListType: String, Identifiable {
    case mainManager = "Main Manager"
    case sharedCaregivers = "Shared Caregivers"

    var id: String { rawValue }

    func title(_ language: AppLanguage) -> String {
        switch self {
        case .mainManager:
            return language.text(en: "Main Manager", zhTW: "主要管理者")
        case .sharedCaregivers:
            return language.text(en: "Shared Caregivers", zhTW: "共同照護者")
        }
    }
}

struct ProfileView: View {
    @Environment(\.appLanguage) private var appLanguage

    @Binding var draft: CareRecipientDraft
    let currentUser: Caregiver
    @Binding var profilePhoto: ProfilePhotoStore

    let onLogout: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedSection: ProfileSectionItem?
    @State private var selectedCaregiverList: CaregiverListType?
    
    @StateObject private var accountStore = CareAccountStore.shared

    private var manager: Caregiver? {
        draft.caregivers.first {
            $0.role == .mainManager && $0.status == .approved
        }
    }

    private var isMainManager: Bool {
        currentUser.role == .mainManager &&
        currentUser.status == .approved
    }
    
    private var pendingMembers: [Caregiver] {
        accountStore.pendingRequests(for: draft.careRecipientID)
    }
    
    private var approvedMembers: [Caregiver] {
        draft.caregivers.filter { $0.status == .approved }
    }

    private var sharedCaregiverCount: Int {
        max(approvedMembers.count - 1, 0)
    }

    private var recipientDisplayName: String {
        let name = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            return appLanguage.text(en: "Care Recipient", zhTW: "被照護者")
        }
        return appLanguage.isChinese ? name : name.careBridgeEnglishDisplayValue
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MainHeaderView(
                            title: appLanguage.text(en: "Care Recipient Profile", zhTW: "被照護者檔案"),
                            subtitle: appLanguage.text(en: "Data center and group management", zhTW: "資料中心與群組管理")
                        )

                        logoutButton

                        profileTopCard

                        statsCard

                        if isMainManager && !pendingMembers.isEmpty {
                            approvalShortcutRow
                        }

                        noteCard

                        sectionList
                    }
                    .padding(24)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedSection) { section in
                ProfileSectionDetailView(
                    section: section,
                    draft: $draft,
                    isEditable: isMainManager,
                    approvedMembers: approvedMembers,
                    pendingMembers: pendingMembers,
                    onApprove: approveMember,
                    onReject: rejectMember
                )
            }
            .sheet(item: $selectedCaregiverList) { listType in
                CaregiverListDetailView(
                    listType: listType,
                    mainManager: manager,
                    caregivers: approvedMembers
                )
            }
            .onChange(of: selectedPhotoItem) {
                loadSelectedPhoto()
            }
        }
    }

    private var logoutButton: some View {
        Button {
            onLogout()
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text(appLanguage.text(en: "Log Out / Back to Entry", zhTW: "登出 / 回到入口"))
                    .fontWeight(.semibold)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .foregroundStyle(AppTheme.dangerRed)
            .padding()
            .background(AppTheme.dangerRed.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
    }
    
    private var profileTopCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 16) {
                Group {
                    if isMainManager {
                        PhotosPicker(
                            selection: $selectedPhotoItem,
                            matching: .images
                        ) {
                            profilePhotoView(showCamera: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        profilePhotoView(showCamera: false)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(recipientDisplayName)
                            .font(.title)
                            .fontWeight(.bold)

                        if isMainManager {
                            Text(appLanguage.text(en: "Main Manager", zhTW: "主要管理者"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(AppTheme.primaryGreen)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppTheme.lightGreen)
                                .clipShape(Capsule())
                        }
                    }

                    Text(profileSubtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                }

                Spacer()
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func profilePhotoView(showCamera: Bool) -> some View {
        ZStack(alignment: .bottomTrailing) {
            ZStack {
                Circle()
                    .fill(AppTheme.lightGreen)
                    .frame(width: 92, height: 92)

                if let image = profilePhoto.image {
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 92, height: 92)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.primaryGreen)
                }
            }

            if showCamera {
                Image(systemName: "camera.fill")
                    .font(.caption)
                    .foregroundStyle(.white)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.primaryGreen)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(Color.white, lineWidth: 2)
                    }
            }
        }
    }
    
    private var profileSubtitle: String {
        let blood = draft.bloodType.isEmpty
            ? appLanguage.text(en: "Blood type not set", zhTW: "未設定血型")
            : appLanguage.text(en: "Type \(draft.bloodType)", zhTW: "\(draft.bloodType) 型")
        return appLanguage.text(
            en: "\(age) years old - \(draft.gender.localizedProfileValue(appLanguage)) - \(blood)",
            zhTW: "\(age) 歲 - \(draft.gender.localizedProfileValue(appLanguage)) - \(blood)"
        )
    }

    private var age: Int {
        Calendar.current.dateComponents([.year], from: draft.birthday, to: Date()).year ?? 0
    }

    private var statsCard: some View {
        HStack(spacing: 10) {
            Button {
                selectedCaregiverList = .mainManager
            } label: {
                ProfileStatCard(
                    icon: "heart.fill",
                    title: appLanguage.text(en: "Primary Caregiver", zhTW: "主要照護者"),
                    value: managerDisplayName,
                    tint: .red
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedCaregiverList = .sharedCaregivers
            } label: {
                ProfileStatCard(
                    icon: "person.2.fill",
                    title: appLanguage.text(en: "Shared Caregivers", zhTW: "共同照護者"),
                    value: "\(sharedCaregiverCount)",
                    tint: .blue
                )
            }
            .buttonStyle(.plain)
        }
    }

    private var noteCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "clipboard.fill")
                .foregroundStyle(AppTheme.warningYellow)
                .frame(width: 38, height: 38)
                .background(AppTheme.warningYellow.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 6) {
                Text(appLanguage.text(en: "Notes", zhTW: "備註"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(draft.carePreference.isEmpty ? appLanguage.text(en: "No special notes yet", zhTW: "目前沒有特殊備註") : draft.carePreference.localizedCareText(appLanguage))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var managerDisplayName: String {
        guard let manager else {
            return appLanguage.text(en: "Not created", zhTW: "尚未建立")
        }
        return manager.name.containsCareBridgeCJKText && !appLanguage.isChinese ? manager.role.displayName(appLanguage) : manager.name.localizedCareText(appLanguage)
    }
    
    private var approvalShortcutRow: some View {
        Button {
            selectedSection = .approval
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "person.badge.plus.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.dangerRed)
                    .frame(width: 46, height: 46)
                    .background(AppTheme.dangerRed.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(appLanguage.text(en: "Join Requests", zhTW: "加入申請"))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        Text("\(pendingMembers.count)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .frame(width: 22, height: 22)
                            .background(AppTheme.dangerRed)
                            .clipShape(Circle())
                    }

                    Text(appLanguage.text(en: "Review join requests from other members", zhTW: "審核其他成員的加入申請"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var sectionList: some View {
        VStack(spacing: 12) {
            ForEach(ProfileSectionItem.allCases) { item in
                if shouldShowSection(item) {
                    sectionRow(item)
                }
            }
        }
    }

    private func shouldShowSection(_ item: ProfileSectionItem) -> Bool {
        switch item {
        case .approval:
            return isMainManager && !pendingMembers.isEmpty

        case .invite:
            return isMainManager

        default:
            return true
        }
    }
    
    private func sectionRow(_ item: ProfileSectionItem) -> some View {
        Button {
            selectedSection = item
        } label: {
            HStack(spacing: 14) {
                Image(systemName: item.icon)
                    .font(.headline)
                    .foregroundStyle(item.tint)
                    .frame(width: 42, height: 42)
                    .background(item.tint.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.title(appLanguage))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.primary)

                        if item == .approval && !pendingMembers.isEmpty {
                            Text("\(pendingMembers.count)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .frame(width: 20, height: 20)
                                .background(AppTheme.dangerRed)
                                .clipShape(Circle())
                        }
                    }

                    Text(item.subtitle(appLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private func approveMember(_ member: Caregiver) {
        let approved = accountStore.approveRequest(
            member,
            careRecipientID: draft.careRecipientID
        )

        if !draft.caregivers.contains(where: { $0.id == approved.id }) {
            draft.caregivers.append(approved)
        }
    }

    private func rejectMember(_ member: Caregiver) {
        accountStore.rejectRequest(
            member,
            careRecipientID: draft.careRecipientID
        )
    }
    
    private func loadSelectedPhoto() {
        guard let selectedPhotoItem else { return }

        Task {
            do {
                if let data = try await selectedPhotoItem.loadTransferable(type: Data.self) {
                    profilePhoto.imageData = data
                }
            } catch {
                print("Failed to load photo: \(error.localizedDescription)")
            }
        }
    }
}

struct ProfileStatCard: View {
    let icon: String
    let title: String
    let value: String
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 34, height: 34)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.bold)
                .lineLimit(1)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 3)
    }
}

#Preview {
    ProfileView(
        draft: .constant(CareRecipientDraft()),
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
        profilePhoto: .constant(ProfilePhotoStore()),
        onLogout: {}
    )
}
