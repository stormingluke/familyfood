//
//  ImageService.swift
//  frindr
//
//  R2 image upload service with compression
//

import Foundation
import UIKit

@MainActor
class ImageService {
    static let shared = ImageService()

    private let apiClient = APIClient.shared
    private let maxSizeKB = 500

    private init() {}

    struct UploadResult {
        let url: String
        let key: String
    }

    func uploadImage(_ data: Data, for mealId: UUID) async throws -> UploadResult {
        // Compress if needed
        let compressedData = compress(data, maxSizeKB: maxSizeKB)

        // Upload to server
        let response = try await apiClient.uploadImage(
            data: compressedData,
            filename: "\(mealId.uuidString).jpg"
        )

        return UploadResult(url: response.url, key: response.key)
    }

    func deleteImage(key: String) async throws {
        try await apiClient.requestNoContent(
            endpoint: .imageDelete(key),
            method: .DELETE
        )
    }

    private func compress(_ data: Data, maxSizeKB: Int) -> Data {
        guard let image = UIImage(data: data) else { return data }

        var quality: CGFloat = 0.8
        var compressedData = image.jpegData(compressionQuality: quality) ?? data

        // Iteratively reduce quality until under size limit
        while compressedData.count > maxSizeKB * 1024 && quality > 0.1 {
            quality -= 0.1
            compressedData = image.jpegData(compressionQuality: quality) ?? compressedData
        }

        // If still too large, resize the image
        if compressedData.count > maxSizeKB * 1024 {
            let scale = sqrt(Double(maxSizeKB * 1024) / Double(compressedData.count))
            if let resizedImage = resizeImage(image, scale: scale) {
                compressedData = resizedImage.jpegData(compressionQuality: 0.7) ?? compressedData
            }
        }

        return compressedData
    }

    private func resizeImage(_ image: UIImage, scale: Double) -> UIImage? {
        let newSize = CGSize(
            width: image.size.width * scale,
            height: image.size.height * scale
        )

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
