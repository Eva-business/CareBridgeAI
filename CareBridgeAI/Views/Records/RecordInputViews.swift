import SwiftUI

struct TextRecordInputView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: ([CareRecord]) -> Void

    @State private var inputText = ""
    @State private var selectedCategories: Set<CareRecordCategory> = []

    private var suggestedCategories: [CareRecordCategory] {
        CareAIService.classifyCategories(inputText)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        TextEditor(text: $inputText)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay(alignment: .topLeading) {
                                if inputText.isEmpty {
                                    Text("請輸入照護內容...")
                                        .font(.subheadline)
                                        .foregroundStyle(.gray.opacity(0.65))
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 16)
                                        .allowsHitTesting(false)
                                }
                            }

                        uploadImageSection

                        categorySelectionSection

                        aiHintSection
                    }
                    .padding(24)
                }
            }
            .navigationTitle("文字輸入")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveRecords()
                    }
                    .fontWeight(.bold)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: inputText) {
                autoSelectSuggestedCategories()
            }
        }
    }

    private var uploadImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("上傳照片（選填）")
                .font(.headline)

            HStack(spacing: 12) {
                placeholderImageButton(icon: "camera.fill", title: "拍照")
                placeholderImageButton(icon: "photo.fill", title: "從相簿選擇")
            }
        }
    }

    private func placeholderImageButton(icon: String, title: String) -> some View {
        Button {
            print(title)
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)
            .frame(width: 110, height: 82)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }

    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI 預測類別（可修改）")
                .font(.headline)

            HStack(spacing: 12) {
                ForEach(CareRecordCategory.allCases) { category in
                    categoryToggle(category)
                }
            }
        }
    }

    private func categoryToggle(_ category: CareRecordCategory) -> some View {
        let isSelected = selectedCategories.contains(category)

        return Button {
            if isSelected {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: category.icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : category.color)
                    .frame(width: 46, height: 46)
                    .background(isSelected ? category.color : category.color.opacity(0.12))
                    .clipShape(Circle())

                Text(categoryShortName(category))
                    .font(.caption2)
                    .fontWeight(.semibold)

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption)
                    .foregroundStyle(isSelected ? category.color : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private var aiHintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("AI 判斷說明")
                .font(.headline)

            Text("系統會根據文字內容預先勾選可能類別。若內容同時包含飲食、用藥、排便或情緒，儲存時會整理成多筆紀錄。")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding()
        .background(AppTheme.lightGreen)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func autoSelectSuggestedCategories() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            selectedCategories.removeAll()
            return
        }

        selectedCategories = Set(suggestedCategories)
    }

    private func saveRecords() {
        let categories = Array(selectedCategories)
        let newRecords = CareAIService.generateRecordsFromText(
            inputText,
            selectedCategories: categories
        )

        onSave(newRecords)
        dismiss()
    }

    private func categoryShortName(_ category: CareRecordCategory) -> String {
        switch category {
        case .food:
            return "食"
        case .medicine:
            return "藥"
        case .bowel:
            return "便"
        case .mood:
            return "情緒"
        case .custom:
            return "其他"
        }
    }
}
struct VoiceRecordInputView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: ([CareRecord]) -> Void

    @StateObject private var speechService = SpeechService()

    private var canSave: Bool {
        !speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 28) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(AppTheme.lightGreen)
                            .frame(width: 170, height: 170)

                        Circle()
                            .stroke(
                                speechService.isRecording
                                ? AppTheme.primaryGreen.opacity(0.35)
                                : AppTheme.primaryGreen.opacity(0.18),
                                lineWidth: 18
                            )
                            .frame(width: speechService.isRecording ? 205 : 190, height: speechService.isRecording ? 205 : 190)
                            .animation(.easeInOut(duration: 0.35), value: speechService.isRecording)

                        Image(systemName: speechService.isRecording ? "waveform" : "mic.fill")
                            .font(.system(size: 62))
                            .foregroundStyle(AppTheme.primaryGreen)
                    }

                    Text(speechService.isRecording ? "正在聆聽照護內容..." : "點擊開始錄音")
                        .font(.headline)

                    Text("語音會先轉成文字，再交給 AI 判斷類別，可能整理成一筆或多筆照護紀錄。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)

                    if let errorMessage = speechService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.dangerRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    transcriptSection

                    Spacer()

                    bottomButtons
                }
            }
            .navigationTitle("語音輸入")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                speechService.requestPermission()
            }
            .onDisappear {
                speechService.stopRecording()
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("語音轉文字結果")
                .font(.headline)

            if speechService.transcript.isEmpty {
                Text("尚未產生文字。請點擊開始錄音後口述照護內容。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else {
                Text(speechService.transcript)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                let categories = CareAIService.classifyCategories(speechService.transcript)

                HStack(spacing: 8) {
                    Text("AI 判斷：")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(categories) { category in
                        Label(category.rawValue, systemImage: category.icon)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(category.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(category.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        HStack(spacing: 14) {
            Button {
                speechService.stopRecording()
                dismiss()
            } label: {
                Text("取消")
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                if speechService.isRecording {
                    speechService.stopRecording()
                } else {
                    speechService.startRecording(language: .zhTW)
                }
            } label: {
                Text(speechService.isRecording ? "停止錄音" : "開始錄音")
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }

            Button {
                saveVoiceRecords()
            } label: {
                Text("儲存")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(canSave ? AppTheme.primaryGreen : Color.gray.opacity(0.4))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!canSave)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    private func saveVoiceRecords() {
        speechService.stopRecording()

        let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else { return }

        let categories = CareAIService.classifyCategories(transcript)

        let newRecords = CareAIService.generateRecordsFromText(
            transcript,
            selectedCategories: categories
        )

        onSave(newRecords)
        dismiss()
    }
}

struct QuickConditionInputView: View {
    @Environment(\.dismiss) private var dismiss

    let onSave: (CareRecord) -> Void

    @State private var selectedCategory: CareRecordCategory = .food
    @State private var selectedCondition: RecordCondition = .good
    @State private var note = ""

    private let categories: [CareRecordCategory] = [.food, .medicine, .bowel, .mood]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("請選擇照護狀況")
                            .font(.headline)

                        conditionGrid

                        VStack(alignment: .leading, spacing: 8) {
                            Text("補充說明（選填）")
                                .font(.headline)

                            TextEditor(text: $note)
                                .frame(height: 100)
                                .padding(8)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(24)
                }
            }
            .navigationTitle("快速判斷")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("儲存") {
                        saveQuickRecord()
                    }
                    .fontWeight(.bold)
                }
            }
        }
    }

    private var conditionGrid: some View {
        VStack(spacing: 14) {
            HStack {
                Text("")
                    .frame(width: 44)

                ForEach(RecordCondition.allCases) { condition in
                    Text(condition.rawValue)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
            }

            ForEach(categories) { category in
                HStack(spacing: 12) {
                    Text(categoryShortName(category))
                        .font(.headline)
                        .foregroundStyle(category.color)
                        .frame(width: 44)

                    ForEach(RecordCondition.allCases) { condition in
                        Button {
                            selectedCategory = category
                            selectedCondition = condition
                        } label: {
                            VStack(spacing: 6) {
                                Image(systemName: condition.icon)
                                    .font(.title2)

                                Circle()
                                    .fill(isSelected(category, condition) ? condition.color : Color.clear)
                                    .frame(width: 8, height: 8)
                            }
                            .foregroundStyle(condition.color)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(
                                isSelected(category, condition)
                                ? condition.color.opacity(0.16)
                                : Color.white
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func isSelected(_ category: CareRecordCategory, _ condition: RecordCondition) -> Bool {
        selectedCategory == category && selectedCondition == condition
    }

    private func saveQuickRecord() {
        let extraNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        let content: String
        if extraNote.isEmpty {
            content = "\(selectedCategory.rawValue)快速判斷：目前狀態\(selectedCondition.rawValue)。"
        } else {
            content = "\(selectedCategory.rawValue)快速判斷：目前狀態\(selectedCondition.rawValue)。\(extraNote)"
        }

        let record = CareRecord(
            content: content,
            category: selectedCategory,
            condition: selectedCondition
        )

        onSave(record)
        dismiss()
    }

    private func categoryShortName(_ category: CareRecordCategory) -> String {
        switch category {
        case .food:
            return "食"
        case .medicine:
            return "藥"
        case .bowel:
            return "便"
        case .mood:
            return "情緒"
        case .custom:
            return "其他"
        }
    }
}

#Preview {
    TextRecordInputView { _ in }
}
