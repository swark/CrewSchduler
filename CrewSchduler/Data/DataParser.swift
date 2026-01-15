import Foundation
import RegexBuilder

class DataParser {
    
    static let baseAirport = "TPE"

    static func parse(ocrText: String) -> [DailySchedule] {
        // 1. [修正] 動態偵測 OCR 文字中的年份與月份
        let (year, month) = detectPeriod(from: ocrText)
        print("Detected Period: \(year)-\(month)") // Debug 用
        
        // 2. 使用偵測到的年月來建立骨架
        var fullSchedule = MonthHelper.generateMonthDays(year: year, month: month)
        
        // 3. 解析 OCR 文字 (後續邏輯保持不變)
        let lines = ocrText.components(separatedBy: "\n")
        
        // Regex 定義
        let datePattern = /^(\d{2})\s+(Mon|Tue|Wed|Thu|Fri|Sat|Sun)/
        let flightPattern = /^([A-Z0-9]+)\s+(\d{4})\s+([A-Z]{3})\s+([A-Z]{3})\s+(\d{4})(.*)/
        let offKeywords = ["OFF", "ADO", "Assigned day off"]
        let trainingKeywords = ["BC", "TRAINING", "COURSE", "G/S"]
        
        var currentDayIndex: Int?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // A. 偵測日期行
            if let match = trimmed.firstMatch(of: datePattern),
               let dayInt = Int(match.1) {
                if dayInt - 1 < fullSchedule.count {
                    currentDayIndex = dayInt - 1
                }
                continue
            }
            
            guard let idx = currentDayIndex else { continue }
            
            // B. 偵測航班
            if let match = trimmed.firstMatch(of: flightPattern) {
                let flightNum = String(match.1)
                let dep = String(match.3)
                let arr = String(match.4)
                let arrTime = String(match.5)
                // [修改] 抓取時間後面的尾綴字串
                let suffix = String(match.6)
                
                // [修改] 只要尾綴包含 "+1"，就視為跨日 (比原本的嚴格比對更安全)
                let isNextDay = suffix.contains("+1") || suffix.contains("*1")
                
                // [新增] Debug 用，印出到底抓到了什麼
                print("[DEBUG] Parsing Flight: '\(trimmed)'")
                print("        -> Suffix: '\(suffix)' | IsNextDay: \(isNextDay)")
                
                let leg = FlightLeg(
                    flightNumber: flightNum,
                    depAirport: dep,
                    arrAirport: arr,
                    depTime: String(match.2),
                    arrTime: String(match.5),
                    isNextDay: isNextDay
                )
                
                fullSchedule[idx].legs.append(leg)
                
                if fullSchedule[idx].flightNumber == nil {
                    fullSchedule[idx].flightNumber = flightNum
                }
                
                // 先標記為 Turnaround，稍後 analyzeTrips 會修正
                fullSchedule[idx].type = .turnaround 
                continue
            }
            
            // C. 偵測休假
            if offKeywords.contains(where: { trimmed.contains($0) }) {
                fullSchedule[idx].type = .dayOff
            }
            
            // D. 偵測受訓
            if trainingKeywords.contains(where: { trimmed.contains($0) }) {
                fullSchedule[idx].type = .training
            }
        }
        
