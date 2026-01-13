import Foundation

enum DutyType: String, Codable {
    case dayOff        // 1. 休假 (OFF, ADO)
    case turnaround    // 2. 單日來回 (只有一腿或兩腿，且當天結束)
    case multiDayTrip  // 3 & 4. 過夜班/長班 (包含飛行日與中間的 Layover)
    case training      // 5. 受訓上課 (SIM, COURSE 等關鍵字)
    case layover       // 純過夜 (通常是長班的中間日期)
    case unknown       // 未知/無排班
}

struct CrewDuty: Identifiable, Codable {
    var id = UUID()
    var date: Date           // 實際的日期物件
    var dateString: String   // 原始字串 e.g., "05 Fri"
    var type: DutyType
    
    // 顯示用的主要資訊
    var primaryFlightNumber: String? // 當天第一個或主要的航班號，例如 "120"
    var isMultiDay: Bool = false     // 是否延續到隔天 (用來畫橫線)
    
    // 詳細資訊 (點擊後可查看)
    var legs: [FlightLeg] = []
    var metaInfo: String?    // "Location: TPE" 或 "Rest: ..."
}
