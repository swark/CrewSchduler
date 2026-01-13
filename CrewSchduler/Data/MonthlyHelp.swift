import Foundation

class MonthHelper {
    // 取得指定年月的所有天數
    static func generateMonthDays(year: Int, month: Int) -> [DailySchedule] {
        var days: [DailySchedule] = []
        let calendar = Calendar.current
        
        // 建立該月1號
        var components = DateComponents(year: year, month: month, day: 1)
        guard let startDate = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: startDate) else {
            return []
        }
        
        // 迴圈生成每一天
        for day in range {
            components.day = day
            if let date = calendar.date(from: components) {
                let weekday = calendar.component(.weekday, from: date)
                
                // 格式化日期字串 (e.g., "17 Fri") 用來跟 OCR 結果比對
                let formatter = DateFormatter()
                formatter.dateFormat = "dd EEE"
                let dateStr = formatter.string(from: date)
                
                days.append(DailySchedule(
                    date: date,
                    day: day,
                    weekday: weekday,
                    dateString: dateStr,
                    type: .unknown
                ))
            }
        }
        return days
    }
}