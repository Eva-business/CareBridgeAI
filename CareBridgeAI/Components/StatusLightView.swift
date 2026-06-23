import SwiftUI

struct StatusLightView: View {
    @Environment(\.appLanguage) private var appLanguage

    let status: CareStatus

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.16))
                    .frame(width: 72, height: 72)

                Image(systemName: status.icon)
                    .font(.system(size: 38))
                    .foregroundStyle(status.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(appLanguage.text(en: "Today's Status", zhTW: "今日狀態"))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(status.displayName(appLanguage))
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(status.color)

                Text(status.description(appLanguage))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    StatusLightView(status: .good)
        .padding()
        .background(AppTheme.background)
}
