import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    @Environment(\.appLanguage) private var appLanguage

    let text: String
    var size: CGFloat = 180

    private let context = CIContext()
    private let filter = CIFilter.qrCodeGenerator()

    var body: some View {
        if let image = generateQRCode(from: text) {
            Image(uiImage: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .padding()
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        } else {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.gray.opacity(0.15))
                .frame(width: size, height: size)
                .overlay {
                    Text(appLanguage.text(en: "QR Code", zhTW: "邀請 QR Code"))
                        .foregroundStyle(.secondary)
                }
        }
    }

    private func generateQRCode(from string: String) -> UIImage? {
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let transform = CGAffineTransform(scaleX: 12, y: 12)
        let scaledImage = outputImage.transformed(by: transform)

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCodeView(text: "carebridge://join/CB-ABCD-1234")
}
