import SwiftUI

struct CaregiverListDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let listType: CaregiverListType
    let mainManager: Caregiver?
    let caregivers: [Caregiver]
    var canRemoveMembers: Bool = false
    var onRemoveMember: ((Caregiver) -> Void)? = nil

    @State private var memberPendingRemoval: Caregiver?

    private var sharedCaregivers: [Caregiver] {
        caregivers.filter {
            $0.role != .mainManager && $0.status == .approved
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        switch listType {
                        case .mainManager:
                            mainManagerContent

                        case .sharedCaregivers:
                            sharedCaregiversContent
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(listType.title(appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Close", zhTW: "關閉")) {
                        dismiss()
                    }
                }
            }
            .alert(
                appLanguage.text(en: "Remove collaborator?", zhTW: "刪除協作人員？"),
                isPresented: Binding(
                    get: { memberPendingRemoval != nil },
                    set: { if !$0 { memberPendingRemoval = nil } }
                ),
                presenting: memberPendingRemoval
            ) { member in
                Button(appLanguage.text(en: "Cancel", zhTW: "取消"), role: .cancel) {
                    memberPendingRemoval = nil
                }

                Button(appLanguage.text(en: "Remove", zhTW: "刪除"), role: .destructive) {
                    onRemoveMember?(member)
                    memberPendingRemoval = nil
                }
            } message: { member in
                Text(appLanguage.text(
                    en: "\(member.name.localizedCareText(appLanguage)) will no longer be able to access this care account.",
                    zhTW: "「\(member.name.localizedCareText(appLanguage))」將無法再存取此照護帳號。"
                ))
            }
        }
    }

    private var mainManagerContent: some View {
        VStack(spacing: 16) {
            if let mainManager {
                caregiverDetailCard(mainManager)
            } else {
                emptyView(
                    icon: "person.crop.circle.badge.exclamationmark",
                    title: appLanguage.text(en: "No primary caregiver yet", zhTW: "目前沒有主要照護者"),
                    message: appLanguage.text(en: "The person who creates the care group becomes the main manager.", zhTW: "建立照護群組的人會成為主要管理者。")
                )
            }
        }
    }

    private var sharedCaregiversContent: some View {
        VStack(spacing: 16) {
            if sharedCaregivers.isEmpty {
                emptyView(
                    icon: "person.2.slash.fill",
                    title: appLanguage.text(en: "No shared caregivers yet", zhTW: "目前沒有共同照護者"),
                    message: appLanguage.text(en: "Other family members, caregivers, or the care recipient will appear here after approval.", zhTW: "其他家人、看護或被照護者本人審核通過後會顯示在這裡。")
                )
            } else {
                ForEach(sharedCaregivers) { caregiver in
                    caregiverDetailCard(caregiver)
                }
            }
        }
    }

    private func caregiverDetailCard(_ caregiver: Caregiver) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(roleColor(caregiver.role).opacity(0.14))
                        .frame(width: 58, height: 58)

                    Image(systemName: roleIcon(caregiver.role))
                        .font(.title2)
                        .foregroundStyle(roleColor(caregiver.role))
                }

                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 6) {
                        Text(caregiver.name.containsCareBridgeCJKText && !appLanguage.isChinese ? caregiver.role.displayName(appLanguage) : caregiver.name.localizedCareText(appLanguage))
                            .font(.title3)
                            .fontWeight(.bold)

                        if caregiver.isCreator {
                            Text(appLanguage.text(en: "Creator", zhTW: "建立者"))
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(AppTheme.primaryGreen)
                                .clipShape(Capsule())
                        }
                    }

                    Text(caregiver.role.displayName(appLanguage))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(roleColor(caregiver.role))
                }

                Spacer()
            }

            Divider()

            caregiverInfoRow(
                icon: "phone.fill",
                title: appLanguage.text(en: "Phone", zhTW: "電話"),
                value: caregiver.phone.isEmpty ? appLanguage.text(en: "Not provided", zhTW: "未提供") : caregiver.phone
            )

            caregiverInfoRow(
                icon: "envelope.fill",
                title: appLanguage.text(en: "Email / Account", zhTW: "Email / 帳號"),
                value: caregiver.email.isEmpty ? appLanguage.text(en: "Not provided", zhTW: "未提供") : caregiver.email
            )
            
            caregiverInfoRow(
                icon: "globe.asia.australia.fill",
                title: appLanguage.text(en: "Language", zhTW: "語言"),
                value: caregiver.preferredLanguage.displayName(in: appLanguage)
            )
            
            caregiverInfoRow(
                icon: "checkmark.seal.fill",
                title: appLanguage.text(en: "Member Status", zhTW: "成員狀態"),
                value: caregiver.status.displayName(appLanguage)
            )

            if canRemoveMembers && caregiver.role != .mainManager {
                Button(role: .destructive) {
                    memberPendingRemoval = caregiver
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text(appLanguage.text(en: "Remove Collaborator", zhTW: "刪除協作人員"))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(AppTheme.dangerRed)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.dangerRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func caregiverInfoRow(
        icon: String,
        title: String,
        value: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 34, height: 34)
                .background(AppTheme.lightGreen)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func emptyView(
        icon: String,
        title: String,
        message: String
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.primaryGreen)

            Text(title)
                .font(.headline)
                .fontWeight(.bold)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private func roleIcon(_ role: CaregiverRole) -> String {
        switch role {
        case .mainManager:
            return "crown.fill"
        case .family:
            return "person.2.fill"
        case .caregiver:
            return "cross.case.fill"
        case .recipientSelf:
            return "person.fill"
        }
    }

    private func roleColor(_ role: CaregiverRole) -> Color {
        switch role {
        case .mainManager:
            return AppTheme.primaryGreen
        case .family:
            return .blue
        case .caregiver:
            return .orange
        case .recipientSelf:
            return .purple
        }
    }
}

#Preview {
    CaregiverListDetailView(
        listType: .mainManager,
        mainManager: Caregiver(
            name: "Main Manager",
            phone: "0912345678",
            email: "test@example.com",
            password: "",
            role: .mainManager,
            isCreator: true
        ),
        caregivers: []
    )
}
