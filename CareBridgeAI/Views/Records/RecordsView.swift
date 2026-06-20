import SwiftUI

enum RecordInputSheet: Identifiable {
    case text
    case voice
    case quick

    var id: String {
        switch self {
        case .text:
            return "text"
        case .voice:
            return "voice"
        case .quick:
            return "quick"
        }
    }
}

struct RecordsView: View {
    let draft: CareRecipientDraft
    @Binding var records: [CareRecord]

    @State private var selectedCategory: CareRecordCategory? = nil
    @State private var activeSheet: RecordInputSheet?

    private var filteredRecords: [CareRecord] {
        let sorted = records.sorted { $0.createdAt > $1.createdAt }

        guard let selectedCategory else {
            return sorted
        }

        return sorted.filter { $0.category == selectedCategory }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        MainHeaderView(
                            title: "照護紀錄",
                            subtitle: "文字、語音與快速判斷"
                        )

                        dateHeader

                        categoryFilter

                        aiSummaryButton

                        recordsList
                    }
                    .padding(24)
                    .padding(.bottom, 140)
                }
                .safeAreaInset(edge: .bottom) {
                    quickAddPanel
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                        .background(
                            AppTheme.background
                                .opacity(0.96)
                        )
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .text:
                    TextRecordInputView { newRecords in
                        records.insert(contentsOf: newRecords, at: 0)
                    }

                case .voice:
                    VoiceRecordInputView { newRecords in
                        records.insert(contentsOf: newRecords, at: 0)
                    }

                case .quick:
                    QuickConditionInputView { newRecord in
                        records.insert(newRecord, at: 0)
                    }
                }
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            Button {
                print("上一天")
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            Spacer()

            Text(Date().formatted(date: .long, time: .omitted))
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Button {
                print("下一天")
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.primaryGreen)
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryIconButton(title: "全部", icon: "square.grid.2x2.fill", category: nil)

                ForEach(CareRecordCategory.allCases) { category in
                    categoryIconButton(
                        title: categoryShortName(category),
                        icon: category.icon,
                        category: category
                    )
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func categoryIconButton(
        title: String,
        icon: String,
        category: CareRecordCategory?
    ) -> some View {
        let isSelected = selectedCategory == category
        let color = category?.color ?? AppTheme.primaryGreen

        return Button {
            selectedCategory = category
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(isSelected ? .white : color)
                    .frame(width: 46, height: 46)
                    .background(isSelected ? color : color.opacity(0.12))
                    .clipShape(Circle())

                Text(title)
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundStyle(isSelected ? color : .secondary)
            }
            .frame(width: 58)
        }
        .buttonStyle(.plain)
    }

    private func categoryShortName(_ category: CareRecordCategory) -> String {
        switch category {
        case .food:
            return "食"
        case .medicine:
            return "藥"
        case .bowel:
            return "便"
        case .mood:
            return "情緒"
        case .custom:
            return "其他"
        }
    }

    private var aiSummaryButton: some View {
        HStack {
            Text("今日紀錄 \(filteredRecords.count) 筆")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                print("AI 摘要")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text("AI 摘要")
                }
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.primaryGreen)
                .clipShape(Capsule())
            }
        }
    }

    private var recordsList: some View {
        VStack(spacing: 12) {
            if filteredRecords.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundStyle(AppTheme.primaryGreen)

                    Text("尚無照護紀錄")
                        .font(.headline)

                    Text("可以透過文字、語音或快速判斷新增紀錄。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
            } else {
                ForEach(filteredRecords) { record in
                    CareRecordRowView(record: record)
                }
            }
        }
    }

    private var quickAddPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("新增照護紀錄")
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text("選擇輸入方式")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                addButton(
                    title: "文字輸入",
                    icon: "pencil",
                    action: {
                        activeSheet = .text
                    }
                )

                addButton(
                    title: "語音輸入",
                    icon: "mic.fill",
                    action: {
                        activeSheet = .voice
                    }
                )

                addButton(
                    title: "快速判斷",
                    icon: "lightbulb.fill",
                    action: {
                        activeSheet = .quick
                    }
                )
            }
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.10), radius: 14, x: 0, y: 6)
    }

    private func addButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(AppTheme.primaryGreen)
                    .frame(width: 54, height: 54)
                    .background(AppTheme.lightGreen)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RecordsView(
        draft: CareRecipientDraft(),
        records: .constant([
            CareRecord(
                content: "早餐吃了半碗粥，食慾尚可。",
                category: .food,
                condition: .good
            )
        ])
    )
}
