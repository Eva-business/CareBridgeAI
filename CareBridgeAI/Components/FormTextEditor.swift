import SwiftUI

struct FormTextEditor: View {
    let title: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $text)
                    .frame(minHeight: 90)
                    .padding(8)
                    .background(Color.white)

                if text.isEmpty {
                    Text(placeholder)
                        .font(.body)
                        .foregroundStyle(.gray.opacity(0.65))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
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
    FormTextEditor(
        title: "Medical History",
        placeholder: "Example: hypertension, diabetes, heart disease",
        text: .constant("")
    )
    .padding()
    .background(AppTheme.background)
}
