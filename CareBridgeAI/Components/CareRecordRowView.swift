import SwiftUI

struct CareRecordRowView: View {
    let record: CareRecord

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(record.category.color.opacity(0.14))
                    .frame(width: 44, height: 44)

                Image(systemName: record.category.icon)
                    .foregroundStyle(record.category.color)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(record.category.rawValue)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(record.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(record.category.color.opacity(0.12))
                        .clipShape(Capsule())

                    if let condition = record.condition {
                        Text(condition.rawValue)
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundStyle(condition.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(condition.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Spacer()
                }

                Text(record.content)
                    .font(.subheadline)
                    .lineSpacing(3)

                HStack {
                    Text(record.createdBy)
                    Text("・")
                    Text(record.createdAt.formatted(date: .numeric, time: .shortened))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    CareRecordRowView(
        record: CareRecord(
            content: "早餐吃了半碗粥，喝水正常。",
            category: .food,
            condition: .good
        )
    )
    .padding()
    .background(AppTheme.background)
}
