//
//  DailySchedule.swift
//  CrewSchduler
//
//  Created by Swark on 2025/3/17.
//

import Foundation

struct DailySchedule: Identifiable, Codable {
    var id: String { dateString } // 使用日期字串當 ID 方便查詢 e.g., "2025-11-17"
    
    // 基礎日期資訊
    let date: Date
    let day: Int            // 日 (1-31)
    let weekday: Int        // 星期幾 (1=Sun, 2=Mon... 7=Sat)
    let dateString: String  // 原始顯示字串 e.g., "17 Fri"
    
    // 勤務狀態
    var type: DutyType = .unknown
    
    // 詳細資料
    var flightNumber: String? // 主要顯示的航班號
    var legs: [FlightLeg] = []
    var metaInfo: String?     // 地點或備註
    
    // 視覺化輔助
    var isTripStart: Bool = false // 是否為長班的第一天
    var isTripEnd: Bool = false   // 是否為長班的最後一天
    var isContinuing: Bool = false // 是否為長班的中間 (畫線用)
}