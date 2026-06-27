import Foundation
import Speech
import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case zhTW = "繁體中文"
    case en = "English"
    case id = "Bahasa Indonesia"
    case vi = "Tiếng Việt"
    case th = "ภาษาไทย"
    case ja = "日本語"

    var id: String { rawValue }

    var displayName: String {
        rawValue
    }

    var code: String {
        switch self {
        case .zhTW:
            return "zh-TW"
        case .en:
            return "en"
        case .id:
            return "id"
        case .vi:
            return "vi"
        case .th:
            return "th"
        case .ja:
            return "ja"
        }
    }

    var speechLocaleIdentifier: String {
        switch self {
        case .zhTW:
            return "zh-TW"
        case .en:
            return "en-US"
        case .id:
            return "id-ID"
        case .vi:
            return "vi-VN"
        case .th:
            return "th-TH"
        case .ja:
            return "ja-JP"
        }
    }

    var englishName: String {
        switch self {
        case .zhTW:
            return "Traditional Chinese"
        case .en:
            return "English"
        case .id:
            return "Indonesian"
        case .vi:
            return "Vietnamese"
        case .th:
            return "Thai"
        case .ja:
            return "Japanese"
        }
    }
}

extension AppLanguage {
    var isChinese: Bool { self == .zhTW }
    var isJapanese: Bool { self == .ja }
    var usesDynamicTargetTranslation: Bool {
        switch self {
        case .id, .vi, .th, .ja:
            return true
        case .zhTW, .en:
            return false
        }
    }

    func text(en: String, zhTW: String) -> String {
        switch self {
        case .zhTW:
            return zhTW
        case .id, .vi, .th:
            return CareBridgeLocalizedAppText.lookup(language: self, en: en, zhTW: zhTW) ?? en
        case .ja:
            return JapaneseAppText.lookup(en: en, zhTW: zhTW) ?? en
        case .en:
            return en
        }
    }

    func displayName(in interfaceLanguage: AppLanguage) -> String {
        if interfaceLanguage.isChinese {
            return displayName
        }

        if interfaceLanguage == .en {
            return englishName
        }

        if let translated = CareBridgeLocalizedAppText.languageName(self, in: interfaceLanguage) {
            return translated
        }

        switch self {
        case .zhTW:
            return "繁体中国語"
        case .en:
            return "英語"
        case .id:
            return "インドネシア語"
        case .vi:
            return "ベトナム語"
        case .th:
            return "タイ語"
        case .ja:
            return displayName
        }
    }

    var foundationModelOutputLanguageName: String {
        switch self {
        case .zhTW:
            return "Traditional Chinese (Taiwan)"
        case .id:
            return "Indonesian"
        case .vi:
            return "Vietnamese"
        case .th:
            return "Thai"
        case .ja:
            return "Japanese"
        case .en:
            return "English"
        }
    }
}

private enum CareBridgeLocalizedAppText {
    static func languageName(_ language: AppLanguage, in interfaceLanguage: AppLanguage) -> String? {
        languageNames[interfaceLanguage]?[language]
    }

    static func lookup(language: AppLanguage, en: String, zhTW: String) -> String? {
        guard let exactTranslations = exactTranslations[language] else { return nil }
        if let exact = exactTranslations[en] ?? exactTranslations[zhTW] {
            return exact
        }

        switch language {
        case .id:
            return dynamicIndonesian(en)
        case .vi:
            return dynamicVietnamese(en)
        case .th:
            return dynamicThai(en)
        case .zhTW, .en, .ja:
            return nil
        }
    }

    private static func dynamicIndonesian(_ en: String) -> String? {
        if en.hasPrefix("Every day at ") {
            return en.replacingOccurrences(of: "Every day at ", with: "Setiap hari pukul ")
        }
        if en.hasPrefix("Every "), en.contains(" at ") {
            return en.replacingOccurrences(of: "Every ", with: "Setiap ")
                .replacingOccurrences(of: " at ", with: " pukul ")
        }
        if en.hasPrefix("Today's status for ") {
            return "Status hari ini untuk \(String(en.dropFirst("Today's status for ".count)))"
        }
        if en.hasSuffix(" - Today's care overview") {
            return en.replacingOccurrences(of: " - Today's care overview", with: " - ringkasan perawatan hari ini")
        }
        if en.contains(" record(s) today") {
            return "\(en.replacingOccurrences(of: " record(s) today", with: "")) catatan hari ini"
        }
        if en.contains(" note(s)") {
            return "\(en.replacingOccurrences(of: " note(s)", with: "")) catatan"
        }
        if en.hasPrefix("Type ") {
            return "Golongan \(String(en.dropFirst("Type ".count)))"
        }
        if en.hasPrefix("Will remind on ") {
            return "Akan mengingatkan pada \(String(en.dropFirst("Will remind on ".count)))"
        }
        if en.hasPrefix("Schedule for ") {
            return "Jadwal untuk \(String(en.dropFirst("Schedule for ".count)))"
        }
        if en.hasPrefix("Current language: ") {
            return "Bahasa saat ini: \(String(en.dropFirst("Current language: ".count)))"
        }
        if en.hasPrefix("Recording in ") {
            return "Merekam dalam \(String(en.dropFirst("Recording in ".count)))"
        }
        if en.hasPrefix("Recognizing with ") {
            let language = en
                .replacingOccurrences(of: "Recognizing with ", with: "")
                .replacingOccurrences(of: ". Speech is converted to text first, then AI classifies it into one or more care records.", with: "")
            return "Mengenali dengan \(language). Suara diubah menjadi teks terlebih dahulu, lalu AI mengelompokkannya menjadi satu atau beberapa catatan perawatan."
        }
        return nil
    }

    private static func dynamicVietnamese(_ en: String) -> String? {
        if en.hasPrefix("Every day at ") {
            return en.replacingOccurrences(of: "Every day at ", with: "Mỗi ngày lúc ")
        }
        if en.hasPrefix("Every "), en.contains(" at ") {
            return en.replacingOccurrences(of: "Every ", with: "Mỗi ")
                .replacingOccurrences(of: " at ", with: " lúc ")
        }
        if en.hasPrefix("Today's status for ") {
            return "Tình trạng hôm nay của \(String(en.dropFirst("Today's status for ".count)))"
        }
        if en.hasSuffix(" - Today's care overview") {
            return en.replacingOccurrences(of: " - Today's care overview", with: " - tổng quan chăm sóc hôm nay")
        }
        if en.contains(" record(s) today") {
            return "\(en.replacingOccurrences(of: " record(s) today", with: "")) ghi chú hôm nay"
        }
        if en.contains(" note(s)") {
            return "\(en.replacingOccurrences(of: " note(s)", with: "")) ghi chú"
        }
        if en.hasPrefix("Type ") {
            return "Nhóm máu \(String(en.dropFirst("Type ".count)))"
        }
        if en.hasPrefix("Will remind on ") {
            return "Sẽ nhắc vào \(String(en.dropFirst("Will remind on ".count)))"
        }
        if en.hasPrefix("Schedule for ") {
            return "Lịch cho \(String(en.dropFirst("Schedule for ".count)))"
        }
        if en.hasPrefix("Current language: ") {
            return "Ngôn ngữ hiện tại: \(String(en.dropFirst("Current language: ".count)))"
        }
        if en.hasPrefix("Recording in ") {
            return "Đang ghi âm bằng \(String(en.dropFirst("Recording in ".count)))"
        }
        if en.hasPrefix("Recognizing with ") {
            let language = en
                .replacingOccurrences(of: "Recognizing with ", with: "")
                .replacingOccurrences(of: ". Speech is converted to text first, then AI classifies it into one or more care records.", with: "")
            return "Nhận dạng bằng \(language). Giọng nói sẽ được chuyển thành văn bản trước, sau đó AI phân loại thành một hoặc nhiều ghi chú chăm sóc."
        }
        return nil
    }

    private static func dynamicThai(_ en: String) -> String? {
        if en.hasPrefix("Every day at ") {
            return en.replacingOccurrences(of: "Every day at ", with: "ทุกวันเวลา ")
        }
        if en.hasPrefix("Every "), en.contains(" at ") {
            return en.replacingOccurrences(of: "Every ", with: "ทุก ")
                .replacingOccurrences(of: " at ", with: " เวลา ")
        }
        if en.hasPrefix("Today's status for ") {
            return "สถานะวันนี้ของ \(String(en.dropFirst("Today's status for ".count)))"
        }
        if en.hasSuffix(" - Today's care overview") {
            return en.replacingOccurrences(of: " - Today's care overview", with: " - ภาพรวมการดูแลวันนี้")
        }
        if en.contains(" record(s) today") {
            return "\(en.replacingOccurrences(of: " record(s) today", with: "")) รายการวันนี้"
        }
        if en.contains(" note(s)") {
            return "\(en.replacingOccurrences(of: " note(s)", with: "")) บันทึก"
        }
        if en.hasPrefix("Type ") {
            return "กรุ๊ป \(String(en.dropFirst("Type ".count)))"
        }
        if en.hasPrefix("Will remind on ") {
            return "จะแจ้งเตือนใน \(String(en.dropFirst("Will remind on ".count)))"
        }
        if en.hasPrefix("Schedule for ") {
            return "ตารางสำหรับ \(String(en.dropFirst("Schedule for ".count)))"
        }
        if en.hasPrefix("Current language: ") {
            return "ภาษาปัจจุบัน: \(String(en.dropFirst("Current language: ".count)))"
        }
        if en.hasPrefix("Recording in ") {
            return "กำลังบันทึกเป็น \(String(en.dropFirst("Recording in ".count)))"
        }
        if en.hasPrefix("Recognizing with ") {
            let language = en
                .replacingOccurrences(of: "Recognizing with ", with: "")
                .replacingOccurrences(of: ". Speech is converted to text first, then AI classifies it into one or more care records.", with: "")
            return "กำลังรู้จำด้วย \(language) ระบบจะแปลงเสียงเป็นข้อความก่อน แล้ว AI จะจัดหมวดหมู่เป็นบันทึกการดูแลหนึ่งรายการหรือมากกว่า"
        }
        return nil
    }

    private static let languageNames: [AppLanguage: [AppLanguage: String]] = [
        .id: [
            .zhTW: "Bahasa Tionghoa Tradisional",
            .en: "Bahasa Inggris",
            .id: "Bahasa Indonesia",
            .vi: "Bahasa Vietnam",
            .th: "Bahasa Thai",
            .ja: "Bahasa Jepang"
        ],
        .vi: [
            .zhTW: "Tiếng Trung phồn thể",
            .en: "Tiếng Anh",
            .id: "Tiếng Indonesia",
            .vi: "Tiếng Việt",
            .th: "Tiếng Thái",
            .ja: "Tiếng Nhật"
        ],
        .th: [
            .zhTW: "จีนตัวเต็ม",
            .en: "อังกฤษ",
            .id: "อินโดนีเซีย",
            .vi: "เวียดนาม",
            .th: "ไทย",
            .ja: "ญี่ปุ่น"
        ],
        .ja: [
            .zhTW: "繁体中国語",
            .en: "英語",
            .id: "インドネシア語",
            .vi: "ベトナム語",
            .th: "タイ語",
            .ja: "日本語"
        ]
    ]

