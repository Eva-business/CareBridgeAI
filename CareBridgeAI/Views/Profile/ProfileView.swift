import SwiftUI
import PhotosUI

enum ProfileSectionItem: String, CaseIterable, Identifiable {
    case basic = "基本資料"
    case medical = "醫療資訊"
    case lifestyle = "生活習慣"
    case cognitive = "認知與情緒狀態"
    case carePreference = "照護需求與偏好"
    case emergency = "緊急聯絡人"
    case medicalUnit = "醫療單位"
    case files = "文件與檔案"
    case approval = "加入申請審核"
    case invite = "邀請成員"

    var id: String { rawValue }

    var subtitle: String {
        switch self {
        case .basic:
            return "姓名、生日、性別、聯絡方式、地址等"
        case .medical:
            return "疾病史、用藥資訊、過敏史、手術史等"
        case .lifestyle:
            return "飲食、睡眠、運動、排泄習慣等"
        case .cognitive:
            return "認知狀況、情緒傾向、溝通能力等"
        case .carePreference:
            return "日常協助需求、個人偏好、禁忌事項等"
        case .emergency:
            return "家人、親友聯絡方式"
        case .medicalUnit:
            return "醫院、診所、醫師、醫療單位聯絡方式"
        case .files:
            return "醫療報告、檢查結果、其他重要文件"
        case .approval:
            return "審核其他成員的加入申請"
        case .invite:
            return "顯示照護帳戶 ID、邀請連結與 QR Code"
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
    case mainManager = "主要管理者"
    case sharedCaregivers = "共同照護者"

    var id: String { rawValue }
}

struct ProfileView: View {
    @Binding var draft: CareRecipientDraft
    let currentUser: Caregiver
    @Binding var profilePhoto: ProfilePhotoStore

    let onLogout: () -> Void

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedSection: ProfileSectionItem?
    @State private var selectedCaregiverList: CaregiverListType?
    
    @StateObject private var accountStore = CareAccountStore.shared
    @State private var approvedExtraMembers: [Caregiver] = []

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
        let original = draft.caregivers.filter { $0.status == .approved }
        return original + approvedExtraMembers
    }

    private var sharedCaregiverCount: Int {
        max(approvedMembers.count - 1, 0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MainHeaderView(
                            title: "被照護者檔案",
                            subtitle: "資料中心與群組管理"
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
                Text("登出 / 返回入口")
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
                        Text(draft.name.isEmpty ? "被照護者" : draft.name)
                            .font(.title)
                            .fontWeight(.bold)

                        if isMainManager {
                            Text("主要管理者")
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
        let blood = draft.bloodType.isEmpty ? "血型未填" : "\(draft.bloodType) 型"
        return "\(age) 歲・\(draft.gender)・\(blood)"
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
                    title: "主要照護者",
                    value: manager?.name ?? "未建立",
                    tint: .red
                )
            }
            .buttonStyle(.plain)

            Button {
                selectedCaregiverList = .sharedCaregivers
            } label: {
                ProfileStatCard(
                    icon: "person.2.fill",
                    title: "共同照護者",
                    value: "\(sharedCaregiverCount) 位",
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
                Text("備註")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(draft.carePreference.isEmpty ? "尚無特別備註" : draft.carePreference)
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
                        Text("加入申請審核")
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

                    Text("審核其他成員的加入申請")
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
                        Text(item.rawValue)
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

                    Text(item.subtitle)
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

        approvedExtraMembers.append(approved)
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
                print("讀取照片失敗：\(error.localizedDescription)")
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
            name: "主要管理者",
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
