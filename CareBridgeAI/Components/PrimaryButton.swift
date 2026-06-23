import SwiftUI

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppTheme.primaryGreen)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }
}

#Preview {
    PrimaryButton(title: "Get Started") {
        print("Button tapped")
    }
    .padding()
}
