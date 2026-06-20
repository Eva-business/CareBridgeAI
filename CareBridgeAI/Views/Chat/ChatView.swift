import SwiftUI

struct ChatView: View {
    @Environment(\.dismiss) private var dismiss

    let careRecipientID: String
    let currentUser: Caregiver

    @StateObject private var accountStore = CareAccountStore.shared
    @State private var inputText = ""
    @State private var showingVoiceInput = false

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
                    }

                    inputBar
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingVoiceInput) {
                VoiceChatInputView(
                    currentUser: currentUser,
                    onSend: { transcript in
                        sendVoiceMessage(transcript)
                    }
                )
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
                Text("照護聊天室")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("目前語言：\(currentUser.preferredLanguage.displayName)")
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

            Text("尚無訊息")
                .font(.headline)
                .fontWeight(.bold)

            Text("家屬與照護者可以在這裡用自己的語言溝通，其他成員可依自己的預設語言翻譯。")
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

            TextField("輸入訊息", text: $inputText, axis: .vertical)
                .lineLimit(1...4)
                .padding(12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            Button {
                sendMessage()
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
        Task {
            let translated = await TranslationService.translate(
                text: message.originalText,
                from: message.originalLanguage,
                to: currentUser.preferredLanguage
            )

            var updatedMessage = message
            updatedMessage.translatedText = translated
            updatedMessage.translatedLanguage = currentUser.preferredLanguage

            accountStore.updateChatMessage(
                careRecipientID: careRecipientID,
                message: updatedMessage
            )
        }
    }
}

#Preview {
    ChatView(
        careRecipientID: "CB-DEMO-1234",
        currentUser: Caregiver(
            name: "王小明",
            phone: "0912345678",
            email: "test@example.com",
            password: "",
            role: .mainManager,
            preferredLanguage: .zhTW
        )
    )
}