    private static let exactTranslations: [AppLanguage: [String: String]] = [
        .id: [
            "Home": "Beranda",
            "Records": "Catatan",
            "Tasks": "Tugas",
            "Profile": "Profil",
            "Care Recipient": "Penerima perawatan",
            "Care Recipient Profile": "Profil penerima perawatan",
            "Data center and group management": "Pusat data dan manajemen grup",
            "Care Records": "Catatan perawatan",
            "Text, voice, and quick status checks": "Teks, suara, dan pemeriksaan cepat",
            "Schedule & Tasks": "Jadwal & tugas",
            "Calendar view and task management": "Tampilan kalender dan pengelolaan tugas",
            "Calendar": "Kalender",
            "Routine Tasks": "Tugas rutin",
            "Today": "Hari ini",
            "No repeat days set": "Hari pengulangan belum diatur",
            "Sun": "Min",
            "Mon": "Sen",
            "Tue": "Sel",
            "Wed": "Rab",
            "Thu": "Kam",
            "Fri": "Jum",
            "Sat": "Sab",
            "Sunday": "Minggu",
            "Monday": "Senin",
            "Tuesday": "Selasa",
            "Wednesday": "Rabu",
            "Thursday": "Kamis",
            "Friday": "Jumat",
            "Saturday": "Sabtu",
            "Stable": "Stabil",
            "Needs Attention": "Perlu perhatian",
            "Urgent": "Darurat",
            "Currently stable": "Saat ini stabil",
            "Follow-up needed": "Perlu pemantauan lanjutan",
            "Immediate attention needed": "Perlu perhatian segera",
            "Today's Status": "Status hari ini",
            "AI Handoff Summary": "Ringkasan serah terima AI",
            "Apple Foundation Models - On-device": "Apple Foundation Models - di perangkat",
            "Smart fallback summary": "Ringkasan cadangan pintar",
            "On-device AI": "AI di perangkat",
            "Smart fallback": "Cadangan pintar",
            "Past 24 hours": "24 jam terakhir",
            "View full summary": "Lihat ringkasan lengkap",
            "Next Task": "Tugas berikutnya",
            "No pending tasks": "Tidak ada tugas tertunda",
            "Personal Notes": "Catatan pribadi",
            "No notes yet": "Belum ada catatan",
            "Tap to add a personal note": "Ketuk untuk menambah catatan pribadi",
            "Add a personal note": "Tambah catatan pribadi",
            "No notes yet. Add one above.": "Belum ada catatan. Tambahkan di atas.",
            "Today's Schedule": "Jadwal hari ini",
            "No schedule for today": "Tidak ada jadwal hari ini",
            "Done": "Selesai",
            "Food": "Makanan",
            "Medication": "Obat",
            "Meds": "Obat",
            "Bowel": "BAB",
            "Mood": "Suasana hati",
            "Other": "Lainnya",
            "Good": "Baik",
            "Fair": "Cukup",
            "Poor": "Buruk",
            "Routine Task": "Tugas rutin",
            "One-time Task": "Tugas sekali",
            "Main Manager": "Pengelola utama",
            "Family": "Keluarga",
            "Caregiver": "Perawat",
            "Pending Review": "Menunggu tinjauan",
            "Joined": "Bergabung",
            "Rejected": "Ditolak",
            "Creator": "Pembuat",
            "Group Invite Code": "Kode undangan grup",
            "QR Code": "Kode QR undangan",
            "Video": "Video",
            "Care Chat": "Chat perawatan",
            "Unable to Translate": "Tidak dapat menerjemahkan",
            "OK": "OK",
            "Please try again later.": "Silakan coba lagi nanti.",
            "No messages yet": "Belum ada pesan",
            "Family members and caregivers can communicate here and translate messages when needed.": "Keluarga dan perawat dapat berkomunikasi di sini dan menerjemahkan pesan saat perlu.",
            "Enter a message": "Masukkan pesan",
            "Voice Message": "Pesan suara",
            "Transcript is hidden": "Transkrip disembunyikan",
            "Show Text": "Tampilkan teks",
            "Translate": "Terjemahkan",
            "Send Voice Message": "Kirim pesan suara",
            "Close": "Tutup",
            "Speech is converted to text first. Review it before sending.": "Suara diubah menjadi teks terlebih dahulu. Periksa sebelum mengirim.",
            "Speech-to-text": "Ucapan ke teks",
            "You can edit recognition errors before sending.": "Anda dapat memperbaiki kesalahan pengenalan sebelum mengirim.",
            "Stop Recording": "Berhenti merekam",
            "Start Recording": "Mulai merekam",
            "Add Care Record": "Tambah catatan perawatan",
            "Choose input method": "Pilih metode input",
            "Text": "Teks",
            "Voice": "Suara",
            "Quick Check": "Cek cepat",
            "Text Input": "Input teks",
            "Voice Input": "Input suara",
            "Cancel": "Batal",
            "Save": "Simpan",
            "Enter care details...": "Masukkan detail perawatan...",
            "Upload photo or video (optional)": "Unggah foto atau video (opsional)",
            "Take Photo": "Ambil foto",
            "Record Video": "Rekam video",
            "Camera": "Kamera",
            "Library": "Galeri",
            "AI Predicted Categories (editable)": "Kategori prediksi AI (dapat diedit)",
            "Analyzing content...": "Menganalisis konten...",
            "AI Analysis Notes": "Catatan analisis AI",
            "Foundation Models analyzed this on device. You can still edit the predicted categories; saving may split the note into multiple care records by category, severity, and content.": "Foundation Models menganalisis ini di perangkat. Anda tetap dapat mengedit kategori prediksi; saat disimpan catatan dapat dipisah menjadi beberapa catatan berdasarkan kategori, tingkat keparahan, dan isi.",
            "The system automatically analyzes and preselects categories and severity. When the on-device model is unavailable, a smart fallback keeps recording available offline.": "Sistem otomatis menganalisis dan memilih kategori serta tingkat keparahan. Saat model di perangkat tidak tersedia, cadangan pintar tetap memungkinkan pencatatan offline.",
            "One attachment could not be read. Please choose it again.": "Satu lampiran tidak dapat dibaca. Pilih lagi.",
            "Only photo or video attachments are supported.": "Hanya lampiran foto atau video yang didukung.",
            "Listening to care details...": "Mendengarkan detail perawatan...",
            "Tap to start recording": "Ketuk untuk mulai merekam",
            "Speech-to-text Result": "Hasil ucapan ke teks",
            "No text yet. Tap start recording and speak the care details.": "Belum ada teks. Ketuk mulai merekam dan ucapkan detail perawatan.",
            "AI analyzing:": "AI menganalisis:",
            "AI assessment:": "Penilaian AI:",
            "Foundation Models - On-device analysis": "Foundation Models - analisis di perangkat",
            "Smart fallback analysis": "Analisis cadangan pintar",
            "Select care status": "Pilih status perawatan",
            "Additional notes (optional)": "Catatan tambahan (opsional)",
            "AI Summary": "Ringkasan AI",
            "Preparing today's care records...": "Menyiapkan catatan perawatan hari ini...",
            "No care records yet": "Belum ada catatan perawatan",
            "Add records with text, voice, or quick status checks.": "Tambah catatan dengan teks, suara, atau cek cepat.",
            "All": "Semua",
            "Basic Info": "Informasi dasar",
            "Medical Info": "Informasi medis",
            "Lifestyle": "Gaya hidup",
            "Cognitive & Mood": "Kognitif & suasana hati",
            "Care Needs & Preferences": "Kebutuhan & preferensi perawatan",
            "Emergency Contacts": "Kontak darurat",
            "Medical Providers": "Penyedia medis",
            "Documents & Files": "Dokumen & file",
            "Join Requests": "Permintaan bergabung",
            "Invite Members": "Undang anggota",
            "Name, birthday, gender, contact details, and address": "Nama, ulang tahun, gender, kontak, dan alamat",
            "Medical history, medications, allergies, and surgeries": "Riwayat medis, obat, alergi, dan operasi",
            "Diet, sleep, exercise, and toileting habits": "Pola makan, tidur, olahraga, dan kebiasaan toilet",
            "Cognition, mood patterns, and communication ability": "Kognisi, pola suasana hati, dan kemampuan komunikasi",
            "Daily assistance needs, preferences, and restrictions": "Kebutuhan bantuan harian, preferensi, dan batasan",
            "Family and trusted contact details": "Detail keluarga dan kontak tepercaya",
            "Hospitals, clinics, physicians, and provider contacts": "Rumah sakit, klinik, dokter, dan kontak penyedia",
            "Medical reports, test results, and important files": "Laporan medis, hasil tes, dan file penting",
            "Review join requests from other members": "Tinjau permintaan bergabung dari anggota lain",
            "Show care account ID, invite link, and QR code": "Tampilkan ID akun perawatan, tautan undangan, dan kode QR",
            "Shared Caregivers": "Perawat bersama",
            "No special notes yet": "Belum ada catatan khusus",
            "Log Out / Back to Entry": "Keluar / kembali ke awal",
            "Care Team": "Tim perawatan",
            "Approved Members": "Anggota disetujui",
            "Pending Requests": "Permintaan tertunda",
            "No primary caregiver yet": "Belum ada perawat utama",
            "The person who creates the care group becomes the main manager.": "Orang yang membuat grup perawatan menjadi pengelola utama.",
            "No shared caregivers yet": "Belum ada perawat bersama",
            "Other family members, caregivers, or the care recipient will appear here after approval.": "Anggota keluarga lain, perawat, atau penerima perawatan akan muncul di sini setelah disetujui.",
            "Blood type not set": "Golongan darah belum diatur",
            "Primary Caregiver": "Perawat utama",
            "Not created": "Belum dibuat",
            "Email / Account": "Email / akun",
            "Not provided": "Tidak disediakan",
            "Language": "Bahasa",
            "Member Status": "Status anggota",
            "Name": "Nama",
            "Relationship": "Hubungan",
            "Gender": "Jenis kelamin",
            "Birthday": "Tanggal lahir",
            "Blood Type": "Golongan darah",
            "Contact / Address Notes": "Catatan kontak / alamat",
            "Medical History": "Riwayat medis",
            "Medication Info": "Informasi obat",
            "Allergy History": "Riwayat alergi",
            "Surgery / Other Medical Notes": "Operasi / catatan medis lain",
            "Restrictions": "Batasan",
            "Emergency Contact": "Kontak darurat",
            "No emergency contacts yet": "Belum ada kontak darurat",
            "No emergency contacts yet.": "Belum ada kontak darurat.",
            "Medical Provider": "Penyedia medis",
            "No medical providers yet": "Belum ada penyedia medis",
            "No medical providers yet.": "Belum ada penyedia medis.",
            "No documents uploaded yet": "Belum ada dokumen diunggah",
            "Care Account ID": "ID akun perawatan",
            "Invite Link": "Tautan undangan",
            "Other members can join this care account through the QR code or invite link. Requests must be approved by the main manager.": "Anggota lain dapat bergabung melalui kode QR atau tautan undangan. Permintaan harus disetujui oleh pengelola utama.",
            "Enter the care recipient name": "Masukkan nama penerima perawatan",
            "Example: Mother, father, grandmother": "Contoh: ibu, ayah, nenek",
            "Female": "Perempuan",
            "Male": "Laki-laki",
            "Select birthday": "Pilih tanggal lahir",
            "Select": "Pilih",
            "Type A": "Golongan A",
            "Type B": "Golongan B",
            "Type O": "Golongan O",
            "Type AB": "Golongan AB",
            "Unknown": "Tidak diketahui",
            "Add Emergency Contact": "Tambah kontak darurat",
            "Add Medical Provider": "Tambah penyedia medis",
            "Provider Name": "Nama penyedia",
            "Department": "Departemen",
            "Physician Name": "Nama dokter",
            "Phone": "Telepon",
            "Enter phone": "Masukkan telepon",
            "Address": "Alamat",
            "Enter address": "Masukkan alamat",
            "Notes": "Catatan",
            "Upload Documents or Files": "Unggah dokumen atau file",
            "No Permission": "Tidak ada izin",
            "Only the main manager can review join requests.": "Hanya pengelola utama yang dapat meninjau permintaan bergabung.",
            "No pending requests": "Tidak ada permintaan tertunda",
            "Members who register through the QR code or invite link will appear here for main manager review.": "Anggota yang mendaftar melalui kode QR atau tautan undangan akan muncul di sini untuk ditinjau pengelola utama.",
            "Joined Members": "Anggota bergabung",
            "No joined members yet": "Belum ada anggota bergabung",
            "Reject": "Tolak",
            "Approve": "Setujui",
            "Add Routine Task": "Tambah tugas rutin",
            "Add Task": "Tambah tugas",
            "Task Name": "Nama tugas",
            "Reminder Time": "Waktu pengingat",
            "Date & Time": "Tanggal & waktu",
            "Select time": "Pilih waktu",
            "Select date and time": "Pilih tanggal dan waktu",
            "Task Type": "Jenis tugas",
            "Choose weekdays for repeated reminders": "Pilih hari untuk pengingat berulang",
            "Reminds once on the selected date": "Mengingatkan sekali pada tanggal yang dipilih",
            "Repeat Weekdays": "Hari pengulangan",
            "Clear": "Hapus",
            "Every day": "Setiap hari",
            "Select at least one day": "Pilih minimal satu hari",
            "Will remind every day": "Akan mengingatkan setiap hari",
            "Task Details": "Detail tugas",
            "Mark as Incomplete": "Tandai belum selesai",
            "Mark as Done": "Tandai selesai",
            "Notification": "Notifikasi",
            "Scheduled by repeat weekdays": "Dijadwalkan berdasarkan hari berulang",
            "Scheduled for the selected date": "Dijadwalkan untuk tanggal terpilih",
            "Completion Status": "Status selesai",
            "Not Done": "Belum selesai",
            "No notes": "Tidak ada catatan",
            "Delete Task": "Hapus tugas",
            "Includes routine tasks and one-time tasks for this day": "Termasuk tugas rutin dan sekali untuk hari ini",
            "No tasks for this day": "Tidak ada tugas untuk hari ini",
            "You can add a one-time task here. Manage routine tasks in the task list.": "Anda dapat menambah tugas sekali di sini. Kelola tugas rutin di daftar tugas.",
            "Care tasks repeated daily or on fixed days": "Tugas perawatan yang berulang harian atau pada hari tetap",
            "No routine tasks yet": "Belum ada tugas rutin",
            "Care Task": "Tugas perawatan",
            "Enter name": "Masukkan nama",
            "Example: Dr. Wang": "Contoh: Dr. Wang",
            "Example: Follow-up visit, rehab, family visit": "Contoh: kunjungan kontrol, rehabilitasi, kunjungan keluarga",
            "Example: Medication before breakfast, blood pressure check": "Contoh: obat sebelum sarapan, cek tekanan darah",
            "Example: NTU Hospital, local clinic": "Contoh: Rumah Sakit NTU, klinik lokal",
            "Example: Take after meals, bring insurance card, monitor blood pressure": "Contoh: minum setelah makan, bawa kartu asuransi, pantau tekanan darah",
            "Example: avoid sweets, avoid getting out of bed alone, avoid specific foods or activities": "Contoh: hindari makanan manis, jangan turun dari tempat tidur sendiri, hindari makanan atau aktivitas tertentu",
            "Example: blood pressure medication at 8 AM, blood sugar medication after dinner": "Contoh: obat tekanan darah pukul 8 pagi, obat gula darah setelah makan malam",
            "Example: cardiology, rehabilitation, family medicine": "Contoh: kardiologi, rehabilitasi, kedokteran keluarga",
            "Example: daily assistance needs, preferences, preferred care style": "Contoh: kebutuhan bantuan harian, preferensi, gaya perawatan yang disukai",
            "Example: daughter, son, spouse, friend": "Contoh: putri, putra, pasangan, teman",
            "Example: diet, sleep, exercise, and toileting habits": "Contoh: pola makan, tidur, olahraga, dan kebiasaan toilet",
            "Example: hypertension, diabetes, heart disease, dementia": "Contoh: hipertensi, diabetes, penyakit jantung, demensia",
            "Example: medication or food allergies; write none if not applicable": "Contoh: alergi obat atau makanan; tulis tidak ada bila tidak berlaku",
            "Example: memory, mood patterns, communication ability, anxiety triggers": "Contoh: ingatan, pola suasana hati, kemampuan komunikasi, pemicu kecemasan",
            "Example: phone, address, or main contact method": "Contoh: telepon, alamat, atau metode kontak utama",
            "Example: priority contact, available at night": "Contoh: kontak prioritas, tersedia malam hari",
            "Example: regular follow-up location, registration method, notes": "Contoh: lokasi kontrol rutin, cara pendaftaran, catatan",
            "Example: surgeries, hospitalization records, special medical instructions": "Contoh: operasi, riwayat rawat inap, instruksi medis khusus",
            "No documents uploaded yet. You can upload medical reports, test results, diagnoses, or other important files.": "Belum ada dokumen yang diunggah. Anda dapat mengunggah laporan medis, hasil tes, diagnosis, atau file penting lainnya."
        ],
        .vi: [
            "Home": "Trang chính",
            "Records": "Ghi chú",
            "Tasks": "Nhiệm vụ",
            "Profile": "Hồ sơ",
            "Care Recipient": "Người được chăm sóc",
            "Care Recipient Profile": "Hồ sơ người được chăm sóc",
            "Data center and group management": "Trung tâm dữ liệu và quản lý nhóm",
            "Care Records": "Ghi chú chăm sóc",
            "Text, voice, and quick status checks": "Văn bản, giọng nói và kiểm tra nhanh",
            "Schedule & Tasks": "Lịch và nhiệm vụ",
            "Calendar view and task management": "Xem lịch và quản lý nhiệm vụ",
            "Calendar": "Lịch",
            "Routine Tasks": "Nhiệm vụ định kỳ",
            "Today": "Hôm nay",
            "No repeat days set": "Chưa đặt ngày lặp lại",
            "Sun": "CN",
            "Mon": "T2",
            "Tue": "T3",
            "Wed": "T4",
            "Thu": "T5",
            "Fri": "T6",
            "Sat": "T7",
            "Sunday": "Chủ nhật",
            "Monday": "Thứ hai",
            "Tuesday": "Thứ ba",
            "Wednesday": "Thứ tư",
            "Thursday": "Thứ năm",
            "Friday": "Thứ sáu",
            "Saturday": "Thứ bảy",
            "Stable": "Ổn định",
            "Needs Attention": "Cần chú ý",
            "Urgent": "Khẩn cấp",
            "Currently stable": "Hiện đang ổn định",
            "Follow-up needed": "Cần theo dõi tiếp",
            "Immediate attention needed": "Cần chú ý ngay",
            "Today's Status": "Tình trạng hôm nay",
            "AI Handoff Summary": "Tóm tắt bàn giao AI",
            "Apple Foundation Models - On-device": "Apple Foundation Models - trên thiết bị",
            "Smart fallback summary": "Tóm tắt dự phòng thông minh",
            "On-device AI": "AI trên thiết bị",
            "Smart fallback": "Dự phòng thông minh",
            "Past 24 hours": "24 giờ qua",
            "View full summary": "Xem tóm tắt đầy đủ",
            "Next Task": "Nhiệm vụ tiếp theo",
            "No pending tasks": "Không có nhiệm vụ chờ",
            "Personal Notes": "Ghi chú cá nhân",
            "No notes yet": "Chưa có ghi chú",
            "Tap to add a personal note": "Chạm để thêm ghi chú cá nhân",
            "Add a personal note": "Thêm ghi chú cá nhân",
            "No notes yet. Add one above.": "Chưa có ghi chú. Hãy thêm ở trên.",
            "Today's Schedule": "Lịch hôm nay",
            "No schedule for today": "Hôm nay chưa có lịch",
            "Done": "Hoàn tất",
            "Food": "Ăn uống",
            "Medication": "Thuốc",
            "Meds": "Thuốc",
            "Bowel": "Đại tiện",
            "Mood": "Tâm trạng",
            "Other": "Khác",
            "Good": "Tốt",
            "Fair": "Bình thường",
            "Poor": "Không tốt",
            "Routine Task": "Nhiệm vụ định kỳ",
            "One-time Task": "Nhiệm vụ một lần",
            "Main Manager": "Người quản lý chính",
            "Family": "Gia đình",
            "Caregiver": "Người chăm sóc",
            "Pending Review": "Chờ xét duyệt",
            "Joined": "Đã tham gia",
            "Rejected": "Đã từ chối",
            "Creator": "Người tạo",
            "Group Invite Code": "Mã mời nhóm",
            "QR Code": "Mã QR mời",
            "Video": "Video",
            "Care Chat": "Trò chuyện chăm sóc",
            "Unable to Translate": "Không thể dịch",
            "OK": "OK",
            "Please try again later.": "Vui lòng thử lại sau.",
            "No messages yet": "Chưa có tin nhắn",
            "Family members and caregivers can communicate here and translate messages when needed.": "Gia đình và người chăm sóc có thể liên lạc tại đây và dịch tin nhắn khi cần.",
            "Enter a message": "Nhập tin nhắn",
            "Voice Message": "Tin nhắn thoại",
            "Transcript is hidden": "Bản ghi đang bị ẩn",
            "Show Text": "Hiện văn bản",
            "Translate": "Dịch",
            "Send Voice Message": "Gửi tin nhắn thoại",
            "Close": "Đóng",
            "Speech is converted to text first. Review it before sending.": "Giọng nói sẽ được chuyển thành văn bản trước. Hãy kiểm tra trước khi gửi.",
            "Speech-to-text": "Giọng nói thành văn bản",
            "You can edit recognition errors before sending.": "Bạn có thể sửa lỗi nhận dạng trước khi gửi.",
            "Stop Recording": "Dừng ghi âm",
            "Start Recording": "Bắt đầu ghi âm",
            "Add Care Record": "Thêm ghi chú chăm sóc",
            "Choose input method": "Chọn cách nhập",
            "Text": "Văn bản",
            "Voice": "Giọng nói",
            "Quick Check": "Kiểm tra nhanh",
            "Text Input": "Nhập văn bản",
            "Voice Input": "Nhập giọng nói",
            "Cancel": "Hủy",
            "Save": "Lưu",
            "Enter care details...": "Nhập chi tiết chăm sóc...",
            "Upload photo or video (optional)": "Tải ảnh hoặc video lên (không bắt buộc)",
            "Take Photo": "Chụp ảnh",
            "Record Video": "Quay video",
            "Camera": "Máy ảnh",
            "Library": "Thư viện",
            "AI Predicted Categories (editable)": "Danh mục AI dự đoán (có thể sửa)",
            "Analyzing content...": "Đang phân tích nội dung...",
            "AI Analysis Notes": "Ghi chú phân tích AI",
            "Foundation Models analyzed this on device. You can still edit the predicted categories; saving may split the note into multiple care records by category, severity, and content.": "Foundation Models đã phân tích trên thiết bị. Bạn vẫn có thể sửa danh mục dự đoán; khi lưu, ghi chú có thể được tách thành nhiều ghi chú chăm sóc theo danh mục, mức độ và nội dung.",
            "The system automatically analyzes and preselects categories and severity. When the on-device model is unavailable, a smart fallback keeps recording available offline.": "Hệ thống tự động phân tích và chọn trước danh mục cùng mức độ. Khi mô hình trên thiết bị không khả dụng, cơ chế dự phòng thông minh vẫn cho phép ghi chú ngoại tuyến.",
            "One attachment could not be read. Please choose it again.": "Không thể đọc một tệp đính kèm. Vui lòng chọn lại.",
            "Only photo or video attachments are supported.": "Chỉ hỗ trợ đính kèm ảnh hoặc video.",
            "Listening to care details...": "Đang nghe chi tiết chăm sóc...",
            "Tap to start recording": "Chạm để bắt đầu ghi âm",
            "Speech-to-text Result": "Kết quả chuyển giọng nói thành văn bản",
            "No text yet. Tap start recording and speak the care details.": "Chưa có văn bản. Chạm bắt đầu ghi âm và nói chi tiết chăm sóc.",
            "AI analyzing:": "AI đang phân tích:",
            "AI assessment:": "Đánh giá AI:",
            "Foundation Models - On-device analysis": "Foundation Models - phân tích trên thiết bị",
            "Smart fallback analysis": "Phân tích dự phòng thông minh",
            "Select care status": "Chọn tình trạng chăm sóc",
            "Additional notes (optional)": "Ghi chú bổ sung (không bắt buộc)",
            "AI Summary": "Tóm tắt AI",
            "Preparing today's care records...": "Đang chuẩn bị ghi chú chăm sóc hôm nay...",
            "No care records yet": "Chưa có ghi chú chăm sóc",
            "Add records with text, voice, or quick status checks.": "Thêm ghi chú bằng văn bản, giọng nói hoặc kiểm tra nhanh.",
            "All": "Tất cả",
            "Basic Info": "Thông tin cơ bản",
            "Medical Info": "Thông tin y tế",
            "Lifestyle": "Lối sống",
            "Cognitive & Mood": "Nhận thức & tâm trạng",
            "Care Needs & Preferences": "Nhu cầu & sở thích chăm sóc",
            "Emergency Contacts": "Liên hệ khẩn cấp",
            "Medical Providers": "Đơn vị y tế",
            "Documents & Files": "Tài liệu & tệp",
            "Join Requests": "Yêu cầu tham gia",
            "Invite Members": "Mời thành viên",
            "Name, birthday, gender, contact details, and address": "Tên, ngày sinh, giới tính, liên hệ và địa chỉ",
            "Medical history, medications, allergies, and surgeries": "Tiền sử bệnh, thuốc, dị ứng và phẫu thuật",
            "Diet, sleep, exercise, and toileting habits": "Ăn uống, ngủ, vận động và thói quen đi vệ sinh",
            "Cognition, mood patterns, and communication ability": "Nhận thức, kiểu tâm trạng và khả năng giao tiếp",
            "Daily assistance needs, preferences, and restrictions": "Nhu cầu hỗ trợ hằng ngày, sở thích và hạn chế",
            "Family and trusted contact details": "Thông tin gia đình và liên hệ đáng tin cậy",
            "Hospitals, clinics, physicians, and provider contacts": "Bệnh viện, phòng khám, bác sĩ và liên hệ",
            "Medical reports, test results, and important files": "Báo cáo y tế, kết quả xét nghiệm và tệp quan trọng",
            "Review join requests from other members": "Xem xét yêu cầu tham gia từ thành viên khác",
            "Show care account ID, invite link, and QR code": "Hiển thị ID tài khoản chăm sóc, liên kết mời và mã QR",
            "Shared Caregivers": "Người chăm sóc chung",
            "No special notes yet": "Chưa có ghi chú đặc biệt",
            "Log Out / Back to Entry": "Đăng xuất / quay lại đầu",
            "Care Team": "Nhóm chăm sóc",
            "Approved Members": "Thành viên đã duyệt",
            "Pending Requests": "Yêu cầu đang chờ",
            "No primary caregiver yet": "Chưa có người chăm sóc chính",
            "The person who creates the care group becomes the main manager.": "Người tạo nhóm chăm sóc sẽ trở thành người quản lý chính.",
            "No shared caregivers yet": "Chưa có người chăm sóc chung",
            "Other family members, caregivers, or the care recipient will appear here after approval.": "Gia đình, người chăm sóc hoặc người được chăm sóc sẽ xuất hiện ở đây sau khi được duyệt.",
            "Blood type not set": "Chưa đặt nhóm máu",
            "Primary Caregiver": "Người chăm sóc chính",
            "Not created": "Chưa tạo",
            "Email / Account": "Email / tài khoản",
            "Not provided": "Chưa cung cấp",
            "Language": "Ngôn ngữ",
            "Member Status": "Trạng thái thành viên",
            "Name": "Tên",
            "Relationship": "Mối quan hệ",
            "Gender": "Giới tính",
            "Birthday": "Ngày sinh",
            "Blood Type": "Nhóm máu",
            "Contact / Address Notes": "Ghi chú liên hệ / địa chỉ",
            "Medical History": "Tiền sử bệnh",
            "Medication Info": "Thông tin thuốc",
            "Allergy History": "Tiền sử dị ứng",
            "Surgery / Other Medical Notes": "Phẫu thuật / ghi chú y tế khác",
            "Restrictions": "Hạn chế",
            "Emergency Contact": "Liên hệ khẩn cấp",
            "No emergency contacts yet": "Chưa có liên hệ khẩn cấp",
            "No emergency contacts yet.": "Chưa có liên hệ khẩn cấp.",
            "Medical Provider": "Đơn vị y tế",
            "No medical providers yet": "Chưa có đơn vị y tế",
            "No medical providers yet.": "Chưa có đơn vị y tế.",
            "No documents uploaded yet": "Chưa tải tài liệu lên",
            "Care Account ID": "ID tài khoản chăm sóc",
            "Invite Link": "Liên kết mời",
            "Other members can join this care account through the QR code or invite link. Requests must be approved by the main manager.": "Thành viên khác có thể tham gia qua mã QR hoặc liên kết mời. Yêu cầu phải được người quản lý chính phê duyệt.",
            "Enter the care recipient name": "Nhập tên người được chăm sóc",
            "Example: Mother, father, grandmother": "Ví dụ: mẹ, cha, bà",
            "Female": "Nữ",
            "Male": "Nam",
            "Select birthday": "Chọn ngày sinh",
            "Select": "Chọn",
            "Type A": "Nhóm A",
            "Type B": "Nhóm B",
            "Type O": "Nhóm O",
            "Type AB": "Nhóm AB",
            "Unknown": "Không rõ",
            "Add Emergency Contact": "Thêm liên hệ khẩn cấp",
            "Add Medical Provider": "Thêm đơn vị y tế",
            "Provider Name": "Tên đơn vị",
            "Department": "Khoa",
            "Physician Name": "Tên bác sĩ",
            "Phone": "Điện thoại",
            "Enter phone": "Nhập điện thoại",
            "Address": "Địa chỉ",
            "Enter address": "Nhập địa chỉ",
            "Notes": "Ghi chú",
            "Upload Documents or Files": "Tải tài liệu hoặc tệp lên",
            "No Permission": "Không có quyền",
            "Only the main manager can review join requests.": "Chỉ người quản lý chính mới có thể xét duyệt yêu cầu tham gia.",
            "No pending requests": "Không có yêu cầu đang chờ",
            "Members who register through the QR code or invite link will appear here for main manager review.": "Thành viên đăng ký qua mã QR hoặc liên kết mời sẽ xuất hiện ở đây để người quản lý chính xét duyệt.",
            "Joined Members": "Thành viên đã tham gia",
            "No joined members yet": "Chưa có thành viên đã tham gia",
            "Reject": "Từ chối",
            "Approve": "Duyệt",
            "Add Routine Task": "Thêm nhiệm vụ định kỳ",
            "Add Task": "Thêm nhiệm vụ",
            "Task Name": "Tên nhiệm vụ",
            "Reminder Time": "Giờ nhắc",
            "Date & Time": "Ngày & giờ",
            "Select time": "Chọn giờ",
            "Select date and time": "Chọn ngày và giờ",
            "Task Type": "Loại nhiệm vụ",
            "Choose weekdays for repeated reminders": "Chọn ngày trong tuần để nhắc lặp lại",
            "Reminds once on the selected date": "Nhắc một lần vào ngày đã chọn",
            "Repeat Weekdays": "Ngày lặp lại",
            "Clear": "Xóa",
            "Every day": "Mỗi ngày",
            "Select at least one day": "Chọn ít nhất một ngày",
            "Will remind every day": "Sẽ nhắc mỗi ngày",
            "Task Details": "Chi tiết nhiệm vụ",
            "Mark as Incomplete": "Đánh dấu chưa hoàn tất",
            "Mark as Done": "Đánh dấu hoàn tất",
            "Notification": "Thông báo",
            "Scheduled by repeat weekdays": "Được lên lịch theo ngày lặp lại",
            "Scheduled for the selected date": "Được lên lịch cho ngày đã chọn",
            "Completion Status": "Trạng thái hoàn thành",
            "Not Done": "Chưa hoàn tất",
            "No notes": "Không có ghi chú",
            "Delete Task": "Xóa nhiệm vụ",
            "Includes routine tasks and one-time tasks for this day": "Bao gồm nhiệm vụ định kỳ và nhiệm vụ một lần trong ngày này",
            "No tasks for this day": "Không có nhiệm vụ cho ngày này",
            "You can add a one-time task here. Manage routine tasks in the task list.": "Bạn có thể thêm nhiệm vụ một lần ở đây. Quản lý nhiệm vụ định kỳ trong danh sách nhiệm vụ.",
            "Care tasks repeated daily or on fixed days": "Nhiệm vụ chăm sóc lặp lại hằng ngày hoặc vào ngày cố định",
            "No routine tasks yet": "Chưa có nhiệm vụ định kỳ",
            "Care Task": "Nhiệm vụ chăm sóc",
            "Enter name": "Nhập tên",
            "Example: Dr. Wang": "Ví dụ: Bác sĩ Wang",
            "Example: Follow-up visit, rehab, family visit": "Ví dụ: tái khám, phục hồi chức năng, gia đình thăm",
            "Example: Medication before breakfast, blood pressure check": "Ví dụ: thuốc trước bữa sáng, kiểm tra huyết áp",
            "Example: NTU Hospital, local clinic": "Ví dụ: Bệnh viện NTU, phòng khám địa phương",
            "Example: Take after meals, bring insurance card, monitor blood pressure": "Ví dụ: uống sau bữa ăn, mang thẻ bảo hiểm, theo dõi huyết áp",
            "Example: avoid sweets, avoid getting out of bed alone, avoid specific foods or activities": "Ví dụ: tránh đồ ngọt, tránh tự ra khỏi giường, tránh một số món ăn hoặc hoạt động",
            "Example: blood pressure medication at 8 AM, blood sugar medication after dinner": "Ví dụ: thuốc huyết áp lúc 8 giờ sáng, thuốc đường huyết sau bữa tối",
            "Example: cardiology, rehabilitation, family medicine": "Ví dụ: tim mạch, phục hồi chức năng, y học gia đình",
            "Example: daily assistance needs, preferences, preferred care style": "Ví dụ: nhu cầu hỗ trợ hằng ngày, sở thích, cách chăm sóc ưa thích",
            "Example: daughter, son, spouse, friend": "Ví dụ: con gái, con trai, vợ/chồng, bạn bè",
            "Example: diet, sleep, exercise, and toileting habits": "Ví dụ: ăn uống, ngủ, vận động và thói quen đi vệ sinh",
            "Example: hypertension, diabetes, heart disease, dementia": "Ví dụ: tăng huyết áp, tiểu đường, bệnh tim, sa sút trí tuệ",
            "Example: medication or food allergies; write none if not applicable": "Ví dụ: dị ứng thuốc hoặc thức ăn; ghi không có nếu không áp dụng",
            "Example: memory, mood patterns, communication ability, anxiety triggers": "Ví dụ: trí nhớ, kiểu tâm trạng, khả năng giao tiếp, yếu tố gây lo âu",
            "Example: phone, address, or main contact method": "Ví dụ: điện thoại, địa chỉ hoặc cách liên hệ chính",
            "Example: priority contact, available at night": "Ví dụ: liên hệ ưu tiên, có thể liên lạc ban đêm",
            "Example: regular follow-up location, registration method, notes": "Ví dụ: nơi tái khám thường xuyên, cách đăng ký, ghi chú",
            "Example: surgeries, hospitalization records, special medical instructions": "Ví dụ: phẫu thuật, hồ sơ nhập viện, chỉ định y tế đặc biệt",
            "No documents uploaded yet. You can upload medical reports, test results, diagnoses, or other important files.": "Chưa có tài liệu nào được tải lên. Bạn có thể tải báo cáo y tế, kết quả xét nghiệm, chẩn đoán hoặc các tệp quan trọng khác."
        ],
        .th: [
            "Home": "หน้าหลัก",
            "Records": "บันทึก",
            "Tasks": "งาน",
            "Profile": "โปรไฟล์",
            "Care Recipient": "ผู้รับการดูแล",
            "Care Recipient Profile": "โปรไฟล์ผู้รับการดูแล",
            "Data center and group management": "ศูนย์ข้อมูลและการจัดการกลุ่ม",
            "Care Records": "บันทึกการดูแล",
            "Text, voice, and quick status checks": "ข้อความ เสียง และการตรวจสถานะด่วน",
            "Schedule & Tasks": "ตารางและงาน",
            "Calendar view and task management": "มุมมองปฏิทินและการจัดการงาน",
            "Calendar": "ปฏิทิน",
            "Routine Tasks": "งานประจำ",
            "Today": "วันนี้",
            "No repeat days set": "ยังไม่ได้ตั้งวันทำซ้ำ",
            "Sun": "อา.",
            "Mon": "จ.",
            "Tue": "อ.",
            "Wed": "พ.",
            "Thu": "พฤ.",
            "Fri": "ศ.",
            "Sat": "ส.",
            "Sunday": "วันอาทิตย์",
            "Monday": "วันจันทร์",
            "Tuesday": "วันอังคาร",
            "Wednesday": "วันพุธ",
            "Thursday": "วันพฤหัสบดี",
            "Friday": "วันศุกร์",
            "Saturday": "วันเสาร์",
            "Stable": "คงที่",
            "Needs Attention": "ต้องเฝ้าระวัง",
            "Urgent": "เร่งด่วน",
            "Currently stable": "ขณะนี้คงที่",
            "Follow-up needed": "ต้องติดตามต่อ",
            "Immediate attention needed": "ต้องดูแลทันที",
            "Today's Status": "สถานะวันนี้",
            "AI Handoff Summary": "สรุปส่งต่อโดย AI",
            "Apple Foundation Models - On-device": "Apple Foundation Models - บนอุปกรณ์",
            "Smart fallback summary": "สรุปสำรองอัจฉริยะ",
            "On-device AI": "AI บนอุปกรณ์",
            "Smart fallback": "สำรองอัจฉริยะ",
            "Past 24 hours": "24 ชั่วโมงที่ผ่านมา",
            "View full summary": "ดูสรุปทั้งหมด",
            "Next Task": "งานถัดไป",
            "No pending tasks": "ไม่มีงานค้าง",
            "Personal Notes": "บันทึกส่วนตัว",
            "No notes yet": "ยังไม่มีบันทึก",
            "Tap to add a personal note": "แตะเพื่อเพิ่มบันทึกส่วนตัว",
            "Add a personal note": "เพิ่มบันทึกส่วนตัว",
            "No notes yet. Add one above.": "ยังไม่มีบันทึก เพิ่มได้ด้านบน",
            "Today's Schedule": "ตารางวันนี้",
            "No schedule for today": "วันนี้ยังไม่มีตาราง",
            "Done": "เสร็จสิ้น",
            "Food": "อาหาร",
            "Medication": "ยา",
            "Meds": "ยา",
            "Bowel": "การขับถ่าย",
            "Mood": "อารมณ์",
            "Other": "อื่น ๆ",
            "Good": "ดี",
            "Fair": "ปานกลาง",
            "Poor": "ไม่ดี",
            "Routine Task": "งานประจำ",
            "One-time Task": "งานครั้งเดียว",
            "Main Manager": "ผู้จัดการหลัก",
            "Family": "ครอบครัว",
            "Caregiver": "ผู้ดูแล",
            "Pending Review": "รอตรวจสอบ",
            "Joined": "เข้าร่วมแล้ว",
            "Rejected": "ถูกปฏิเสธ",
            "Creator": "ผู้สร้าง",
            "Group Invite Code": "รหัสเชิญกลุ่ม",
            "QR Code": "QR Code เชิญ",
            "Video": "วิดีโอ",
            "Care Chat": "แชทการดูแล",
            "Unable to Translate": "ไม่สามารถแปลได้",
            "OK": "ตกลง",
            "Please try again later.": "โปรดลองอีกครั้งภายหลัง",
            "No messages yet": "ยังไม่มีข้อความ",
            "Family members and caregivers can communicate here and translate messages when needed.": "ครอบครัวและผู้ดูแลสามารถสื่อสารที่นี่ และแปลข้อความเมื่อจำเป็น",
            "Enter a message": "พิมพ์ข้อความ",
            "Voice Message": "ข้อความเสียง",
            "Transcript is hidden": "ซ่อนข้อความถอดเสียง",
            "Show Text": "แสดงข้อความ",
            "Translate": "แปล",
            "Send Voice Message": "ส่งข้อความเสียง",
            "Close": "ปิด",
            "Speech is converted to text first. Review it before sending.": "เสียงจะถูกแปลงเป็นข้อความก่อน โปรดตรวจสอบก่อนส่ง",
            "Speech-to-text": "เสียงเป็นข้อความ",
            "You can edit recognition errors before sending.": "คุณสามารถแก้ไขข้อผิดพลาดก่อนส่ง",
            "Stop Recording": "หยุดบันทึก",
            "Start Recording": "เริ่มบันทึก",
            "Add Care Record": "เพิ่มบันทึกการดูแล",
            "Choose input method": "เลือกวิธีป้อนข้อมูล",
            "Text": "ข้อความ",
            "Voice": "เสียง",
            "Quick Check": "ตรวจด่วน",
            "Text Input": "ป้อนข้อความ",
            "Voice Input": "ป้อนเสียง",
            "Cancel": "ยกเลิก",
            "Save": "บันทึก",
            "Enter care details...": "กรอกรายละเอียดการดูแล...",
            "Upload photo or video (optional)": "อัปโหลดรูปหรือวิดีโอ (ไม่บังคับ)",
            "Take Photo": "ถ่ายรูป",
            "Record Video": "บันทึกวิดีโอ",
            "Camera": "กล้อง",
            "Library": "คลังรูปภาพ",
            "AI Predicted Categories (editable)": "หมวดหมู่ที่ AI คาดการณ์ (แก้ไขได้)",
            "Analyzing content...": "กำลังวิเคราะห์เนื้อหา...",
            "AI Analysis Notes": "หมายเหตุการวิเคราะห์ AI",
            "Foundation Models analyzed this on device. You can still edit the predicted categories; saving may split the note into multiple care records by category, severity, and content.": "Foundation Models วิเคราะห์บนอุปกรณ์แล้ว คุณยังแก้ไขหมวดหมู่ได้ และเมื่อบันทึกอาจแยกเป็นหลายบันทึกตามหมวดหมู่ ระดับความรุนแรง และเนื้อหา",
            "The system automatically analyzes and preselects categories and severity. When the on-device model is unavailable, a smart fallback keeps recording available offline.": "ระบบจะวิเคราะห์และเลือกหมวดหมู่กับระดับความรุนแรงอัตโนมัติ หากโมเดลบนอุปกรณ์ไม่พร้อม ระบบสำรองอัจฉริยะยังช่วยบันทึกแบบออฟไลน์ได้",
            "One attachment could not be read. Please choose it again.": "อ่านไฟล์แนบหนึ่งรายการไม่ได้ โปรดเลือกใหม่",
            "Only photo or video attachments are supported.": "รองรับเฉพาะรูปภาพหรือวิดีโอ",
            "Listening to care details...": "กำลังฟังรายละเอียดการดูแล...",
            "Tap to start recording": "แตะเพื่อเริ่มบันทึก",
            "Speech-to-text Result": "ผลลัพธ์เสียงเป็นข้อความ",
            "No text yet. Tap start recording and speak the care details.": "ยังไม่มีข้อความ แตะเริ่มบันทึกแล้วพูดรายละเอียดการดูแล",
            "AI analyzing:": "AI กำลังวิเคราะห์:",
            "AI assessment:": "การประเมินของ AI:",
            "Foundation Models - On-device analysis": "Foundation Models - วิเคราะห์บนอุปกรณ์",
            "Smart fallback analysis": "การวิเคราะห์สำรองอัจฉริยะ",
            "Select care status": "เลือกสถานะการดูแล",
            "Additional notes (optional)": "หมายเหตุเพิ่มเติม (ไม่บังคับ)",
            "AI Summary": "สรุป AI",
            "Preparing today's care records...": "กำลังเตรียมบันทึกการดูแลวันนี้...",
            "No care records yet": "ยังไม่มีบันทึกการดูแล",
            "Add records with text, voice, or quick status checks.": "เพิ่มบันทึกด้วยข้อความ เสียง หรือการตรวจด่วน",
            "All": "ทั้งหมด",
            "Basic Info": "ข้อมูลพื้นฐาน",
            "Medical Info": "ข้อมูลทางการแพทย์",
            "Lifestyle": "ไลฟ์สไตล์",
            "Cognitive & Mood": "การรับรู้และอารมณ์",
            "Care Needs & Preferences": "ความต้องการและความชอบในการดูแล",
            "Emergency Contacts": "ผู้ติดต่อฉุกเฉิน",
            "Medical Providers": "หน่วยแพทย์",
            "Documents & Files": "เอกสารและไฟล์",
            "Join Requests": "คำขอเข้าร่วม",
            "Invite Members": "เชิญสมาชิก",
            "Name, birthday, gender, contact details, and address": "ชื่อ วันเกิด เพศ ข้อมูลติดต่อ และที่อยู่",
            "Medical history, medications, allergies, and surgeries": "ประวัติการแพทย์ ยา ภูมิแพ้ และการผ่าตัด",
            "Diet, sleep, exercise, and toileting habits": "อาหาร การนอน การออกกำลัง และการขับถ่าย",
            "Cognition, mood patterns, and communication ability": "การรับรู้ รูปแบบอารมณ์ และความสามารถสื่อสาร",
            "Daily assistance needs, preferences, and restrictions": "ความต้องการช่วยเหลือรายวัน ความชอบ และข้อจำกัด",
            "Family and trusted contact details": "ข้อมูลครอบครัวและผู้ติดต่อที่ไว้ใจได้",
            "Hospitals, clinics, physicians, and provider contacts": "โรงพยาบาล คลินิก แพทย์ และข้อมูลติดต่อ",
            "Medical reports, test results, and important files": "รายงานแพทย์ ผลตรวจ และไฟล์สำคัญ",
            "Review join requests from other members": "ตรวจสอบคำขอเข้าร่วมจากสมาชิกอื่น",
            "Show care account ID, invite link, and QR code": "แสดง ID บัญชีดูแล ลิงก์เชิญ และ QR Code",
            "Shared Caregivers": "ผู้ดูแลร่วม",
            "No special notes yet": "ยังไม่มีหมายเหตุพิเศษ",
            "Log Out / Back to Entry": "ออกจากระบบ / กลับหน้าเริ่มต้น",
            "Care Team": "ทีมดูแล",
            "Approved Members": "สมาชิกที่อนุมัติแล้ว",
            "Pending Requests": "คำขอที่รอ",
            "No primary caregiver yet": "ยังไม่มีผู้ดูแลหลัก",
            "The person who creates the care group becomes the main manager.": "ผู้สร้างกลุ่มดูแลจะเป็นผู้จัดการหลัก",
            "No shared caregivers yet": "ยังไม่มีผู้ดูแลร่วม",
            "Other family members, caregivers, or the care recipient will appear here after approval.": "ครอบครัว ผู้ดูแล หรือผู้รับการดูแลจะแสดงที่นี่หลังอนุมัติ",
            "Blood type not set": "ยังไม่ได้ตั้งกรุ๊ปเลือด",
            "Primary Caregiver": "ผู้ดูแลหลัก",
            "Not created": "ยังไม่ได้สร้าง",
            "Email / Account": "อีเมล / บัญชี",
            "Not provided": "ไม่ได้ระบุ",
            "Language": "ภาษา",
            "Member Status": "สถานะสมาชิก",
            "Name": "ชื่อ",
            "Relationship": "ความสัมพันธ์",
            "Gender": "เพศ",
            "Birthday": "วันเกิด",
            "Blood Type": "กรุ๊ปเลือด",
            "Contact / Address Notes": "หมายเหตุการติดต่อ / ที่อยู่",
            "Medical History": "ประวัติการแพทย์",
            "Medication Info": "ข้อมูลยา",
            "Allergy History": "ประวัติภูมิแพ้",
            "Surgery / Other Medical Notes": "การผ่าตัด / หมายเหตุแพทย์อื่น",
            "Restrictions": "ข้อจำกัด",
            "Emergency Contact": "ผู้ติดต่อฉุกเฉิน",
            "No emergency contacts yet": "ยังไม่มีผู้ติดต่อฉุกเฉิน",
            "No emergency contacts yet.": "ยังไม่มีผู้ติดต่อฉุกเฉิน",
            "Medical Provider": "หน่วยแพทย์",
            "No medical providers yet": "ยังไม่มีหน่วยแพทย์",
            "No medical providers yet.": "ยังไม่มีหน่วยแพทย์",
            "No documents uploaded yet": "ยังไม่มีเอกสารที่อัปโหลด",
            "Care Account ID": "ID บัญชีดูแล",
            "Invite Link": "ลิงก์เชิญ",
            "Other members can join this care account through the QR code or invite link. Requests must be approved by the main manager.": "สมาชิกอื่นเข้าร่วมบัญชีดูแลนี้ผ่าน QR Code หรือลิงก์เชิญได้ โดยต้องให้ผู้จัดการหลักอนุมัติ",
            "Enter the care recipient name": "กรอกชื่อผู้รับการดูแล",
            "Example: Mother, father, grandmother": "เช่น แม่ พ่อ ย่า",
            "Female": "หญิง",
            "Male": "ชาย",
            "Select birthday": "เลือกวันเกิด",
            "Select": "เลือก",
            "Type A": "กรุ๊ป A",
            "Type B": "กรุ๊ป B",
            "Type O": "กรุ๊ป O",
            "Type AB": "กรุ๊ป AB",
            "Unknown": "ไม่ทราบ",
            "Add Emergency Contact": "เพิ่มผู้ติดต่อฉุกเฉิน",
            "Add Medical Provider": "เพิ่มหน่วยแพทย์",
            "Provider Name": "ชื่อหน่วย",
            "Department": "แผนก",
            "Physician Name": "ชื่อแพทย์",
            "Phone": "โทรศัพท์",
            "Enter phone": "กรอกโทรศัพท์",
            "Address": "ที่อยู่",
            "Enter address": "กรอกที่อยู่",
            "Notes": "หมายเหตุ",
            "Upload Documents or Files": "อัปโหลดเอกสารหรือไฟล์",
            "No Permission": "ไม่มีสิทธิ์",
            "Only the main manager can review join requests.": "เฉพาะผู้จัดการหลักเท่านั้นที่ตรวจสอบคำขอเข้าร่วมได้",
            "No pending requests": "ไม่มีคำขอที่รอ",
            "Members who register through the QR code or invite link will appear here for main manager review.": "สมาชิกที่ลงทะเบียนผ่าน QR Code หรือลิงก์เชิญจะแสดงที่นี่เพื่อให้ผู้จัดการหลักตรวจสอบ",
            "Joined Members": "สมาชิกที่เข้าร่วมแล้ว",
            "No joined members yet": "ยังไม่มีสมาชิกที่เข้าร่วม",
            "Reject": "ปฏิเสธ",
            "Approve": "อนุมัติ",
            "Add Routine Task": "เพิ่มงานประจำ",
            "Add Task": "เพิ่มงาน",
            "Task Name": "ชื่องาน",
            "Reminder Time": "เวลาแจ้งเตือน",
            "Date & Time": "วันที่และเวลา",
            "Select time": "เลือกเวลา",
            "Select date and time": "เลือกวันที่และเวลา",
            "Task Type": "ประเภทงาน",
            "Choose weekdays for repeated reminders": "เลือกวันสำหรับการแจ้งเตือนซ้ำ",
            "Reminds once on the selected date": "แจ้งเตือนครั้งเดียวในวันที่เลือก",
            "Repeat Weekdays": "วันทำซ้ำ",
            "Clear": "ล้าง",
            "Every day": "ทุกวัน",
            "Select at least one day": "เลือกอย่างน้อยหนึ่งวัน",
            "Will remind every day": "จะแจ้งเตือนทุกวัน",
            "Task Details": "รายละเอียดงาน",
            "Mark as Incomplete": "ทำเครื่องหมายว่ายังไม่เสร็จ",
            "Mark as Done": "ทำเครื่องหมายว่าเสร็จแล้ว",
            "Notification": "การแจ้งเตือน",
            "Scheduled by repeat weekdays": "กำหนดตามวันทำซ้ำ",
            "Scheduled for the selected date": "กำหนดในวันที่เลือก",
            "Completion Status": "สถานะเสร็จสิ้น",
            "Not Done": "ยังไม่เสร็จ",
            "No notes": "ไม่มีหมายเหตุ",
            "Delete Task": "ลบงาน",
            "Includes routine tasks and one-time tasks for this day": "รวมงานประจำและงานครั้งเดียวของวันนี้",
            "No tasks for this day": "ไม่มีงานสำหรับวันนี้",
            "You can add a one-time task here. Manage routine tasks in the task list.": "คุณเพิ่มงานครั้งเดียวที่นี่ได้ จัดการงานประจำในรายการงาน",
            "Care tasks repeated daily or on fixed days": "งานดูแลที่ทำซ้ำทุกวันหรือวันที่กำหนด",
            "No routine tasks yet": "ยังไม่มีงานประจำ",
            "Care Task": "งานดูแล",
            "Enter name": "กรอกชื่อ",
            "Example: Dr. Wang": "เช่น นพ. Wang",
            "Example: Follow-up visit, rehab, family visit": "เช่น นัดติดตาม กายภาพบำบัด ครอบครัวมาเยี่ยม",
            "Example: Medication before breakfast, blood pressure check": "เช่น ยาก่อนอาหารเช้า ตรวจความดันโลหิต",
            "Example: NTU Hospital, local clinic": "เช่น โรงพยาบาล NTU คลินิกใกล้บ้าน",
            "Example: Take after meals, bring insurance card, monitor blood pressure": "เช่น รับประทานหลังอาหาร นำบัตรประกัน ติดตามความดันโลหิต",
            "Example: avoid sweets, avoid getting out of bed alone, avoid specific foods or activities": "เช่น เลี่ยงของหวาน หลีกเลี่ยงการลุกจากเตียงเอง เลี่ยงอาหารหรือกิจกรรมบางอย่าง",
            "Example: blood pressure medication at 8 AM, blood sugar medication after dinner": "เช่น ยาความดันเวลา 8 โมงเช้า ยาน้ำตาลหลังอาหารเย็น",
            "Example: cardiology, rehabilitation, family medicine": "เช่น โรคหัวใจ เวชศาสตร์ฟื้นฟู เวชศาสตร์ครอบครัว",
            "Example: daily assistance needs, preferences, preferred care style": "เช่น ความต้องการช่วยเหลือรายวัน ความชอบ รูปแบบการดูแลที่ชอบ",
            "Example: daughter, son, spouse, friend": "เช่น ลูกสาว ลูกชาย คู่สมรส เพื่อน",
            "Example: diet, sleep, exercise, and toileting habits": "เช่น อาหาร การนอน การออกกำลัง และการขับถ่าย",
            "Example: hypertension, diabetes, heart disease, dementia": "เช่น ความดันโลหิตสูง เบาหวาน โรคหัวใจ ภาวะสมองเสื่อม",
            "Example: medication or food allergies; write none if not applicable": "เช่น แพ้ยา หรือแพ้อาหาร หากไม่มีให้เขียนว่าไม่มี",
            "Example: memory, mood patterns, communication ability, anxiety triggers": "เช่น ความจำ รูปแบบอารมณ์ ความสามารถสื่อสาร สิ่งกระตุ้นความกังวล",
            "Example: phone, address, or main contact method": "เช่น โทรศัพท์ ที่อยู่ หรือช่องทางติดต่อหลัก",
            "Example: priority contact, available at night": "เช่น ผู้ติดต่อหลัก ติดต่อได้ตอนกลางคืน",
            "Example: regular follow-up location, registration method, notes": "เช่น สถานที่ติดตามประจำ วิธีลงทะเบียน หมายเหตุ",
            "Example: surgeries, hospitalization records, special medical instructions": "เช่น การผ่าตัด ประวัตินอนโรงพยาบาล คำสั่งแพทย์พิเศษ",
            "No documents uploaded yet. You can upload medical reports, test results, diagnoses, or other important files.": "ยังไม่มีเอกสารที่อัปโหลด คุณสามารถอัปโหลดรายงานแพทย์ ผลตรวจ การวินิจฉัย หรือไฟล์สำคัญอื่น ๆ ได้"
        ]
    ]
}

