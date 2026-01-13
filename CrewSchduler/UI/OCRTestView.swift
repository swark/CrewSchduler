import SwiftUI

struct OCRTestView: View {
    @State private var recognizedText: String = "OCR Result will appear here"
    @State private var images: [UIImage] = []
    @State private var showImagePicker = false
    @State private var isProcessing = false
    @State private var progress: Float = 0.0
    
    // [修改] 配合新的 Model，這裡改成 [DailySchedule]
    @State private var parsedDuties: [DailySchedule] = []

    var body: some View {
        VStack {
            // 圖片預覽區 (保持不變)
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
                parsedDuties = [] // 重置舊資料
                
                OCRManager.recognizeText(from: images, progress: { currentProgress in
                    DispatchQueue.main.async {
                        progress = currentProgress
                    }
                }) { results in
                    DispatchQueue.main.async {
                        // 1. 取得完整文字
                        let fullText = results.joined(separator: "\n")
                        self.recognizedText = fullText
                        
                        // 2. 呼叫新的 Parser (會自動補齊整個月的日期)
                        let duties = DataParser.parse(ocrText: fullText)
                        self.parsedDuties = duties
                        
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

            // [修改] 根據是否有資料顯示月曆
            if !parsedDuties.isEmpty {
                ScrollView {
                    // 傳入新的資料結構
                    RosterCalendarView(days: parsedDuties)
                        .padding()
                }
            } else {
                ScrollView {
                    Text(recognizedText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(images: $images)
        }
    }
}
