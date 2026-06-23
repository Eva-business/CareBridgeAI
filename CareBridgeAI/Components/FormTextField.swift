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
                .submitLabel(.done)
                .onSubmit {
                    hideKeyboard()
                }
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
        title: "Name",
        placeholder: "Enter name",
        text: .constant("")
    )
    .padding()
    .background(AppTheme.background)
}
