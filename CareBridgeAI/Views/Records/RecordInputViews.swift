import SwiftUI
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct TextRecordInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let onSave: ([CareRecord]) -> Void

    @State private var inputText = ""
    @State private var selectedMediaItems: [PhotosPickerItem] = []
    @State private var attachments: [CareRecordAttachment] = []
    @State private var mediaErrorMessage: String?
    @State private var showingCameraPicker = false
    @State private var cameraCaptureKind: CareRecordAttachmentKind = .image
    @State private var selectedCategories: Set<CareRecordCategory> = []
    @State private var inferredCondition: RecordCondition?
    @State private var inferredSuggestions: [CareAIRecordSuggestion] = []
    @State private var isAnalyzing = false
    @State private var usesOnDeviceModel = false

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
                                    Text(appLanguage.text(en: "Enter care details...", zhTW: "輸入照護細節..."))
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
            .dismissKeyboardOnTap()
            .navigationTitle(appLanguage.text(en: "Text Input", zhTW: "文字輸入"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text(en: "Cancel", zhTW: "取消")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Save", zhTW: "儲存")) {
                        saveRecords()
                    }
                    .fontWeight(.bold)
                    .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .task(id: inputText) {
                await analyzeInput()
            }
            .onChange(of: selectedMediaItems) { _, newItems in
                Task {
                    await loadSelectedMedia(from: newItems)
                }
            }
            .sheet(isPresented: $showingCameraPicker) {
                CameraMediaPicker(captureKind: cameraCaptureKind) { attachment in
                    attachments.append(attachment)
                }
            }
        }
    }

    private var uploadImageSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appLanguage.text(en: "Upload photo or video (optional)", zhTW: "上傳照片或影片（選填）"))
                .font(.headline)

            HStack(spacing: 12) {
                cameraMenu
                mediaLibraryPicker
            }

            if !attachments.isEmpty {
                attachmentPreviewGrid
            }

            if let mediaErrorMessage {
                Text(mediaErrorMessage)
                    .font(.caption)
                    .foregroundStyle(AppTheme.dangerRed)
            }
        }
    }

    private var cameraMenu: some View {
        Menu {
            Button {
                cameraCaptureKind = .image
                showingCameraPicker = true
            } label: {
                Label(appLanguage.text(en: "Take Photo", zhTW: "拍照"), systemImage: "camera.fill")
            }

            Button {
                cameraCaptureKind = .video
                showingCameraPicker = true
            } label: {
                Label(appLanguage.text(en: "Record Video", zhTW: "錄影"), systemImage: "video.fill")
            }
        } label: {
            mediaActionTile(icon: "camera.fill", title: appLanguage.text(en: "Camera", zhTW: "相機"))
        }
    }

    private var mediaLibraryPicker: some View {
        PhotosPicker(
            selection: $selectedMediaItems,
            maxSelectionCount: 6,
            matching: .any(of: [.images, .videos])
        ) {
            mediaActionTile(icon: "photo.on.rectangle.angled", title: appLanguage.text(en: "Library", zhTW: "相簿"))
        }
    }

    private func mediaActionTile(icon: String, title: String) -> some View {
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

    private var attachmentPreviewGrid: some View {
        LazyVGrid(
            columns: [GridItem(.adaptive(minimum: 92), spacing: 10)],
            spacing: 10
        ) {
            ForEach(attachments) { attachment in
                attachmentPreview(attachment)
            }
        }
    }

    private func attachmentPreview(_ attachment: CareRecordAttachment) -> some View {
        ZStack(alignment: .topTrailing) {
            Group {
                if attachment.kind == .image,
                   let uiImage = UIImage(data: attachment.data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "video.fill")
                            .font(.title2)
                        Text(appLanguage.text(en: "Video", zhTW: "影片"))
                            .font(.caption2)
                            .fontWeight(.semibold)
                    }
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(AppTheme.lightGreen)
                }
            }
            .frame(height: 92)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Button {
                attachments.removeAll { $0.id == attachment.id }
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundStyle(.white, .black.opacity(0.55))
                    .padding(5)
            }
            .buttonStyle(.plain)
        }
    }

    private var categorySelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(appLanguage.text(en: "AI Predicted Categories (editable)", zhTW: "AI 預測分類（可編輯）"))
                .font(.headline)

            if isAnalyzing {
                Label(appLanguage.text(en: "Analyzing content...", zhTW: "正在分析內容..."), systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(AppTheme.primaryGreen)
            }

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

                if let condition = predictedCondition(for: category), isSelected {
                    Text(condition.displayName(appLanguage))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(condition.color)
                }

                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.caption)
                    .foregroundStyle(isSelected ? category.color : .gray)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func predictedCondition(for category: CareRecordCategory) -> RecordCondition? {
        inferredSuggestions.first(where: { $0.category == category })?.condition ?? inferredCondition
    }

    private var aiHintSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appLanguage.text(en: "AI Analysis Notes", zhTW: "AI 分析說明"))
                .font(.headline)

            Text(
                usesOnDeviceModel
                    ? appLanguage.text(en: "Foundation Models analyzed this on device. You can still edit the predicted categories; saving may split the note into multiple care records by category, severity, and content.", zhTW: "Foundation Models 已在裝置端完成分析。你仍可編輯預測分類；儲存時可能依分類、嚴重度與內容拆成多筆照護紀錄。")
                    : appLanguage.text(en: "The system automatically analyzes and preselects categories and severity. When the on-device model is unavailable, a smart fallback keeps recording available offline.", zhTW: "系統會自動分析並預選分類與嚴重度；當裝置端模型不可用時，智慧 fallback 仍可離線完成紀錄。")
            )
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineSpacing(3)
        }
        .padding()
        .background(AppTheme.lightGreen)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func analyzeInput() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            selectedCategories.removeAll()
            inferredCondition = nil
            inferredSuggestions = []
            usesOnDeviceModel = false
            return
        }

        isAnalyzing = true
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        let analysis = await CareAIService.analyze(trimmed, language: appLanguage)
        guard !Task.isCancelled else { return }
        selectedCategories = Set(analysis.categories)
        inferredCondition = analysis.condition
        inferredSuggestions = analysis.suggestions
        usesOnDeviceModel = analysis.usedOnDeviceModel
        isAnalyzing = false
    }

    private func saveRecords() {
        Task {
            let analysis = await CareAIService.analyze(inputText, language: appLanguage)
            let categories = selectedCategories.isEmpty ? analysis.categories : Array(selectedCategories)
            var newRecords = CareAIService.generateRecordsFromText(
                inputText,
                selectedCategories: categories,
                analysis: analysis,
                condition: analysis.condition ?? inferredCondition
            )
            if !attachments.isEmpty, !newRecords.isEmpty {
                newRecords[0].attachments = attachments
            }
            onSave(newRecords)
            dismiss()
        }
    }

    private func loadSelectedMedia(from items: [PhotosPickerItem]) async {
        mediaErrorMessage = nil

        for item in items {
            guard let data = try? await item.loadTransferable(type: Data.self) else {
                mediaErrorMessage = appLanguage.text(en: "One attachment could not be read. Please choose it again.", zhTW: "有一個附件無法讀取，請重新選擇。")
                continue
            }

            guard let contentType = item.supportedContentTypes.first(where: {
                $0.conforms(to: .image) || $0.conforms(to: .movie)
            }) else {
                mediaErrorMessage = appLanguage.text(en: "Only photo or video attachments are supported.", zhTW: "只支援照片或影片附件。")
                continue
            }

            let kind: CareRecordAttachmentKind = contentType.conforms(to: .movie) ? .video : .image
            let fileExtension = contentType.preferredFilenameExtension ?? (kind == .video ? "mov" : "jpg")
            let attachment = CareRecordAttachment(
                kind: kind,
                data: data,
                filename: "\(kind == .video ? "video" : "image")-\(UUID().uuidString).\(fileExtension)",
                contentType: contentType.identifier
            )
            attachments.append(attachment)
        }

        selectedMediaItems = []
    }

    private func categoryShortName(_ category: CareRecordCategory) -> String {
        category.shortDisplayName(appLanguage)
    }
}

