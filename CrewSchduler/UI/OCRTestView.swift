//
//  OCRTestView.swift
//  CrewSchduler
//
//  Created by Swark on 2025/3/17.
//

import SwiftUI

struct OCRTestView: View {
    @State private var recognizedText: String = "OCR Result will appear here"
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var progress: Float = 0.0

    var body: some View {
        VStack {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(images, id: \.self) { image in
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                    }
                }
            }

            Button("Select Images") {
                showImagePicker = true
            }
            .padding()
            .disabled(isProcessing)

            Button("Run OCR") {
                isProcessing = true
                progress = 0.0
                recognizedText = "Processing..."
                OCRManager.recognizeText(from: images, progress: { currentProgress in
                    DispatchQueue.main.async {
                        progress = currentProgress
                    }
                }) { results in
                    DispatchQueue.main.async {
                        recognizedText = results.joined(separator: "\n\n---\n\n")
                        isProcessing = false
                    }
                }
            }
            .padding()
            .disabled(images.isEmpty || isProcessing)

            if isProcessing {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    ProgressView(value: progress) {
                        Text("Processing \(Int(progress * 100))%")
                            .font(.caption)
                    }
                    .padding(.horizontal)
                }
            }

            ScrollView {
                Text(recognizedText)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $images)
        }
    }
}
