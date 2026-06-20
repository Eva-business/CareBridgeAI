import SwiftUI

struct HomeCardView<Content: View>: View {
    let title: String
    let icon: String
    let content: Content

    init(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(width: 32, height: 32)
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 9))

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            content
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    HomeCardView(title: "AI 交接摘要", icon: "sparkles") {
        Text("今天狀態穩定，食慾正常，晚間需提醒服藥。")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
    .padding()
    .background(AppTheme.background)
}
