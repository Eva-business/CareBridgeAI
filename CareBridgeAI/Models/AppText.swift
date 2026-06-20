import Foundation

enum AppText {
    case next
    case back
    case finish
    case createCareRecipientProfile
    case basicInfo
    case manager
    case complete

    case name
    case namePlaceholder
    case relationship
    case relationshipPlaceholder
    case gender
    case female
    case male
    case other
    case birthday
    case bloodType
    case select
    case contactAddressNote
    case contactAddressPlaceholder

    case createManagerAccount
    case managerName
    case managerPhone
    case managerEmail
    case password
    case confirmPassword
    case inviteFamilyCaregiver
    case inviteDescription
    case careAccountID
    case inviteLink

    case setupComplete
    case enterHome
    case careRecipient
    case mainManager
    case inviteMethod

    func text(_ language: AppLanguage) -> String {
        switch language {
        case .zhTW:
            return zhTW
        case .en:
            return en
        case .id:
            return id
        case .vi:
            return vi
        case .th:
            return th
        case .ja:
            return ja
        }
    }

    private var zhTW: String {
        switch self {
        case .next: return "下一步"
        case .back: return "返回"
        case .finish: return "完成"
        case .createCareRecipientProfile: return "建立被照護者基本資料"
        case .basicInfo: return "基本資料"
        case .manager: return "管理者"
        case .complete: return "完成"

        case .name: return "姓名"
        case .namePlaceholder: return "請輸入被照護者姓名"
        case .relationship: return "關係"
        case .relationshipPlaceholder: return "請選擇關係"
        case .gender: return "性別"
        case .female: return "女"
        case .male: return "男"
        case .other: return "其他"
        case .birthday: return "生日"
        case .bloodType: return "血型"
        case .select: return "請選擇"
        case .contactAddressNote: return "聯絡方式 / 地址備註"
        case .contactAddressPlaceholder: return "例如：電話、地址、主要聯絡方式"

        case .createManagerAccount: return "建立主要管理者帳號"
        case .managerName: return "主要管理者姓名"
        case .managerPhone: return "電話"
        case .managerEmail: return "電子信箱 / 帳號"
        case .password: return "密碼"
        case .confirmPassword: return "確認密碼"
        case .inviteFamilyCaregiver: return "邀請家人或照護者"
        case .inviteDescription: return "其他成員可透過 QR Code 或邀請連結申請加入，需由主要管理者審核。"
        case .careAccountID: return "照護帳戶 ID"
        case .inviteLink: return "邀請連結"

        case .setupComplete: return "建立完成"
        case .enterHome: return "進入首頁"
        case .careRecipient: return "被照護者"
        case .mainManager: return "主要管理者"
        case .inviteMethod: return "邀請方式"
        }
    }

    private var en: String {
        switch self {
        case .next: return "Next"
        case .back: return "Back"
        case .finish: return "Finish"
        case .createCareRecipientProfile: return "Create care recipient profile"
        case .basicInfo: return "Basic info"
        case .manager: return "Manager"
        case .complete: return "Complete"

        case .name: return "Name"
        case .namePlaceholder: return "Enter the care recipient's name"
        case .relationship: return "Relationship"
        case .relationshipPlaceholder: return "Select relationship"
        case .gender: return "Gender"
        case .female: return "Female"
        case .male: return "Male"
        case .other: return "Other"
        case .birthday: return "Birthday"
        case .bloodType: return "Blood type"
        case .select: return "Select"
        case .contactAddressNote: return "Contact / address note"
        case .contactAddressPlaceholder: return "Phone, address, or main contact method"

        case .createManagerAccount: return "Create main manager account"
        case .managerName: return "Main manager name"
        case .managerPhone: return "Phone"
        case .managerEmail: return "Email / account"
        case .password: return "Password"
        case .confirmPassword: return "Confirm password"
        case .inviteFamilyCaregiver: return "Invite family or caregivers"
        case .inviteDescription: return "Other members can apply through the QR code or invite link and must be approved by the main manager."
        case .careAccountID: return "Care account ID"
        case .inviteLink: return "Invite link"

        case .setupComplete: return "Setup complete"
        case .enterHome: return "Enter home"
        case .careRecipient: return "Care recipient"
        case .mainManager: return "Main manager"
        case .inviteMethod: return "Invite method"
        }
    }

