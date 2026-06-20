import SwiftUI

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String
    var tint: Color = AppTheme.primaryGreen

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(value.isEmpty ? "未填寫" : value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(value.isEmpty ? .secondary : .primary)
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding()
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ProfileInfoRow(
        icon: "person.fill",
        title: "姓名",
        value: "王奶奶"
    )
    .padding()
    .background(Color.white)
}
