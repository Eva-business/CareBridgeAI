import SwiftUI
import Translation
import UIKit

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appLanguage) private var appLanguage

    let careRecipientID: String
    let currentUser: Caregiver

    @StateObject private var accountStore = CareAccountStore.shared
    @State private var inputText = ""
    @State private var showingVoiceInput = false
    @State private var translationConfiguration: TranslationSession.Configuration?
    @State private var messagePendingTranslation: ChatMessage?
    @State private var translationError: String?

    private var messages: [ChatMessage] {
        accountStore.chatMessages(for: careRecipientID)
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func revealTranscript(_ message: ChatMessage) {
        var updatedMessage = message
        updatedMessage.isTranscriptVisible = true

        accountStore.updateChatMessage(
            careRecipientID: careRecipientID,
            message: updatedMessage
        )
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    header

                    ScrollViewReader { proxy in
                        ScrollView {
                            VStack(spacing: 14) {
                                if messages.isEmpty {
                                    emptyState
                                } else {
                                    ForEach(messages) { message in
                                        ChatMessageRowView(
                                            message: message,
                                            currentUser: currentUser,
                                            onTranslate: {
                                                translateMessage(message)
                                            },
                                            onRevealTranscript: {
                                                revealTranscript(message)
                                            }
                                        )
                                        .id(message.id)
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .onChange(of: messages.count) {
                            if let last = messages.last {
                                withAnimation {
                                    proxy.scrollTo(last.id, anchor: .bottom)
                                }
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                    }

                    inputBar
                }
            }
            .dismissKeyboardOnTap()
            .navigationBarHidden(true)
            .sheet(isPresented: $showingVoiceInput) {
                VoiceChatInputView(
                    currentUser: currentUser,
                    onSend: { transcript in
                        sendVoiceMessage(transcript)
                    }
                )
            }
            .translationTask(translationConfiguration) { session in
                await performTranslation(using: session)
            }
            .alert(appLanguage.text(en: "Unable to Translate", zhTW: "無法翻譯"), isPresented: Binding(
                get: { translationError != nil },
                set: { if !$0 { translationError = nil } }
            )) {
                Button(appLanguage.text(en: "OK", zhTW: "確定"), role: .cancel) { }
            } message: {
                Text(translationError ?? appLanguage.text(en: "Please try again later.", zhTW: "請稍後再試。"))
            }
            .onAppear {
                markMessagesAsRead()
            }
            .onChange(of: messages.count) {
                markMessagesAsRead()
            }
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(width: 42, height: 42)
                .background(AppTheme.lightGreen)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(appLanguage.text(en: "Care Chat", zhTW: "照護聊天室"))
                    .font(.headline)
                    .fontWeight(.bold)

                Text(appLanguage.text(en: "Current language: \(currentUser.preferredLanguage.englishName)", zhTW: "目前語言：\(currentUser.preferredLanguage.displayName)"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(AppTheme.background)
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color.white.opacity(0.85))
        .shadow(color: .black.opacity(0.04), radius: 5, x: 0, y: 3)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(AppTheme.primaryGreen)

            Text(appLanguage.text(en: "No messages yet", zhTW: "目前沒有訊息"))
                .font(.headline)
                .fontWeight(.bold)

            Text(appLanguage.text(en: "Family members and caregivers can communicate here and translate messages when needed.", zhTW: "家人與照護者可以在這裡溝通，必要時可翻譯訊息。"))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.75))
        .clipShape(RoundedRectangle(cornerRadius: 24))
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            Button {
                showingVoiceInput = true
            } label: {
                Image(systemName: "mic.fill")
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.lightGreen)
                    .clipShape(Circle())
            }

            TextField(appLanguage.text(en: "Enter a message", zhTW: "輸入訊息"), text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .submitLabel(.send)
                .onSubmit {
                    sendMessage()
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

            Button {
                sendMessage()
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            } label: {
                Image(systemName: "paperplane.fill")
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(canSend ? AppTheme.primaryGreen : Color.gray.opacity(0.45))
                    .clipShape(Circle())
            }
            .disabled(!canSend)
        }
        .padding()
        .background(Color.white.opacity(0.9))
    }

    private func sendMessage() {
        let trimmedText = inputText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        let message = ChatMessage(
            senderID: currentUser.id,
            senderName: currentUser.name,
            senderRole: currentUser.role,
            originalLanguage: currentUser.preferredLanguage,
            originalText: trimmedText
        )

        accountStore.sendChatMessage(
            careRecipientID: careRecipientID,
            message: message
        )

        inputText = ""
    }
    
    private func sendVoiceMessage(_ transcript: String) {
        let trimmedText = transcript.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedText.isEmpty else { return }

        let message = ChatMessage(
            senderID: currentUser.id,
            senderName: currentUser.name,
            senderRole: currentUser.role,
            originalLanguage: currentUser.preferredLanguage,
            originalText: trimmedText,
            isVoiceMessage: true,
            isTranscriptVisible: false
        )

        accountStore.sendChatMessage(
            careRecipientID: careRecipientID,
            message: message
        )
    }

    private func translateMessage(_ message: ChatMessage) {
        guard message.originalLanguage != currentUser.preferredLanguage else { return }

        messagePendingTranslation = message
        let nextConfiguration = TranslationService.configuration(
            from: message.originalLanguage,
            to: currentUser.preferredLanguage
        )

        if translationConfiguration == nextConfiguration {
            translationConfiguration?.invalidate()
        } else {
            translationConfiguration = nextConfiguration
        }
    }

    private func performTranslation(using session: TranslationSession) async {
        guard let message = messagePendingTranslation else { return }

        do {
            let translated = try await TranslationService.translate(
                text: message.originalText,
                using: session
            )
            var updatedMessage = message
            updatedMessage.translatedText = translated
            updatedMessage.translatedLanguage = currentUser.preferredLanguage
            accountStore.updateChatMessage(
                careRecipientID: careRecipientID,
                message: updatedMessage
            )
            messagePendingTranslation = nil
        } catch {
            translationError = appLanguage.text(
                en: "The translation language pack may not be downloaded, or translation is currently unavailable.\n\(error.localizedDescription)",
                zhTW: "翻譯語言包可能尚未下載，或目前無法使用翻譯。\n\(error.localizedDescription)"
            )
        }
    }

    private func markMessagesAsRead() {
        accountStore.markChatAsRead(
            careRecipientID: careRecipientID,
            userID: currentUser.id
        )
    }
}

#Preview {
    ChatView(
        careRecipientID: "CB-DEMO-1234",
        currentUser: Caregiver(
            name: "Main Manager",
            phone: "0912345678",
            email: "test@example.com",
            password: "",
            role: .mainManager,
            preferredLanguage: .zhTW
        )
    )
}
