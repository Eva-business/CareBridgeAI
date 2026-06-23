import SwiftUI

struct ContentView: View {
    @State private var onboardingStep = 0
    @State private var selectedLanguage: AppLanguage = .zhTW

    @State private var recipientDraft = CareRecipientDraft()

    @State private var currentDraft: CareRecipientDraft?
    @State private var currentUser: Caregiver?
    @State private var isLoggedIn = false

    var body: some View {
        if isLoggedIn, let currentDraft, let currentUser {
            AppMainView(
                draft: currentDraft,
                currentUser: currentUser,
                onLogout: {
                    isLoggedIn = false
                    self.currentDraft = nil
                    self.currentUser = nil
                    onboardingStep = 0
                }
            )
        } else {
            switch onboardingStep {
            case 0:
                LanguageSelectionView(
                    selectedLanguage: $selectedLanguage,
                    onNext: {
                        onboardingStep = 1
                    }
                )

            case 1:
                WelcomeView(
                    selectedLanguage: selectedLanguage,
                    onCreateNewAccount: {
                        recipientDraft = CareRecipientDraft()
                        onboardingStep = 2
                    },
                    onJoinExistingAccount: {
                        onboardingStep = 10
                    },
                    onLogin: {
                        onboardingStep = 20
                    }
                )

            case 2:
                CreateRecipientView(
                    draft: $recipientDraft,
                    selectedLanguage: selectedLanguage,
                    onNext: {
                        onboardingStep = 3
                    }
                )

            case 3:
                CreateCaregiverGroupView(
                    draft: $recipientDraft,
                    selectedLanguage: selectedLanguage,
                    onBack: {
                        onboardingStep = 2
                    },
                    onFinish: {
                        onboardingStep = 4
                    }
                )

            case 4:
                SetupCompleteView(
                    draft: recipientDraft,
                    selectedLanguage: selectedLanguage,
                    onEnterHome: {
                        CareAccountStore.shared.saveCareAccount(recipientDraft)

                        if let manager = recipientDraft.caregivers.first(where: {
                            $0.role == .mainManager && $0.status == .approved
                        }) {
                            var localizedManager = manager
                            localizedManager.preferredLanguage = selectedLanguage
                            CareAccountStore.shared.registerUser(
                                caregiver: localizedManager,
                                careRecipientID: recipientDraft.careRecipientID
                            )

                            currentDraft = recipientDraft
                            currentUser = localizedManager
                            isLoggedIn = true
                        }
                    }
                )

            case 10:
                JoinExistingAccountView(
                    selectedLanguage: selectedLanguage,
                    presetCareRecipientID: "",
                    onBack: {
                        onboardingStep = 1
                    },
                    onFinish: {
                        onboardingStep = 20
                    }
                )

            case 20:
                LoginView(
                    selectedLanguage: selectedLanguage,
                    onBack: {
                        onboardingStep = 1
                    },
                    onLoginSuccess: { draft, user in
                        var localizedUser = user
                        localizedUser.preferredLanguage = selectedLanguage
                        currentDraft = draft
                        currentUser = localizedUser
                        isLoggedIn = true
                    }
                )

            default:
                LanguageSelectionView(
                    selectedLanguage: $selectedLanguage,
                    onNext: {
                        onboardingStep = 1
                    }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
