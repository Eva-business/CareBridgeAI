import SwiftUI

struct ChatMessageRowView: View {
    @Environment(\.appLanguage) private var appLanguage

    let message: ChatMessage
    let currentUser: Caregiver
    let onTranslate: () -> Void
    let onRevealTranscript: () -> Void

    private var isMine: Bool {
        message.senderID == currentUser.id
    }

    private var shouldShowTranslateButton: Bool {
        !isMine && message.originalLanguage != currentUser.preferredLanguage
    }
    
    private var voiceMessageContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "waveform")
                    .foregroundStyle(AppTheme.primaryGreen)

                Text(appLanguage.text(en: "Voice Message", zhTW: "語音訊息"))
                    .font(.subheadline)
                    .fontWeight(.bold)

                Spacer()
            }

            if message.isTranscriptVisible {
                Text(message.originalText)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineSpacing(3)
            } else {
                Text(appLanguage.text(en: "Transcript is hidden", zhTW: "逐字稿已隱藏"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        HStack {
            if isMine {
                Spacer(minLength: 48)
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 8) {
                if !isMine {
                    HStack(spacing: 6) {
                        Text(message.senderName.containsCareBridgeCJKText && !appLanguage.isChinese ? message.senderRole.displayName(appLanguage) : message.senderName.localizedCareText(appLanguage))
                            .font(.caption)
                            .fontWeight(.bold)

                        Text(message.senderRole.displayName(appLanguage))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    if message.isVoiceMessage {
                        voiceMessageContent
                    } else {
                        Text(message.originalText)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineSpacing(3)
                    }

                    HStack(spacing: 6) {
                        Image(systemName: "globe.asia.australia.fill")
                        Text(appLanguage.isChinese ? message.originalLanguage.displayName : message.originalLanguage.englishName)
                    }
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                    if let translatedText = message.translatedText,
                       let translatedLanguage = message.translatedLanguage {
                        Divider()

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Image(systemName: "translate")
                                Text(appLanguage.isChinese ? translatedLanguage.displayName : translatedLanguage.englishName)
                            }
                            .font(.caption2)
                            .foregroundStyle(AppTheme.primaryGreen)

                            Text(translatedText)
                                .font(.subheadline)
                                .foregroundStyle(AppTheme.primaryGreen)
                                .lineSpacing(3)
                        }
                    }
                }
                .padding()
                .background(isMine ? AppTheme.lightGreen : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .shadow(color: .black.opacity(0.035), radius: 5, x: 0, y: 3)

                HStack(spacing: 10) {
                    Text(message.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    if message.isVoiceMessage && !message.isTranscriptVisible {
                        Button {
                            onRevealTranscript()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "text.bubble")
                                Text(appLanguage.text(en: "Show Text", zhTW: "顯示文字"))
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primaryGreen)
                        }
                    }
                    
                    if shouldShowTranslateButton {
                        Button {
                            onTranslate()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "translate")
                                Text(appLanguage.text(en: "Translate", zhTW: "翻譯"))
                            }
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.primaryGreen)
                        }
                    }
                }
            }

            if !isMine {
                Spacer(minLength: 48)
            }
        }
    }
}

#Preview {
    ChatMessageRowView(
        message: ChatMessage(
            senderID: UUID(),
            senderName: "Maria",
            senderRole: .caregiver,
            originalLanguage: .id,
            originalText: "Nenek hari ini sudah makan sedikit.",
            isVoiceMessage: true,
            isTranscriptVisible: false
        ),
        currentUser: Caregiver(
            name: "Main Manager",
            phone: "0912345678",
            email: "test@example.com",
            password: "",
            role: .mainManager,
            preferredLanguage: .zhTW
        ),
        onTranslate: {},
        onRevealTranscript: {}
    )
    .padding()
    .background(AppTheme.background)
}
