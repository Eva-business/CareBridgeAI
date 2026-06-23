import SwiftUI

struct CaregiverRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let caregiver: Caregiver
    var canRemove: Bool = false
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(roleColor.opacity(0.15))
                    .frame(width: 46, height: 46)

                Image(systemName: roleIcon)
                    .foregroundStyle(roleColor)
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(caregiver.name.containsCareBridgeCJKText && !appLanguage.isChinese ? caregiver.role.displayName(appLanguage) : caregiver.name.localizedCareText(appLanguage))
                        .font(.headline)

                    if caregiver.isCreator {
                        Text(appLanguage.text(en: "Creator", zhTW: "建立者"))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(AppTheme.primaryGreen)
                            .clipShape(Capsule())
                    }
                }

                Text("\(caregiver.role.displayName(appLanguage)) - \(caregiver.status.displayName(appLanguage))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !caregiver.phone.isEmpty {
                    Text(caregiver.phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if canRemove {
                Button {
                    onRemove?()
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppTheme.dangerRed)
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var roleIcon: String {
        switch caregiver.role {
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

    private var roleColor: Color {
        switch caregiver.role {
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
    CaregiverRowView(
        caregiver: Caregiver(
            name: "Main Manager",
            phone: "0912345678",
            email: "test@example.com",
            password: "12345678",
            role: .mainManager,
            isCreator: true
        )
    )
    .padding()
    .background(AppTheme.background)
}