    private var id: String {
        switch self {
        case .next: return "Lanjut"
        case .back: return "Kembali"
        case .finish: return "Selesai"
        case .createCareRecipientProfile: return "Buat profil penerima perawatan"
        case .basicInfo: return "Informasi dasar"
        case .manager: return "Pengelola"
        case .complete: return "Selesai"

        case .name: return "Nama"
        case .namePlaceholder: return "Masukkan nama penerima perawatan"
        case .relationship: return "Hubungan"
        case .relationshipPlaceholder: return "Pilih hubungan"
        case .gender: return "Jenis kelamin"
        case .female: return "Perempuan"
        case .male: return "Laki-laki"
        case .other: return "Lainnya"
        case .birthday: return "Tanggal lahir"
        case .bloodType: return "Golongan darah"
        case .select: return "Pilih"
        case .contactAddressNote: return "Catatan kontak / alamat"
        case .contactAddressPlaceholder: return "Telepon, alamat, atau cara kontak utama"

        case .createManagerAccount: return "Buat akun pengelola utama"
        case .managerName: return "Nama pengelola utama"
        case .managerPhone: return "Telepon"
        case .managerEmail: return "Email / akun"
        case .password: return "Kata sandi"
        case .confirmPassword: return "Konfirmasi kata sandi"
        case .inviteFamilyCaregiver: return "Undang keluarga atau perawat"
        case .inviteDescription: return "Anggota lain dapat mendaftar melalui QR Code atau tautan undangan dan harus disetujui oleh pengelola utama."
        case .careAccountID: return "ID akun perawatan"
        case .inviteLink: return "Tautan undangan"

        case .setupComplete: return "Pembuatan selesai"
        case .enterHome: return "Masuk ke beranda"
        case .careRecipient: return "Penerima perawatan"
        case .mainManager: return "Pengelola utama"
        case .inviteMethod: return "Metode undangan"
        }
    }

    private var vi: String {
        switch self {
        case .next: return "Tiếp tục"
        case .back: return "Quay lại"
        case .finish: return "Hoàn tất"
        case .createCareRecipientProfile: return "Tạo hồ sơ người được chăm sóc"
        case .basicInfo: return "Thông tin cơ bản"
        case .manager: return "Người quản lý"
        case .complete: return "Hoàn tất"

        case .name: return "Tên"
        case .namePlaceholder: return "Nhập tên người được chăm sóc"
        case .relationship: return "Mối quan hệ"
        case .relationshipPlaceholder: return "Chọn mối quan hệ"
        case .gender: return "Giới tính"
        case .female: return "Nữ"
        case .male: return "Nam"
        case .other: return "Khác"
        case .birthday: return "Ngày sinh"
        case .bloodType: return "Nhóm máu"
        case .select: return "Chọn"
        case .contactAddressNote: return "Ghi chú liên hệ / địa chỉ"
        case .contactAddressPlaceholder: return "Số điện thoại, địa chỉ hoặc cách liên hệ chính"

        case .createManagerAccount: return "Tạo tài khoản người quản lý chính"
        case .managerName: return "Tên người quản lý chính"
        case .managerPhone: return "Số điện thoại"
        case .managerEmail: return "Email / tài khoản"
        case .password: return "Mật khẩu"
        case .confirmPassword: return "Xác nhận mật khẩu"
        case .inviteFamilyCaregiver: return "Mời gia đình hoặc người chăm sóc"
        case .inviteDescription: return "Thành viên khác có thể đăng ký qua mã QR hoặc liên kết mời và cần được người quản lý chính phê duyệt."
        case .careAccountID: return "ID tài khoản chăm sóc"
        case .inviteLink: return "Liên kết mời"

        case .setupComplete: return "Thiết lập hoàn tất"
        case .enterHome: return "Vào trang chính"
        case .careRecipient: return "Người được chăm sóc"
        case .mainManager: return "Người quản lý chính"
        case .inviteMethod: return "Cách mời"
        }
    }