private enum JapaneseAppText {
    static func lookup(en: String, zhTW: String) -> String? {
        if let exact = exactTranslations[en] ?? exactTranslations[zhTW] {
            return exact
        }

        if en.hasPrefix("Every day at ") {
            return en.replacingOccurrences(of: "Every day at ", with: "毎日 ")
        }

        if en.hasPrefix("Every "), en.contains(" at ") {
            let body = en
                .replacingOccurrences(of: "Every ", with: "毎週")
                .replacingOccurrences(of: " at ", with: " ")
            return body
        }

        if en.hasPrefix("Today's status for ") {
            let name = String(en.dropFirst("Today's status for ".count))
            return "\(name)の今日の状態"
        }

        if en.hasSuffix(" - Today's care overview") {
            return en.replacingOccurrences(of: " - Today's care overview", with: " - 今日のケア概要")
        }

        if en.contains(" record(s) today") {
            let count = en.replacingOccurrences(of: " record(s) today", with: "")
            return "本日の記録 \(count) 件"
        }

        if en.contains(" note(s)") {
            let count = en.replacingOccurrences(of: " note(s)", with: "")
            return "\(count)件のメモ"
        }

        if en.hasPrefix("Type ") {
            let type = String(en.dropFirst("Type ".count))
            return "\(type)型"
        }

        if en.hasPrefix("Will remind on ") {
            let days = String(en.dropFirst("Will remind on ".count))
            return "\(days)に通知します"
        }

        if en.hasPrefix("Schedule for ") {
            let date = String(en.dropFirst("Schedule for ".count))
            return "\(date)の予定"
        }

        if en.hasPrefix("Current language: ") {
            let language = String(en.dropFirst("Current language: ".count))
            return "現在の言語：\(language)"
        }

        if en.hasPrefix("Recording in ") {
            let language = String(en.dropFirst("Recording in ".count))
            return "\(language)で録音中"
        }

        if en.hasPrefix("Recognizing with ") {
            let language = en
                .replacingOccurrences(of: "Recognizing with ", with: "")
                .replacingOccurrences(of: ". Speech is converted to text first, then AI classifies it into one or more care records.", with: "")
            return "\(language)で認識します。音声は先に文字へ変換され、その後AIが1件以上のケア記録に分類します。"
        }

        return nil
    }

