import SwiftUI

struct WelcomeView: View {
    let selectedLanguage: AppLanguage
    let onCreateNewAccount: () -> Void
    let onJoinExistingAccount: () -> Void
    let onLogin: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                LogoView(size: 110)

                VStack(spacing: 10) {
                    Text(titleText)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(subtitleText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }

                VStack(spacing: 14) {
                    Button {
                        onCreateNewAccount()
                    } label: {
                        onboardingChoiceCard(
                            icon: "plus.circle.fill",
                            title: createTitle,
                            subtitle: createSubtitle
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        onJoinExistingAccount()
                    } label: {
                        onboardingChoiceCard(
                            icon: "person.badge.plus.fill",
                            title: joinTitle,
                            subtitle: joinSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        onLogin()
                    } label: {
                        onboardingChoiceCard(
                            icon: "person.crop.circle.fill",
                            title: loginTitle,
                            subtitle: loginSubtitle
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private var loginTitle: String {
        switch selectedLanguage {
        case .zhTW: return "我已有帳號，登入"
        case .en: return "I already have an account"
        case .id: return "Saya sudah punya akun"
        case .vi: return "Tôi đã có tài khoản"
        case .th: return "ฉันมีบัญชีแล้ว"
        case .ja: return "すでにアカウントを持っています"
        }
    }

    private var loginSubtitle: String {
        switch selectedLanguage {
        case .zhTW: return "使用 Email 與密碼登入照護帳戶"
        case .en: return "Log in with your email and password"
        case .id: return "Masuk dengan email dan kata sandi"
        case .vi: return "Đăng nhập bằng email và mật khẩu"
        case .th: return "เข้าสู่ระบบด้วยอีเมลและรหัสผ่าน"
        case .ja: return "メールとパスワードでログイン"
        }
    }
    
    private func onboardingChoiceCard(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 48, height: 48)
                .background(AppTheme.lightGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var titleText: String {
        switch selectedLanguage {
        case .zhTW:
            return "歡迎使用 CareBridge AI"
        case .en:
            return "Welcome to CareBridge AI"
        case .id:
            return "Selamat datang di CareBridge AI"
        case .vi:
            return "Chào mừng đến với CareBridge AI"
        case .th:
            return "ยินดีต้อนรับสู่ CareBridge AI"
        case .ja:
            return "CareBridge AIへようこそ"
        }
    }

    private var subtitleText: String {
        switch selectedLanguage {
        case .zhTW:
            return "協助家屬與照護者整理紀錄、溝通照護資訊"
        case .en:
            return "Helping families and caregivers organize care records and communication"
        case .id:
            return "Membantu keluarga dan perawat mengelola catatan dan komunikasi perawatan"
        case .vi:
            return "Hỗ trợ gia đình và người chăm sóc quản lý ghi chú và trao đổi chăm sóc"
        case .th:
            return "ช่วยครอบครัวและผู้ดูแลจัดการบันทึกและการสื่อสารด้านการดูแล"
        case .ja:
            return "家族と介護者の記録整理とコミュニケーションを支援します"
        }
    }

    private var createTitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "建立新的照護帳戶"
        case .en:
            return "Create a new care account"
        case .id:
            return "Buat akun perawatan baru"
        case .vi:
            return "Tạo tài khoản chăm sóc mới"
        case .th:
            return "สร้างบัญชีการดูแลใหม่"
        case .ja:
            return "新しい介護アカウントを作成"
        }
    }

    private var createSubtitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "適合主要照護者建立新的被照護者資料"
        case .en:
            return "For the main caregiver to create a new care recipient profile"
        case .id:
            return "Untuk pengelola utama membuat profil penerima perawatan"
        case .vi:
            return "Dành cho người chăm sóc chính tạo hồ sơ người được chăm sóc"
        case .th:
            return "สำหรับผู้ดูแลหลักสร้างข้อมูลผู้รับการดูแล"
        case .ja:
            return "主な介護者が新しい被介護者情報を作成します"
        }
    }

    private var joinTitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "加入現有照護帳戶"
        case .en:
            return "Join an existing care account"
        case .id:
            return "Bergabung dengan akun perawatan"
        case .vi:
            return "Tham gia tài khoản chăm sóc hiện có"
        case .th:
            return "เข้าร่วมบัญชีการดูแลที่มีอยู่"
        case .ja:
            return "既存の介護アカウントに参加"
        }
    }

    private var joinSubtitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "適合家人、看護或被照護者本人加入群組"
        case .en:
            return "For family members, caregivers, or the care recipient to join"
        case .id:
            return "Untuk keluarga, perawat, atau penerima perawatan bergabung"
        case .vi:
            return "Dành cho gia đình, người chăm sóc hoặc người được chăm sóc tham gia"
        case .th:
            return "สำหรับครอบครัว ผู้ดูแล หรือผู้รับการดูแลเข้าร่วม"
        case .ja:
            return "家族、介護者、本人がグループに参加します"
        }
    }
}

#Preview {
    WelcomeView(
        selectedLanguage: .zhTW,
        onCreateNewAccount: {},
        onJoinExistingAccount: {},
        onLogin: {}
    )
}
