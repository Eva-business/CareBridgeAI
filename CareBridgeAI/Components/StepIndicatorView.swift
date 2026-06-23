import SwiftUI

struct StepIndicatorView: View {
    let currentStep: Int
    let totalSteps: Int
    let titles: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...totalSteps, id: \.self) { step in
                VStack(spacing: 6) {
                    Circle()
                        .fill(step <= currentStep ? AppTheme.primaryGreen : Color.gray.opacity(0.25))
                        .frame(width: 26, height: 26)
                        .overlay {
                            Text("\(step)")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundStyle(step <= currentStep ? .white : .gray)
                        }

                    if step - 1 < titles.count {
                        Text(titles[step - 1])
                            .font(.caption2)
                            .foregroundStyle(step == currentStep ? AppTheme.primaryGreen : .secondary)
                    }
                }

                if step < totalSteps {
                    Rectangle()
                        .fill(step < currentStep ? AppTheme.primaryGreen : Color.gray.opacity(0.25))
                        .frame(height: 2)
                        .padding(.horizontal, 4)
                        .offset(y: -10)
                }
            }
        }
    }
}

#Preview {
    StepIndicatorView(
        currentStep: 1,
        totalSteps: 3,
        titles: ["Basic Info", "Manager", "Complete"]
    )
    .padding()
}
