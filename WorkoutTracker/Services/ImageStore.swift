import Foundation
import UIKit

enum ImageStore {
    static func save(data: Data) throws -> String {
        let name = UUID().uuidString + ".jpg"
        let url = documentsDirectory().appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return name
    }

    static func saveVideo(from sourceURL: URL) throws -> String {
        let ext = sourceURL.pathExtension.isEmpty ? "mov" : sourceURL.pathExtension
        let name = UUID().uuidString + ".\(ext)"
        let destination = documentsDirectory().appendingPathComponent(name)
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.copyItem(at: sourceURL, to: destination)
        return name
    }

    static func load(_ filename: String) -> UIImage? {
        let url = documentsDirectory().appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }

    static func fileURL(for filename: String) -> URL {
        documentsDirectory().appendingPathComponent(filename)
    }

    static func delete(_ filename: String) {
        let url = documentsDirectory().appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: url)
    }

    static func documentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
