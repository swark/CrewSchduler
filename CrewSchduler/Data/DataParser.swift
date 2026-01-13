import Foundation
import RegexBuilder

class DataParser {
    
    // 暫存年份月份 (實際應從 OCR 抓取，這裡先以此為例)
    static var currentYear = 2025
    static var currentMonth = 12 

    static func parse(ocrText: String) -> [DailySchedule] {
        // 1. 先建立整個月的骨架 (例如 1號到31號 全部都是 .unknown)
        var fullSchedule = MonthHelper.generateMonthDays(year: currentYear, month: currentMonth)
        
        // 2. 解析 OCR 文字，把有資料的日期填進去
        let lines = ocrText.components(separatedBy: "\n")
        
        // Regex 定義
        let datePattern = /^(\d{2})\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/
        let flightPattern = /^([A-Z0-9]+)\s+(\d{4})\s+([A-Z]{3})\s+([A-Z]{3})\s+(\d{4})([+]1)?/
        let offKeywords = ["OFF", "ADO", "Assigned day off"]
        let trainingKeywords = ["BC", "ETS"] // 5. 受訓關鍵字
        
        var currentDayIndex: Int? // 紀錄目前正在處理哪一天 (0-30)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // A. 偵測日期行 (e.g., "17 Fri") -> 定位到陣列中的 index
            if let match = trimmed.firstMatch(of: datePattern),
               let dayInt = Int(match.1) {
                // 找到對應的 index (day - 1)
                if dayInt - 1 < fullSchedule.count {
                    currentDayIndex = dayInt - 1
                }
                continue
            }
            
            // 確保有鎖定日期才開始填資料
            guard let idx = currentDayIndex else { continue }
            
            // B. 偵測航班 (Type 2, 3, 4)
            if let match = trimmed.firstMatch(of: flightPattern) {
                let flightNum = String(match.1)
                let isNextDay = match.6 != nil
                
                // 填入資料
                fullSchedule[idx].legs.append(FlightLeg(
                    flightNumber: flightNum,
                    depAirport: String(match.3),
                    arrAirport: String(match.4),
                    depTime: String(match.2),
                    arrTime: String(match.5),
                    isNextDay: isNextDay
                ))
                
                if fullSchedule[idx].flightNumber == nil {
                    fullSchedule[idx].flightNumber = flightNum
                }
                
                // 初步判斷類型
                if isNextDay {
                    fullSchedule[idx].type = .multiDayTrip // 跨日肯定是長班
                } else {
                    fullSchedule[idx].type = .turnaround // 暫定單日，後續補洞邏輯會修正
                }
                continue
            }
            
            // C. 偵測休假 (Type 1)
            if offKeywords.contains(where: { trimmed.contains($0) }) {
                fullSchedule[idx].type = .dayOff
                fullSchedule[idx].metaInfo = "OFF"
            }
            
            // D. 偵測受訓 (Type 5)
            if trainingKeywords.contains(where: { trimmed.contains($0) }) {
                fullSchedule[idx].type = .training
                fullSchedule[idx].metaInfo = trimmed
            }
        }
        
        // 3. (關鍵步驟) 補洞邏輯：處理長班中間消失的日期
        return fillGaps(schedule: fullSchedule)
    }
    
    static func fillGaps(schedule: [DailySchedule]) -> [DailySchedule] {
        var result = schedule
        
        for i in 0..<result.count {
            // 如果這一天是 "unknown" (OCR 沒抓到資料)
            // 檢查前一天是不是 "multiDayTrip" 或 "layover"
            if result[i].type == .unknown {
                if i > 0 {
                    let prevType = result[i-1].type
                    // 如果前一天是長班，那今天大概率也是長班的一部分 (Layover)
                    if prevType == .multiDayTrip || prevType == .layover {
                        result[i].type = .layover
                        result[i].isContinuing = true
                        
                        // 嘗試把前一天的航班號延續過來顯示 (選用)
                         result[i].flightNumber = result[i-1].flightNumber
                    }
                }
            }
            
            // 修正單日與長班的判斷：
            // 如果某天判斷是 turnaround，但下一天變成了 layover，那這天其實是 multiDayTrip 的開始
            if result[i].type == .turnaround && i + 1 < result.count {
                if result[i+1].type == .layover || result[i+1].type == .multiDayTrip {
                    result[i].type = .multiDayTrip
                    result[i].isTripStart = true
                }
            }
        }
        
        return result
    }
}