private struct CameraMediaPicker: UIViewControllerRepresentable {
    let captureKind: CareRecordAttachmentKind
    let onCapture: (CareRecordAttachment) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.mediaTypes = [
            captureKind == .video ? UTType.movie.identifier : UTType.image.identifier
        ]
        picker.videoQuality = .typeMedium
        picker.cameraCaptureMode = captureKind == .video ? .video : .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) { }

    func makeCoordinator() -> Coordinator {
        Coordinator(captureKind: captureKind, onCapture: onCapture, dismiss: dismiss)
    }

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let captureKind: CareRecordAttachmentKind
        let onCapture: (CareRecordAttachment) -> Void
        let dismiss: DismissAction

        init(
            captureKind: CareRecordAttachmentKind,
            onCapture: @escaping (CareRecordAttachment) -> Void,
            dismiss: DismissAction
        ) {
            self.captureKind = captureKind
            self.onCapture = onCapture
            self.dismiss = dismiss
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            defer { dismiss() }

            if captureKind == .image,
               let image = info[.originalImage] as? UIImage,
               let data = image.jpegData(compressionQuality: 0.82) {
                onCapture(
                    CareRecordAttachment(
                        kind: .image,
                        data: data,
                        filename: "camera-\(UUID().uuidString).jpg",
                        contentType: UTType.jpeg.identifier
                    )
                )
                return
            }

            if captureKind == .video,
               let url = info[.mediaURL] as? URL,
               let data = try? Data(contentsOf: url) {
                onCapture(
                    CareRecordAttachment(
                        kind: .video,
                        data: data,
                        filename: "video-\(UUID().uuidString).mov",
                        contentType: UTType.quickTimeMovie.identifier
                    )
                )
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            dismiss()
        }
    }
}
struct VoiceRecordInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let recordingLanguage: AppLanguage
    let onSave: ([CareRecord]) -> Void

    @StateObject private var speechService = SpeechService()
    @State private var predictedCategories: [CareRecordCategory] = []
    @State private var predictedSuggestions: [CareAIRecordSuggestion] = []
    @State private var isAnalyzingTranscript = false
    @State private var transcriptUsesOnDeviceModel = false

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

                    Text(
                        speechService.isRecording
                            ? appLanguage.text(en: "Listening to care details...", zhTW: "正在聆聽照護細節...")
                            : appLanguage.text(en: "Tap to start recording", zhTW: "點一下開始錄音")
                    )
                        .font(.headline)

                    Text(appLanguage.text(en: "Recognizing with \(recordingLanguage.displayName(in: appLanguage)). Speech is converted to text first, then AI classifies it into one or more care records.", zhTW: "使用\(recordingLanguage.displayName)辨識。語音會先轉成文字，再由 AI 分類成一筆或多筆照護紀錄。"))
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
            .navigationTitle(appLanguage.text(en: "Voice Input", zhTW: "語音輸入"))
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                speechService.requestPermission()
            }
            .onDisappear {
                speechService.stopRecording()
            }
            .task(id: speechService.transcript) {
                await analyzeTranscript()
            }
        }
    }

    private var transcriptSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appLanguage.text(en: "Speech-to-text Result", zhTW: "語音轉文字結果"))
                .font(.headline)

            if speechService.transcript.isEmpty {
                Text(appLanguage.text(en: "No text yet. Tap start recording and speak the care details.", zhTW: "目前沒有文字。點選開始錄音後說出照護細節。"))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)
            } else {
                Text(speechService.transcript)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineSpacing(4)

                HStack(spacing: 8) {
                    Text(isAnalyzingTranscript ? appLanguage.text(en: "AI analyzing:", zhTW: "AI 分析中：") : appLanguage.text(en: "AI assessment:", zhTW: "AI 評估："))
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(predictedSuggestions) { suggestion in
                        Label(
                            "\(suggestion.category.displayName(appLanguage)) / \(suggestion.condition.displayName(appLanguage))",
                            systemImage: suggestion.category.icon
                        )
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(suggestion.condition.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(suggestion.condition.color.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }

                Text(transcriptUsesOnDeviceModel ? appLanguage.text(en: "Foundation Models - On-device analysis", zhTW: "Foundation Models - 裝置端分析") : appLanguage.text(en: "Smart fallback analysis", zhTW: "智慧 fallback 分析"))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
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
                Text(appLanguage.text(en: "Cancel", zhTW: "取消"))
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
                    speechService.startRecording(language: recordingLanguage)
                }
            } label: {
                Text(
                    speechService.isRecording
                        ? appLanguage.text(en: "Stop Recording", zhTW: "停止錄音")
                        : appLanguage.text(en: "Start Recording", zhTW: "開始錄音")
                )
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
                Text(appLanguage.text(en: "Save", zhTW: "儲存"))
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

        Task {
            let analysis = await CareAIService.analyze(transcript, language: recordingLanguage)
            let newRecords = CareAIService.generateRecordsFromText(
                transcript,
                selectedCategories: analysis.categories,
                analysis: analysis,
                condition: analysis.condition
            )
            onSave(newRecords)
            dismiss()
        }
    }

    private func analyzeTranscript() async {
        let transcript = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !transcript.isEmpty else {
            predictedCategories = []
            predictedSuggestions = []
            transcriptUsesOnDeviceModel = false
            return
        }

        isAnalyzingTranscript = true
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        let analysis = await CareAIService.analyze(transcript, language: recordingLanguage)
        guard !Task.isCancelled else { return }
        predictedCategories = analysis.categories
        predictedSuggestions = analysis.suggestions
        transcriptUsesOnDeviceModel = analysis.usedOnDeviceModel
        isAnalyzingTranscript = false
    }
}

struct QuickConditionInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

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
                        Text(appLanguage.text(en: "Select care status", zhTW: "選擇照護狀態"))
                            .font(.headline)

                        conditionGrid

                        VStack(alignment: .leading, spacing: 8) {
                            Text(appLanguage.text(en: "Additional notes (optional)", zhTW: "補充備註（選填）"))
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
            .dismissKeyboardOnTap()
            .navigationTitle(appLanguage.text(en: "Quick Check", zhTW: "快速判斷"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(appLanguage.text(en: "Cancel", zhTW: "取消")) {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Save", zhTW: "儲存")) {
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
                    Text(condition.displayName(appLanguage))
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
            content = appLanguage.text(
                en: "\(selectedCategory.displayName(appLanguage)) quick check: current status is \(selectedCondition.displayName(appLanguage)).",
                zhTW: "\(selectedCategory.displayName(appLanguage))快速判斷：目前狀態為\(selectedCondition.displayName(appLanguage))。"
            )
        } else {
            content = appLanguage.text(
                en: "\(selectedCategory.displayName(appLanguage)) quick check: current status is \(selectedCondition.displayName(appLanguage)). \(extraNote)",
                zhTW: "\(selectedCategory.displayName(appLanguage))快速判斷：目前狀態為\(selectedCondition.displayName(appLanguage))。\(extraNote)"
            )
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
        category.shortDisplayName(appLanguage)
    }
}

#Preview {
    TextRecordInputView { _ in }
}
