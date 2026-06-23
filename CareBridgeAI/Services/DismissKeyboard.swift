import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

#if canImport(UIKit)
public func hideKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
}
#endif

#if canImport(UIKit)
private struct KeyboardDismissTapInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> KeyboardDismissHostingView {
        KeyboardDismissHostingView()
    }

    func updateUIView(_ uiView: KeyboardDismissHostingView, context: Context) {}
}

private final class KeyboardDismissHostingView: UIView, UIGestureRecognizerDelegate {
    private weak var installedWindow: UIWindow?

    private lazy var tapRecognizer: UITapGestureRecognizer = {
        let recognizer = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        recognizer.cancelsTouchesInView = false
        recognizer.delegate = self
        return recognizer
    }()

    override func didMoveToWindow() {
        super.didMoveToWindow()

        guard window !== installedWindow else { return }
        installedWindow?.removeGestureRecognizer(tapRecognizer)
        installedWindow = window
        window?.addGestureRecognizer(tapRecognizer)
    }

    deinit {
        installedWindow?.removeGestureRecognizer(tapRecognizer)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        var touchedView: UIView? = touch.view

        while let view = touchedView {
            if view is UITextField || view is UITextView {
                return false
            }
            touchedView = view.superview
        }

        return true
    }

    @objc private func backgroundTapped() {
        hideKeyboard()
    }
}
#endif

public extension View {
    /// Dismisses the keyboard without competing with text-input gestures.
    func dismissKeyboardOnTap() -> some View {
        #if canImport(UIKit)
        background {
            KeyboardDismissTapInstaller()
                .frame(width: 0, height: 0)
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    hideKeyboard()
                }
            }
        }
        #else
        self
        #endif
    }
}
