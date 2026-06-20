import SwiftUI

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                }
        }
    }
}

#Preview {
    FormTextField(
        title: "姓名",
        placeholder: "請輸入姓名",
        text: .constant("")
    )
    .padding()
    .background(AppTheme.background)
}
