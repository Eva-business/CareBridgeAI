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
    @Environment(\.appLanguage) private var appLanguage

    let draft: CareRecipientDraft
    @Binding var records: [CareRecord]
    let recordingLanguage: AppLanguage
    let onSummaryGenerated: (CareAISummary) -> Void

    @State private var selectedCategory: CareRecordCategory? = nil
    @State private var selectedDate = Date()
    @State private var activeSheet: RecordInputSheet?
    @State private var showingAISummary = false
    @State private var isGeneratingSummary = false
    @State private var generatedSummary: CareAISummary?

    init(
        draft: CareRecipientDraft,
        records: Binding<[CareRecord]>,
        recordingLanguage: AppLanguage = .zhTW,
        onSummaryGenerated: @escaping (CareAISummary) -> Void = { _ in }
    ) {
        self.draft = draft
        _records = records
        self.recordingLanguage = recordingLanguage
        self.onSummaryGenerated = onSummaryGenerated
    }

    private var selectedDateRecords: [CareRecord] {
        records
            .filter { Calendar.current.isDate($0.createdAt, inSameDayAs: selectedDate) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var filteredRecords: [CareRecord] {
        let sorted = selectedDateRecords

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
                            title: appLanguage.text(en: "Care Records", zhTW: "照護紀錄"),
                            subtitle: appLanguage.text(en: "Text, voice, and quick status checks", zhTW: "文字、語音與快速判斷")
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
                        insertRecords(onSelectedDate: newRecords)
                    }

                case .voice:
                    VoiceRecordInputView(recordingLanguage: recordingLanguage) { newRecords in
                        insertRecords(onSelectedDate: newRecords)
                    }

                case .quick:
                    QuickConditionInputView { newRecord in
                        insertRecords(onSelectedDate: [newRecord])
                    }
                }
            }
            .sheet(isPresented: $showingAISummary) {
                NavigationStack {
                    VStack(alignment: .leading, spacing: 20) {
                        Label(appLanguage.text(en: "AI Handoff Summary", zhTW: "AI 交接摘要"), systemImage: "sparkles")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primaryGreen)

                        if isGeneratingSummary {
                            ProgressView(appLanguage.text(en: "Preparing today's care records...", zhTW: "正在整理今日照護紀錄..."))
                        } else if let generatedSummary {
                            LocalizedDataText(text: generatedSummary.text)
                                .font(.body)
                                .lineSpacing(6)

                            Label(
                                generatedSummary.usedOnDeviceModel ? appLanguage.text(en: "Apple Foundation Models - On-device", zhTW: "Apple Foundation Models - 裝置端生成") : appLanguage.text(en: "Smart fallback summary", zhTW: "智慧備援摘要"),
                                systemImage: generatedSummary.usedOnDeviceModel ? "iphone.gen3" : "checkmark.shield"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(24)
                    .background(AppTheme.background.ignoresSafeArea())
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(appLanguage.text(en: "Done", zhTW: "完成")) { showingAISummary = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            .onChange(of: selectedDate) {
                generatedSummary = nil
            }
        }
    }

    private var dateHeader: some View {
        HStack {
            Button {
                changeSelectedDate(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundStyle(AppTheme.primaryGreen)
            }

            Spacer()

            Text(selectedDate.formatted(date: .long, time: .omitted))
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Button {
                changeSelectedDate(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppTheme.primaryGreen)
            }
            .disabled(Calendar.current.isDateInToday(selectedDate))
            .opacity(Calendar.current.isDateInToday(selectedDate) ? 0.35 : 1)
        }
        .padding()
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 6, x: 0, y: 3)
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                categoryIconButton(title: appLanguage.text(en: "All", zhTW: "全部"), icon: "square.grid.2x2.fill", category: nil)

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
            return CareRecordCategory.food.shortDisplayName(appLanguage)
        case .medicine:
            return CareRecordCategory.medicine.shortDisplayName(appLanguage)
        case .bowel:
            return CareRecordCategory.bowel.shortDisplayName(appLanguage)
        case .mood:
            return CareRecordCategory.mood.shortDisplayName(appLanguage)
        case .custom:
            return CareRecordCategory.custom.shortDisplayName(appLanguage)
        }
    }

    private var aiSummaryButton: some View {
        HStack {
            Text(appLanguage.text(en: "\(filteredRecords.count) record(s) today", zhTW: "當日紀錄 \(filteredRecords.count) 筆"))
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            Button {
                showingAISummary = true
                isGeneratingSummary = true
                Task {
                    let result = await CareAIService.summarize(
                        selectedDateRecords,
                        applying24HourWindow: false,
                        language: recordingLanguage
                    )
                    generatedSummary = result
                    if Calendar.current.isDateInToday(selectedDate) {
                        onSummaryGenerated(result)
                    }
                    isGeneratingSummary = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                    Text(appLanguage.text(en: "AI Summary", zhTW: "AI 摘要"))
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

                    Text(appLanguage.text(en: "No care records yet", zhTW: "尚無照護紀錄"))
                        .font(.headline)

                    Text(appLanguage.text(en: "Add records with text, voice, or quick status checks.", zhTW: "可以透過文字、語音或快速判斷新增紀錄。"))
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
                Text(appLanguage.text(en: "Add Care Record", zhTW: "新增照護紀錄"))
                    .font(.headline)
                    .fontWeight(.bold)

                Spacer()

                Text(appLanguage.text(en: "Choose input method", zhTW: "選擇輸入方式"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                addButton(
                    title: appLanguage.text(en: "Text", zhTW: "文字"),
                    icon: "pencil",
                    action: {
                        activeSheet = .text
                    }
                )

                addButton(
                    title: appLanguage.text(en: "Voice", zhTW: "語音"),
                    icon: "mic.fill",
                    action: {
                        activeSheet = .voice
                    }
                )

                addButton(
                    title: appLanguage.text(en: "Quick Check", zhTW: "快速判斷"),
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

    private func changeSelectedDate(by dayOffset: Int) {
        guard let date = Calendar.current.date(byAdding: .day, value: dayOffset, to: selectedDate) else { return }
        selectedDate = min(date, Date())
    }

    private func insertRecords(onSelectedDate newRecords: [CareRecord]) {
        let calendar = Calendar.current
        let selectedComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)

        let datedRecords = newRecords.map { record -> CareRecord in
            var datedRecord = record
            let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: record.createdAt)
            var components = selectedComponents
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            components.second = timeComponents.second
            datedRecord.createdAt = calendar.date(from: components) ?? selectedDate
            return datedRecord
        }
        records.insert(contentsOf: datedRecords, at: 0)
    }
}

#Preview {
    RecordsView(
        draft: CareRecipientDraft(),
        records: .constant([
            CareRecord(
                content: "Ate half a bowl of congee for breakfast. Appetite was fair.",
                category: .food,
                condition: .good
            )
        ])
    )
}
