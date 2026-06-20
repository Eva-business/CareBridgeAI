import SwiftUI

struct LoginView: View {
    let selectedLanguage: AppLanguage
    let onBack: () -> Void
    let onLoginSuccess: (CareRecipientDraft, Caregiver) -> Void

    @State private var email = ""
    @State private var password = ""
    @State private var message = ""

    private var canLogin: Bool {
        !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !password.isEmpty
    }

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    topBar

                    LogoView(size: 86)

                    VStack(spacing: 10) {
                        Text(loginTitle)
                            .font(.title)
                            .fontWeight(.bold)

                        Text(loginDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(spacing: 16) {
                        FormTextField(
                            title: AppText.managerEmail.text(selectedLanguage),
                            placeholder: "care@example.com",
                            text: $email,
                            keyboardType: .emailAddress
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppText.password.text(selectedLanguage))
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            SecureField(AppText.password.text(selectedLanguage), text: $password)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                }
                        }

                        if !message.isEmpty {
                            Text(message)
                                .font(.caption)
                                .foregroundStyle(AppTheme.dangerRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        PrimaryButton(title: loginButtonText) {
                            login()
                        }
                        .disabled(!canLogin)
                        .opacity(canLogin ? 1 : 0.5)
                    }
                    .padding()
                    .background(Color.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                }
                .padding(24)
            }
        }
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
        }
    }

    private func login() {
        let result = CareAccountStore.shared.login(
            email: email,
            password: password
        )

        switch result {
        case .success(let draft, let user):
            message = ""
            onLoginSuccess(draft, user)

        case .pending:
            message = pendingText

        case .rejected:
            message = rejectedText

        case .wrongPassword:
            message = wrongPasswordText

        case .notFound:
            message = notFoundText
        }
    }

    private var loginTitle: String {
        switch selectedLanguage {
        case .zhTW: return "登入"
        case .en: return "Log in"
        case .id: return "Masuk"
        case .vi: return "Đăng nhập"
        case .th: return "เข้าสู่ระบบ"
        case .ja: return "ログイン"
        }
    }

    private var loginDescription: String {
        switch selectedLanguage {
        case .zhTW: return "請使用你註冊時的 Email 與密碼登入。"
        case .en: return "Log in with the email and password you registered with."
        case .id: return "Masuk dengan email dan kata sandi yang Anda daftarkan."
        case .vi: return "Đăng nhập bằng email và mật khẩu bạn đã đăng ký."
        case .th: return "เข้าสู่ระบบด้วยอีเมลและรหัสผ่านที่คุณลงทะเบียนไว้"
        case .ja: return "登録したメールアドレスとパスワードでログインしてください。"
        }
    }

    private var loginButtonText: String {
        switch selectedLanguage {
        case .zhTW: return "登入"
        case .en: return "Log in"
        case .id: return "Masuk"
        case .vi: return "Đăng nhập"
        case .th: return "เข้าสู่ระบบ"
        case .ja: return "ログイン"
        }
    }

    private var pendingText: String {
        switch selectedLanguage {
        case .zhTW: return "你的加入申請尚未通過審核。"
        case .en: return "Your join request is still pending approval."
        case .id: return "Permintaan bergabung Anda masih menunggu persetujuan."
        case .vi: return "Yêu cầu tham gia của bạn vẫn đang chờ phê duyệt."
        case .th: return "คำขอเข้าร่วมของคุณยังรอการอนุมัติ"
        case .ja: return "参加申請はまだ承認待ちです。"
        }
    }

    private var rejectedText: String {
        switch selectedLanguage {
        case .zhTW: return "你的加入申請已被拒絕。"
        case .en: return "Your join request was rejected."
        case .id: return "Permintaan bergabung Anda ditolak."
        case .vi: return "Yêu cầu tham gia của bạn đã bị từ chối."
        case .th: return "คำขอเข้าร่วมของคุณถูกปฏิเสธ"
        case .ja: return "参加申請は拒否されました。"
        }
    }

    private var wrongPasswordText: String {
        switch selectedLanguage {
        case .zhTW: return "密碼錯誤。"
        case .en: return "Incorrect password."
        case .id: return "Kata sandi salah."
        case .vi: return "Mật khẩu không đúng."
        case .th: return "รหัสผ่านไม่ถูกต้อง"
        case .ja: return "パスワードが正しくありません。"
        }
    }

    private var notFoundText: String {
        switch selectedLanguage {
        case .zhTW: return "找不到此帳號。"
        case .en: return "Account not found."
        case .id: return "Akun tidak ditemukan."
        case .vi: return "Không tìm thấy tài khoản."
        case .th: return "ไม่พบบัญชีนี้"
        case .ja: return "このアカウントは見つかりません。"
        }
    }
}

#Preview {
    LoginView(
        selectedLanguage: .zhTW,
        onBack: {},
        onLoginSuccess: { _, _ in }
    )
}
