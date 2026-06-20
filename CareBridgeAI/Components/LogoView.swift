import SwiftUI

struct LogoView: View {
    var size: CGFloat = 72
    var showText: Bool = true

    var body: some View {
        VStack(spacing: 10) {
            Image("CareBridgeLogo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)

            if showText {
                Text("CareBridge AI")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryGreen)
            }
        }
    }
}

#Preview {
    LogoView(size: 100, showText: true)
}
