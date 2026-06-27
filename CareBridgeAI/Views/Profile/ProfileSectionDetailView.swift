import SwiftUI
import UniformTypeIdentifiers

struct ProfileSectionDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let section: ProfileSectionItem
    @Binding var draft: CareRecipientDraft
    let isEditable: Bool
    let approvedMembers: [Caregiver]

    let pendingMembers: [Caregiver]

    let onApprove: (Caregiver) -> Void
    let onReject: (Caregiver) -> Void

    @State private var showingFileImporter = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        switch section {
                        case .basic:
                            isEditable ? AnyView(basicEditContent) : AnyView(basicReadOnlyContent)

                        case .medical:
                            isEditable ? AnyView(medicalEditContent) : AnyView(medicalReadOnlyContent)

                        case .lifestyle:
                            isEditable ? AnyView(lifestyleEditContent) : AnyView(lifestyleReadOnlyContent)

                        case .cognitive:
                            isEditable ? AnyView(cognitiveEditContent) : AnyView(cognitiveReadOnlyContent)

                        case .carePreference:
                            isEditable ? AnyView(carePreferenceEditContent) : AnyView(carePreferenceReadOnlyContent)

                        case .emergency:
                            isEditable ? AnyView(emergencyEditContent) : AnyView(emergencyReadOnlyContent)

                        case .medicalUnit:
                            isEditable ? AnyView(medicalUnitEditContent) : AnyView(medicalUnitReadOnlyContent)

                        case .files:
                            isEditable ? AnyView(filesContent) : AnyView(filesReadOnlyContent)

                        case .invite:
                            inviteContent

                        case .approval:
                            approvalContent
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle(section.title(appLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Done", zhTW: "完成")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var basicReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.basic), icon: "person.2.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "person.fill", title: field("Name", "姓名"), value: localizedProfileText(draft.name, fallbackEN: "Care Recipient", fallbackZH: "被照護者"))
                ProfileInfoRow(icon: "heart.fill", title: field("Relationship", "關係"), value: draft.relationship.localizedProfileValue(appLanguage))
                ProfileInfoRow(icon: "person.crop.circle", title: field("Gender", "性別"), value: draft.gender.localizedProfileValue(appLanguage))
                ProfileInfoRow(icon: "drop.fill", title: field("Blood Type", "血型"), value: draft.bloodType.localizedProfileValue(appLanguage))
                ProfileInfoRow(
                    icon: "birthday.cake.fill",
                    title: field("Birthday", "生日"),
                    value: draft.birthday.formatted(date: .numeric, time: .omitted)
                )
                ProfileInfoRow(
                    icon: "phone.fill",
                    title: field("Contact / Address Notes", "聯絡 / 地址備註"),
                    value: draft.phoneNote.localizedCareText(appLanguage)
                )
            }
        }
    }
    
    private var medicalReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.medical), icon: "cross.case.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "heart.text.square.fill", title: field("Medical History", "病史"), value: draft.medicalHistory.localizedCareText(appLanguage), tint: .red)
                ProfileInfoRow(icon: "pills.fill", title: field("Medication Info", "用藥資訊"), value: draft.medications.localizedCareText(appLanguage), tint: .purple)
                ProfileInfoRow(icon: "exclamationmark.triangle.fill", title: field("Allergy History", "過敏史"), value: draft.allergyHistory.localizedCareText(appLanguage), tint: AppTheme.warningYellow)
                ProfileInfoRow(icon: "cross.case.fill", title: field("Surgery / Other Medical Notes", "手術 / 其他醫療備註"), value: draft.surgeryAndMedicalNote.localizedCareText(appLanguage), tint: .orange)
            }
        }
    }
    
    private var lifestyleReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.lifestyle), icon: "figure.walk") {
            ProfileInfoRow(
                icon: "figure.walk",
                title: sectionTitle(.lifestyle),
                value: draft.lifestyle.localizedCareText(appLanguage),
                tint: .brown
            )
        }
    }
    
    private var cognitiveReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.cognitive), icon: "brain.head.profile") {
            ProfileInfoRow(
                icon: "brain.head.profile",
                title: sectionTitle(.cognitive),
                value: draft.cognitiveStatus.localizedCareText(appLanguage),
                tint: .blue
            )
        }
    }
    
    private var carePreferenceReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.carePreference), icon: "heart.text.square.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(
                    icon: "heart.text.square.fill",
                    title: sectionTitle(.carePreference),
                    value: draft.carePreference.localizedCareText(appLanguage)
                )

                ProfileInfoRow(
                    icon: "nosign",
                    title: field("Restrictions", "限制事項"),
                    value: draft.taboo.localizedCareText(appLanguage),
                    tint: AppTheme.dangerRed
                )
            }
        }
    }
    
    private var emergencyReadOnlyContent: some View {
        ProfileSectionView(title: field("Emergency Contact", "緊急聯絡人"), icon: "phone.fill") {
            VStack(spacing: 12) {
                if draft.emergencyContacts.isEmpty {
                    Text(field("No emergency contacts yet", "目前沒有緊急聯絡人"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(draft.emergencyContacts) { contact in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(localizedProfileText(contact.name, fallbackEN: "Emergency Contact", fallbackZH: "緊急聯絡人"))
                                .font(.headline)
                                .fontWeight(.bold)

                            ProfileInfoRow(icon: "heart.fill", title: field("Relationship", "關係"), value: contact.relationship.localizedProfileValue(appLanguage))
                            ProfileInfoRow(icon: "phone.fill", title: field("Phone", "電話"), value: contact.phone)
                            ProfileInfoRow(icon: "note.text", title: field("Notes", "備註"), value: contact.note.localizedCareText(appLanguage))
                        }
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
    }
    
    private var medicalUnitReadOnlyContent: some View {
        ProfileSectionView(title: field("Medical Provider", "醫療單位"), icon: "building.2.fill") {
            VStack(spacing: 12) {
                if draft.medicalUnits.isEmpty {
                    Text(field("No medical providers yet", "目前沒有醫療單位"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(draft.medicalUnits) { unit in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(localizedProfileText(unit.name, fallbackEN: "Provider name not provided", fallbackZH: "未提供醫療單位名稱"))
                                .font(.headline)
                                .fontWeight(.bold)

                            ProfileInfoRow(icon: "stethoscope", title: field("Department", "科別"), value: unit.department.localizedCareText(appLanguage))
                            ProfileInfoRow(icon: "person.fill", title: field("Physician Name", "醫師姓名"), value: unit.doctorName.localizedCareText(appLanguage))
                            ProfileInfoRow(icon: "phone.fill", title: field("Phone", "電話"), value: unit.phone)
                            ProfileInfoRow(icon: "mappin.and.ellipse", title: field("Address", "地址"), value: unit.address.localizedCareText(appLanguage))
                            ProfileInfoRow(icon: "note.text", title: field("Notes", "備註"), value: unit.note.localizedCareText(appLanguage))
                        }
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
    }
    
    private var filesReadOnlyContent: some View {
        ProfileSectionView(title: sectionTitle(.files), icon: "doc.text.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if draft.documents.isEmpty {
                    Text(field("No documents uploaded yet", "目前沒有上傳文件"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(draft.documents) { document in
                        HStack(spacing: 12) {
                            Image(systemName: "doc.text.fill")
                                .foregroundStyle(AppTheme.warningYellow)
                                .frame(width: 42, height: 42)
                                .background(AppTheme.warningYellow.opacity(0.12))
                                .clipShape(RoundedRectangle(cornerRadius: 12))

                            VStack(alignment: .leading, spacing: 4) {
                                Text(document.fileName)
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text("\(document.fileType) - \(document.addedAt.formatted(date: .numeric, time: .shortened))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                    }
                }
            }
        }
    }
    
    private var inviteContent: some View {
        ProfileSectionView(title: sectionTitle(.invite), icon: "qrcode") {
            VStack(spacing: 16) {
                QRCodeView(
                    text: InviteService.makeInviteLink(for: draft.careRecipientID),
                    size: 200
                )

                VStack(spacing: 6) {
                    Text(field("Care Account ID", "照護帳號 ID"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(draft.careRecipientID)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .textSelection(.enabled)
                }

                VStack(spacing: 6) {
                    Text(field("Invite Link", "邀請連結"))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(InviteService.makeWebInviteLink(for: draft.careRecipientID))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }

                Text(field("Other members can join this care account through the QR code or invite link. Requests must be approved by the main manager.", "其他成員可透過 QR Code 或邀請連結加入此照護帳號，加入申請需由主要管理者審核。"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineSpacing(3)
                    .padding()
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    private var basicEditContent: some View {
        ProfileSectionView(title: sectionTitle(.basic), icon: "person.2.fill") {
            VStack(spacing: 14) {
                FormTextField(
                    title: field("Name", "姓名"),
                    placeholder: field("Enter the care recipient name", "輸入被照護者姓名"),
                    text: $draft.name
                )

                FormTextField(
                    title: field("Relationship", "關係"),
                    placeholder: field("Example: Mother, father, grandmother", "例如：母親、父親、祖母"),
                    text: $draft.relationship
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text(field("Gender", "性別"))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Picker(field("Gender", "性別"), selection: $draft.gender) {
                        Text(field("Female", "女")).tag("Female")
                        Text(field("Male", "男")).tag("Male")
                        Text(field("Other", "其他")).tag("Other")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(field("Birthday", "生日"))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DatePicker(
                        field("Select birthday", "選擇生日"),
                        selection: $draft.birthday,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(field("Blood Type", "血型"))
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Picker(field("Blood Type", "血型"), selection: $draft.bloodType) {
                        Text(field("Select", "請選擇")).tag("")
                        Text(field("Type A", "A 型")).tag("A")
                        Text(field("Type B", "B 型")).tag("B")
                        Text(field("Type O", "O 型")).tag("O")
                        Text(field("Type AB", "AB 型")).tag("AB")
                        Text(field("Unknown", "不確定")).tag("Unknown")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                FormTextField(
                    title: field("Contact / Address Notes", "聯絡 / 地址備註"),
                    placeholder: field("Example: phone, address, or main contact method", "例如：電話、地址或主要聯絡方式"),
                    text: $draft.phoneNote
                )
            }
        }
    }

    private var medicalEditContent: some View {
        ProfileSectionView(title: sectionTitle(.medical), icon: "cross.case.fill") {
            VStack(spacing: 14) {
                FormTextEditor(
                    title: field("Medical History", "病史"),
                    placeholder: field("Example: hypertension, diabetes, heart disease, dementia", "例如：高血壓、糖尿病、心臟病、失智症"),
                    text: $draft.medicalHistory
                )

                FormTextEditor(
                    title: field("Medication Info", "用藥資訊"),
                    placeholder: field("Example: blood pressure medication at 8 AM, blood sugar medication after dinner", "例如：早上 8 點血壓藥、晚餐後血糖藥"),
                    text: $draft.medications
                )

                FormTextEditor(
                    title: field("Allergy History", "過敏史"),
                    placeholder: field("Example: medication or food allergies; write none if not applicable", "例如：藥物或食物過敏，若無請填無"),
                    text: $draft.allergyHistory
                )

                FormTextEditor(
                    title: field("Surgery / Other Medical Notes", "手術 / 其他醫療備註"),
                    placeholder: field("Example: surgeries, hospitalization records, special medical instructions", "例如：手術、住院紀錄、特殊醫囑"),
                    text: $draft.surgeryAndMedicalNote
                )
            }
        }
    }

    private var lifestyleEditContent: some View {
        ProfileSectionView(title: sectionTitle(.lifestyle), icon: "figure.walk") {
            FormTextEditor(
                title: sectionTitle(.lifestyle),
                placeholder: field("Example: diet, sleep, exercise, and toileting habits", "例如：飲食、睡眠、運動與如廁習慣"),
                text: $draft.lifestyle
            )
        }
    }

    private var cognitiveEditContent: some View {
        ProfileSectionView(title: sectionTitle(.cognitive), icon: "brain.head.profile") {
            FormTextEditor(
                title: sectionTitle(.cognitive),
                placeholder: field("Example: memory, mood patterns, communication ability, anxiety triggers", "例如：記憶力、情緒模式、溝通能力、焦慮誘因"),
                text: $draft.cognitiveStatus
            )
        }
    }

    private var carePreferenceEditContent: some View {
        ProfileSectionView(title: sectionTitle(.carePreference), icon: "heart.text.square.fill") {
            VStack(spacing: 14) {
                FormTextEditor(
                    title: sectionTitle(.carePreference),
                    placeholder: field("Example: daily assistance needs, preferences, preferred care style", "例如：日常協助需求、偏好、喜歡的照護方式"),
                    text: $draft.carePreference
                )

                FormTextEditor(
                    title: field("Restrictions", "限制事項"),
                    placeholder: field("Example: avoid sweets, avoid getting out of bed alone, avoid specific foods or activities", "例如：避免甜食、避免獨自下床、避免特定食物或活動"),
                    text: $draft.taboo
                )
            }
        }
    }

    private var emergencyEditContent: some View {
        ProfileSectionView(title: field("Emergency Contact", "緊急聯絡人"), icon: "phone.fill") {
            VStack(spacing: 16) {
                if draft.emergencyContacts.isEmpty {
                    Text(field("No emergency contacts yet.", "目前沒有緊急聯絡人。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach($draft.emergencyContacts) { $contact in
                        emergencyContactEditor(contact: $contact)
                    }
                }

                Button {
                    draft.emergencyContacts.append(EmergencyContact())
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(field("Add Emergency Contact", "新增緊急聯絡人"))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
    
    private var medicalUnitEditContent: some View {
        ProfileSectionView(title: field("Medical Provider", "醫療單位"), icon: "building.2.fill") {
            VStack(spacing: 16) {
                if draft.medicalUnits.isEmpty {
                    Text(field("No medical providers yet.", "目前沒有醫療單位。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach($draft.medicalUnits) { $unit in
                        medicalUnitEditor(unit: $unit)
                    }
                }

                Button {
                    draft.medicalUnits.append(MedicalUnit())
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(field("Add Medical Provider", "新增醫療單位"))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }
    
    private func medicalUnitEditor(unit: Binding<MedicalUnit>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(field("Medical Provider", "醫療單位"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    draft.medicalUnits.removeAll { $0.id == unit.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppTheme.dangerRed)
                }
            }

            FormTextField(
                title: field("Provider Name", "醫療單位名稱"),
                placeholder: field("Example: NTU Hospital, local clinic", "例如：台大醫院、社區診所"),
                text: unit.name
            )

            FormTextField(
                title: field("Department", "科別"),
                placeholder: field("Example: cardiology, rehabilitation, family medicine", "例如：心臟內科、復健科、家醫科"),
                text: unit.department
            )

            FormTextField(
                title: field("Physician Name", "醫師姓名"),
                placeholder: field("Example: Dr. Wang", "例如：王醫師"),
                text: unit.doctorName
            )

            FormTextField(
                title: field("Phone", "電話"),
                placeholder: field("Enter phone", "輸入電話"),
                text: unit.phone,
                keyboardType: .phonePad
            )

            FormTextField(
                title: field("Address", "地址"),
                placeholder: field("Enter address", "輸入地址"),
                text: unit.address
            )

            FormTextEditor(
                title: field("Notes", "備註"),
                placeholder: field("Example: regular follow-up location, registration method, notes", "例如：固定回診地點、掛號方式、注意事項"),
                text: unit.note
            )
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
    
    private func emergencyContactEditor(contact: Binding<EmergencyContact>) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(field("Emergency Contact", "緊急聯絡人"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Button {
                    draft.emergencyContacts.removeAll { $0.id == contact.wrappedValue.id }
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(AppTheme.dangerRed)
                }
            }

            FormTextField(
                title: field("Name", "姓名"),
                placeholder: field("Enter name", "輸入姓名"),
                text: contact.name
            )

            FormTextField(
                title: field("Relationship", "關係"),
                placeholder: field("Example: daughter, son, spouse, friend", "例如：女兒、兒子、配偶、朋友"),
                text: contact.relationship
            )

            FormTextField(
                title: field("Phone", "電話"),
                placeholder: field("Enter phone", "輸入電話"),
                text: contact.phone,
                keyboardType: .phonePad
            )

            FormTextField(
                title: field("Notes", "備註"),
                placeholder: field("Example: priority contact, available at night", "例如：優先聯絡、夜間可聯絡"),
                text: contact.note
            )
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var filesContent: some View {
        ProfileSectionView(title: sectionTitle(.files), icon: "doc.text.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showingFileImporter = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text(field("Upload Documents or Files", "上傳文件或檔案"))
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if draft.documents.isEmpty {
                    Text(field("No documents uploaded yet. You can upload medical reports, test results, diagnoses, or other important files.", "目前沒有上傳文件。你可以上傳醫療報告、檢驗結果、診斷證明或其他重要檔案。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                } else {
                    VStack(spacing: 10) {
                        ForEach(draft.documents) { document in
                            HStack(spacing: 12) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundStyle(AppTheme.warningYellow)
                                    .frame(width: 42, height: 42)
                                    .background(AppTheme.warningYellow.opacity(0.12))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(document.fileName)
                                        .font(.headline)
                                        .fontWeight(.bold)

                                    Text("\(document.fileType) - \(document.addedAt.formatted(date: .numeric, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    deleteDocument(document)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(AppTheme.dangerRed)
                                }
                            }
                            .padding()
                            .background(AppTheme.background)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $showingFileImporter,
            allowedContentTypes: [.pdf, .image, .text, .data],
            allowsMultipleSelection: true
        ) { result in
            handleImportedFiles(result)
        }
    }

    private var approvalContent: some View {
        Group {
            if !isEditable {
                ProfileSectionView(title: field("No Permission", "無權限"), icon: "lock.fill") {
                    Text(field("Only the main manager can review join requests.", "只有主要管理者可以審核加入申請。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                approvalManagerContent
            }
        }
    }

    private var approvalManagerContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            if pendingMembers.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.primaryGreen)

                    Text(field("No pending requests", "目前沒有待審核申請"))
                        .font(.headline)

                    Text(field("Members who register through the QR code or invite link will appear here for main manager review.", "透過 QR Code 或邀請連結註冊的成員，會出現在這裡供主要管理者審核。"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 24))
            } else {
                ForEach(pendingMembers) { member in
                    pendingMemberCard(member)
                }
            }

            ProfileSectionView(title: field("Joined Members", "已加入成員"), icon: "person.3.fill") {
                if approvedMembers.isEmpty {
                    Text(field("No joined members yet", "目前沒有已加入成員"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 10) {
                        ForEach(approvedMembers) { member in
                            CaregiverRowView(caregiver: member)
                        }
                    }
                }
            }
        }
    }

    private func pendingMemberCard(_ member: Caregiver) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "person.badge.plus.fill")
                    .foregroundStyle(AppTheme.warningYellow)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.warningYellow.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(member.name.containsCareBridgeCJKText && !appLanguage.isChinese ? member.role.displayName(appLanguage) : member.name.localizedCareText(appLanguage))
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("\(member.role.displayName(appLanguage)) - \(member.status.displayName(appLanguage))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(member.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            HStack(spacing: 10) {
                Button {
                    onReject(member)
                } label: {
                    Text(field("Reject", "拒絕"))
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.dangerRed)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.dangerRed.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onApprove(member)
                } label: {
                    Text(field("Approve", "核准"))
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.primaryGreen)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }

    private func field(_ en: String, _ zhTW: String) -> String {
        appLanguage.text(en: en, zhTW: zhTW)
    }

    private func sectionTitle(_ section: ProfileSectionItem) -> String {
        section.title(appLanguage)
    }

    private func localizedProfileText(_ value: String, fallbackEN: String, fallbackZH: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return field(fallbackEN, fallbackZH)
        }

        if appLanguage.isJapanese {
            return trimmed.containsCareBridgeCJKText ? field(fallbackEN, fallbackZH) : trimmed
        }
        return appLanguage.isChinese ? trimmed : trimmed.careBridgeEnglishDisplayValue
    }

    private func handleImportedFiles(_ result: Result<[URL], Error>) {
        do {
            let urls = try result.get()

            for url in urls {
                let document = CareDocument(
                    fileName: url.lastPathComponent,
                    fileType: url.pathExtension.isEmpty ? "file" : url.pathExtension
                )

                draft.documents.append(document)
            }
        } catch {
            print("Failed to upload file：\(error.localizedDescription)")
        }
    }

    private func deleteDocument(_ document: CareDocument) {
        draft.documents.removeAll { $0.id == document.id }
    }
}

#Preview {
    ProfileSectionDetailView(
        section: .basic,
        draft: .constant(CareRecipientDraft()),
        isEditable: true,
        approvedMembers: [],
        pendingMembers: [],
        onApprove: { _ in },
        onReject: { _ in }
    )
}
