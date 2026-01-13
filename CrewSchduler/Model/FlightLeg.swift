//
//  FlightLeg.swift
//  CrewSchduler
//
//  Created by Swark on 2025/3/17.
//
import Foundation

struct FlightLeg: Identifiable, Codable, Hashable {
    var id = UUID()
    var flightNumber: String // e.g., "120", "S738"
    var depAirport: String   // e.g., "TPE"
    var arrAirport: String   // e.g., "OKA"
    var depTime: String      // e.g., "0810"
    var arrTime: String      // e.g., "0945"
    var isNextDay: Bool      // 是否有 "+1" 標記
}