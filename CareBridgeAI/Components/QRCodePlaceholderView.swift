import SwiftUI

struct QRCodePlaceholderView: View {
    let groupCode: String

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.white)
                    .frame(width: 170, height: 170)
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)

                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(.black)

                LogoView(size: 34, showText: false)
                    .background(Color.white)
                    .clipShape(Circle())
            }

            Text("群組邀請碼")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(groupCode)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryGreen)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppTheme.lightGreen)
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

#Preview {
    QRCodePlaceholderView(groupCode: "CB-2026-8888")
        .padding()
}
