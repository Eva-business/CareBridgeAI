import SwiftUI

struct CreateCaregiverGroupView: View {
    @Binding var draft: CareRecipientDraft
    let selectedLanguage: AppLanguage

    let onBack: () -> Void
    let onFinish: () -> Void

    @State private var managerName: String = ""
    @State private var managerPhone: String = ""
    @State private var managerEmail: String = ""
    @State private var managerPassword: String = ""
    @State private var confirmPassword: String = ""

    private var groupCode: String {
        draft.careRecipientID
    }

    private var inviteLink: String {
        InviteService.makeInviteLink(for: draft.careRecipientID)
    }
    
    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    topBar

                    StepIndicatorView(
                        currentStep: 2,
                        totalSteps: 3,
                        titles: [
                            AppText.basicInfo.text(selectedLanguage),
                            AppText.manager.text(selectedLanguage),
                            AppText.complete.text(selectedLanguage)
                        ]
                    )

                    managerAccountSection

                    inviteSection

                    PrimaryButton(title: finishInitialSetupText) {
                        onFinish()
                    }
                    .disabled(!hasMainManager)
                    .opacity(hasMainManager ? 1 : 0.5)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.immediately) // 💡 支援滑動收起鍵盤
        }
        .onAppear {
            loadExistingManagerToForm()
        }
        .dismissKeyboardOnTap() // 💡 套用專案內建的收鍵盤功能
    }

    private var topBar: some View {
        HStack {
            Button {
                onBack()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(width: 40, height: 40)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Spacer()

            LogoView(size: 44, showText: false)

            Spacer()

            Color.clear
                .frame(width: 40, height: 40)
        }
    }

    private var managerAccountSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppText.createManagerAccount.text(selectedLanguage))
                .font(.title2)
                .fontWeight(.bold)

            Text(managerDescriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let manager = mainManager {
                CaregiverRowView(caregiver: manager)

                Button {
                    resetMainManager()
                } label: {
                    HStack {
                        Image(systemName: "arrow.counterclockwise")
                        Text(resetManagerText)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppTheme.dangerRed)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.dangerRed.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            } else {
                FormTextField(
                    title: AppText.managerName.text(selectedLanguage),
                    placeholder: managerNamePlaceholderText,
                    text: $managerName
                )

                FormTextField(
                    title: AppText.managerPhone.text(selectedLanguage),
                    placeholder: managerPhonePlaceholderText,
                    text: $managerPhone,
                    keyboardType: .phonePad
                )

                FormTextField(
                    title: AppText.managerEmail.text(selectedLanguage),
                    placeholder: "care@example.com",
                    text: $managerEmail,
                    keyboardType: .emailAddress
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.password.text(selectedLanguage))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    SecureField(passwordPlaceholderText, text: $managerPassword)
                        .submitLabel(.next)
                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.confirmPassword.text(selectedLanguage))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    SecureField(confirmPasswordPlaceholderText, text: $confirmPassword)

                        .textFieldStyle(.plain)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        }
                }

                if !passwordMessage.isEmpty {
                    Text(passwordMessage)
                        .font(.caption)
                        .foregroundStyle(passwordsAreValid ? AppTheme.primaryGreen : AppTheme.dangerRed)
                }

                Button {
                    createMainManagerAccount()
                } label: {
                    HStack {
                        Image(systemName: "crown.fill")
                        Text(AppText.createManagerAccount.text(selectedLanguage))
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canCreateManager ? AppTheme.primaryGreen : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(!canCreateManager)
            }
        }
        .padding()
        .background(Color.white.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var inviteSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppText.inviteFamilyCaregiver.text(selectedLanguage))
                .font(.title2)
                .fontWeight(.bold)

            Text(inviteDescriptionText)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            VStack(spacing: 14) {
                QRCodeView(text: inviteLink, size: 180)

                VStack(spacing: 6) {
                    Text(AppText.careAccountID.text(selectedLanguage))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(groupCode)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .textSelection(.enabled)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 8) {
                Text(inviteLinkTitleText)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                HStack(spacing: 10) {
                    Text(inviteLink)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)

                    Spacer()

                    Button {
                        UIPasteboard.general.string = inviteLink
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .foregroundStyle(AppTheme.primaryGreen)
                    }
                }
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle.fill")
                    .foregroundStyle(AppTheme.primaryGreen)

                Text(inviteNoteText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(AppTheme.lightGreen)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding()
        .background(Color.white.opacity(0.68))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }

    private var mainManager: Caregiver? {
        draft.caregivers.first {
            $0.role == .mainManager && $0.status == .approved
        }
    }

    private var hasMainManager: Bool {
        mainManager != nil
    }

    private var canCreateManager: Bool {
        !managerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !managerEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        passwordsAreValid
    }

    private var passwordsAreValid: Bool {
        managerPassword.count >= 8 &&
        managerPassword == confirmPassword
    }

    private var passwordMessage: String {
        if managerPassword.isEmpty && confirmPassword.isEmpty {
            return ""
        }

        if managerPassword.count < 8 {
            return passwordTooShortText
        }

        if managerPassword != confirmPassword {
            return passwordNotMatchText
        }

        return passwordValidText
    }

    private func createMainManagerAccount() {
        let manager = Caregiver(
            name: managerName,
            phone: managerPhone,
            email: managerEmail,
            password: managerPassword,
            role: .mainManager,
            status: .approved,
            isCreator: true,
            preferredLanguage: selectedLanguage
        )

        draft.caregivers.removeAll { $0.role == .mainManager }
        draft.caregivers.insert(manager, at: 0)

        clearManagerForm()
    }

    private func resetMainManager() {
        guard let manager = mainManager else { return }

        managerName = manager.name
        managerPhone = manager.phone
        managerEmail = manager.email
        managerPassword = ""
        confirmPassword = ""

        draft.caregivers.removeAll { $0.id == manager.id }
    }

    private func clearManagerForm() {
        managerName = ""
        managerPhone = ""
        managerEmail = ""
        managerPassword = ""
        confirmPassword = ""
    }

    private func loadExistingManagerToForm() {
        guard let manager = mainManager else { return }

        managerName = manager.name
        managerPhone = manager.phone
        managerEmail = manager.email
    }

    private var managerDescriptionText: String {
        switch selectedLanguage {
        case .zhTW:
            return "建立此帳戶的人會成為主要管理者。主要管理者可以審核加入申請、移除成員，以及刪除整個照護群組。"
        case .en:
            return "The person who creates this account becomes the main manager. The main manager can approve join requests, remove members, and delete the care group."
        case .id:
            return "Orang yang membuat akun ini akan menjadi pengelola utama. Pengelola utama dapat menyetujui permintaan bergabung, menghapus anggota, dan menghapus grup perawatan."
        case .vi:
            return "Người tạo tài khoản này sẽ trở thành người quản lý chính. Người quản lý chính có thể duyệt yêu cầu tham gia, xóa thành viên và xóa nhóm chăm sóc."
        case .th:
            return "ผู้ที่สร้างบัญชีนี้จะเป็นผู้จัดการหลัก สามารถอนุมัติคำขอเข้าร่วม ลบสมาชิก และลบกลุ่มการดูแลได้"
        case .ja:
            return "このアカウントを作成した人が主管理者になります。主管理者は参加申請の承認、メンバー削除、介護グループの削除ができます。"
        }
    }

    private var managerNamePlaceholderText: String {
        switch selectedLanguage {
        case .zhTW:
            return "請輸入你的姓名"
        case .en:
            return "Enter your name"
        case .id:
            return "Masukkan nama Anda"
        case .vi:
            return "Nhập tên của bạn"
        case .th:
            return "กรอกชื่อของคุณ"
        case .ja:
            return "あなたの名前を入力"
        }
    }

    private var managerPhonePlaceholderText: String {
        switch selectedLanguage {
        case .zhTW:
            return "請輸入電話"
        case .en:
            return "Enter phone number"
        case .id:
            return "Masukkan nomor telepon"
        case .vi:
            return "Nhập số điện thoại"
        case .th:
            return "กรอกหมายเลขโทรศัพท์"
        case .ja:
            return "電話番号を入力"
        }
    }

    private var passwordPlaceholderText: String {
        switch selectedLanguage {
        case .zhTW:
            return "請輸入至少 8 碼密碼"
        case .en:
            return "Enter at least 8 characters"
        case .id:
            return "Masukkan minimal 8 karakter"
        case .vi:
            return "Nhập ít nhất 8 ký tự"
        case .th:
            return "กรอกรหัสผ่านอย่างน้อย 8 ตัวอักษร"
        case .ja:
            return "8文字以上で入力"
        }
    }

    private var confirmPasswordPlaceholderText: String {
        switch selectedLanguage {
        case .zhTW:
            return "請再次輸入密碼"
        case .en:
            return "Enter the password again"
        case .id:
            return "Masukkan kata sandi lagi"
        case .vi:
            return "Nhập lại mật khẩu"
        case .th:
            return "กรอกรหัสผ่านอีกครั้ง"
        case .ja:
            return "もう一度パスワードを入力"
        }
    }

    private var passwordTooShortText: String {
        switch selectedLanguage {
        case .zhTW:
            return "密碼至少需要 8 碼"
        case .en:
            return "Password must be at least 8 characters"
        case .id:
            return "Kata sandi minimal 8 karakter"
        case .vi:
            return "Mật khẩu phải có ít nhất 8 ký tự"
        case .th:
            return "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร"
        case .ja:
            return "パスワードは8文字以上必要です"
        }
    }

    private var passwordNotMatchText: String {
        switch selectedLanguage {
        case .zhTW:
            return "兩次輸入的密碼不一致"
        case .en:
            return "The passwords do not match"
        case .id:
            return "Kata sandi tidak sama"
        case .vi:
            return "Mật khẩu không khớp"
        case .th:
            return "รหัสผ่านไม่ตรงกัน"
        case .ja:
            return "パスワードが一致しません"
        }
    }

    private var passwordValidText: String {
        switch selectedLanguage {
        case .zhTW:
            return "密碼格式正確"
        case .en:
            return "Password looks good"
        case .id:
            return "Format kata sandi benar"
        case .vi:
            return "Mật khẩu hợp lệ"
        case .th:
            return "รูปแบบรหัสผ่านถูกต้อง"
        case .ja:
            return "パスワード形式は正しいです"
        }
    }

    private var resetManagerText: String {
        switch selectedLanguage {
        case .zhTW:
            return "取消並重新填寫"
        case .en:
            return "Cancel and fill again"
        case .id:
            return "Batalkan dan isi ulang"
        case .vi:
            return "Hủy và nhập lại"
        case .th:
            return "ยกเลิกและกรอกใหม่"
        case .ja:
            return "キャンセルして再入力"
        }
    }

    private var inviteDescriptionText: String {
        switch selectedLanguage {
        case .zhTW:
            return "其他家人、看護或被照護者本人，請透過 QR Code 或邀請連結加入。受邀者加入時需要建立自己的帳號密碼，並等待主要管理者審核。"
        case .en:
            return "Other family members, caregivers, or the care recipient can join through the QR code or invite link. They need to create their own account and wait for approval."
        case .id:
            return "Anggota keluarga lain, perawat, atau penerima perawatan dapat bergabung melalui QR Code atau tautan undangan. Mereka perlu membuat akun sendiri dan menunggu persetujuan."
        case .vi:
            return "Các thành viên gia đình, người chăm sóc hoặc người được chăm sóc có thể tham gia qua mã QR hoặc liên kết mời. Họ cần tạo tài khoản riêng và chờ phê duyệt."
        case .th:
            return "สมาชิกครอบครัว ผู้ดูแล หรือผู้รับการดูแลสามารถเข้าร่วมผ่าน QR Code หรือลิงก์เชิญ ต้องสร้างบัญชีของตนเองและรอการอนุมัติ"
        case .ja:
            return "他の家族、介護者、または本人はQRコードまたは招待リンクから参加できます。参加時に自分のアカウントを作成し、承認を待つ必要があります。"
        }
    }

    private var inviteLinkTitleText: String {
        switch selectedLanguage {
        case .zhTW:
            return "邀請連結"
        case .en:
            return "Invite link"
        case .id:
            return "Tautan undangan"
        case .vi:
            return "Liên kết mời"
        case .th:
            return "ลิงก์เชิญ"
        case .ja:
            return "招待リンク"
        }
    }

    private var inviteNoteText: String {
        switch selectedLanguage {
        case .zhTW:
            return "目前不需要由主要管理者手動輸入其他成員。其他人會自己註冊帳號並申請加入。"
        case .en:
            return "The main manager does not need to manually add other members. Others will create their own accounts and request to join."
        case .id:
            return "Pengelola utama tidak perlu memasukkan anggota lain secara manual. Orang lain akan membuat akun sendiri dan mengajukan permintaan bergabung."
        case .vi:
            return "Người quản lý chính không cần nhập thủ công các thành viên khác. Những người khác sẽ tự tạo tài khoản và gửi yêu cầu tham gia."
        case .th:
            return "ผู้จัดการหลักไม่จำเป็นต้องเพิ่มสมาชิกคนอื่นด้วยตนเอง ผู้อื่นจะสร้างบัญชีและส่งคำขอเข้าร่วมเอง"
        case .ja:
            return "主管理者が他のメンバーを手動で入力する必要はありません。他の人は自分でアカウントを作成し、参加申請します。"
        }
    }

    private var finishInitialSetupText: String {
        switch selectedLanguage {
        case .zhTW:
            return "完成初始設定"
        case .en:
            return "Finish setup"
        case .id:
            return "Selesaikan pengaturan"
        case .vi:
            return "Hoàn tất thiết lập"
        case .th:
            return "ตั้งค่าให้เสร็จสิ้น"
        case .ja:
            return "初期設定を完了"
        }
    }
}

#Preview {
    CreateCaregiverGroupView(
        draft: .constant(CareRecipientDraft()),
        selectedLanguage: .zhTW,
        onBack: {},
        onFinish: {}
    )
}
