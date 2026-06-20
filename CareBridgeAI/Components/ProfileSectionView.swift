import SwiftUI

struct ProfileSectionView<Content: View>: View {
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
                    .frame(width: 34, height: 34)
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()
            }

            content
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ProfileSectionView(title: "基本資料", icon: "person.text.rectangle") {
        ProfileInfoRow(icon: "person.fill", title: "姓名", value: "王奶奶")
    }
    .padding()
    .background(AppTheme.background)
}