        // 4. 使用 Base-to-Base 邏輯重新順過一次
        return analyzeTrips(schedule: fullSchedule)
    }
    
    // MARK: - [新增] 自動偵測年份與月份
    static func detectPeriod(from text: String) -> (year: Int, month: Int) {
        let currentDates = Date()
        let calendar = Calendar.current
        var detectedYear = calendar.component(.year, from: currentDates)
        var detectedMonth = calendar.component(.month, from: currentDates)
        
        // 1. 嘗試抓取年份 (尋找 2024-2030)
        // 常見格式可能是 "Period: Nov 2025" 或 "Rest: ... (02/01/2026)"
        let yearPattern = /202[0-9]/
        if let match = text.firstMatch(of: yearPattern), let y = Int(match.0) {
            detectedYear = y
        }
        
        // 2. 嘗試抓取月份英文 (JAN, FEB...)
        // 這通常出現在檔頭
        let monthMap = [
            "JAN": 1, "FEB": 2, "MAR": 3, "APR": 4, "MAY": 5, "JUN": 6,
            "JUL": 7, "AUG": 8, "SEP": 9, "OCT": 10, "NOV": 11, "DEC": 12,
            "January": 1, "February": 2, "March": 3, "April": 4, "May": 5, "June": 6,
            "July": 7, "August": 8, "September": 9, "October": 10, "November": 11, "December": 12
        ]
        
        // 掃描前 1000 個字元來找月份，避免抓到跨月的下個月份
        let prefixText = String(text.prefix(1000))
        for (key, value) in monthMap {
            if prefixText.localizedCaseInsensitiveContains(key) {
                detectedMonth = value
                break // 找到就停止 (假設第一個出現的是當月)
            }
        }
        
        return (detectedYear, detectedMonth)
    }
    
    // MARK: - 核心邏輯：Base 到 Base 視為一個 Trip (v2 修正版)
    static func analyzeTrips(schedule: [DailySchedule]) -> [DailySchedule] {
        print("========== [DEBUG] BEFORE analyzeTrips ==========")
        printDebugInfo(schedule)
        
        var result = schedule
        var isAwayFromBase = false
        
        // 新增：用來記錄「跨日抵達」的狀態
        // 如果前一天是 +1 抵達 TPE，這裡會記錄該航班號，並在第二天強制結算
        var pendingArrivalFlight: String? = nil
        
        for i in 0..<result.count {
            let legs = result[i].legs
            let departsFromBase = legs.contains { $0.depAirport == baseAirport }
            let arrivesAtBase = legs.contains { $0.arrAirport == baseAirport }
            
            var decisionLog = ""
            
            // Step 0: 處理跨日抵達 (Handle +1 Arrival)
            // 如果前一天標記了「明天才到」，那今天就是 Trip End
            if let pendingFlight = pendingArrivalFlight {
                result[i].type = .multiDayTrip
                result[i].isTripEnd = true
                result[i].isTripStart = false
                result[i].isContinuing = false
                result[i].flightNumber = pendingFlight
                
                isAwayFromBase = false // 任務結束
                pendingArrivalFlight = nil // 重置
                decisionLog = "Trip END (Delayed Arrival +1)"
                
                // 注意：如果這天剛好又要飛出去 (Turnaround)，下面的邏輯會覆蓋它，這是正確的
                // 但通常長班回來會有休息時間，所以這裡強制設為 End 是安全的
            }
            
            // Step 1: 修正 DayOff 誤判 (Day 31 Issue)
            // 只有當「沒有航段」且「標記為休假/受訓」時，才重置狀態
            // 如果有 Legs，即使 OCR 掃到 OFF (可能是誤判)，也應該視為工作日
            if (result[i].type == .dayOff && legs.isEmpty) || result[i].type == .training {
                isAwayFromBase = false
                pendingArrivalFlight = nil
                decisionLog = "Reset (OFF/Training)"
            }
            // Step 2: 單日來回 (Turnaround)
            else if departsFromBase && arrivesAtBase {
                // 檢查是否回程是 +1
                if let inbound = legs.first(where: { $0.arrAirport == baseAirport }), inbound.isNextDay {
                    // 特殊情況：當天出發，隔天回來 (跨夜班) -> 視為長班開始
                    result[i].type = .multiDayTrip
                    result[i].isTripStart = true
                    result[i].isTripEnd = false
                    
                    if let outbound = legs.first(where: { $0.depAirport == baseAirport }) {
                         result[i].flightNumber = outbound.flightNumber
                    }
                    
                    isAwayFromBase = true // 雖然還在飛，但算 Trip 進行中
                    pendingArrivalFlight = inbound.flightNumber // 標記明天結束
                    decisionLog = "Trip START (Overnight Turnaround +1)"
                } else {
                    // 正常的當天來回
                    result[i].type = .turnaround
                    result[i].isTripStart = false
                    result[i].isTripEnd = false
                    isAwayFromBase = false
                    pendingArrivalFlight = nil
                    decisionLog = "Turnaround"
                }
            }
            // Step 3: 長班開始 (Trip Start) -> 離家
            else if departsFromBase && !arrivesAtBase {
                result[i].type = .multiDayTrip
                result[i].isTripStart = true
                result[i].isTripEnd = false
                
                if let outboundLeg = legs.first(where: { $0.depAirport == baseAirport }) {
                    result[i].flightNumber = outboundLeg.flightNumber
                }
                isAwayFromBase = true
                decisionLog = "Trip START"
            }
            // Step 4: 長班結束 (Trip End) -> 回家
            else if !departsFromBase && arrivesAtBase {
                // 檢查是否是 +1 抵達
                if let inboundLeg = legs.first(where: { $0.arrAirport == baseAirport }) {
                    
                    if inboundLeg.isNextDay {
                        // 雖然這天有飛回來，但其實是「明天」才落地
                        // 所以這天變成「航程中 (Continuing)」，明天才是 End
                        result[i].type = .multiDayTrip
                        result[i].isTripStart = false
                        result[i].isTripEnd = false
                        result[i].isContinuing = true // 線條繼續畫
                        // 這天顯示回程航班號
                        result[i].flightNumber = inboundLeg.flightNumber
                        
                        isAwayFromBase = true // 狀態還沒結束
                        pendingArrivalFlight = inboundLeg.flightNumber // 交代明天收尾
                        decisionLog = "Continuing (Arrives Tomorrow +1)"
                    } else {
                        // 正常當天落地
                        result[i].type = .multiDayTrip
                        result[i].isTripStart = false
                        result[i].isTripEnd = true
                        result[i].flightNumber = inboundLeg.flightNumber
                        
                        isAwayFromBase = false
                        decisionLog = "Trip END"
                    }
                }
            }
            // Step 5: 外站/過夜
            else if isAwayFromBase {
                // 如果已經被 Step 0 (Delayed Arrival) 處理過，就跳過
                if decisionLog.isEmpty {
                    if !legs.isEmpty {
                        result[i].type = .multiDayTrip
                        result[i].isContinuing = true
                        decisionLog = "Continuing (Flying Abroad)"
                    } else {
                        result[i].type = .layover
                        result[i].isContinuing = true
                        decisionLog = "Layover"
                    }
                }
            }
            
            // [DEBUG]
            if result[i].type != .unknown || !legs.isEmpty {
                 print("Day \(result[i].day): \(decisionLog) | Legs: \(legs.count) | Away: \(isAwayFromBase) | Pending: \(pendingArrivalFlight ?? "nil")")
            }
        }
        
        print("========== [DEBUG] AFTER analyzeTrips ==========")
        printDebugInfo(result)
        
        return result
    }
    
    // MARK: - [新增] 輔助 Debug 列印函式
    static func printDebugInfo(_ schedule: [DailySchedule]) {
        for day in schedule {
            // 為了版面整潔，只印出有類型的日子
            if day.type == .unknown && day.legs.isEmpty { continue }
            
            let legsStr = day.legs.map { "\($0.depAirport)->\($0.arrAirport)(\($0.flightNumber))" }.joined(separator: ", ")
            
            var flags: [String] = []
            if day.isTripStart { flags.append("START") }
            if day.isContinuing { flags.append("CONT") }
            if day.isTripEnd { flags.append("END") }
            
            print(String(format: "[%02d] Type: %-12@ | Flt: %-4@ | Flags: %-15@ | Legs: %@",
                         day.day,
                         day.type.rawValue,
                         day.flightNumber ?? "--",
                         flags.description,
                         legsStr))
        }
    }
}
