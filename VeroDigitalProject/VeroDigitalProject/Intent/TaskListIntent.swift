//
//  TaskListIntent.swift
//  VeroDigitalProject
//
//  Created by Ivo Vasilski on 4.12.24.
//


enum TaskListIntent {
    case loadTasks
    case refresh
    case search(String)
    case scanQRCode(String)
}