    private static let exactTranslations: [String: String] = [
        "Home": "ホーム",
        "Records": "記録",
        "Tasks": "タスク",
        "Profile": "プロフィール",
        "Care Recipient": "被介護者",
        "Care Recipient Profile": "被介護者プロフィール",
        "Data center and group management": "データ管理とグループ管理",
        "Care Records": "ケア記録",
        "Text, voice, and quick status checks": "テキスト、音声、クイック確認",
        "Schedule & Tasks": "予定とタスク",
        "Calendar view and task management": "カレンダー表示とタスク管理",
        "Calendar": "カレンダー",
        "Routine Tasks": "定期タスク",
        "Today": "今日",
        "No repeat days set": "繰り返し日が未設定です",
        "Sun": "日",
        "Mon": "月",
        "Tue": "火",
        "Wed": "水",
        "Thu": "木",
        "Fri": "金",
        "Sat": "土",
        "Sunday": "日曜日",
        "Monday": "月曜日",
        "Tuesday": "火曜日",
        "Wednesday": "水曜日",
        "Thursday": "木曜日",
        "Friday": "金曜日",
        "Saturday": "土曜日",
        "Add Routine Task": "定期タスクを追加",
        "Add Task": "タスクを追加",
        "Task Name": "タスク名",
        "Example: Medication before breakfast, blood pressure check": "例：朝食前の服薬、血圧確認",
        "Example: Follow-up visit, rehab, family visit": "例：再診、リハビリ、家族訪問",
        "Reminder Time": "リマインド時刻",
        "Date & Time": "日時",
        "Select time": "時刻を選択",
        "Select date and time": "日時を選択",
        "Example: Take after meals, bring insurance card, monitor blood pressure": "例：食後に服用、保険証を持参、血圧を観察",
        "Task Type": "タスク種別",
        "Choose weekdays for repeated reminders": "繰り返しリマインドする曜日を選択",
        "Reminds once on the selected date": "選択した日時に1回通知します",
        "Repeat Weekdays": "繰り返し曜日",
        "Clear": "クリア",
        "Every day": "毎日",
        "Select at least one day": "少なくとも1日選択してください",
        "Will remind every day": "毎日通知します",
        "Task Details": "タスク詳細",
        "Mark as Incomplete": "未完了に戻す",
        "Mark as Done": "完了にする",
        "Notification": "通知",
        "Scheduled by repeat weekdays": "繰り返し曜日に基づいて予定",
        "Scheduled for the selected date": "選択した日時に予定",
        "Completion Status": "完了状況",
        "Not Done": "未完了",
        "No notes": "メモなし",
        "Delete Task": "タスクを削除",
        "Includes routine tasks and one-time tasks for this day": "この日の定期タスクと単発タスクを含みます",
        "No tasks for this day": "この日のタスクはありません",
        "You can add a one-time task here. Manage routine tasks in the task list.": "ここで単発タスクを追加できます。定期タスクはタスクリストで管理してください。",
        "Care tasks repeated daily or on fixed days": "毎日または決まった曜日に繰り返すケアタスク",
        "No routine tasks yet": "定期タスクはまだありません",

        "Stable": "安定",
        "Needs Attention": "要注意",
        "Urgent": "緊急",
        "Currently stable": "現在は安定しています",
        "Follow-up needed": "継続的な確認が必要です",
        "Immediate attention needed": "すぐに確認が必要です",
        "Today's Status": "今日の状態",
        "AI Handoff Summary": "AI申し送り要約",
        "Apple Foundation Models - On-device": "Apple Foundation Models - デバイス上で生成",
        "Smart fallback summary": "スマート代替要約",
        "On-device AI": "デバイス上AI",
        "Smart fallback": "スマート代替",
        "Past 24 hours": "過去24時間",
        "View full summary": "要約全文を見る",
        "Next Task": "次のタスク",
        "No pending tasks": "保留中のタスクはありません",
        "Personal Notes": "個人メモ",
        "No notes yet": "メモはまだありません",
        "Tap to add a personal note": "タップして個人メモを追加",
        "Add a personal note": "個人メモを追加",
        "No notes yet. Add one above.": "メモはまだありません。上から追加できます。",
        "Today's Schedule": "今日の予定",
        "No schedule for today": "今日の予定はありません",
        "Done": "完了",

        "Food": "食事",
        "Medication": "服薬",
        "Meds": "薬",
        "Bowel": "排便",
        "Mood": "気分",
        "Other": "その他",
        "Good": "良好",
        "Fair": "普通",
        "Poor": "不調",
        "Routine Task": "定期タスク",
        "One-time Task": "単発タスク",
        "Main Manager": "主管理者",
        "Family": "家族",
        "Caregiver": "介護者",
        "Pending Review": "審査待ち",
        "Joined": "参加済み",
        "Rejected": "拒否済み",
        "Creator": "作成者",
        "Group Invite Code": "グループ招待コード",
        "QR Code": "招待QRコード",
        "Video": "動画",

        "Care Chat": "ケアチャット",
        "Unable to Translate": "翻訳できません",
        "OK": "OK",
        "Please try again later.": "後でもう一度お試しください。",
        "No messages yet": "まだメッセージはありません",
        "Family members and caregivers can communicate here and translate messages when needed.": "家族と介護者がここで連絡し、必要に応じてメッセージを翻訳できます。",
        "Enter a message": "メッセージを入力",
        "Voice Message": "音声メッセージ",
        "Transcript is hidden": "文字起こしは非表示です",
        "Show Text": "文字を表示",
        "Translate": "翻訳",
        "Send Voice Message": "音声メッセージを送信",
        "Close": "閉じる",
        "Speech is converted to text first. Review it before sending.": "音声は先に文字へ変換されます。送信前に確認できます。",
        "Speech-to-text": "音声文字変換",
        "You can edit recognition errors before sending.": "送信前に認識ミスを修正できます。",
        "Stop Recording": "録音を停止",
        "Start Recording": "録音を開始",

        "Add Care Record": "ケア記録を追加",
        "Choose input method": "入力方法を選択",
        "Text": "テキスト",
        "Voice": "音声",
        "Quick Check": "クイック確認",
        "Text Input": "テキスト入力",
        "Voice Input": "音声入力",
        "Cancel": "キャンセル",
        "Save": "保存",
        "Enter care details...": "ケア内容を入力...",
        "Upload photo or video (optional)": "写真または動画をアップロード（任意）",
        "Take Photo": "写真を撮影",
        "Record Video": "動画を撮影",
        "Camera": "カメラ",
        "Library": "ライブラリ",
        "AI Predicted Categories (editable)": "AI予測カテゴリ（編集可）",
        "Analyzing content...": "内容を分析中...",
        "AI Analysis Notes": "AI分析メモ",
        "Foundation Models analyzed this on device. You can still edit the predicted categories; saving may split the note into multiple care records by category, severity, and content.": "Foundation Modelsがデバイス上で分析しました。予測カテゴリは編集でき、保存時にカテゴリ、重症度、内容ごとに複数のケア記録へ分割される場合があります。",
        "The system automatically analyzes and preselects categories and severity. When the on-device model is unavailable, a smart fallback keeps recording available offline.": "システムがカテゴリと重症度を自動分析して事前選択します。デバイス上のモデルが使えない場合も、スマート代替処理によりオフラインで記録できます。",
        "One attachment could not be read. Please choose it again.": "添付ファイルを読み取れませんでした。もう一度選択してください。",
        "Only photo or video attachments are supported.": "写真または動画の添付のみ対応しています。",
        "Listening to care details...": "ケア内容を聞き取っています...",
        "Tap to start recording": "タップして録音を開始",
        "Speech-to-text Result": "音声文字変換の結果",
        "No text yet. Tap start recording and speak the care details.": "まだ文字はありません。録音を開始してケア内容を話してください。",
        "AI analyzing:": "AI分析中：",
        "AI assessment:": "AI評価：",
        "Foundation Models - On-device analysis": "Foundation Models - デバイス上で分析",
        "Smart fallback analysis": "スマート代替分析",
        "Select care status": "ケア状態を選択",
        "Additional notes (optional)": "補足メモ（任意）",
        "AI Summary": "AI要約",
        "Preparing today's care records...": "本日のケア記録を整理中...",
        "No care records yet": "まだケア記録はありません",
        "Add records with text, voice, or quick status checks.": "テキスト、音声、クイック確認で記録を追加できます。",
        "All": "すべて",

        "Basic Info": "基本情報",
        "Medical Info": "医療情報",
        "Lifestyle": "生活習慣",
        "Cognitive & Mood": "認知と気分",
        "Care Needs & Preferences": "ケアの必要事項と希望",
        "Emergency Contacts": "緊急連絡先",
        "Medical Providers": "医療機関",
        "Documents & Files": "書類とファイル",
        "Join Requests": "参加申請",
        "Invite Members": "メンバー招待",
        "Name, birthday, gender, contact details, and address": "氏名、生年月日、性別、連絡先、住所",
        "Medical history, medications, allergies, and surgeries": "病歴、服薬、アレルギー、手術歴",
        "Diet, sleep, exercise, and toileting habits": "食事、睡眠、運動、排泄習慣",
        "Cognition, mood patterns, and communication ability": "認知、気分の傾向、コミュニケーション能力",
        "Daily assistance needs, preferences, and restrictions": "日常介助の必要事項、希望、制限",
        "Family and trusted contact details": "家族と信頼できる連絡先",
        "Hospitals, clinics, physicians, and provider contacts": "病院、クリニック、医師、連絡先",
        "Medical reports, test results, and important files": "医療報告、検査結果、重要ファイル",
        "Review join requests from other members": "他のメンバーからの参加申請を確認",
        "Show care account ID, invite link, and QR code": "ケアアカウントID、招待リンク、QRコードを表示",
        "Shared Caregivers": "共同介護者",
        "No special notes yet": "特別なメモはまだありません",
        "Log Out / Back to Entry": "ログアウト / 入り口へ戻る",
        "Care Team": "ケアチーム",
        "Approved Members": "承認済みメンバー",
        "Pending Requests": "保留中の申請",
        "No primary caregiver yet": "主担当介護者はまだいません",
        "The person who creates the care group becomes the main manager.": "ケアグループを作成した人が主管理者になります。",
        "No shared caregivers yet": "共同介護者はまだいません",
        "Other family members, caregivers, or the care recipient will appear here after approval.": "他の家族、介護者、被介護者本人は承認後にここへ表示されます。",
        "Blood type not set": "血液型未設定",
        "Primary Caregiver": "主担当介護者",
        "Not created": "未作成",
        "Email / Account": "メール / アカウント",
        "Not provided": "未提供",
        "Language": "言語",
        "Member Status": "メンバー状態",

        "Name": "氏名",
        "Relationship": "続柄",
        "Gender": "性別",
        "Birthday": "生年月日",
        "Blood Type": "血液型",
        "Contact / Address Notes": "連絡先 / 住所メモ",
        "Medical History": "病歴",
        "Medication Info": "服薬情報",
        "Allergy History": "アレルギー歴",
        "Surgery / Other Medical Notes": "手術 / その他医療メモ",
        "Restrictions": "制限事項",
        "Emergency Contact": "緊急連絡先",
        "No emergency contacts yet": "緊急連絡先はまだありません",
        "No emergency contacts yet.": "緊急連絡先はまだありません。",
        "Medical Provider": "医療機関",
        "No medical providers yet": "医療機関はまだありません",
        "No medical providers yet.": "医療機関はまだありません。",
        "No documents uploaded yet": "アップロード済み書類はまだありません",
        "Care Account ID": "ケアアカウントID",
        "Invite Link": "招待リンク",
        "Other members can join this care account through the QR code or invite link. Requests must be approved by the main manager.": "他のメンバーはQRコードまたは招待リンクからこのケアアカウントに参加できます。申請は主管理者の承認が必要です。",
        "Enter the care recipient name": "被介護者の氏名を入力",
        "Example: Mother, father, grandmother": "例：母、父、祖母",
        "Female": "女性",
        "Male": "男性",
        "Select birthday": "生年月日を選択",
        "Select": "選択",
        "Type A": "A型",
        "Type B": "B型",
        "Type O": "O型",
        "Type AB": "AB型",
        "Unknown": "不明",
        "Example: phone, address, or main contact method": "例：電話、住所、主な連絡方法",
        "Example: hypertension, diabetes, heart disease, dementia": "例：高血圧、糖尿病、心疾患、認知症",
        "Example: blood pressure medication at 8 AM, blood sugar medication after dinner": "例：朝8時の血圧薬、夕食後の血糖薬",
        "Example: medication or food allergies; write none if not applicable": "例：薬や食物アレルギー。該当なしの場合は「なし」と記入",
        "Example: surgeries, hospitalization records, special medical instructions": "例：手術歴、入院記録、特別な医療指示",
        "Example: diet, sleep, exercise, and toileting habits": "例：食事、睡眠、運動、排泄習慣",
        "Example: memory, mood patterns, communication ability, anxiety triggers": "例：記憶、気分の傾向、会話能力、不安のきっかけ",
        "Example: daily assistance needs, preferences, preferred care style": "例：日常介助の必要事項、希望、好みのケア方法",
        "Example: avoid sweets, avoid getting out of bed alone, avoid specific foods or activities": "例：甘い物を避ける、一人で離床しない、特定の食べ物や活動を避ける",
        "Add Emergency Contact": "緊急連絡先を追加",
        "Add Medical Provider": "医療機関を追加",
        "Provider Name": "医療機関名",
        "Example: NTU Hospital, local clinic": "例：大学病院、地域クリニック",
        "Department": "診療科",
        "Example: cardiology, rehabilitation, family medicine": "例：循環器内科、リハビリ科、家庭医療科",
        "Physician Name": "医師名",
        "Example: Dr. Wang": "例：王医師",
        "Phone": "電話",
        "Enter phone": "電話番号を入力",
        "Address": "住所",
        "Enter address": "住所を入力",
        "Notes": "メモ",
        "Example: regular follow-up location, registration method, notes": "例：定期受診先、受付方法、注意事項",
        "Enter name": "氏名を入力",
        "Example: daughter, son, spouse, friend": "例：娘、息子、配偶者、友人",
        "Example: priority contact, available at night": "例：優先連絡先、夜間連絡可",
        "Upload Documents or Files": "書類またはファイルをアップロード",
        "No documents uploaded yet. You can upload medical reports, test results, diagnoses, or other important files.": "まだ書類はアップロードされていません。医療報告、検査結果、診断書、その他重要ファイルをアップロードできます。",
        "No Permission": "権限がありません",
        "Only the main manager can review join requests.": "参加申請を確認できるのは主管理者のみです。",
        "No pending requests": "保留中の申請はありません",
        "Members who register through the QR code or invite link will appear here for main manager review.": "QRコードまたは招待リンクから登録したメンバーは、主管理者の確認用にここに表示されます。",
        "Joined Members": "参加済みメンバー",
        "No joined members yet": "参加済みメンバーはまだいません",
        "Reject": "拒否",
        "Approve": "承認",
        "Care Task": "ケアタスク"
    ]
}

