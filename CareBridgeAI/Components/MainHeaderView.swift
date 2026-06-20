import SwiftUI

struct MainHeaderView: View {
    let title: String
    let subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            LogoView(size: 42, showText: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.bold)

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Button {
                print("聊天室")
            } label: {
                Image(systemName: "message.fill")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(width: 42, height: 42)
                    .background(AppTheme.lightGreen)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    MainHeaderView(title: "首頁", subtitle: "今日照護狀態")
        .padding()
}
