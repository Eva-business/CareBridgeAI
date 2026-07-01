import Foundation
import Speech
import AVFoundation
import Combine

final class SpeechService: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined
    @Published var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var speechRecognizer: SFSpeechRecognizer?
    private var accumulatedTranscript: String = ""
    private var currentRecordingTranscript: String = ""

    func requestPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            Task { @MainActor in
                self.authorizationStatus = status
            }
        }

        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            Task { @MainActor in
                if !granted {
                    self.errorMessage = "Microphone permission has not been granted."
                }
            }
        }
    }

    func startRecording(language: AppLanguage) {
        stopRecording()

        accumulatedTranscript = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        currentRecordingTranscript = ""
        transcript = accumulatedTranscript
        errorMessage = nil

        speechRecognizer = SFSpeechRecognizer(
            locale: Locale(identifier: language.speechLocaleIdentifier)
        )

        guard let speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition is not available for this language right now."
            return
        }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()

            guard let recognitionRequest else {
                errorMessage = "Unable to create a speech recognition request."
                return
            }

            recognitionRequest.shouldReportPartialResults = true

            let inputNode = audioEngine.inputNode

            recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
                Task { @MainActor in
                    if let result {
                        self.currentRecordingTranscript = result.bestTranscription.formattedString
                        self.transcript = self.joinedTranscript(
                            self.accumulatedTranscript,
                            self.currentRecordingTranscript
                        )
                    }

                    if let error {
                        self.errorMessage = error.localizedDescription
                        self.stopRecording()
                    }

                    if result?.isFinal == true {
                        self.stopRecording()
                    }
                }
            }

            let recordingFormat = inputNode.outputFormat(forBus: 0)

            inputNode.removeTap(onBus: 0)
            inputNode.installTap(
                onBus: 0,
                bufferSize: 1024,
                format: recordingFormat
            ) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
            stopRecording()
        }
    }

    func stopRecording() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        recognitionRequest?.endAudio()
        recognitionRequest = nil
        recognitionTask?.cancel()
        recognitionTask = nil

        accumulatedTranscript = joinedTranscript(accumulatedTranscript, currentRecordingTranscript)
        currentRecordingTranscript = ""
        transcript = accumulatedTranscript
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false)
    }

    private func joinedTranscript(_ previous: String, _ current: String) -> String {
        let previous = previous.trimmingCharacters(in: .whitespacesAndNewlines)
        let current = current.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !previous.isEmpty else { return current }
        guard !current.isEmpty else { return previous }

        return "\(previous) \(current)"
    }
}
