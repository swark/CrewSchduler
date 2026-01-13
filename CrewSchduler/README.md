CrewScheduler/
│── Assets/                  // 靜態資源（如測試圖片）
│── CppCore/                 // C++ 核心邏輯
│   │── FlightLeg.hpp
│   │── Trip.hpp
│   │── MonthlyRoster.hpp
│   │── DataProcessor.cpp
│── CrewSchedulerApp.swift    // App 入口
│── ContentView.swift         // 主要畫面
│── Data/                    // OCR 解析與數據處理
│   │── OCRManager.swift      // 圖片 OCR 解析
│   │── DataParser.swift      // OCR 文字解析成 FlightLeg
│── Model/                   // SwiftData 或 CoreData 模型
│   │── FlightLeg.swift       // 航班結構
│   │── Trip.swift            // 航程結構
│   │── MonthlyRoster.swift   // 整個月的班表
│── Tests/                   // 測試
│── UI/                      // UI 相關檔案
│   │── OCRTestView.swift     // 測試 OCR 的畫面
│── CrewScheduler.xcodeproj   // Xcode 專案檔