private struct AppLanguageKey: EnvironmentKey {
    static let defaultValue: AppLanguage = .en
}

extension EnvironmentValues {
    var appLanguage: AppLanguage {
        get { self[AppLanguageKey.self] }
        set { self[AppLanguageKey.self] = newValue }
    }
}

extension CareStatus {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Stable", zhTW: "穩定")
        case .warning:
            return language.text(en: "Needs Attention", zhTW: "需注意")
        case .danger:
            return language.text(en: "Urgent", zhTW: "緊急")
        }
    }

    func description(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Currently stable", zhTW: "目前狀態穩定")
        case .warning:
            return language.text(en: "Follow-up needed", zhTW: "需要持續觀察")
        case .danger:
            return language.text(en: "Immediate attention needed", zhTW: "需要立即關注")
        }
    }
}

extension CareRecordCategory {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .food:
            return language.text(en: "Food", zhTW: "飲食")
        case .medicine:
            return language.text(en: "Medication", zhTW: "用藥")
        case .bowel:
            return language.text(en: "Bowel", zhTW: "排便")
        case .mood:
            return language.text(en: "Mood", zhTW: "情緒")
        case .custom:
            return language.text(en: "Other", zhTW: "其他")
        }
    }

    func shortDisplayName(_ language: AppLanguage) -> String {
        switch self {
        case .food:
            return language.text(en: "Food", zhTW: "食")
        case .medicine:
            return language.text(en: "Meds", zhTW: "藥")
        case .bowel:
            return language.text(en: "Bowel", zhTW: "便")
        case .mood:
            return language.text(en: "Mood", zhTW: "情緒")
        case .custom:
            return language.text(en: "Other", zhTW: "其他")
        }
    }
}

extension RecordCondition {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .good:
            return language.text(en: "Good", zhTW: "良好")
        case .normal:
            return language.text(en: "Fair", zhTW: "普通")
        case .bad:
            return language.text(en: "Poor", zhTW: "不好")
        }
    }
}

extension CareTaskType {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .routine:
            return language.text(en: "Routine Task", zhTW: "常態任務")
        case .temporary:
            return language.text(en: "One-time Task", zhTW: "單次任務")
        }
    }
}

extension CaregiverRole {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .mainManager:
            return language.text(en: "Main Manager", zhTW: "主要管理者")
        case .family:
            return language.text(en: "Family", zhTW: "家人")
        case .caregiver:
            return language.text(en: "Caregiver", zhTW: "看護")
        case .recipientSelf:
            return language.text(en: "Care Recipient", zhTW: "被照護者")
        }
    }
}

extension MemberStatus {
    func displayName(_ language: AppLanguage) -> String {
        switch self {
        case .pending:
            return language.text(en: "Pending Review", zhTW: "等待審核")
        case .approved:
            return language.text(en: "Joined", zhTW: "已加入")
        case .rejected:
            return language.text(en: "Rejected", zhTW: "已拒絕")
        }
    }
}
