import SwiftUI

extension Notification.Name {
    static let openCareBridgeChat = Notification.Name("openCareBridgeChat")
}

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
                NotificationCenter.default.post(name: .openCareBridgeChat, object: nil)
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
    MainHeaderView(title: "Home", subtitle: "Today's care status")
        .padding()
}
