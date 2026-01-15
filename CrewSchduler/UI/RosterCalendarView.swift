import SwiftUI

struct RosterCalendarView: View {
    // 這裡接收的是整個月的完整日程
    let days: [DailySchedule]
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
    let daysOfWeek = ["日", "一", "二", "三", "四", "五", "六"]
    
    // 計算前面的空白天數 (如果1號不是禮拜天)
    var offsetDays: Int {
        guard let firstDay = days.first else { return 0 }
        // weekday: 1=Sun, 2=Mon... 所以 offset = weekday - 1
        return firstDay.weekday - 1
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 星期標頭
            HStack(spacing: 0) {
                ForEach(daysOfWeek, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
            }
            .background(Color.black)
            
            // 月曆網格
            LazyVGrid(columns: columns, spacing: 0) {
                // 1. 補前面的空白格
                ForEach(0..<offsetDays, id: \.self) { _ in
                    Color.black.frame(height: 80)
                }
                
                // 2. 顯示每一天
                ForEach(days) { daySchedule in
                    DayCell(day: daySchedule)
                        .frame(height: 80)
                        .border(Color.gray.opacity(0.2), width: 0.5)
                }
            }
        }
        .background(Color.black)
    }
}

struct DayCell: View {
    let day: DailySchedule
    
    // 決定顯示顏色
    var indicatorColor: Color {
        // 範例邏輯：如果是長班(multiDayTrip)或純過夜(layover)顯示黃色，單日班紅色，休假綠色
        switch day.type {
        case .multiDayTrip, .layover:
            return .yellow
        case .turnaround:
            return .red
        case .dayOff:
            return .green
        case .training:
            return .blue
        default:
            return .white
        }
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black // 背景全黑
            
            VStack(alignment: .leading, spacing: 2) {
                // 1. 日期數字
                Text("\(day.day)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(4)
                
                Spacer()
                
                // 2. 內容顯示區
                switch day.type {
                case .dayOff:
                    Text("OFF")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundStyle(.green)
                        .padding(.leading, 4)
                        .padding(.bottom, 4)
                    
                case .turnaround, .multiDayTrip, .layover:
                    HStack(spacing: 0) {
                        // 左側線條 (如果是中間日或結束日，要接續前一天)
                        if day.isContinuing || day.isTripEnd {
                             Rectangle()
                                .fill(indicatorColor)
                                .frame(height: 3)
                                .frame(maxWidth: .infinity) // 填滿左半邊
                                .offset(y: 2)
                        } else {
                             Spacer() // 開始日左邊要是空的
                        }

                        // 航班號碼 (只在開始或單日班顯示，避免擁擠)
                        if let flightNum = day.flightNumber, (day.isTripStart || day.type == .turnaround || day.isTripEnd) {
                            Text(flightNum)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(indicatorColor)
                                .lineLimit(1)
                                .layoutPriority(1) // 確保文字優先顯示
                                .padding(.horizontal, 2)
                        }
                        
                        // 右側線條 (如果是開始日或中間日，要延伸到明天)
                        if day.isContinuing || day.isTripStart || (day.type == .layover) {
                             Rectangle()
                                .fill(indicatorColor)
                                .frame(height: 3)
                                .frame(maxWidth: .infinity) // 填滿右半邊
                                .offset(y: 2)
                        } else {
                             Spacer() // 結束日右邊要是空的
                        }
                    }
                    .padding(.bottom, 12)
                    
                case .training:
                    Text("Training")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .padding(.leading, 4)
                        
                case .unknown:
                    EmptyView()
                }
            }
        }
    }
}