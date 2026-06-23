import SwiftUI

struct VoiceChatInputView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let currentUser: Caregiver
    let onSend: (String) -> Void

    @StateObject private var speechService = SpeechService()

    private var canSend: Bool {
        !speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    header

                    transcriptCard

                    recordButton

                    if let errorMessage = speechService.errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundStyle(AppTheme.dangerRed)
                            .multilineTextAlignment(.center)
                    }

                    Spacer()

                    PrimaryButton(title: appLanguage.text(en: "Send Voice Message", zhTW: "送出語音訊息")) {
                        sendVoiceMessage()
                    }
                    .disabled(!canSend)
                    .opacity(canSend ? 1 : 0.5)
                }
                .padding(24)
            }
            .navigationTitle(appLanguage.text(en: "Voice Message", zhTW: "語音訊息"))
            .navigationBarTitleDisplayMode(.inline)
            .dismissKeyboardOnTap()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(appLanguage.text(en: "Close", zhTW: "關閉")) {
                        speechService.stopRecording()
                        dismiss()
                    }
                }
            }
            .onAppear {
                speechService.requestPermission()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(systemName: "mic.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(AppTheme.primaryGreen)

            Text(appLanguage.text(en: "Recording in \(currentUser.preferredLanguage.englishName)", zhTW: "使用\(currentUser.preferredLanguage.displayName)錄音"))
                .font(.headline)
                .fontWeight(.bold)

            Text(appLanguage.text(en: "Speech is converted to text first. Review it before sending.", zhTW: "語音會先轉成文字，送出前可再次確認。"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
    }

    private var transcriptCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(appLanguage.text(en: "Speech-to-text", zhTW: "語音轉文字"))
                .font(.headline)
                .fontWeight(.bold)

            TextEditor(text: $speechService.transcript)
                .frame(minHeight: 160)
                .padding(8)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.gray.opacity(0.18), lineWidth: 1)
                }

            Text(appLanguage.text(en: "You can edit recognition errors before sending.", zhTW: "送出前可以修正辨識錯誤。"))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color.white.opacity(0.72))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
    }

    private var recordButton: some View {
        Button {
            if speechService.isRecording {
                speechService.stopRecording()
            } else {
                speechService.startRecording(language: currentUser.preferredLanguage)
            }
        } label: {
            HStack {
                Image(systemName: speechService.isRecording ? "stop.fill" : "mic.fill")
                Text(
                    speechService.isRecording
                        ? appLanguage.text(en: "Stop Recording", zhTW: "停止錄音")
                        : appLanguage.text(en: "Start Recording", zhTW: "開始錄音")
                )
                    .fontWeight(.bold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(speechService.isRecording ? AppTheme.dangerRed : AppTheme.primaryGreen)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }

    private func sendVoiceMessage() {
        let text = speechService.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        speechService.stopRecording()
        onSend(text)
        dismiss()
    }
}

#Preview {
    VoiceChatInputView(
        currentUser: Caregiver(
            name: "Maria",
            phone: "0912345678",
            email: "maria@example.com",
            password: "",
            role: .caregiver,
            preferredLanguage: .id
        ),
        onSend: { _ in }
    )
}
