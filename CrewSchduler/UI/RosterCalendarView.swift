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
                    // 顯示航班號碼與線條
                    HStack(spacing: 0) {
                        Spacer()
                        
                        // 只有長班的開始 或 單日班 才顯示航班號
                        if let flightNum = day.flightNumber, (day.isTripStart || day.type == .turnaround) {
                            Text(flightNum)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(indicatorColor)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                        }
                        
                        // 畫線邏輯
                        if day.isContinuing || day.type == .layover || day.isTripStart {
                            // 向右延伸的線
                            Rectangle()
                                .fill(indicatorColor)
                                .frame(height: 3)
                                .frame(width: 25) // 線的長度
                                .offset(y: 2)
                        } else if day.isTripEnd {
                             // 結束點可能需要向左的線 (視需求調整，目前簡化處理)
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