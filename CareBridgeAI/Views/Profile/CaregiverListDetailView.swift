import SwiftUI

struct CaregiverListDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let listType: CaregiverListType
    let mainManager: Caregiver?
    let caregivers: [Caregiver]

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
            .navigationTitle(listType.rawValue)
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

    private var mainManagerContent: some View {
        VStack(spacing: 16) {
            if let mainManager {
                caregiverDetailCard(mainManager)
            } else {
                emptyView(
                    icon: "person.crop.circle.badge.exclamationmark",
                    title: "尚未建立主要照護者",
                    message: "建立照護群組的人會成為主要管理者。"
                )
            }
        }
    }

    private var sharedCaregiversContent: some View {
        VStack(spacing: 16) {
            if sharedCaregivers.isEmpty {
                emptyView(
                    icon: "person.2.slash.fill",
                    title: "目前沒有共同照護者",
                    message: "其他家人、看護或被照護者本人加入並通過審核後，會顯示在這裡。"
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
                        Text(caregiver.name)
                            .font(.title3)
                            .fontWeight(.bold)

                        if caregiver.isCreator {
                            Text("建立者")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 4)
                                .background(AppTheme.primaryGreen)
                                .clipShape(Capsule())
                        }
                    }

                    Text(caregiver.role.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(roleColor(caregiver.role))
                }

                Spacer()
            }

            Divider()

            caregiverInfoRow(
                icon: "phone.fill",
                title: "電話",
                value: caregiver.phone.isEmpty ? "未填寫" : caregiver.phone
            )

            caregiverInfoRow(
                icon: "envelope.fill",
                title: "信箱 / 帳號",
                value: caregiver.email.isEmpty ? "未填寫" : caregiver.email
            )
            
            caregiverInfoRow(
                icon: "globe.asia.australia.fill",
                title: "使用語言",
                value: caregiver.preferredLanguage.displayName
            )
            
            caregiverInfoRow(
                icon: "checkmark.seal.fill",
                title: "加入狀態",
                value: caregiver.status.rawValue
            )
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
            name: "王小明",
            phone: "0912345678",
            email: "test@example.com",
            password: "",
            role: .mainManager,
            isCreator: true
        ),
        caregivers: []
    )
}
