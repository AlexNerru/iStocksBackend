//
//  Chart.swift
//  App
//
//  Created by AlexNerru on 02.04.2020.
//

import Foundation

struct Chart: Decodable {
    typealias Data = [Point]
    
    struct Point: Decodable {
        let low: Double
        let high: Double
        let date: String
    }
        
    static func thin(data: [Double], max: Int = 100) -> [Double] {
        let delta = Double(data.count) / Double(max)
        var sum = 0.0
        var result: [Double] = []
        
        if data.count > 100 {
            var tempDelta = delta
            var index = 0
            while index < data.count {
                if tempDelta >= 1 {
                    sum += data[index]
                    tempDelta -= 1
                } else {
                    sum += (tempDelta * data[index])
                    result.append(sum / delta)

                    sum = ((1 - tempDelta) * data[index])
                    tempDelta = delta - (1 - tempDelta)
                }
                index += 1
            }

            return data.enumerated()
                       .filter {
                           abs(Double($0.offset)
                               .remainder(dividingBy: delta)) < 0.3
                           }
                       .map { $0.element }
        }
        return data
    }
    
    static func process(chart: Data) -> [Double] {
        return thin(data: chart.map { ($0.high + $0.low) / 2 })
    }
    
    static func process(charts: [(Data, Int)]) -> [Double] {
        var chart = [Double](repeating: 0, count: charts.first!.0.count)
        charts.forEach { chartData in
            chartData.0.enumerated().forEach {
                chart[$0.offset] += (($0.element.high + $0.element.low) / 2) * Double(chartData.1)
            }
        }
        return thin(data: chart)
    }
}


