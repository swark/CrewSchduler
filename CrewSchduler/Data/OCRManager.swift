//
//  OCRManager.swift
//  CrewSchduler
//
//  Created by Swark on 2025/3/17.
//

import Vision
import UIKit

class OCRManager {
    static func recognizeText(from image: UIImage, completion: @escaping (String) -> Void) {
        guard let cgImage = image.cgImage else {
            completion("Error: Unable to process image")
            return
        }

        let request = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation], error == nil else {
                completion("Error: OCR failed")
                return
            }

            // Get OCR result
            let recognizedText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            completion(recognizedText)
        }

        request.recognitionLevel = .accurate
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try requestHandler.perform([request])
            } catch {
                completion("Error: \(error.localizedDescription)")
            }
        }
    }

    static func recognizeText(from images: [UIImage], progress: @escaping (Float) -> Void, completion: @escaping ([String]) -> Void) {
        var results: [String] = []
        let group = DispatchGroup()
        let totalImages = Float(images.count)
        var processedImages: Float = 0
        
        for image in images {
            group.enter()
            recognizeText(from: image) { text in
                results.append(text)
                processedImages += 1
                progress(processedImages / totalImages)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            completion(results)
        }
    }
}
