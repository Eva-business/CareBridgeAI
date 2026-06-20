import SwiftUI

struct SetupCompleteView: View {
    let draft: CareRecipientDraft
    let selectedLanguage: AppLanguage
    let onEnterHome: () -> Void

    private var manager: Caregiver? {
        draft.caregivers.first {
            $0.role == .mainManager && $0.status == .approved
        }
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 26) {
                    LogoView(size: 72, showText: true)

                    StepIndicatorView(
                        currentStep: 3,
                        totalSteps: 3,
                        titles: [
                            AppText.basicInfo.text(selectedLanguage),
                            AppText.manager.text(selectedLanguage),
                            AppText.complete.text(selectedLanguage)
                        ]
                    )

                    completeCard

                    summarySection

                    PrimaryButton(title: AppText.enterHome.text(selectedLanguage)) {
                        onEnterHome()
                    }
                }
                .padding(24)
            }
        }
    }

    private var completeCard: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(AppTheme.lightGreen)
                    .frame(width: 110, height: 110)

                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 58))
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            Text(AppText.setupComplete.text(selectedLanguage))
                .font(.title)
                .fontWeight(.bold)

            Text(completeDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(summaryTitle)
                .font(.title2)
                .fontWeight(.bold)

            SummaryRow(
                icon: "person.fill",
                title: AppText.careRecipient.text(selectedLanguage),
                value: draft.name.isEmpty ? "-" : draft.name
            )

            SummaryRow(
                icon: "crown.fill",
                title: AppText.mainManager.text(selectedLanguage),
                value: manager?.name ?? "-"
            )

            SummaryRow(
                icon: "number",
                title: "CareBridge ID",
                value: draft.careRecipientID
            )

            SummaryRow(
                icon: "qrcode",
                title: AppText.inviteMethod.text(selectedLanguage),
                value: inviteMethodValue
            )

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.primaryGreen)

                Text(AppText.inviteDescription.text(selectedLanguage))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
            }
            .padding()
            .background(AppTheme.lightGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var completeDescription: String {
        switch selectedLanguage {
        case .zhTW:
            return "CareBridge AI 已為你建立照護群組，接下來可以開始記錄照護狀況、安排任務，並邀請其他成員加入。"
        case .en:
            return "CareBridge AI has created your care group. You can now record care updates, arrange tasks, and invite other members."
        case .id:
            return "CareBridge AI telah membuat grup perawatan Anda. Sekarang Anda dapat mencatat kondisi perawatan, mengatur tugas, dan mengundang anggota lain."
        case .vi:
            return "CareBridge AI đã tạo nhóm chăm sóc cho bạn. Bây giờ bạn có thể ghi lại tình trạng chăm sóc, sắp xếp nhiệm vụ và mời thành viên khác."
        case .th:
            return "CareBridge AI ได้สร้างกลุ่มการดูแลของคุณแล้ว ตอนนี้คุณสามารถบันทึกข้อมูลการดูแล จัดการงาน และเชิญสมาชิกคนอื่นได้"
        case .ja:
            return "CareBridge AI が介護グループを作成しました。これから介護記録、タスク管理、メンバー招待を始められます。"
        }
    }

    private var summaryTitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "建立內容確認"
        case .en:
            return "Setup summary"
        case .id:
            return "Ringkasan pembuatan"
        case .vi:
            return "Tóm tắt thiết lập"
        case .th:
            return "สรุปการตั้งค่า"
        case .ja:
            return "作成内容の確認"
        }
    }

    private var inviteMethodValue: String {
        switch selectedLanguage {
        case .zhTW:
            return "QR Code 與邀請連結"
        case .en:
            return "QR Code and invite link"
        case .id:
            return "QR Code dan tautan undangan"
        case .vi:
            return "Mã QR và liên kết mời"
        case .th:
            return "QR Code และลิงก์เชิญ"
        case .ja:
            return "QRコードと招待リンク"
        }
    }
}

struct SummaryRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 34, height: 34)
                .background(AppTheme.lightGreen)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

#Preview {
    SetupCompleteView(
        draft: CareRecipientDraft(),
        selectedLanguage: .zhTW,
        onEnterHome: {}
    )
}
