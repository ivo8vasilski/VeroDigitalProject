//
//  ViewState.swift
//  VeroDigitalProject
//
//  Created by Ivo Vasilski on 4.12.24.
//
import Foundation

enum ViewState {
    case loading
    case success([Task])
    case error(String)
    case empty
}
