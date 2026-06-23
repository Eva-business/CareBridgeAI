import SwiftUI

struct CreateRecipientView: View {
    @Binding var draft: CareRecipientDraft
    let selectedLanguage: AppLanguage
    let onNext: () -> Void

    private let relationships = ["母親", "父親", "祖母", "祖父", "配偶", "家人", "看護", "本人", "其他"]
    private let genders = ["女", "男", "其他"]
    private let bloodTypes = ["A", "B", "O", "AB", "不確定"]

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    LogoView(size: 54, showText: true)

                    StepIndicatorView(
                        currentStep: 1,
                        totalSteps: 3,
                        titles: [
                            AppText.basicInfo.text(selectedLanguage),
                            AppText.manager.text(selectedLanguage),
                            AppText.complete.text(selectedLanguage)
                        ]
                    )

                    VStack(alignment: .leading, spacing: 18) {
                        Text(AppText.createCareRecipientProfile.text(selectedLanguage))
                            .font(.title2)
                            .fontWeight(.bold)

                        Text(instructionText)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineSpacing(3)

                        FormTextField(
                            title: AppText.name.text(selectedLanguage),
                            placeholder: AppText.namePlaceholder.text(selectedLanguage),
                            text: $draft.name
                        )

                        relationshipPicker

                        genderPicker

                        birthdayPicker

                        bloodTypePicker

                        FormTextField(
                            title: AppText.contactAddressNote.text(selectedLanguage),
                            placeholder: AppText.contactAddressPlaceholder.text(selectedLanguage),
                            text: $draft.phoneNote
                        )
                    }
                    .padding()
                    .background(Color.white.opacity(0.65))
                    .clipShape(RoundedRectangle(cornerRadius: 22))
                    .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)

                    PrimaryButton(title: AppText.next.text(selectedLanguage)) {
                        onNext()
                    }
                    .disabled(isNextDisabled)
                    .opacity(isNextDisabled ? 0.5 : 1)
                }
                .padding(24)
            }
            .scrollDismissesKeyboard(.immediately) // 💡 補上支援滑動收起鍵盤
        }
        .dismissKeyboardOnTap() // 套用專案內建的收鍵盤功能
    }

    private var relationshipPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.relationship.text(selectedLanguage))
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker(AppText.relationship.text(selectedLanguage), selection: $draft.relationship) {
                Text(AppText.select.text(selectedLanguage)).tag("")

                ForEach(relationships, id: \.self) { relationship in
                    Text(localizedRelationship(relationship))
                        .tag(relationship)
                }
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

    private var genderPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.gender.text(selectedLanguage))
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker(AppText.gender.text(selectedLanguage), selection: $draft.gender) {
                Text(AppText.female.text(selectedLanguage)).tag("女")
                Text(AppText.male.text(selectedLanguage)).tag("男")
                Text(AppText.other.text(selectedLanguage)).tag("其他")
            }
            .pickerStyle(.segmented)
        }
    }

    private var birthdayPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.birthday.text(selectedLanguage))
                .font(.subheadline)
                .fontWeight(.semibold)

            DatePicker(
                AppText.birthday.text(selectedLanguage),
                selection: $draft.birthday,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            }
        }
    }

    private var bloodTypePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(AppText.bloodType.text(selectedLanguage))
                .font(.subheadline)
                .fontWeight(.semibold)

            Picker(AppText.bloodType.text(selectedLanguage), selection: $draft.bloodType) {
                Text(AppText.select.text(selectedLanguage)).tag("")

                ForEach(bloodTypes, id: \.self) { type in
                    Text(localizedBloodType(type))
                        .tag(type)
                }
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

    private var isNextDisabled: Bool {
        draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var instructionText: String {
        switch selectedLanguage {
        case .zhTW:
            return "請先填寫基本資料，之後可以再補充病史、藥物、緊急聯絡人與醫療單位。"
        case .en:
            return "Please fill in the basic information first. Medical history, medication, emergency contacts, and medical units can be added later."
        case .id:
            return "Silakan isi informasi dasar terlebih dahulu. Riwayat medis, obat, kontak darurat, dan unit medis dapat ditambahkan nanti."
        case .vi:
            return "Vui lòng điền thông tin cơ bản trước. Tiền sử bệnh, thuốc, liên hệ khẩn cấp và cơ sở y tế có thể bổ sung sau."
        case .th:
            return "กรุณากรอกข้อมูลพื้นฐานก่อน ประวัติการรักษา ยา ผู้ติดต่อฉุกเฉิน และหน่วยแพทย์สามารถเพิ่มภายหลังได้"
        case .ja:
            return "まず基本情報を入力してください。病歴、薬、緊急連絡先、医療機関は後で追加できます。"
        }
    }

    private func localizedRelationship(_ relationship: String) -> String {
        switch selectedLanguage {
        case .zhTW:
            return relationship

        case .en:
            switch relationship {
            case "母親": return "Mother"
            case "父親": return "Father"
            case "祖母": return "Grandmother"
            case "祖父": return "Grandfather"
            case "配偶": return "Spouse"
            case "家人": return "Family member"
            case "看護": return "Caregiver"
            case "本人": return "Self"
            case "其他": return "Other"
            default: return relationship
            }

        case .id:
            switch relationship {
            case "母親": return "Ibu"
            case "父親": return "Ayah"
            case "祖母": return "Nenek"
            case "祖父": return "Kakek"
            case "配偶": return "Pasangan"
            case "家人": return "Keluarga"
            case "看護": return "Perawat"
            case "本人": return "Diri sendiri"
            case "其他": return "Lainnya"
            default: return relationship
            }

        case .vi:
            switch relationship {
            case "母親": return "Mẹ"
            case "父親": return "Cha"
            case "祖母": return "Bà"
            case "祖父": return "Ông"
            case "配偶": return "Vợ / chồng"
            case "家人": return "Thành viên gia đình"
            case "看護": return "Người chăm sóc"
            case "本人": return "Bản thân"
            case "其他": return "Khác"
            default: return relationship
            }

        case .th:
            switch relationship {
            case "母親": return "แม่"
            case "父親": return "พ่อ"
            case "祖母": return "ย่า / ยาย"
            case "祖父": return "ปู่ / ตา"
            case "配偶": return "คู่สมรส"
            case "家人": return "สมาชิกครอบครัว"
            case "看護": return "ผู้ดูแล"
            case "本人": return "ตนเอง"
            case "其他": return "อื่น ๆ"
            default: return relationship
            }

        case .ja:
            switch relationship {
            case "母親": return "母"
            case "父親": return "父"
            case "祖母": return "祖母"
            case "祖父": return "祖父"
            case "配偶": return "配偶者"
            case "家人": return "家族"
            case "看護": return "介護者"
            case "本人": return "本人"
            case "其他": return "その他"
            default: return relationship
            }
        }
    }

    private func localizedBloodType(_ type: String) -> String {
        switch type {
        case "不確定":
            switch selectedLanguage {
            case .zhTW:
                return "不確定"
            case .en:
                return "Not sure"
            case .id:
                return "Tidak yakin"
            case .vi:
                return "Không chắc"
            case .th:
                return "ไม่แน่ใจ"
            case .ja:
                return "不明"
            }
        default:
            return type
        }
    }
}

#Preview {
    CreateRecipientView(
        draft: .constant(CareRecipientDraft()),
        selectedLanguage: .zhTW,
        onNext: {}
    )
}
