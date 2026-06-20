import Foundation
import SwiftUI

struct ProfilePhotoStore {
    var imageData: Data?

    var image: Image? {
        guard let imageData,
              let uiImage = UIImage(data: imageData)
        else {
            return nil
        }

        return Image(uiImage: uiImage)
    }
}
