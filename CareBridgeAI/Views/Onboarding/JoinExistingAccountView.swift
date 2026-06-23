import SwiftUI

struct JoinExistingAccountView: View {
    let selectedLanguage: AppLanguage
    let presetCareRecipientID: String

    let onBack: () -> Void
    let onFinish: () -> Void

    @State private var careRecipientID: String = ""
    @State private var name: String = ""
    @State private var phone: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var selectedRole: CaregiverRole = .family
    @State private var joinNote: String = ""

    @State private var hasSubmitted = false

    private var canSubmit: Bool {
        !careRecipientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        passwordsAreValid
    }

    private var passwordsAreValid: Bool {
        password.count >= 8 && password == confirmPassword
    }

    private var passwordMessage: String {
        if password.isEmpty && confirmPassword.isEmpty {
            return ""
        }

        if password.count < 8 {
            return passwordTooShortText
        }

        if password != confirmPassword {
            return passwordNotMatchText
        }

        return passwordValidText
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            if hasSubmitted {
                submittedView
            } else {
                formView
            }
        }
        .onAppear {
            careRecipientID = presetCareRecipientID
        }
        .dismissKeyboardOnTap() // 💡 套用專案內建的收鍵盤功能
    }

    private var formView: some View {
        ScrollView {
            VStack(spacing: 24) {
                topBar

                headerSection

                accountIDSection

                userInfoSection

                PrimaryButton(title: submitButtonText) {
                    submitJoinRequest()
                }
                .disabled(!canSubmit)
                .opacity(canSubmit ? 1 : 0.5)
            }
            .padding(24)
        }
        .scrollDismissesKeyboard(.immediately) // 支援滑動收起鍵盤
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

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.plus.fill")
                .font(.system(size: 54))
                .foregroundStyle(AppTheme.primaryGreen)

            Text(pageTitle)
                .font(.title)
                .fontWeight(.bold)

            Text(pageDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var accountIDSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(careAccountIDTitle)
                .font(.title2)
                .fontWeight(.bold)

            FormTextField(
                title: careAccountIDTitle,
                placeholder: "CB-XXXX-XXXX",
                text: $careRecipientID
            )

            Text(accountIDHintText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var userInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(userInfoTitle)
                .font(.title2)
                .fontWeight(.bold)

            FormTextField(
                title: AppText.name.text(selectedLanguage),
                placeholder: namePlaceholderText,
                text: $name
            )

            FormTextField(
                title: AppText.managerPhone.text(selectedLanguage),
                placeholder: phonePlaceholderText,
                text: $phone,
                keyboardType: .phonePad
            )

            FormTextField(
                title: AppText.managerEmail.text(selectedLanguage),
                placeholder: "care@example.com",
                text: $email,
                keyboardType: .emailAddress
            )

            rolePicker

            passwordFields

            FormTextEditor(
                title: joinNoteTitle,
                placeholder: joinNotePlaceholder,
                text: $joinNote
            )
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var rolePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(roleTitle)
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker(roleTitle, selection: $selectedRole) {
                Text(roleText(.family)).tag(CaregiverRole.family)
                Text(roleText(.caregiver)).tag(CaregiverRole.caregiver)
                Text(roleText(.recipientSelf)).tag(CaregiverRole.recipientSelf)
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }
        }
    }

    private var passwordFields: some View {
        VStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(AppText.password.text(selectedLanguage))
                    .font(.subheadline)
                    .fontWeight(.semibold)

                SecureField(passwordPlaceholderText, text: $password)
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
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var submittedView: some View {
        VStack(spacing: 24) {
            Spacer()

            LogoView(size: 72, showText: true)

            ZStack {
                Circle()
                    .fill(AppTheme.lightGreen)
                    .frame(width: 120, height: 120)

                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            VStack(spacing: 10) {
                Text(submittedTitle)
                    .font(.title)
                    .fontWeight(.bold)

                Text(submittedDescription)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            VStack(alignment: .leading, spacing: 12) {
                SummaryRow(
                    icon: "number",
                    title: careAccountIDTitle,
                    value: careRecipientID
                )

                SummaryRow(
                    icon: "person.fill",
                    title: AppText.name.text(selectedLanguage),
                    value: name
                )

                SummaryRow(
                    icon: "person.crop.circle.badge.checkmark",
                    title: roleTitle,
                    value: roleText(selectedRole)
                )
            }
            .padding()
            .background(Color.white.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)

            PrimaryButton(title: finishButtonText) {
                onFinish()
            }

            Spacer()
        }
        .padding(24)
    }

    private func submitJoinRequest() {
        let request = Caregiver(
            name: name,
            phone: phone,
            email: email,
            password: password,
            role: selectedRole,
            status: .pending,
            isCreator: false,
            preferredLanguage: selectedLanguage
        )

        CareAccountStore.shared.submitJoinRequest(
            careRecipientID: careRecipientID,
            caregiver: request
        )

        print("送出加入申請：\(request)")
        print("加入帳戶 ID：\(careRecipientID)")
        print("加入備註：\(joinNote)")

        hasSubmitted = true
    }

    private var pageTitle: String {
        switch selectedLanguage {
        case .zhTW: return "加入現有照護帳戶"
        case .en: return "Join an existing care account"
        case .id: return "Bergabung dengan akun perawatan"
        case .vi: return "Tham gia tài khoản chăm sóc hiện có"
        case .th: return "เข้าร่วมบัญชีการดูแลที่มีอยู่"
        case .ja: return "既存の介護アカウントに参加"
        }
    }

    private var pageDescription: String {
        switch selectedLanguage {
        case .zhTW:
            return "請輸入照護帳戶 ID，並建立自己的帳號。送出後需要等待主要管理者審核。"
        case .en:
            return "Enter the care account ID and create your own account. Your request must be approved by the main manager."
        case .id:
            return "Masukkan ID akun perawatan dan buat akun Anda sendiri. Permintaan Anda harus disetujui oleh pengelola utama."
        case .vi:
            return "Nhập ID tài khoản chăm sóc và tạo tài khoản của riêng bạn. Yêu cầu cần được người quản lý chính phê duyệt."
        case .th:
            return "กรอก ID บัญชีการดูแลและสร้างบัญชีของคุณเอง คำขอจะต้องได้รับการอนุมัติจากผู้จัดการหลัก"
        case .ja:
            return "介護アカウントIDを入力し、自分のアカウントを作成してください。申請は主管理者の承認が必要です。"
        }
    }

    private var careAccountIDTitle: String {
        switch selectedLanguage {
        case .zhTW: return "照護帳戶 ID"
        case .en: return "Care account ID"
        case .id: return "ID akun perawatan"
        case .vi: return "ID tài khoản chăm sóc"
        case .th: return "ID บัญชีการดูแล"
        case .ja: return "介護アカウントID"
        }
    }

    private var accountIDHintText: String {
        switch selectedLanguage {
        case .zhTW:
            return "如果你是透過邀請連結或 QR Code 進入，這個 ID 會自動填入。若是自行加入，請向主要管理者取得 ID。"
        case .en:
            return "If you entered through an invite link or QR code, this ID will be filled automatically. Otherwise, ask the main manager for the ID."
        case .id:
            return "Jika Anda masuk melalui tautan undangan atau QR Code, ID ini akan terisi otomatis. Jika tidak, minta ID kepada pengelola utama."
        case .vi:
            return "Nếu bạn vào bằng liên kết mời hoặc mã QR, ID này sẽ tự động điền. Nếu không, hãy hỏi người quản lý chính."
        case .th:
            return "หากคุณเข้าผ่านลิงก์เชิญหรือ QR Code ระบบจะกรอก ID ให้อัตโนมัติ หากไม่ใช่ โปรดขอ ID จากผู้จัดการหลัก"
        case .ja:
            return "招待リンクまたはQRコードから入った場合、このIDは自動入力されます。そうでない場合は主管理者にIDを確認してください。"
        }
    }

    private var userInfoTitle: String {
        switch selectedLanguage {
        case .zhTW: return "建立你的帳號"
        case .en: return "Create your account"
        case .id: return "Buat akun Anda"
        case .vi: return "Tạo tài khoản của bạn"
        case .th: return "สร้างบัญชีของคุณ"
        case .ja: return "あなたのアカウントを作成"
        }
    }

    private var namePlaceholderText: String {
        switch selectedLanguage {
        case .zhTW: return "請輸入你的姓名"
        case .en: return "Enter your name"
        case .id: return "Masukkan nama Anda"
        case .vi: return "Nhập tên của bạn"
        case .th: return "กรอกชื่อของคุณ"
        case .ja: return "あなたの名前を入力"
        }
    }

    private var phonePlaceholderText: String {
        switch selectedLanguage {
        case .zhTW: return "請輸入電話"
        case .en: return "Enter phone number"
        case .id: return "Masukkan nomor telepon"
        case .vi: return "Nhập số điện thoại"
        case .th: return "กรอกหมายเลขโทรศัพท์"
        case .ja: return "電話番号を入力"
        }
    }

    private var roleTitle: String {
        switch selectedLanguage {
        case .zhTW: return "你的身分"
        case .en: return "Your role"
        case .id: return "Peran Anda"
        case .vi: return "Vai trò của bạn"
        case .th: return "บทบาทของคุณ"
        case .ja: return "あなたの役割"
        }
    }

    private func roleText(_ role: CaregiverRole) -> String {
        switch selectedLanguage {
        case .zhTW:
            return role.rawValue
        case .en:
            switch role {
            case .mainManager: return "Main manager"
            case .family: return "Family member"
            case .caregiver: return "Caregiver"
            case .recipientSelf: return "Care recipient"
            }
        case .id:
            switch role {
            case .mainManager: return "Pengelola utama"
            case .family: return "Anggota keluarga"
            case .caregiver: return "Perawat"
            case .recipientSelf: return "Penerima perawatan"
            }
        case .vi:
            switch role {
            case .mainManager: return "Người quản lý chính"
            case .family: return "Thành viên gia đình"
            case .caregiver: return "Người chăm sóc"
            case .recipientSelf: return "Người được chăm sóc"
            }
        case .th:
            switch role {
            case .mainManager: return "ผู้จัดการหลัก"
            case .family: return "สมาชิกครอบครัว"
            case .caregiver: return "ผู้ดูแล"
            case .recipientSelf: return "ผู้รับการดูแล"
            }
        case .ja:
            switch role {
            case .mainManager: return "主管理者"
            case .family: return "家族"
            case .caregiver: return "介護者"
            case .recipientSelf: return "被介護者本人"
            }
        }
    }

    private var passwordPlaceholderText: String {
        switch selectedLanguage {
        case .zhTW: return "請輸入至少 8 碼密碼"
        case .en: return "Enter at least 8 characters"
        case .id: return "Masukkan minimal 8 karakter"
        case .vi: return "Nhập ít nhất 8 ký tự"
        case .th: return "กรอกรหัสผ่านอย่างน้อย 8 ตัวอักษร"
        case .ja: return "8文字以上で入力"
        }
    }

    private var confirmPasswordPlaceholderText: String {
        switch selectedLanguage {
        case .zhTW: return "請再次輸入密碼"
        case .en: return "Enter the password again"
        case .id: return "Masukkan kata sandi lagi"
        case .vi: return "Nhập lại mật khẩu"
        case .th: return "กรอกรหัสผ่านอีกครั้ง"
        case .ja: return "もう一度パスワードを入力"
        }
    }

    private var passwordTooShortText: String {
        switch selectedLanguage {
        case .zhTW: return "密碼至少需要 8 碼"
        case .en: return "Password must be at least 8 characters"
        case .id: return "Kata sandi minimal 8 karakter"
        case .vi: return "Mật khẩu phải có ít nhất 8 ký tự"
        case .th: return "รหัสผ่านต้องมีอย่างน้อย 8 ตัวอักษร"
        case .ja: return "パスワードは8文字以上必要です"
        }
    }

    private var passwordNotMatchText: String {
        switch selectedLanguage {
        case .zhTW: return "兩次輸入的密碼不一致"
        case .en: return "The passwords do not match"
        case .id: return "Kata sandi tidak sama"
        case .vi: return "Mật khẩu không khớp"
        case .th: return "รหัสผ่านไม่ตรงกัน"
        case .ja: return "パスワードが一致しません"
        }
    }

    private var passwordValidText: String {
        switch selectedLanguage {
        case .zhTW: return "密碼格式正確"
        case .en: return "Password looks good"
        case .id: return "Format kata sandi benar"
        case .vi: return "Mật khẩu hợp lệ"
        case .th: return "รูปแบบรหัสผ่านถูกต้อง"
        case .ja: return "パスワード形式は正しいです"
        }
    }

    private var joinNoteTitle: String {
        switch selectedLanguage {
        case .zhTW: return "申請備註"
        case .en: return "Request note"
        case .id: return "Catatan permintaan"
        case .vi: return "Ghi chú yêu cầu"
        case .th: return "หมายเหตุคำขอ"
        case .ja: return "申請メモ"
        }
    }

    private var joinNotePlaceholder: String {
        switch selectedLanguage {
        case .zhTW: return "例如：我是王奶奶的女兒、我是平日看護"
        case .en: return "Example: I am her daughter, or I am the weekday caregiver"
        case .id: return "Contoh: Saya putrinya, atau saya perawat hari kerja"
        case .vi: return "Ví dụ: Tôi là con gái, hoặc tôi là người chăm sóc ngày thường"
        case .th: return "เช่น ฉันเป็นลูกสาว หรือเป็นผู้ดูแลวันธรรมดา"
        case .ja: return "例：私は娘です、または平日の介護者です"
        }
    }

    private var submitButtonText: String {
        switch selectedLanguage {
        case .zhTW: return "送出加入申請"
        case .en: return "Submit join request"
        case .id: return "Kirim permintaan bergabung"
        case .vi: return "Gửi yêu cầu tham gia"
        case .th: return "ส่งคำขอเข้าร่วม"
        case .ja: return "参加申請を送信"
        }
    }

    private var submittedTitle: String {
        switch selectedLanguage {
        case .zhTW: return "已送出加入申請"
        case .en: return "Join request submitted"
        case .id: return "Permintaan bergabung terkirim"
        case .vi: return "Đã gửi yêu cầu tham gia"
        case .th: return "ส่งคำขอเข้าร่วมแล้ว"
        case .ja: return "参加申請を送信しました"
        }
    }

    private var submittedDescription: String {
        switch selectedLanguage {
        case .zhTW:
            return "你的申請已送出，請等待主要管理者審核。審核通過後，你就可以查看照護紀錄、任務與聊天室。"
        case .en:
            return "Your request has been sent. Please wait for the main manager to approve it. After approval, you can view records, tasks, and chat."
        case .id:
            return "Permintaan Anda telah dikirim. Tunggu persetujuan pengelola utama. Setelah disetujui, Anda dapat melihat catatan, tugas, dan obrolan."
        case .vi:
            return "Yêu cầu của bạn đã được gửi. Vui lòng chờ người quản lý chính phê duyệt. Sau khi được duyệt, bạn có thể xem ghi chú, nhiệm vụ và trò chuyện."
        case .th:
            return "คำขอของคุณถูกส่งแล้ว โปรดรอให้ผู้จัดการหลักอนุมัติ หลังจากอนุมัติแล้ว คุณจะดูบันทึก งาน และแชทได้"
        case .ja:
            return "申請が送信されました。主管理者の承認をお待ちください。承認後、記録、タスク、チャットを確認できます。"
        }
    }

    private var finishButtonText: String {
        switch selectedLanguage {
        case .zhTW: return "完成"
        case .en: return "Finish"
        case .id: return "Selesai"
        case .vi: return "Hoàn tất"
        case .th: return "เสร็จสิ้น"
        case .ja: return "完了"
        }
    }
}

#Preview {
    JoinExistingAccountView(
        selectedLanguage: .zhTW,
        presetCareRecipientID: "CB-DXXG-VAND",
        onBack: {},
        onFinish: {}
    )
}
