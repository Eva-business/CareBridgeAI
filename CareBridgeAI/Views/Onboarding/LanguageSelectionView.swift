import SwiftUI

struct LanguageSelectionView: View {
    @Binding var selectedLanguage: AppLanguage

    let onNext: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                LogoView(size: 96)

                VStack(spacing: 10) {
                    Text("選擇使用語言")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Please select your language")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Pilih bahasa yang ingin digunakan")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(AppLanguage.allCases) { language in
                        Button {
                            selectedLanguage = language
                        } label: {
                            HStack {
                                Text(language.displayName)
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.primary)

                                Spacer()

                                if selectedLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(AppTheme.primaryGreen)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(
                                        selectedLanguage == language
                                        ? AppTheme.primaryGreen
                                        : Color.gray.opacity(0.18),
                                        lineWidth: selectedLanguage == language ? 2 : 1
                                    )
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }

                PrimaryButton(title: nextButtonTitle) {
                    onNext()
                }

                Spacer()
            }
            .padding(24)
        }
    }

    private var nextButtonTitle: String {
        switch selectedLanguage {
        case .zhTW:
            return "下一步"
        case .en:
            return "Next"
        case .id:
            return "Lanjut"
        case .vi:
            return "Tiếp tục"
        case .th:
            return "ถัดไป"
        case .ja:
            return "次へ"
        }
    }
}

#Preview {
    LanguageSelectionView(
        selectedLanguage: .constant(.zhTW),
        onNext: {}
    )
}
