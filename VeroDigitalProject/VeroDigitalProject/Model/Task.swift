//
//  Task.swift
//  VeroDigitalProject
//
//  Created by Ivo Vasilski on 4.12.24.
//

import Foundation

struct Task: Identifiable, Codable {
    let id = UUID()
    let task: String
    let title: String
    let description: String
    let colorCode: String?

    enum CodingKeys: String, CodingKey {
        case task = "task"
        case title = "title"
        case description = "description"
        case colorCode = "colorCode"
    }
}