    private var th: String {
        switch self {
        case .next: return "ถัดไป"
        case .back: return "กลับ"
        case .finish: return "เสร็จสิ้น"
        case .createCareRecipientProfile: return "สร้างข้อมูลผู้รับการดูแล"
        case .basicInfo: return "ข้อมูลพื้นฐาน"
        case .manager: return "ผู้จัดการ"
        case .complete: return "เสร็จสิ้น"

        case .name: return "ชื่อ"
        case .namePlaceholder: return "กรอกชื่อผู้รับการดูแล"
        case .relationship: return "ความสัมพันธ์"
        case .relationshipPlaceholder: return "เลือกความสัมพันธ์"
        case .gender: return "เพศ"
        case .female: return "หญิง"
        case .male: return "ชาย"
        case .other: return "อื่น ๆ"
        case .birthday: return "วันเกิด"
        case .bloodType: return "กรุ๊ปเลือด"
        case .select: return "เลือก"
        case .contactAddressNote: return "หมายเหตุการติดต่อ / ที่อยู่"
        case .contactAddressPlaceholder: return "โทรศัพท์ ที่อยู่ หรือช่องทางติดต่อหลัก"

        case .createManagerAccount: return "สร้างบัญชีผู้จัดการหลัก"
        case .managerName: return "ชื่อผู้จัดการหลัก"
        case .managerPhone: return "โทรศัพท์"
        case .managerEmail: return "อีเมล / บัญชี"
        case .password: return "รหัสผ่าน"
        case .confirmPassword: return "ยืนยันรหัสผ่าน"
        case .inviteFamilyCaregiver: return "เชิญครอบครัวหรือผู้ดูแล"
        case .inviteDescription: return "สมาชิกอื่นสามารถสมัครผ่าน QR Code หรือลิงก์เชิญ และต้องได้รับการอนุมัติจากผู้จัดการหลัก"
        case .careAccountID: return "รหัสบัญชีการดูแล"
        case .inviteLink: return "ลิงก์เชิญ"

        case .setupComplete: return "ตั้งค่าเสร็จสิ้น"
        case .enterHome: return "เข้าสู่หน้าหลัก"
        case .careRecipient: return "ผู้รับการดูแล"
        case .mainManager: return "ผู้จัดการหลัก"
        case .inviteMethod: return "วิธีเชิญ"
        }
    }

    private var ja: String {
        switch self {
        case .next: return "次へ"
        case .back: return "戻る"
        case .finish: return "完了"
        case .createCareRecipientProfile: return "被介護者の基本情報を作成"
        case .basicInfo: return "基本情報"
        case .manager: return "管理者"
        case .complete: return "完了"

        case .name: return "名前"
        case .namePlaceholder: return "被介護者の名前を入力"
        case .relationship: return "関係"
        case .relationshipPlaceholder: return "関係を選択"
        case .gender: return "性別"
        case .female: return "女性"
        case .male: return "男性"
        case .other: return "その他"
        case .birthday: return "誕生日"
        case .bloodType: return "血液型"
        case .select: return "選択してください"
        case .contactAddressNote: return "連絡先 / 住所メモ"
        case .contactAddressPlaceholder: return "電話、住所、主な連絡方法など"

        case .createManagerAccount: return "主管理者アカウントを作成"
        case .managerName: return "主管理者の名前"
        case .managerPhone: return "電話"
        case .managerEmail: return "メール / アカウント"
        case .password: return "パスワード"
        case .confirmPassword: return "パスワード確認"
        case .inviteFamilyCaregiver: return "家族または介護者を招待"
        case .inviteDescription: return "他のメンバーはQRコードまたは招待リンクから申請し、主管理者の承認が必要です。"
        case .careAccountID: return "介護アカウントID"
        case .inviteLink: return "招待リンク"

        case .setupComplete: return "作成完了"
        case .enterHome: return "ホームへ"
        case .careRecipient: return "被介護者"
        case .mainManager: return "主管理者"
        case .inviteMethod: return "招待方法"
        }
    }
}
