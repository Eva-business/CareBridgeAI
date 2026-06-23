import SwiftUI
import UIKit

struct CareRecordRowView: View {
    @Environment(\.appLanguage) private var appLanguage

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
                    Text(record.category.displayName(appLanguage))
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundStyle(record.category.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(record.category.color.opacity(0.12))
                        .clipShape(Capsule())

                    if let condition = record.condition {
                        Text(condition.displayName(appLanguage))
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

                LocalizedDataText(text: record.content)
                    .font(.subheadline)
                    .lineSpacing(3)

                if !record.attachments.isEmpty {
                    attachmentStrip
                }

                HStack {
                    LocalizedDataText(text: record.createdBy)
                    Text("-")
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

    private var attachmentStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(record.attachments) { attachment in
                    attachmentThumbnail(attachment)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func attachmentThumbnail(_ attachment: CareRecordAttachment) -> some View {
        Group {
            if attachment.kind == .image,
               let uiImage = UIImage(data: attachment.data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                VStack(spacing: 6) {
                    Image(systemName: "video.fill")
                        .font(.title3)
                    Text(appLanguage.text(en: "Video", zhTW: "影片"))
                        .font(.caption2)
                        .fontWeight(.bold)
                }
                .foregroundStyle(AppTheme.primaryGreen)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.lightGreen)
            }
        }
        .frame(width: 72, height: 72)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.black.opacity(0.06), lineWidth: 1)
        )
    }
}

#Preview {
    CareRecordRowView(
        record: CareRecord(
            content: "Ate half a bowl of congee for breakfast. Water intake was normal.",
            category: .food,
            condition: .good
        )
    )
    .padding()
    .background(AppTheme.background)
}
