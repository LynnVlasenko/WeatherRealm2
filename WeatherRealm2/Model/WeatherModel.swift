//
//  WeatherModel.swift
//  WeatherSearcher
//
//  Created by Алина Власенко on 21.03.2023.
//

import Foundation

struct WeatherModel: Codable {
    let name: String?
    let weather: [Weather]?
    let main: Main?
    let wind: Wind?
}

struct Weather: Codable {
    let description: String?
    let icon: String?
}

struct Main: Codable {
    let temperature: Float?
    let pressure: Int?
    let humidity: Int?
    let feels_like: Float?
    private enum CodingKeys: String, CodingKey {
        case temperature = "temp"
        case pressure
        case humidity
        case feels_like
    }
}

struct Wind: Codable {
    let speed: Float?
}
