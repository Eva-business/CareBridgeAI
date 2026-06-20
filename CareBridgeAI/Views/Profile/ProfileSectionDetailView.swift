import SwiftUI
import UniformTypeIdentifiers

struct ProfileSectionDetailView: View {
    @Environment(\.dismiss) private var dismiss

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
            .navigationTitle(section.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完成") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var basicReadOnlyContent: some View {
        ProfileSectionView(title: "基本資料", icon: "person.2.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "person.fill", title: "姓名", value: draft.name)
                ProfileInfoRow(icon: "heart.fill", title: "關係", value: draft.relationship)
                ProfileInfoRow(icon: "person.crop.circle", title: "性別", value: draft.gender)
                ProfileInfoRow(icon: "drop.fill", title: "血型", value: draft.bloodType)
                ProfileInfoRow(
                    icon: "birthday.cake.fill",
                    title: "生日",
                    value: draft.birthday.formatted(date: .numeric, time: .omitted)
                )
                ProfileInfoRow(
                    icon: "phone.fill",
                    title: "聯絡方式 / 地址備註",
                    value: draft.phoneNote
                )
            }
        }
    }
    
    private var medicalReadOnlyContent: some View {
        ProfileSectionView(title: "醫療資訊", icon: "cross.case.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(icon: "heart.text.square.fill", title: "疾病史", value: draft.medicalHistory, tint: .red)
                ProfileInfoRow(icon: "pills.fill", title: "用藥資訊", value: draft.medications, tint: .purple)
                ProfileInfoRow(icon: "exclamationmark.triangle.fill", title: "過敏史", value: draft.allergyHistory, tint: AppTheme.warningYellow)
                ProfileInfoRow(icon: "cross.case.fill", title: "手術史 / 其他醫療備註", value: draft.surgeryAndMedicalNote, tint: .orange)
            }
        }
    }
    
    private var lifestyleReadOnlyContent: some View {
        ProfileSectionView(title: "生活習慣", icon: "figure.walk") {
            ProfileInfoRow(
                icon: "figure.walk",
                title: "生活習慣",
                value: draft.lifestyle,
                tint: .brown
            )
        }
    }
    
    private var cognitiveReadOnlyContent: some View {
        ProfileSectionView(title: "認知與情緒狀態", icon: "brain.head.profile") {
            ProfileInfoRow(
                icon: "brain.head.profile",
                title: "認知與情緒狀態",
                value: draft.cognitiveStatus,
                tint: .blue
            )
        }
    }
    
    private var carePreferenceReadOnlyContent: some View {
        ProfileSectionView(title: "照護需求與偏好", icon: "heart.text.square.fill") {
            VStack(spacing: 12) {
                ProfileInfoRow(
                    icon: "heart.text.square.fill",
                    title: "照護需求與偏好",
                    value: draft.carePreference
                )

                ProfileInfoRow(
                    icon: "nosign",
                    title: "禁忌事項",
                    value: draft.taboo,
                    tint: AppTheme.dangerRed
                )
            }
        }
    }
    
    private var emergencyReadOnlyContent: some View {
        ProfileSectionView(title: "緊急聯絡人", icon: "phone.fill") {
            VStack(spacing: 12) {
                if draft.emergencyContacts.isEmpty {
                    Text("目前尚未新增緊急聯絡人")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(draft.emergencyContacts) { contact in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(contact.name.isEmpty ? "未填寫姓名" : contact.name)
                                .font(.headline)
                                .fontWeight(.bold)

                            ProfileInfoRow(icon: "heart.fill", title: "關係", value: contact.relationship)
                            ProfileInfoRow(icon: "phone.fill", title: "電話", value: contact.phone)
                            ProfileInfoRow(icon: "note.text", title: "備註", value: contact.note)
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
        ProfileSectionView(title: "醫療單位", icon: "building.2.fill") {
            VStack(spacing: 12) {
                if draft.medicalUnits.isEmpty {
                    Text("目前尚未新增醫療單位")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(AppTheme.background)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                } else {
                    ForEach(draft.medicalUnits) { unit in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(unit.name.isEmpty ? "未填寫醫療單位名稱" : unit.name)
                                .font(.headline)
                                .fontWeight(.bold)

                            ProfileInfoRow(icon: "stethoscope", title: "科別", value: unit.department)
                            ProfileInfoRow(icon: "person.fill", title: "醫師姓名", value: unit.doctorName)
                            ProfileInfoRow(icon: "phone.fill", title: "電話", value: unit.phone)
                            ProfileInfoRow(icon: "mappin.and.ellipse", title: "地址", value: unit.address)
                            ProfileInfoRow(icon: "note.text", title: "備註", value: unit.note)
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
        ProfileSectionView(title: "文件與檔案", icon: "doc.text.fill") {
            VStack(alignment: .leading, spacing: 12) {
                if draft.documents.isEmpty {
                    Text("目前尚未上傳文件")
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

                                Text("\(document.fileType)・\(document.addedAt.formatted(date: .numeric, time: .shortened))")
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
        ProfileSectionView(title: "邀請成員", icon: "qrcode") {
            VStack(spacing: 16) {
                QRCodeView(
                    text: InviteService.makeInviteLink(for: draft.careRecipientID),
                    size: 200
                )

                VStack(spacing: 6) {
                    Text("照護帳戶 ID")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(draft.careRecipientID)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.primaryGreen)
                        .textSelection(.enabled)
                }

                VStack(spacing: 6) {
                    Text("邀請連結")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(InviteService.makeWebInviteLink(for: draft.careRecipientID))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .textSelection(.enabled)
                }

                Text("其他成員可透過 QR Code 或邀請連結加入此照護帳戶，送出申請後需由主要管理者審核。")
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
        ProfileSectionView(title: "基本資料", icon: "person.2.fill") {
            VStack(spacing: 14) {
                FormTextField(
                    title: "姓名",
                    placeholder: "請輸入被照護者姓名",
                    text: $draft.name
                )

                FormTextField(
                    title: "關係",
                    placeholder: "例如：母親、父親、祖母",
                    text: $draft.relationship
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("性別")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Picker("性別", selection: $draft.gender) {
                        Text("女").tag("女")
                        Text("男").tag("男")
                        Text("其他").tag("其他")
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("生日")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    DatePicker(
                        "選擇生日",
                        selection: $draft.birthday,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("血型")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Picker("血型", selection: $draft.bloodType) {
                        Text("請選擇").tag("")
                        Text("A 型").tag("A")
                        Text("B 型").tag("B")
                        Text("O 型").tag("O")
                        Text("AB 型").tag("AB")
                        Text("不確定").tag("不確定")
                    }
                    .pickerStyle(.menu)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                FormTextField(
                    title: "聯絡方式 / 地址備註",
                    placeholder: "例如：電話、地址、主要聯絡方式",
                    text: $draft.phoneNote
                )
            }
        }
    }

    private var medicalEditContent: some View {
        ProfileSectionView(title: "醫療資訊", icon: "cross.case.fill") {
            VStack(spacing: 14) {
                FormTextEditor(
                    title: "疾病史",
                    placeholder: "例如：高血壓、糖尿病、心臟病、失智症等",
                    text: $draft.medicalHistory
                )

                FormTextEditor(
                    title: "用藥資訊",
                    placeholder: "例如：早上 8 點降血壓藥、晚餐後血糖藥",
                    text: $draft.medications
                )

                FormTextEditor(
                    title: "過敏史",
                    placeholder: "例如：藥物過敏、食物過敏；若無可填無",
                    text: $draft.allergyHistory
                )

                FormTextEditor(
                    title: "手術史 / 其他醫療備註",
                    placeholder: "例如：曾開刀、住院紀錄、特殊醫囑等",
                    text: $draft.surgeryAndMedicalNote
                )
            }
        }
    }

    private var lifestyleEditContent: some View {
        ProfileSectionView(title: "生活習慣", icon: "figure.walk") {
            FormTextEditor(
                title: "生活習慣",
                placeholder: "例如：飲食、睡眠、運動、排泄習慣等",
                text: $draft.lifestyle
            )
        }
    }

    private var cognitiveEditContent: some View {
        ProfileSectionView(title: "認知與情緒狀態", icon: "brain.head.profile") {
            FormTextEditor(
                title: "認知與情緒狀態",
                placeholder: "例如：記憶狀況、情緒傾向、溝通能力、容易焦慮的情境等",
                text: $draft.cognitiveStatus
            )
        }
    }

    private var carePreferenceEditContent: some View {
        ProfileSectionView(title: "照護需求與偏好", icon: "heart.text.square.fill") {
            VStack(spacing: 14) {
                FormTextEditor(
                    title: "照護需求與偏好",
                    placeholder: "例如：日常協助需求、個人偏好、喜歡的照護方式等",
                    text: $draft.carePreference
                )

                FormTextEditor(
                    title: "禁忌事項",
                    placeholder: "例如：不能吃太甜、避免獨自下床、避免特定食物或活動",
                    text: $draft.taboo
                )
            }
        }
    }

    private var emergencyEditContent: some View {
        ProfileSectionView(title: "緊急聯絡人", icon: "phone.fill") {
            VStack(spacing: 16) {
                if draft.emergencyContacts.isEmpty {
                    Text("目前尚未新增緊急聯絡人。")
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
                        Text("新增緊急聯絡人")
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
        ProfileSectionView(title: "醫療單位", icon: "building.2.fill") {
            VStack(spacing: 16) {
                if draft.medicalUnits.isEmpty {
                    Text("目前尚未新增醫療單位。")
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
                        Text("新增醫療單位")
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
                Text("醫療單位")
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
                title: "醫療單位名稱",
                placeholder: "例如：台大醫院、某某診所",
                text: unit.name
            )

            FormTextField(
                title: "科別",
                placeholder: "例如：心臟內科、復健科、家醫科",
                text: unit.department
            )

            FormTextField(
                title: "醫師姓名",
                placeholder: "例如：王醫師",
                text: unit.doctorName
            )

            FormTextField(
                title: "電話",
                placeholder: "請輸入電話",
                text: unit.phone,
                keyboardType: .phonePad
            )

            FormTextField(
                title: "地址",
                placeholder: "請輸入地址",
                text: unit.address
            )

            FormTextEditor(
                title: "備註",
                placeholder: "例如：固定回診地點、掛號方式、注意事項",
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
                Text("緊急聯絡人")
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
                title: "姓名",
                placeholder: "請輸入姓名",
                text: contact.name
            )

            FormTextField(
                title: "關係",
                placeholder: "例如：女兒、兒子、配偶、朋友",
                text: contact.relationship
            )

            FormTextField(
                title: "電話",
                placeholder: "請輸入電話",
                text: contact.phone,
                keyboardType: .phonePad
            )

            FormTextField(
                title: "備註",
                placeholder: "例如：優先聯絡、晚上可聯絡",
                text: contact.note
            )
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var filesContent: some View {
        ProfileSectionView(title: "文件與檔案", icon: "doc.text.fill") {
            VStack(alignment: .leading, spacing: 16) {
                Button {
                    showingFileImporter = true
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("上傳文件或檔案")
                            .fontWeight(.bold)
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.primaryGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }

                if draft.documents.isEmpty {
                    Text("目前尚未上傳文件。可上傳醫療報告、檢查結果、診斷證明或其他重要文件。")
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

                                    Text("\(document.fileType)・\(document.addedAt.formatted(date: .numeric, time: .shortened))")
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
                ProfileSectionView(title: "無權限", icon: "lock.fill") {
                    Text("只有主要管理者可以審核加入申請。")
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

                    Text("目前沒有待審核申請")
                        .font(.headline)

                    Text("其他成員透過 QR Code 或邀請連結註冊後，會出現在這裡等待主要管理者審核。")
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

            ProfileSectionView(title: "已加入成員", icon: "person.3.fill") {
                if approvedMembers.isEmpty {
                    Text("目前尚無已加入成員")
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
                    Text(member.name)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text("\(member.role.rawValue)・\(member.status.rawValue)")
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
                    Text("拒絕")
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
                    Text("同意加入")
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
            print("上傳檔案失敗：\(error.localizedDescription)")
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
