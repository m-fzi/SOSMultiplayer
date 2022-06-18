//
//  Logging.swift
//  SOSMultiplayer
//
//  Created by f on 18.06.2022.
//

// Faking it for now

import Foundation

public func debug(_ category: String, _ message: String, file: String = #fileID, line: Int = #line, function: String = #function) {
    // ignore
}

public func log(_ category: String, _ message: String, file: String = #fileID, line: Int = #line, function: String = #function) {
    print("[\(category)][\(file):\(line)](\(function)) \(message)")
}
