import Foundation
import UIKit

enum ImageStorage {
    private static var materialsDirectory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("Materials", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func saveJPEG(_ data: Data, suggestedName: String? = nil) throws -> String {
        let name = suggestedName ?? UUID().uuidString + ".jpg"
        let url = materialsDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return name
    }

    static func saveResizedImage(_ image: UIImage, maxLongEdge: CGFloat = 1200, quality: CGFloat = 0.82) throws -> String {
        let scaled = image.resized(maxLongEdge: maxLongEdge)
        guard let data = scaled.jpegData(compressionQuality: quality) else {
            throw NSError(domain: "ImageStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "JPEG変換に失敗しました"])
        }
        return try saveJPEG(data)
    }

    static func fileURL(forStoredFileName name: String) -> URL {
        materialsDirectory.appendingPathComponent(name)
    }

    static func deleteIfExists(fileName: String) {
        let url = fileURL(forStoredFileName: fileName)
        try? FileManager.default.removeItem(at: url)
    }
}

private extension UIImage {
    func resized(maxLongEdge: CGFloat) -> UIImage {
        let w = size.width
        let h = size.height
        let long = max(w, h)
        guard long > maxLongEdge, long > 0 else { return self }
        let scale = maxLongEdge / long
        let newSize = CGSize(width: w * scale, height: h * scale)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
